#include <strstream>

#include <pthread.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <asm/errno.h>
#include <unistd.h>
#include <assert.h>
#include <time.h>

#include "daemon.h"
#include "query.h"

// forward decls
void* se_thread_handle (void *);
void* poll_thread_handle (void *);

/* these must be global so the term handler can get them */
pid_t childunix, childinet;
vector<pid_t> children;

/* term for main searchd process */
void handler_term( int arg ) {
	if( childunix ) kill( childunix, SIGTERM );
	if( childinet ) kill( childinet, SIGTERM );
	exit( 0 );
}

/* handle sigchld to clean up zombies */
void handler_child( int arg ) {
	wait( NULL );
}

/* term for listeners */
void handler_term_listener( int arg ) {
	/* kill all the children */
	for( int i=0; i < children.size(); ++i ) {
		if( children[i] )
			kill( children[i], SIGTERM );
	}
}

/* sigchld for listeners */
void handler_child_listener( int arg ) {
	pid_t ch = wait( NULL );
	for( int i=0; i < children.size(); ++i )
		if( children[i]==ch ) children[i] = 0;
}

searchdaemon::searchdaemon( confhelper &options ) :
	_options( options ),
	_log( options.get_string( "LogFile" ), logger::DEBUG ) { }

void searchdaemon::listenloop( listener &l ) {
	pthread_t thread;
	pthread_attr_t poll_attr;
	pthread_attr_t se_attr;

	assert(pthread_attr_init (&poll_attr) == 0);
	assert(pthread_attr_init (&se_attr) == 0);

	pthread_attr_setdetachstate(&se_attr, PTHREAD_CREATE_DETACHED);

	engine.initmutex();

	// set up memory polling thread
	//
	int pollint = _options.get_int( "PollInterval" );
	pthread_t poll_thread;
	if (pollint > 0) {
		assert(pthread_create(
			&poll_thread,
			&poll_attr,
			(void*(*)(void*))poll_thread_handle,
			(void*)this
		) == 0);
	}

	// connection handling loop
	//
	while( true ) {
		next_conn = new connection( l.get_connection() );
		
		// create a thread for the connection
		assert(pthread_create(
			&thread,
			&se_attr,
			//(void*)thread_handle,
			(void*(*)(void*))se_thread_handle,
			(void*)this
		) == 0);
	}

	// stop memory polling thread. NOTE: this is actually unreachable. we
	// need a graceful exit.
	//
	if (pollint > 0) {
		pthread_cancel(poll_thread);
	}
}
// dummy function to receive memory polling thread handling
//
void* poll_thread_handle(void *arg) {

	// init polling control variables (condition and mutex)
	//
	pthread_cond_t poll_cond;
	pthread_mutex_t poll_mutex;
	
	pthread_mutexattr_t poll_ma;
	pthread_mutexattr_init(&poll_ma);
	pthread_mutex_init(&poll_mutex, &poll_ma);
			
	pthread_cond_init(&poll_cond, NULL);

	// localize some stuff we need to refer to
	searchdaemon *s = (searchdaemon *)arg;
	vector_search *engine = s->get_engine();
	confhelper& options = s->get_options();
	
	int interval = options.get_int( "PollInterval" ) * 60; // minutes->seconds

	// lock poll condition mutex
	pthread_mutex_lock(&poll_mutex);

	// loop indefinitely around polling
	// 
	while (1) {
		
		// "sleep"
		//
		timespec u_spec;
		time_t until = time(NULL) + interval;
		u_spec.tv_sec = until;
		u_spec.tv_nsec = 0;
		
		pthread_cond_timedwait(&poll_cond, &poll_mutex, &u_spec);

		// do a memory poll
		//
		engine->poll();
	}
	
	// TODO: this is never reached. the quit() command needs to be made 
	// functional. different return value from connection thread?
	pthread_mutex_unlock(&poll_mutex);
}

