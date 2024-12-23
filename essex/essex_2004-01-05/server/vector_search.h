/******************************************************************************
 
 The vector space search engine class.	Contains inverted index, and routines
 for accessing it.

 - Essentially completely rewritten, spring '03 by Aaron Krowne.  now based 
   almost entire on custom hash maps (intmap and stringmap).
 - Originally by Matt Gracey, fall '02
 
******************************************************************************/

#ifndef VECTOR_SEARCH_H 
#define VECTOR_SEARCH_H

#include <string>
#include <vector>
//#include <pthread_alloc>
#include <cstring>
#include <iostream>
#include <math.h>
#include <fstream>
#include <map>
#include <pthread.h>
#include <stdio.h>

#include "util.h"
#include "logger.h"
#include "morphology.h"
#include "stringmap.h"
#include "intmap.h"
#include "global.h"
#include "query.h"
#include "docrec.h"
#include "posting_list.h"

/* Define what in-field combination to use when structuring the queries */
//#define STRUCT_SUM
//#define STRUCT_AVG
#define STRUCT_OR

/* Define what field combination to use when  structuring the queries */
#define STRUCT_F_AVG
//#define STRUCT_F_AND

/* Minimum number of documents in which a word should appear in a field to be
   considered for query structuring */
#define MIN_GFF 1


class vector_search {
private:

	/* vector of postings lists, the core of the inverted index */
	intmap<posting_list*>* inverted_index;

	/* dictionaries for tags, words, and doc ids */
	stringmap<short> tagid_lookup;
	stringmap<int> wordid_lookup;
	stringmap<int> docid_lookup;

#ifdef STRUCTURE_QUERIES
	/* maps that keep which words occur in each tag field. */
	intmap<intmap<int>*> tag_dict;
#endif

	/* a reverse lookup for docids, so we can get doc name from id */
	intmap<string> docid_reverse;

	/* document records, for fast removal and magnitude calculation 
	 * (this is essentially a forward index) */
	intmap<docrec*> doc_list;

	int wordid_counter;
	int tagid_counter;
	int docid_counter;

	/* text morpher */
	Morphology morpher;
	
	/* miscellany */
	int num_docs;
	int num_words;
	int num_tags;
	
	/* logger */
	logger* _log;

	/* index access mutex */
	/* this is very coarse-grained control.	 really we should do some 
	 * read/write mutexing.	 */

	pthread_mutex_t index_access_mutex;
	
	// ID and tag maintenance.
	
	/* make (or get) the id of a word */
	int make_wordid(string _word);

	/* can only get (not make) a word id */
	int get_wordid(string _word);

	/* get the id of a document name, which may also assign an id */
	int get_docid(string _docname);

	/* get the name of a document, given its id */
	string get_docname(int _docid);

	/* make (or get) id of a tag name */
	int make_tagid(string _tagname);

	/* can only get (not make) a tag id) */
	int get_tagid(string _tagname);

#ifdef STRUCTURE_QUERIES
	
	// structured query stuff

	/* prepares the query for structuring */
	void _structure_prepare_query(vector<query_node>&);

	/* build word/tag combinations for structuring queries */
	void add_query_tags(vector<query_node>, vector<query_score>&);

	/* compute the score of a structured query */
	double compute_score(const vector<query_node>&, intmap<float> field_weights, stringmap<double>& query_cache);
	
	/* make a unique hash key from query */
	string get_query_key(vector<query_node>& query);

	/* compute the score for just one tag sub-query of a structured query */ 
	double compute_tag_score(const vector<query_node>&);
#endif

	// search helpers
	
	/* get IR data in the form of various slices and views of the postings
	 * lists */
	void _search_get_IR_data(
			vector<query_node> query, 
			vector<intmap<short>*>& doc_postings, 
			vector<float>& dfs,
			intmap<intmap<short>*>& field_counts, 
			vector<intmap<int>*>& field_frequencies,
			int structmode);

	/* filter the returned documents list based on force and forbid clauses */
	void _search_force_forbid(intmap<MYBOOL>& found_docs, 
			vector<query_node> query, 
			vector<intmap<short>*> doc_postings);

	/* initialize field weights based on query parameters */
	intmap<float> _search_prepare_field_weights(vector<query_node> query);
	
	/* basic initialization of a query; stemming, splitting, removing */
	int _search_prepare_query(vector<query_node>& query);

	/* sort results set. also unifies results set with external document id 
	 * labels.  */

	vector<query_result> _search_sort_results (
		intmap<float> similarity, 
		int& limit);

	/* calculate similarity between document vectors and query.  */
	   
	void _search_calc_similarity(
		intmap<float>& similarity,
		vector<query_node> query,
		int mag_query, 
		intmap<MYBOOL> found_docs, 
		vector<intmap<float> > weighted_postings, 
		intmap<intmap<short>*> field_counts, 
		vector<intmap<int>*> field_frequencies,
		intmap<float> field_weights,
		vector<float> dfs,
		int structmode);

	/* get (potentially ntf) weighted versions of per-query-term postings list
	 * vectors. */

	vector<intmap<float> > _search_get_weighted_postings(
		vector<query_node> query,
		vector<intmap<short>*> doc_postings,
		intmap<MYBOOL> found_docs,
		int hash_init);

	/* clean up memory structures created during searching */

	void _search_cleanup(
		vector<intmap<short>*> doc_postings,
		intmap<intmap<short>*> field_counts,
		vector<intmap<int>*> field_frequencies);
	
public:
	/* core functions */

	/* constructor */
	vector_search() : 
		tagid_lookup(-1), 
		wordid_lookup(-1), 
		docid_lookup(-1), 
#ifdef STRUCTURE_QUERIES
		tag_dict(NULL),
#endif
		docid_reverse("UNKNOWN"),
		morpher(),
		num_docs(0), 
		num_words(0), 
		num_tags(0), 
		doc_list(NULL), 
		wordid_counter(0),
		docid_counter(0), 
		tagid_counter(0),
		_log(NULL)
		{
			inverted_index = new intmap<posting_list*> (NULL);
		}
		
	/* initialize mutex stuff */
	void initmutex();

	/* remove a document from the index */
	void remove_doc(string _docname);

	/* index the text of a single element of the document */
	void add_element(vector<string> words, const string _docname, const string _tagname);

	/* execute a search for a query, get a result set. unlimited, no 
	 * structmode */
	vector<query_result> search(vector<query_node>);

	/* execute a search for a query, get a result set. unlimited, allow setting
	 * structmode */
	vector<query_result> search(vector<query_node>, int structmode);

	/* version of search that limits # of results for efficiency. this is the
	 * actual core version. */
	vector<query_result> search(vector<query_node>, int structmode, int& limit);

#ifdef STRUCTURE_QUERIES
	/* given an unstructured query, creates a list of possible structured
	 * queries and ranks them according to the contents of the database. */
	vector<query_score> build_structures(vector<query_node>);
#endif 

	/* print some statistics */
	void stats();

	/* clean up wasted space */
	void compactify();

	/* "poll" major search engines structures */
	void poll(void);

	/* set a logger */
	void setlogger(logger* log) { _log = log; }

	/*void print();*/
	
	/* persistance */

	/*
	void writeDisk();
	void readDisk();
	void revision_add(vector<string>, const string, const string);
	void revision_remove(const string, const string);
	int process_revision(fstream&, int);
	int read_add(fstream& file, int);
	int read_remove(fstream& file, int);
	*/
};

#endif
