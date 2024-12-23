#ifndef __MORPH_H__
#define __MORPH_H__

#include <string>
#include <vector>
#include <iostream>
#include <fstream>

#include "global.h"
#include "stringstring_hash.h"

using namespace std;

string const EMPTY = "!!!";

/*
 * Text Morphology class: stem and stop words
 *
 * The stemmer class will cache past results, meaning it should get faster
 * the more it is used.
 *
 * Much of this code is adapted from Hussein Suleman's Perl stemmer.  In fact,
 * it was tweaked until the results matched on Hussein's test suite of ~ 70
 * terms.
 *
 * NOTE: The cached stemming and stopping distringuishes "add" mode in order 
 * to keep the dictionary of mappings from being spammable.  In query mode,
 * when you are accepting input from anonymous users, you should stem with
 * add = 0.  This keeps novel terms from being added to memory, preventing a
 * potential DoS attack through memory consumption.
 *
 */
class Morphology : public stringstring_hash {
	private:

		vector<string> _values;

		bool isvowel( char c );
		string vowelize( string );
		bool suffix( string const &word, string const &suffix );
		bool isLetter(char);
		string removePunc(string);

		int porterm( string word );

		/* just do stemming */
		string stem ( string word );

	public:
		Morphology(); 

		/* stem and stop a word. if add is 1, new words are added to cache */
		string stem_and_stop( string word, int add );

		/* same as above but assumes add = 1 */
		string stem_and_stop( string word );

		/*
		void print();		//MG
		int writeDisk(int, fstream&);	//MG
		int readDisk(int, fstream&);	//MG
		*/
};

#endif
