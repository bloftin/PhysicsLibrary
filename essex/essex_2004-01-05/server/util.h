/*
 * util.h - random utility fucntions
 */

#include <string>
#include <vector>

using namespace std;

// not sure why we need these... there is some goofy problem with bool and 
// STL
#define MYBOOL unsigned char
#define MYTRUE 1
#define MYFALSE 0

// utility defines

// square a number
#define SQUARE(x) ((x)*(x))

// get the index of iterator i in vector v
#define IDX(i,v) ((i)-(v.begin()))

vector<string> split_for_indexing( vector<string> &inlist );
vector<string> split_for_indexing ( string const &s );
vector<string> split( char c, string const &s );
vector<string> splitwhite( string const &s );