// dummy function to receive search engine thread handling
//
void* se_thread_handle(void *arg) {
	
	searchdaemon *s = (searchdaemon *)arg;

	// invoke handler for current connection
	//
	s->handle_current();

	// APK - pthread-style exit
	pthread_exit(0);
}

// public access to tell the searchdaemon to handle the incoming connection. 
// needed for interface with pthreads.
//
void searchdaemon::handle_current( void ) {

	// copy next connection into a local variable, since when the next one
	// comes in, the value of next_conn will change.
	//
	connection* c;
	c = next_conn;
	
	// call the handler.
	//
	handle(*c);

	delete c;	// free mem
}

// main connection handler
//
void searchdaemon::handle( connection c ) {
	c.send_message( connection::HELLO, string( "searchd" ) );

	vector<string> t;
	string cmd( "" );
	do {
		t = c.get_response();

		// lost peer
		if( t[0] == "DISCON") break;

		if( t.size() < 1 ) {
			c.send_message( connection::BADCMD, "Empty command" );
		} 
		else {
			cmd = t[0];

			/* index a document chunk (corresponds to XML element) */
			
			if (cmd == "index") {
#ifdef LOG_INDEXING
				_log.lprintf( logger::DEBUG, "Got index command\n" );
#endif
				c.send_message( connection::OK, "indexing; send IDs" );

				// read in doc/tag IDs
				vector<string> IDs = c.get_index_IDs();
				assert(IDs.size()==2);
				string docID=IDs[0];
				string tagID=IDs[1];
#ifdef LOG_INDEXING
				_log.lprintf( logger::DEBUG, "Got index IDs\n" );
#endif
				c.send_message( connection::OK, "send words" );

				// read in terms
				vector<string> words = c.get_words();
#ifdef LOG_INDEXING
				_log.lprintf( logger::DEBUG, "Receiving indexing words\n" );
#endif

				// add to inverted index
				engine.add_element(words, docID, tagID);

				//cout << "printing ii" << endl;
				//engine.print();
				//cout << "done printing ii" << endl;
			} 

			/* unindex based on a document id */

			else if (cmd == "unindex") {
#ifdef LOG_INDEXING
				_log.lprintf( logger::DEBUG, "Got unindex command\n" );
#endif
				c.send_message( connection::OK, "unindexing; send ID" );

				string docID = c.get_unindex_ID();
#ifdef LOG_INDEXING
				_log.lprintf( logger::DEBUG, "Unindexing\n" );
#endif

				engine.remove_doc(docID);
			}

			/* execute a search */

			else if (cmd == "search") {
				_log.lprintf( logger::DEBUG, "Got search command\n" );
				c.send_message( connection::OK, "send query" );

				vector<query_node> query = c.get_query();
				_log.lprintf( logger::DEBUG, "Searching\n" );

				vector<query_result> results = engine.search(query);

				if( results.size()>0 ) {
					_log.lprintf( logger::DEBUG, "Sending some search results\n" );
					c.send_message( connection::BEGINSEARCHRESULT, "here are some results");
					for( int i=0; i < results.size(); i++ )
						c.send_search_result(results[i]);

					c.send_message( connection::ENDSEARCHRESULT, "that is all" );
					// cleanup
					free_query_result_vector(results);
				} 
				else {
					c.send_message( connection::NOSEARCHRESULT, "no results" );
				}

				// cleanup
				free_query_vector(query);
			}

			/* execute a limited search */

			else if (cmd == "limitsearch") {
				_log.lprintf( logger::DEBUG, "Got search command\n" );
				c.send_message( connection::OK, "send query" );

				vector<query_node> query = c.get_query();
				int limit = c.get_limit();
				_log.lprintf( logger::DEBUG, "Limited Searching\n" );

				// actual number of matches gets returned in nmatches
				int nmatches = limit;
				// 1 is useidf
				vector<query_result> results = engine.search(query, 1, nmatches);

				if( results.size() > 0 ) {

					_log.lprintf( logger::DEBUG, "Sending search results number of matches\n" );
					char buf[101];
					ostrstream os(buf, 100);	
					os << nmatches << endl;

					c.send_message( connection::NMATCHES, buf);

					_log.lprintf( logger::DEBUG, "Sending some search results\n" );
					c.send_message( connection::BEGINSEARCHRESULT, "here are some results");
					for( int i=0; i < results.size() && i < results.size(); i++ )
						c.send_search_result(results[i]);

					c.send_message( connection::ENDSEARCHRESULT, "that is all" );

					// cleanup
					free_query_result_vector(results);
				} 
				else {
					c.send_message( connection::NOSEARCHRESULT, "no results" );
				}

				// cleanup
				free_query_vector(query);
			}

			/* shut down daemon */

			else if( cmd == "quit" ) {
				_log.lprintf( logger::DEBUG, "Shutting down.\n" );
				c.send_message( connection::BYE, "Thanks for playing" );
			} 

			/* get statistics */

			else if ( cmd == "stats" ) {

				c.send_message( connection::OK, "printing statistics" );
				engine.stats();
			}

			/* squeeze down data structures to conserve memory, do other 
			 * maintenance */

			else if ( cmd == "compactify" ) {

				c.send_message( connection::OK, "compactifying data structures" );
				engine.stats();
			}
			
#ifdef STRUCTURE_QUERIES
			/* structure a query */

			else if (cmd == "structurequery") {
				_log.lprintf( logger::DEBUG, "Got structurequery command\n" );
				c.send_message( connection::OK, "send query" );

				vector<query_node> query = c.get_query();

				_log.lprintf( logger::DEBUG, "Creating structures\n" );
				vector<query_score> squeries = engine.build_structures(query);

				if ( squeries.size() > 0 ) {
					_log.lprintf( logger::DEBUG, "Sending ranked queries\n" );
					c.send_message( connection::BEGINQUERYRANK, "here are the structured queries");
					for( int i = 0; i < squeries.size(); ++i)
						c.send_query_score(squeries[i]);
					c.send_message( connection::ENDQUERYRANK, "that is all");

					// cleanup
					free_query_score_vector(squeries);
				}
				else {
					c.send_message( connection::NOSTRUCTURES, "no structures" );
				}

				// cleanup
				free_query_vector(query);
			}
#endif

			/*
			else if ( cmd=="printindex" ) {

				c.send_message( connection::OK, "printing inverted index" );
				engine.print();
			}
			*/

			/* say what? */

			else c.send_message( connection::BADCMD, string( "Unknown command " ) + cmd );
		}
	} while( cmd != "quit" );

	c.finish();
}

