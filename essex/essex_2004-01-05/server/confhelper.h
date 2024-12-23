/*
 * confhelper.h - class to parse and deal with configuration files
 */

#if !defined( __CONFHELPER_H__ )
#define __CONFHELPER_H__

#include <string>
#include <map>
#include <vector>

#include "config.h"

using namespace std;

/* define the config keys, including default values */

const string CONF_MAIN =
	string( "ListenUnix,bool,true\n" ) +
	string( "ListenInet,bool,true\n" ) +
	string( "UnixSocket,string,\"searchd.sock\"\n" ) + 
	string( "BindAddress,string,\"0.0.0.0\"\n" ) +
	string( "ListenPort,int,1723\n" ) +
	string( "PollInterval,int,10\n" ) +
    string( "PidFile,string,\"searchd.pid\"\n" ) + 
    string( "User,string,\"searchd\"\n" ) +
    string( "Group,string,\"searchd\"\n" ) +
	string( "LogFile,string,\"searchd.log\"" ); 

class confhelper {
	public:
	private:
		enum {
			BOOL = 0,
			INT = 1,
			STRING = 2,
			SUBSECTION = 3
		};

		map<string,int> _typeof;
		map<string,string> _value;
	public:
		confhelper( string const &conffile, string const &format );

		bool get_bool( string const &key ) const;
		int get_int( string const &key ) const;
		string get_string( string const &key ) const;
};

#endif
