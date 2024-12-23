
#if !defined( __CONNECTION_H__ )
#define __CONNECTION_H__

#include <stdio.h>
#include <string>
#include <unistd.h>
#include <vector>

#include "query.h"
#include "util.h"

using namespace std;

class connection {
	private:
		int _s;
	public:
		enum {
			HELLO = 100,
			OK = 101,
			BYE = 102,

			NOSEARCHRESULT = 200,
			BEGINSEARCHRESULT = 201,
			ENDSEARCHRESULT = 202,
			NMATCHES = 203,

			BADCMD = 300,
			DEADCONN = 301,

			NOSTRUCTURES = 400,
			BEGINQUERYRANK = 401,
			ENDQUERYRANK = 402,
		};

		connection( int socket ) : _s( socket ) { }

		void send_message( int code, string msg );
		/* void send_class_result( int cat, int rel ); */
		void send_search_result(query_result);
		void send_query_score(const query_score&);

		vector<string> get_response();
		string get_line();
		int get_limit();
		vector<string> get_words();

		vector<string> get_index_IDs();
		string get_unindex_ID();
		vector<query_node> get_query();


		void finish() { close( _s ); }
};
#endif