void searchdaemon::go() {

	/* let search engine get at logger */
	engine.setlogger(&_log);

	/* fork off listeners */
	_log.lprintf( logger::DEBUG, "Looks good: %d\n", getpid() );
	childunix=0;
	childinet=0;

	/* fork off a unix listener .. */
	if( _options.get_bool( "ListenUnix" ) ) {
		_log.lprintf( logger::DEBUG, "Forking UNIX domain listener\n" );
		if( (childunix=fork())==0 ) {
			listener unix_listen( _log, _options.get_string( "UnixSocket" ) );
			listenloop( unix_listen );
		}
	}

	/* .. and an inet listener */
	if( _options.get_bool( "ListenInet" ) ) {
		_log.lprintf( logger::DEBUG, "Forking inet domain listener\n" );
		if( (childinet=fork())==0 ) {
			listener inet_listen( _log, _options.get_string( "BindAddress" ), _options.get_int( "ListenPort" ) );
			listenloop( inet_listen );
		}
	}

	signal( SIGTERM, handler_term );

	/* now just chill for a bit */
   while( childunix != 0 || childinet != 0 ) {
	 pid_t child = wait( NULL );
	 if( child==childunix ) childunix = 0;
	 if( child==childinet ) childinet = 0;
   }
	exit( 0 );
}
