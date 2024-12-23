/******************************************************************************

 Class definition for a single postings list.

******************************************************************************/

#ifndef POSTING_LIST_H
#define POSTING_LIST_H 

#include <string>
#include <iostream>
#include <vector>
#include <fstream>
#include <map>
#include <cassert>

#include "global.h"
#include "intmap.h"
#include "vlmap.h"

using namespace std;

/* postings list entry struct */

#ifdef RELAX_POSTINGS

/* 6-byte version */ 

typedef struct postent {
	unsigned int docid;			// the id of the document 
	unsigned char count;		// an occurrence count. total over all tags. 
	unsigned char tagid;		// tagid the word occurs in
} postentry;

const struct postent EMPTY_ENTRY = {0, 0, 0};

#else

/* super-compact version... only 4 bytes per posting entry. */

/* unfortunately this limits us to 16.7 million documents, 16 unique tags,
 * and 16 different term counts, but this should suffice for many 
 * purposes. */

typedef struct postent {

	unsigned short docid;		// docid, low 2 bytes
	unsigned char docid_high;	// high byte
	
	// count and tagid; low nibble is count, high is tagid. 
	unsigned char count_and_tagid;
} postentry;

const struct postent EMPTY_ENTRY = {0, 0, 0};

#endif


/* new postings list class */

class posting_list {

private:

	// the postings list
	vector<postentry> list;

#ifdef SUPER_FAST_UNINDEXING
	// keep track of index of last removed record and check it first for next
	// unindexed record. this removes the need to do a binary search when
	// unindexing in order.
	int last;	
#endif

public:
	// don't have to do anything for constructor
	//
	posting_list() 
#ifdef SUPER_FAST_UNINDEXING
	:
		last (-1) 
#endif
	{  }

	// unless you want to allocate a specifically-sized vector
	//
	posting_list(int _init_size) : list(_init_size, EMPTY_ENTRY)
#ifdef SUPER_FAST_UNINDEXING
	, last(-1)  
#endif
	{ }

	// copy constructor
	//
	posting_list(posting_list& from) : list(from.get_filled(), EMPTY_ENTRY) {
		for (int i = 0; i < from.get_filled(); i++) {
			list.push_back(from[i]);
		}
	}

	// compact postings list accessors
	inline int get_docid(postentry&);
	inline void set_docid(postentry&, int);
	inline int get_count(postentry&);
	inline void set_count(postentry&, int);
	inline int get_tagid(postentry&);
	inline void set_tagid(postentry&, int);

	// get the percentage of records using their tag lists
	float get_taglist_frac();

	// get the allocated memory size
	int get_size() { return list.capacity(); }

	// get the underlying vector capacity
	int get_capacity() { return list.capacity(); }

	// get the filled posting entry count 
	int get_filled() { return list.size(); }
	
	// add a word instance to the postings list
	void add(int _docid, int _tagid);
	
	// remove list entry for a docid (incl. deallocating its tag list)
	void remove(int _docid);

	// get a posting entry at a specific index
	postentry operator[](int index) {
		
		return list[index];
	}

	// is the postings list empty?
	//
	bool is_empty() { return !list.size(); }

	void print() { } // implement later

	// This method gets "slices" of the posting list data which contain 
	// necessary and sufficient information for rank calculations.  This slice
	// is filtered based on field specifier criteria, otherwise we'd just
	// return different "interpretations" of the entire postings list, and 
	// wouldn't call them "slices".
	//
	// The first slice returned is a {docid => count} map.  This contains
	// standard tf information for each full document in the list.
	//
	// The second slice, updated from the passed-in field_counts parameter,
	// contains {docid => {field => count}}, in other words a "global" map
	// of occurrence counts of query words in the various fields of each 
	// document.  This is useful for calculating the field wieght component 
	// of the document rank later.
	//
	// The third slice, updated from the passed-in field_frequencies parameter,
	// is of the form {field => count}.  We assume the caller keeps one of 
	// these for each query term.  Thus at the end of all postings list calls,
	// these structures should contain frequencies of each term in the various
	// fields that term occurred in, in any document.  This is useful (and
	// only performed) for structured query weighting.
	//
	intmap<short>* get_list(
		int collection_size, 	// used for structure size estimation
		int num_tags, 			// same
		int _tagid,				// tag to filter by, or -1
		intmap<intmap<short>*>& field_counts, 	// described above
		intmap<int>* field_frequencies);
};

#endif
	

	
