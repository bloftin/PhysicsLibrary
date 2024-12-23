/******************************************************************************

 Vector space search engine routines, implemented.

******************************************************************************/

#include <algorithm>
#include <string.h>
#include <time.h>

#include "vector_search.h"
#include "intmap.h"
#include "rankmm.h"
//#include "vlrankmap.h"

/* init mutexes */
void vector_search::initmutex() {
	
	// init our index mutex
	pthread_mutexattr_t ma;
	pthread_mutexattr_init(&ma);
	pthread_mutex_init(&index_access_mutex, &ma);
}

/* make (or get) an integer id for a word (in the "dictionary") */
int vector_search::make_wordid(string _word) {
		
	int id = wordid_lookup[_word];

	// new doc
	if (id == -1) {
		wordid_lookup[_word] = wordid_counter;
		id = wordid_counter;
		wordid_counter++;
		num_words++;
	}

	return id;
}

/* only get, not make, a word id */
int vector_search::get_wordid(string _word) {
		
	return wordid_lookup[_word];
}

/* get the id of a document name, which may also assign an id */
int vector_search::get_docid(string _docname) {
		
	int id = docid_lookup[_docname];

	// new doc
	if (id == -1) {
		docid_lookup[_docname] = docid_counter;
		id = docid_counter;
		
		docid_counter++;
		num_docs++;

		// also add to reverse lookup map
		//
		docid_reverse[id] = _docname;
	}

	return id;
}

/* get the name of a document, given id. if not found, returns "UNKNOWN" */
string vector_search::get_docname(int _docid) {
		
	string docname;

	if (docid_reverse.exists(_docid)) {
		docname = docid_reverse[_docid];
	} else {
		docname = "UNKNOWN";
	}

	return docname;
}

/* make (or get) the id of a tag name, which may also assign an id */
int vector_search::make_tagid(string _tagname) {
		
	int id = tagid_lookup[_tagname];

	if (id == -1) {
		tagid_lookup[_tagname] = tagid_counter;
		id = tagid_counter;
		tagid_counter++;
		num_tags++;
	}

	return id;
}

/* can only get, not make, a tag id from a tag name */
int vector_search::get_tagid(string _tagname) {

	return tagid_lookup[_tagname];
}

/* remove a document from the index, given its string identifier/name */
void vector_search::remove_doc(string _docname) {
	
	assert (pthread_mutex_lock(&index_access_mutex) == 0);
	
	int docid = get_docid(_docname);

	docrec* doc_record = doc_list[docid];

	// access the doc record for the document. this is a list of word ids 
	// indexed for the document.  step through this and remove postings list
	// data for this document for each words
	//
	if (doc_record != NULL) {

		intmap<char>::iterator it;
		for (it = doc_record->words->begin(); it != doc_record->words->end(); it++) {

			int wordid = it.get_key();

			// get the postings list for the word
			// 
			posting_list* plist = (*inverted_index)[wordid];

			// remove any traces of the document from the postings list
			//
			if (plist != NULL) {
				plist->remove(docid);

				// if the postings list is empty, remove it
				//
				if (plist->is_empty()) {
					
					inverted_index->remove(wordid);
					delete plist;
				}
			}
		}

		// remove the doc record and deallocate it
		//
		delete doc_record->words;
		delete doc_list.remove(docid);

		// remove the docname lookup data
		//
		docid_lookup.remove(_docname);
		docid_reverse.remove(docid);
	}

	assert (pthread_mutex_unlock(&index_access_mutex) == 0);
}

/* poll major search engine structures to ensure they don't get swapped */
void vector_search::poll(void) {

	assert (pthread_mutex_lock(&index_access_mutex) == 0);

//	time_t curtime = time(NULL);
//	cout << "vector_search::poll : beginning poll (" << curtime << ")" << endl;

	intmap<posting_list*>* new_index = new intmap<posting_list*>(inverted_index->get_size(), NULL);	

	intmap<posting_list*>::iterator ii;

	// iterate over postings lists
	// 
	for (ii = inverted_index->begin(); ii != inverted_index->end(); ii++) {

		posting_list* cur_posting = *ii;
		
		// iterate over posting entries
		//
		for (int i = 0; i < cur_posting->get_filled(); i++) { 
		
			(*cur_posting)[i]; // retrieve, nop
		}
	}

	// iterate over doclists
	// 
	intmap<docrec*>::iterator di;

	for (di = doc_list.begin(); di != doc_list.end(); di++) {

		intmap<char>* words = (*di)->words;

		intmap<char>::iterator wi;

		for (wi = words->begin(); wi != words->end(); wi++) {
			*wi; // retrieve, nop
		}
	}

//	curtime = time(NULL);
//	cout << "vector_search::poll : ending poll (" << curtime << ")" << endl;

	assert (pthread_mutex_unlock(&index_access_mutex) == 0);
}

/* clean up wasted space. this is done by re-allocating everything. */
void vector_search::compactify() {

	assert (pthread_mutex_lock(&index_access_mutex) == 0);

	intmap<posting_list*>* new_index = new intmap<posting_list*>(inverted_index->get_size(), NULL);	

	intmap<posting_list*>::iterator it;

	// for each postings list
	for (it = inverted_index->begin(); it != inverted_index->end(); it++) {

		// create a postings list with the memory allocated precisely and
		// the values from the old list
		// 
		posting_list* new_posting = new posting_list(*(*it));

		new_index[it.get_key()] = new_posting;
	}

	// clear out old index
	//
	for (it = inverted_index->begin(); it != inverted_index->end(); it++) {
		delete &(*it);
		*it = NULL;
	}
	delete inverted_index;

	// switch over to new index
	//
	inverted_index = new_index;

	assert (pthread_mutex_unlock(&index_access_mutex) == 0);
}

/* print out some statistics */ 
void vector_search::stats() {
	
	intmap<posting_list*>::iterator iii;
	
	int n = 0;
	int tag_n = 0;
	float tagfrac = 0;
	float filledfrac = 0;
	float avgfilled = 0;
	float avgcap = 0;
	
	// get index statistics
	// 
	for (iii = inverted_index->begin(); iii != inverted_index->end(); iii++) {
		
		if (!(*iii)->is_empty()) {
			float avg = (*iii)->get_taglist_frac();
			tag_n++;

			tagfrac = (tagfrac*(tag_n-1) + avg)/tag_n;
		}

		n++;

		int size = (*iii)->get_size();
		int filled = (*iii)->get_filled();
		int capacity = (*iii)->get_capacity();
		float frac =  ((float)filled)/((float)size);

		filledfrac = (filledfrac*(n-1) + frac)/n;
		avgfilled = (avgfilled*(n-1) + filled)/n;
		avgcap = (avgcap*(n-1) + capacity)/n;
	}

	// get doc record statistics
	//
	float avgwords = 0;
	int totalwords = 0;
	n = doc_list.get_filled();
	intmap<docrec*>::iterator it;
	for (it = doc_list.begin(); it != doc_list.end(); it++) {
		docrec* doc_record = *it;
		totalwords += doc_record->words->get_filled();
	}

	avgwords = (float)totalwords/n;

	// TODO: have this go to the log
	//
	// print out statistics
	//
	cout << "vector_search::stats : dictionary size is " << wordid_counter+1 << endl;
	cout << "vector_search::stats : tag dictionary size size is " << tagid_counter+1 << endl;
	cout << "vector_search::stats : number of indexed documents is " << docid_counter+1 << endl;
	//cout << "vector_search::stats : average fraction of tag lists used is " << tagfrac << endl;
	cout << "vector_search::stats : average posting list filled fraction is " << filledfrac << endl;
	cout << "vector_search::stats : average posting list filled is " << avgfilled << endl;
	cout << "vector_search::stats : average posting list vector capacity is " << avgcap << endl;
	cout << "vector_search::stats : average unique words per document is " << avgwords << endl;
}

/* index an element of a document (list of words within the element) */
void vector_search::add_element(vector<string> _text, const string _docName, const string _tagName) {

	assert (pthread_mutex_lock(&index_access_mutex) == 0);

	int idx;
	vector<string> text;	     // final output list of terms to index
    intmap<MYBOOL> tagged(0);	// tells if a word is already in tag_dict

	// get internal identifiers
	//
	int docid = get_docid(_docName);
	int tagid = make_tagid(_tagName);

#ifdef STRUCTURE_QUERIES
	// create a tag dictionary, if it does not exist already
	if (!tag_dict.exists(tagid)) tag_dict[tagid] = new intmap<int>(0);
#endif

	// do some more splitting (like hyphenated terms)
	text = split_for_indexing(_text);

	// grab/create doc record for the document. this contains wordids of
	// all words that appear in the document
	//
	docrec* doc_record = doc_list[docid];
	if (doc_record == NULL) {
		doc_record = new docrec;
		doc_record->words = new intmap<char>(0);
		doc_record->mag = 0.0;
		doc_list[docid] = doc_record;
	}

	intmap<char>* docwords = doc_record->words;		// for convenience

	// iterate over words
	//
	for (idx = 0; idx < text.size(); idx++) {

		// get morphed (stemmed, stopped, etc) version of text[idx]
		string morphed_word = morpher.stem_and_stop(text[idx]);

		// if word didn't get stopped, index it
		//
		if (morphed_word.length() > 0) {
			
			// get/create a word id for this morphed word
			//
			int wordid = make_wordid(morphed_word);

#ifdef VS_DEBUG
			cout << "vector_search::add_element : adding occurrence of (docid=" << docid << ", tagid=" << tagid << ", wordid=" << wordid << ", word=" << morphed_word << ") to postings list" << endl;
#endif

			// get postings list for this word
			//
			posting_list* plist = (*inverted_index)[wordid];

			// create a new postings list if we need to
			// 
			if (plist == NULL) {
				plist = new posting_list();
				(*inverted_index)[wordid] = plist;	
			}

			// add to the postings list
			//
			plist->add(docid, tagid);

			// add to doc record.  if new slot for wordid, the position will 
			// be initialized to zero then incremented to 1.
			int count = (*docwords)[wordid];
			if (count < 255) {
				(*docwords)[wordid] = count + 1;
			}

#ifdef STRUCTURE_QUERIES
            // check if the word is in the tag dictionary, if not, add it
            if (!tagged.exists(wordid)) {
                tagged[wordid] = 1;
                ++((*tag_dict[tagid])[wordid]);
            }
#endif
		}
	}

	// update the document magnitude (used in ranking later)
	//
	intmap<char>::iterator it;
	float sum = 0;
	for (it = docwords->begin(); it != docwords->end(); it++) {
		sum += SQUARE(*it);
	}
	doc_record->mag = sqrt(sum);

	assert (pthread_mutex_unlock(&index_access_mutex) == 0);
}

/* search version that sets limit to unlimited and structmode to 'no' */
vector<query_result> vector_search::search(vector<query_node> query) {
	int limit = -1;
	int structmode = 1;

	return search(query, structmode, limit);
}

/* search version that sets limit to unlimited */
vector<query_result> vector_search::search(vector<query_node> query, int structmode) {
	int limit = -1;

	return search(query, structmode, limit);
}

/* our main feature-- the search method */
vector<query_result> vector_search::search(vector<query_node> _query, int structmode, int& limit) {

	// Try to predict a good size intelligently here. 
	// this probably needs work, but shouldn't be catastrophically wrong.
	//
	int predicted_docs = int(0.5 * sqrt((float)num_docs) + 0.5);
	int hash_max = num_docs * 2;
	int hash_init = (50 > predicted_docs ? 50 : predicted_docs);

	int num_terms = 0;

	// preprocess query-- uniqify, morph, split terms, get magnitude
	vector<query_node> query = _query;  // we are going to modify, copy.
	int mag_query = _search_prepare_query(query);

	// figure out field weights based on query and defaults. 
	intmap<float> field_weights = _search_prepare_field_weights(query);

	// populate the doc_postings and field_counts structures using the contents
	// of the inverted index.  This is the only point of index access.
	//
	// doc_postings is [query_term_idx => {docid => count} ]
	// field_counts is {docid => => {fieldid => count}}
	// field_frequencies is [query_term_idx => { fieldid => count}]
	//
	vector<intmap<short>*> doc_postings(query.size(), NULL);
	intmap<intmap<short>*> field_counts(hash_init, NULL);
	vector<intmap<int>*> field_frequencies(query.size(), NULL);
	vector<float> dfs(query.size(), 0);

	_search_get_IR_data(query, doc_postings, dfs, field_counts, field_frequencies, structmode);

	// process force and forbid (+ and - operators)
	//
	intmap<MYBOOL> found_docs(hash_init, MYFALSE);
	_search_force_forbid(found_docs, query, doc_postings);
	
	// get (potentially df) weighted versions of per-query-term postings list 
	// vectors 
	//
	vector<intmap<float> > weighted_postings = _search_get_weighted_postings(query, doc_postings, found_docs, hash_init);

	// loop through the document vectors, calculating their similarity to
	// the query.
	//
	intmap<float> similarity (hash_init, 0.0);	
	_search_calc_similarity(similarity, query, mag_query, found_docs, weighted_postings, field_counts, field_frequencies, field_weights, dfs, structmode);

	// sort results set and threshold by limit.
	//
	int nmatches;
	vector<query_result> results = _search_sort_results(similarity, limit);

	// cleanup (deallocate memory)
	_search_cleanup(doc_postings, field_counts, field_frequencies);
	
	// and return results records
	return results;
}

/* release memory that won't automatically be deallocated */

/* we wouldn't have to be doing this if we weren't using vectors of pointers */

void vector_search::_search_cleanup(
	vector<intmap<short>*> doc_postings,
	intmap<intmap<short>*> field_counts,
	vector<intmap<int>*> field_frequencies) {

	vector<intmap<short>*>::iterator dpi;
	for (dpi = doc_postings.begin(); dpi != doc_postings.end(); dpi++) {
		if (*dpi)
			delete *dpi;
	}

	vector<intmap<int>*>::iterator ffi;
	for (ffi = field_frequencies.begin(); ffi != field_frequencies.end(); ffi++) {
		if (*ffi)
			delete *ffi;
	}

	// taken care of within search_calc_similarity
	/* 
	intmap<intmap<short>*>::iterator fci;
	for (fci = field_counts.begin(); fci != field_counts.end(); fci++) {
		cout << "size of field counts is " << field_counts.get_size() << endl;
		cout << "fci iterator index is " << fci.get_index() << endl;
		if (*fci) {
			cout << "fci pointer is [" << *fci << "]" << ", key is " << fci.get_key() << endl;

			delete (intmap<short>*)*fci;
		}
	}*/
}


/* sort results set. currently this is based on STL introspective sort.
 * this could be converted to radix later, since ranks are normalized. 
 *
 * also unifies results set with external document id labels.  */

vector<query_result> vector_search::_search_sort_results (
	intmap<float> similarity, 
	int& limit) {

	// build a list of ranked results and a map of ranks to documents which 
	// have that rank.  also count # of matches.
	//
	rankmm rank_docid_map((int)similarity.get_filled()/5);  
	vector<float> ranks((int)similarity.get_filled()/5);
	
	int r = 0;
	int nmatches = 0;		// number matching documents
	intmap<float>::iterator si;
	for (si = similarity.begin(); si != similarity.end(); si++) {
		int docid = si.get_key();
		if (*si > 0.0) {
			ranks.push_back(*si);
			rank_docid_map.add(*si, docid);

			r++;
			nmatches++;
		}
	}

	// use the STL introspective sort. this could be improved upon further 
	// by using a radix sort, since we know all of our ranks lie in a fixed
	// range.
	//
	sort(ranks.begin(), ranks.end());

	// generate results list, minding any limit that may have been set
	//
	vector<query_result> results(limit == -1 ? nmatches : limit);	
	int count = 0;
	float lastrank = -1;
	for (int i = ranks.size()-1; i >= 0; i--) {

		float rank = ranks[i];
		if (rank == lastrank) continue;

		vector<int>* docs = rank_docid_map[rank];

		if (docs != NULL) {
			for (int j = 0; j < docs->size(); j++) {

				results[count].docID = get_docname((*docs)[j]);
				results[count].sim = rank;

				count++;
				
				if (limit != -1 && count == limit) break;	
			}
		}

		if (limit != -1 && count == limit) break;

		lastrank = rank;
	}

	// pass back # of matches in limit parameter
	limit = nmatches;

	// return results vector
	return results;
}


/* calculate similarity between document vectors and query.  this is where 
 * ranking happens. */

void vector_search::_search_calc_similarity(
	intmap<float>& similarity,
	vector<query_node> query,
	int mag_query, 
	intmap<MYBOOL> found_docs, 
	vector<intmap<float> > weighted_postings, 
	intmap<intmap<short>*> field_counts, 
	vector<intmap<int>*> field_frequencies,
	intmap<float> field_weights, 
	vector<float> dfs,
	int structmode) {

	float dot_prod = 0.0, mag_doc = 0.0, mag = 0.0;

#ifdef FF_WEIGHTING 
	// prepare summary field frequency data
	//
	vector<int> fdfs (weighted_postings.size(), 0);
	vector<int> ftfs (weighted_postings.size(), 1);
	vector<int> ftf_max (weighted_postings.size(), 1);
	for (int i = 0; i < weighted_postings.size(); i++) {
		if (field_frequencies[i]) {
			// get field 'df' value -- # of fields this term occurs in
			fdfs[i] = field_frequencies[i]->get_filled();

			// if element/tag was specified...
			//
			if (query[i].elemName != "") {
				// get ff 'tf' value -- # of occurrences of the term in this
				// tag only
				//
				ftfs[i] = (*field_frequencies[i])[get_tagid(query[i].elemName)];
				
				// get max ff 'tf' value so we can normalize
				//
				intmap<int>::iterator ffi;
				for (ffi = field_frequencies[i]->begin(); ffi != field_frequencies[i]->end(); ffi++) {
					if (*ffi > ftf_max[i]) ftf_max[i] = *ffi;
				}
			}
		} 
	}
#endif
   
	// calculate similarity between each document and query; loop through
	// documents (using found_docs list)
	//
	intmap<MYBOOL>::iterator fdi;
	for (fdi = found_docs.begin(); fdi != found_docs.end(); fdi++) {
		
		int docid = fdi.get_key();

		if (*fdi == MYTRUE) {

			intmap<short>* doc_field_counts = field_counts[docid];

#ifdef VS_DEBUG
			cout << "calculating similarity for docid " << docid << endl;
#endif
		
			// calculate dot product of query*doc for this docid
			//
			// loop through weight vectors for each term
			//
			for (int y = 0; y < weighted_postings.size(); y++) {
	
#ifdef VS_DEBUG
				cout << " scanning weights vector for term " << y << endl;
#endif
				// add to accumulators if docid is represented in this weight
				// vectors
				//
				if (weighted_postings[y].exists(docid)) {

					// get tf (or ntf, eventually?)
					// 
					float prod = weighted_postings[y][docid];
					
					if (structmode) mag_doc += prod*prod;

					// multiply in idf
					// 
					if (!structmode) {
						prod *= 1/log((float)(2 + dfs[y]));	
					} 

#ifdef FF_WEIGHTING 
					if (structmode) {
						// multiply in field 'df' frequency
						//
						prod *= ((float)num_tags+1-(float)fdfs[y])/(float)num_tags;

						// multiply in field 'tf' frequency
						//
						prod *= (float)ftfs[y]/(float)ftf_max[y];
					}
#endif

					// add to dot product accumulator
					//
					dot_prod += prod;
#ifdef VS_DEBUG
					cout << "  dot_prod = " << dot_prod << endl;
#endif
				}
			}

			// get final cosine normalized similarity expression, and add to 
			// similarity intmap.
			//
			if (!structmode)
				mag_doc = doc_list[docid]->mag;	

			mag = sqrt((float)mag_query) * sqrt(mag_doc);

			// final vector space similarity
			float vectorsim = dot_prod/mag;

			// now get field similarity 
			//
			float sumcounts = 0;
			float sumweighted = 0;
			intmap<short>::iterator dfc;
			for (dfc = doc_field_counts->begin(); dfc != doc_field_counts->end(); dfc++) {
				float weight = field_weights[dfc.get_key()];

				/* it seems that I've repaired the field weightimg similarity
				   here, that is, it doesn't seem *too* paradoxical anymore.  
				   however, it still is actually *harmful* to a document
				   to have "extra" matches in a very non-valuable field.  

				   Really, to have the field weighting behave in a purely 
				   relative manner, scalings should be relative to the set 
				   of all matching documents, not relative to where the matches
				   come from within a document.	 perhaps we need the field 
				   weight similarity to be something like:

				   fieldsim(d) = (\sum_i fc_i(d) * fw_i(d))/(max_d(fieldsim(d)))

				   the key here is that additional fields can only *help*, and
				   we provide relative weightings by normalizing by the 
				   best fieldweight.

				   the drawback to this method is that if you were to add
				   documents to the collection which matched a query, the 
				   weights of the *other* matching documents could change.
				   in other words, a weight is no longer unique to the 
				   (document,query) pair, but is unique to the
				   (documents_matching(query),query) pair (one element of
				   which is a set!)

				   */

				//sumcounts += SQUARE(*dfc);
				//sumweighted += SQUARE(weight * (float)(*dfc));

				/* this double-log suppresses the effect of high counts in
				   field weights. */ 

				float scaled_dfc = log(1 + log(1 + (float)*dfc));
				sumcounts += scaled_dfc;
				sumweighted += weight * scaled_dfc;
			}
			//float fieldsim = sqrt(sumweighted)/sqrt(sumcounts);
			float fieldsim = sumweighted/sumcounts;

			//_log->lprintf(logger::DEBUG, "similarity for document %s: fieldsim = %f, vectorsim = %f, similarity = %f\n", get_docname(docid).c_str(), fieldsim, vectorsim, fieldsim*vectorsim);

			// calculate final similarity
			//
			similarity[docid] = fieldsim * vectorsim;
	
#ifdef VS_DEBUG
			cout << " setting similarity for " << docid << " to " << similarity[docid] << endl;
#endif

			// reset accumulators, etc, for next doc vector
			dot_prod = 0.0, mag_doc = 0.0, mag = 0.0;

			// free the doc_field_counts vector, while we're here
			delete doc_field_counts;
		}
	}
}

/* get (potentially df) weighted versions of per-query-term postings list 
 * vectors. another function of this subroutine is to copy integral tfs
 * into floating-point weight variables.  we could potentially also 
 * normalize tf here.  */

vector<intmap<float> > vector_search::_search_get_weighted_postings(
	vector<query_node> query,
	vector<intmap<short>*> doc_postings,
	intmap<MYBOOL> found_docs,
	int hash_init) {

	// output vector-of-(hash)vectors
	vector<intmap<float> > weighted_postings;

	vector<query_node>::iterator _qi;
	for (_qi = query.begin(); _qi != query.end(); _qi++) {
	
		// vector to store weights for this term
		intmap<float> weights(hash_init, 0.0);		

		// if this term is forbidden, it doesn't belong in the vector space
		//
		if (_qi->qualifier != '-') {

			// loop through postings list
			intmap<short>::iterator _pi;
			intmap<short>* slice = doc_postings[IDX(_qi,query)];

			if (slice != NULL) {

				for (_pi = slice->begin(); _pi != slice->end(); _pi++) {

					int docid = _pi.get_key();

					// set weight
					if (found_docs[docid]) {

						float weight = *_pi;

						// TODO: some sort of normalized tf here? might have to 
						//	use doc record to get maxtf
						// 
							
						weights[docid] = weight;
#ifdef VS_DEBUG
						cout << "setting weight vector for query term " << IDX(_qi,query) << " and document " << docid	<< " to value " << weight << " (tf=" << (*_pi) << ", df=" << slice->get_filled() << ")" << endl;
#endif
					}
				}
			}

			// add this vector to the set 
#ifdef VS_DEBUG
			cout << "pushing weight vector for term " << _qi->queryTerm << " to weighted_postings" << endl;
#endif
		}
		weighted_postings.push_back(weights);
	}

	return weighted_postings;
}
	

/* get sufficient IR data from postings lists. this includes both classical (tf)
 * and field weight information.  */
void vector_search::_search_get_IR_data(vector<query_node> query, 
	vector<intmap<short>*>& doc_postings, 
	vector<float>& dfs, 
	intmap<intmap<short>*>& field_counts, 
	vector<intmap<int>*>& field_frequencies, 
	int structmode) {

	// pointer to posting list "slice" for a term
	intmap<short>* this_term;

	assert (pthread_mutex_lock(&index_access_mutex) == 0);

	// Walk through each query term, retrieve corresponding postings lists.
	// (Also get a field count version of the postings).
	// 
	vector<query_node>::iterator _qi;
	for (_qi = query.begin(); _qi != query.end(); _qi++) {

		int tagid = -1; 

		if (_qi->elemName.length() > 0) {
			tagid = get_tagid(_qi->elemName);
		}

		int wordid = get_wordid(_qi->queryTerm);

#ifdef VS_DEBUG
		cout << "vector_search::search: got word id " << wordid << " for word " << _qi->queryTerm << endl;
#endif

		// if there is posting list associated with this term
		// 
		if (wordid != -1 && inverted_index->exists(wordid)) {

			intmap<int>* field_freq;
			
#ifdef STRUCTURE_QUERIES
			field_freq = new intmap<int>(num_tags * 2, 0);
#endif

			// get a slice of it and update field counts
			//
			this_term = (*inverted_index)[wordid]->get_list(num_docs, num_tags, tagid, field_counts, field_freq);

#ifdef STRUCTURE_QUERIES
			field_frequencies[IDX(_qi,query)] = field_freq;
#endif

			// get full df and save
			//
			if (!structmode) {
				dfs[IDX(_qi,query)] = (*inverted_index)[wordid]->get_filled();
			}
			
			// place in postings list slice vector
			//
			if (this_term->get_filled() > 0) {
				doc_postings[IDX(_qi,query)] = this_term;
#ifdef VS_DEBUG
				cout << "populated postings list found for word " << _qi->queryTerm << endl;
#endif
			} 
#ifdef VS_DEBUG
			else {
				cout << "empty postings list for word " << _qi->queryTerm << " (wordid is " << wordid << ")" << endl;
			}
#endif
		}

#ifdef VS_DEBUG
		// no postings list found
		else {
			cout << "no postings found for word " << _qi->queryTerm << endl;
		}
#endif
	}
	
	assert (pthread_mutex_unlock(&index_access_mutex) == 0);
}

/* alter input found_docs hash/list so that only documents that pass
 * force and forbid filters remain */
void vector_search::_search_force_forbid(intmap<MYBOOL>& found_docs, vector<query_node> query, vector<intmap<short>*> doc_postings) {

	// temporary struct to parallel found_docs 
	intmap<MYBOOL> these_docs(found_docs.get_size(), MYFALSE);
	
#ifdef VS_DEBUG
	cout << "entering force/forbid subroutine" << endl;
#endif
	
	// record all candidate documents as found (though these still have to 
	// make it through force/forbid processing)
	// 
	vector<query_node>::iterator _qi; // query iterator
	for (_qi = query.begin();  _qi != query.end(); _qi++) {

		intmap<short>::iterator _si; // slice iterator
		intmap<short>* slice = doc_postings[IDX(_qi,query)];

		if (slice == NULL) continue;

		for (_si = slice->begin(); _si != slice->end(); _si++) {
			// value (occurrence count) must be greater than zero
			if (*_si > 0) {
				int docid = _si.get_key();
				found_docs[docid] = MYTRUE;
#ifdef VS_DEBUG
				cout << "force/forbid: initting docid " << docid << " as found" << endl;
#endif
			}
		}
	}
#ifdef VS_DEBUG
	cout << "force/forbid: done initting found_docs list" << endl;
#endif

	// process forbid (-).	this is easy: any found document which contains a
	// forbidden term simply gets removed.
	//
	for (_qi = query.begin(); _qi != query.end(); _qi++) {
	
		if (_qi->qualifier != '-') continue;

		// loop through postings list slice for this term.	remove all documents
		// in the list from found_docs.
		//
		intmap<short>::iterator _si; // slice iterator
		intmap<short>* slice = doc_postings[IDX(_qi,query)];

		if (slice == NULL) continue;

		for (_si = slice->begin(); _si != slice->end(); _si++) {
	
			if (*_si > 0) {
				int docid = _si.get_key();
				found_docs[docid] = MYFALSE;
#ifdef VS_DEBUG
				cout << "forbid : setting found_docs for " << docid << " to false" << endl;
#endif
			}
		}
	}

	// process force.  this is a little more complicated.  for each forced term:
	// 1. we make a temp docs boolean map and init it to _false_ (using the
	//	  found_docs which are true)
	// 2. for each document in the postings for the term, set the document's
	//	  entry in the temp map to _true_
	// 3. AND found_docs with temp doc list, which will leave only the found
	//	  docs which passed all previous tests plus the force test for the 
	//	  current term
	//
	
	// init these_docs to false
	//
	intmap<MYBOOL>::iterator _fi; // found iterator
	for (_fi = found_docs.begin(); _fi != found_docs.end(); _fi++) {

		// set to false... in the next loop these will have to "prove their
		// worth" to be included.
		//
		if (*_fi == MYTRUE) {
			int docid = _fi.get_key();
#ifdef VS_DEBUG
			cout << "initting these_docs[" << docid << "] to false" << endl;
#endif 
			these_docs[docid] = MYFALSE;
		}
	}
	
	for (_qi = query.begin(); _qi != query.end(); _qi++) {
	
		if (_qi->qualifier != '+') continue;

#ifdef VS_DEBUG
		cout << "processing forbid for query term " << _qi->elemName << endl;
#endif
	
		// now loop through postings list for this term and "turn on" the found
		// documents in these_docs
		//
		intmap<short>::iterator _si; // slice iterator
		intmap<short>* slice = doc_postings[IDX(_qi,query)];

		if (slice == NULL) continue;
		
		for (_si = slice->begin(); _si != slice->end(); _si++) {
		
			int docid = _si.get_key();
			these_docs[docid] = MYTRUE;
#ifdef VS_DEBUG
			cout << " setting these_docs[" << docid << "] = true" << endl;
#endif
		}	

		// now copy over the processed these_docs values, which will only "let
		// through" docs that had the current term.
		//
		intmap<MYBOOL>::iterator _fi; // found iterator
		for (_fi = found_docs.begin(); _fi != found_docs.end(); _fi++) {

			// we only have to exclude included documents
			if (*_fi == MYTRUE) {

				int docid = _fi.get_key();

				// copy the temp value over
				found_docs[docid] = these_docs[docid];
#ifdef VS_DEBUG
				cout << " setting found_docs[" << docid << "] = " << these_docs[docid] << "(these_docs[" << docid << "])" << endl;
#endif

				// reset temp values for next loop
				these_docs[docid] = MYFALSE;
			}
		}
	}
}

/* prepare field weights based on query input and defaults */
intmap<float> vector_search::_search_prepare_field_weights(vector<query_node> query) {

	intmap<float> field_weights(2*num_tags, 1);
	
	// first build field weights hash based on query.  remove them from the
	// query
	//
	int i;	
	float maxweight = -1;
	for (i = 0; i < query.size(); i++) {

		// look for '=' delimiter, as in field=weight
		//
		if (strchr(query[i].queryTerm.c_str(),'=')) {

			vector<string> field_weight = split('=', query[i].queryTerm);

			int fieldid = get_tagid(field_weight[0]);
			float weight = (float)strtod(field_weight[1].c_str(), NULL);		

			// set the weight in the field_weights map
			//
			if (fieldid != -1) {

				// only set the weight the first time we see it.  this allows
				// a digital library to append some default weights, but when
				// a user manually specifies other weights, they will take
				// precendent.
				//
				if (!field_weights.exists(fieldid)) {
					field_weights[fieldid] = weight;

					// keep track of max weight for normalization later
					if (weight > maxweight) maxweight = weight;
				}
			}
			
			// erase this node, since its a directive, not a real query term
			query.erase(query.begin() + i);
			i--;
		}
	}

	// add in unspecified weights
	for (int i = 0; i < num_tags; i++) {
		if (!field_weights.exists(i)) {
			field_weights[i] = 1.0;
			if (1.0 > maxweight) maxweight = 1.0;
		}
	}

	// normalize the field weights
	for (intmap<float>::iterator fwi = field_weights.begin(); fwi != field_weights.end(); fwi++) *fwi = *fwi/maxweight;

	return field_weights;
}

/* preprocess query: morph, uniqify, and split terms */
int vector_search::_search_prepare_query(vector<query_node>& query) {

	// split query terms.  for a term that is split, we copy the 
	// metadata tag and qualifier fields into all of the split terms.
	// 
	for (int i = 0; i < query.size(); i++) {
		vector<string> split_terms = split_for_indexing(query[i].queryTerm);

		// make new query nodes
		if (split_terms.size() > 1) {

#ifdef VS_DEBUG
			cout << "splitting query term " << query[i].queryTerm << endl;
#endif 
			
			// remove (but save) old node
			query_node old_node = query[i];
			query.erase(query.begin() + i);

			int j;
			for (j=0; j<split_terms.size(); j++) {
				query_node tempq;

				// build a new node with old metadata but new term
				tempq = old_node;
				tempq.queryTerm = split_terms[j];

				// add the current node
				query.insert(query.begin() + i, tempq);
			}

			// don't analyze the new nodes we just added
			i += split_terms.size() - 1;
		}
	}
	
	// morph and uniquify query terms to remove unecessary information
	// 
	stringmap<MYBOOL> qunique(query.size(), MYFALSE);
	for (int qi = 0; qi < query.size(); qi++) {
		string old = query[qi].queryTerm;

		query[qi].queryTerm = morpher.stem_and_stop(query[qi].queryTerm, 0);

		// word was stopped or isn't in index, remove the query condition 
		// 
		if (query[qi].queryTerm.length() == 0 || 
			query[qi].queryTerm == EMPTY) {
			
#ifdef VS_DEBUG
			cout << "removing stopped query term " << old << endl;
#endif
			query.erase(query.begin() + qi);
			
			qi--;		// look at this index again
		}

		// check for uniqueness 
		//
		else {
			// remove dupes
			if (qunique.exists(query[qi].queryTerm)) {

#ifdef VS_DEBUG
				cout << "removing dupe query term " << query[qi].queryTerm << endl;
#endif
				query.erase(query.begin() + qi);

				qi--;	// look at this index again
			}
			
			// add non-dupes (first occurrence of anything)
			else { 
				qunique[query[qi].queryTerm] = MYTRUE;
			}
		}
	}

	// get query "magnitude" (this leaves out - terms)
	//
	int mag_query = 0;
	for (int qi = 0; qi < query.size(); qi++) {
		if (query[qi].qualifier == '-') continue;
		mag_query++;
	}

	return mag_query;
}

#ifdef STRUCTURE_QUERIES

/* preprocess a query specially for structure inference */
void vector_search::_structure_prepare_query(vector<query_node>& query) {

	// remove weights from the query
	for (int qi = 0; qi < query.size(); qi++)
		if (strchr(query[qi].queryTerm.c_str(),'=')) {
			vector<string> field_weight = split('=', query[qi].queryTerm);
			if (get_tagid(field_weight[0]) != -1) {
				query.erase(query.begin() + qi);
				qi--;
			}
		}

	// split query terms
	for (int qi = 0; qi < query.size(); qi++) {
		vector<string> split_terms = split_for_indexing(query[qi].queryTerm);
		if (split_terms.size() > 1) {
			query_node old_node = query[qi];
			query.erase(query.begin() + qi);
			for (int ti = 0; ti < split_terms.size(); ti++) {
				query_node tempq;
				tempq = old_node;
				tempq.queryTerm = split_terms[ti];
				query.insert(query.begin() + qi, tempq);
			}
			qi += split_terms.size() - 1;
		}
	}
	
	// uniquify query terms to remove unecessary information
	stringmap<MYBOOL> qunique(query.size(), MYFALSE);
	for (int qi = 0; qi < query.size(); qi++) {
		string term = morpher.stem_and_stop(query[qi].queryTerm,0);
		if (term.length() == 0 || term == EMPTY) {
			query.erase(query.begin() + qi);
			qi--;
		}
		else 
			if (qunique.exists(term)) {
				query.erase(query.begin() + qi);
				qi--;
			} else {
				qunique[term] = MYTRUE;
			}
	}
}

/* build and score structured queries */
vector<query_score> vector_search::build_structures(vector<query_node> query) {

    // spurious code, used just to get the number of times each term appears in
    // each field. to use it, uncomment, recompile, and send a request for
    // query structuring
    /*
    stringmap<int>::iterator i;
    stringmap<short>::iterator j;
    for (i = wordid_lookup.begin(); i != wordid_lookup.end(); ++i) {
        cerr<<i.get_key()<<":\t";
        for (j = tagid_lookup.begin(); j != tagid_lookup.end(); ++j)
            cerr<<j.get_key()<<"="<<(*tag_dict[*j])[*i]<<"\t";
        cerr<<endl;
    }
    */

    // get the weights for each field
	intmap<float> field_weights = _search_prepare_field_weights(query);

	// remove duplicates and non-existing terms, and split terms
	_structure_prepare_query(query);

	// build the structured queries
	vector<query_score> squeries;
	add_query_tags(query, squeries);

	// compute the score of each structured query
	//
	stringmap<double> query_cache(100,-1);
	for (int i = 0; i < squeries.size(); ++i) {
		squeries[i].score = compute_score(squeries[i].query, field_weights, query_cache);
		
		// APK- remove 0-scoring queries.
		if (squeries[i].score == 0.0) {
			squeries.erase(squeries.begin() + i);
			i--;
		}
	}

	return squeries;
}


/* add field-specifier tags to structured queries */
void vector_search::add_query_tags(vector<query_node> query, vector<query_score>& squeries) {

	// if the query was no words, just end the recursion
	if (query.size() == 0) return;
  
#ifdef ST_DEBUG
	cerr << "add_query_tags in: ";
	for (int i = 0; i < query.size(); ++i)
		cerr << query[i].elemName << ":" << query[i].queryTerm << " ";
	cerr << endl;
#endif

	// if the query as just one word, create a one word query for each tag
	if (query.size() == 1) {
		int wordid = wordid_lookup[morpher.stem_and_stop(query[0].queryTerm,0)];

#ifdef ST_DEBUG
		cerr << "wordid: " << wordid << endl;
#endif

		for (stringmap<short>::iterator i = tagid_lookup.begin(); i != tagid_lookup.end(); ++i) {
		
#ifdef ST_DEBUG
			cerr << "tag: " << *i << ":" << i.get_key() << " " << (*tag_dict[*i])[wordid] << endl;
#endif

			if ((*tag_dict[*i])[wordid] >= MIN_GFF) {
				query[0].elemName = i.get_key();
				query_score aux = {query, 0};
				squeries.push_back(aux);
			}
		}

#ifdef ST_DEBUG
		cerr << "add_query_tags out: ";
		for (int j = 0; j < squeries.size(); ++j) {
			for (int i = 0; i < squeries[j].query.size(); ++i)
				cerr << j << " " << ":" << squeries[j].query[i].elemName << ":" << squeries[j].query[i].queryTerm << " ";
			cerr << endl;
		}
#endif

		return;
	}

	// get the last word and remove it from the vector
	query_node word = query.back();
	query.pop_back();

	// get the remaining word/tag combinations (recursive step)
	vector<query_score> aux;
	add_query_tags(query, aux);

	int wordid = wordid_lookup[morpher.stem_and_stop(word.queryTerm,0)];
	for (stringmap<short>::iterator i = tagid_lookup.begin(); i != tagid_lookup.end(); ++i)
		if ((*tag_dict[*i])[wordid] >= MIN_GFF) {
			word.elemName = i.get_key();
			for (int j = 0; j < aux.size(); ++j) {
				squeries.push_back(aux[j]);
				squeries.back().query.push_back(word);
			}
		}

#ifdef ST_DEBUG
	cerr << "add_query_tags out: ";
	for (int j = 0; j < squeries.size(); ++j) {
		cerr << j << " :";
		for (int i = 0; i < squeries[j].query.size(); ++i)
			cerr << " " << squeries[j].query[i].elemName << ":" << squeries[j].query[i].queryTerm;
		cerr << endl;
	}
#endif
}

/* print out a query for use as a hash key */
string vector_search::get_query_key(vector<query_node>& query) {

	string s = "";

	vector<query_node>::iterator qi;

	for (qi = query.begin(); qi != query.end(); qi++) {

		if (s.length())
			s += ' ';

		if (qi->qualifier)
			s += qi->qualifier;

		if (qi->elemName != "") 
			s += qi->elemName + ':';

		s += qi->queryTerm;
	}

	return s;
}

/* score a structured query */
double vector_search::compute_score(const vector<query_node>& query, intmap<float> field_weights, stringmap<double>& query_cache) {

	double final_score = 0;

#ifdef STRUCT_F_AND
	double accum_score = 1;
#else
#ifdef STRUCT_F_AVG
	double accum_score = 0;
	int num_tag = 0;
#endif
#endif

#ifdef ST_DEBUG
	cerr << endl << "compute score: ";
	for (int i = 0; i < query.size(); ++i)
		cerr << query[i].elemName << ":" << query[i].queryTerm << " ";
	cerr << endl;
#endif

	// gets the score for each tag
	for (stringmap<short>::iterator i = tagid_lookup.begin(); i != tagid_lookup.end(); ++i) {

		// selects only the terms for tag i
		vector<query_node> selected;
		for (int j = 0; j < query.size(); ++j)
			if (tagid_lookup[query[j].elemName] == *i) {
				query_node n;
				n.elemName = query[j].elemName;
				n.queryTerm = query[j].queryTerm;
				n.qualifier = '+';
				selected.push_back(n);
				//selected.push_back(query[j]);
			}

#ifdef ST_DEBUG
		cerr << "selected " << *i << ":" << i.get_key() << endl;
		for (int k = 0; k < selected.size(); ++k)
			cerr << selected[k].qualifier << selected[k].elemName << ":" << selected[k].queryTerm << " ";
		cerr << endl;
#endif

		if (selected.size() == 0) continue;

#ifdef STRUCT_F_AVG
		++num_tag;
#endif

		double tag_score = 0;

		// APK- look up or submit tag sub-query to get score
		//
		string tag_key = get_query_key(selected);

		// is query result cached?
		if (query_cache.exists(tag_key)) {
			// look up
			tag_score = query_cache[tag_key];
		} else {
			// calculate anew
			tag_score = compute_tag_score(selected);

			// cache result
			query_cache[tag_key] = tag_score;
		}

#ifdef ST_DEBUG
		cerr << "tag_score: " << tag_score << " fw: "<< field_weights[*i] << endl;
#endif

		// computes the accumulated score
#ifdef STRUCT_F_AND
		accum_score *= field_weights[*i] * tag_score;
#else
#ifdef STRUCT_F_AVG
		accum_score += field_weights[*i] * tag_score;
#endif
#endif
		
#ifdef ST_DEBUG
		cerr << "score so far: " << accum_score << endl;
#endif

		// cleanup
		free_query_vector(selected);
		selected.clear();
	}

#ifdef STRUCT_F_AVG
	final_score = (num_tag == 0 ? 0 : accum_score / (float)(num_tag*num_tag));
#ifdef ST_DEBUG
	cerr << "num-tag: " << num_tag << endl;
#endif
#else
	// AND and OR methods; final is in accumulator
	final_score = accum_score;
#endif

#ifdef ST_DEBUG
	fprintf(stderr, "final_score: %.20f\n\n", final_score);
#endif

	return final_score;
}
#endif

// compute the score for just one tag sub-query of a structured query
// 
double vector_search::compute_tag_score(const vector<query_node>& selected) {

	// performs a search to get matches for tag, struct mode is turned on 
	//
	vector<query_result> results = search(selected, 1);

#ifdef ST_DEBUG
	if (results.size() != 0) {
		cerr << "results: ";
		for (int i = 0; i < results.size(); ++i)
			cerr << results[i].sim << " ";
		cerr << endl;
	}
#endif
		
	if (results.size() == 0) return 0.0;

	// turn matching document ranks into tag sub-query score via the selected
	// combination method.
	//

#ifdef STRUCT_OR
	double tag_score = 1.0;
#else
#ifdef STRUCT_AVG
	double tag_score = 0.0;
#else
#ifdef STRUCT_SUM
	double tag_score = 0.0;
#endif
#endif
#endif

	for (int j = 0; j < results.size(); ++j) {
#ifdef STRUCT_OR
		tag_score *= (1 - results[j].sim);
#else
#ifdef STRUCT_AVG
		tag_score += results[j].sim;
#else
#ifdef STRUCT_SUM
		tag_score += results[j].sim;
#endif
#endif
#endif

//#ifdef ST_DEBUG
//		cerr << "ts: " << tag_score << " ";
//#endif
	}

	// cleanup results vector
	free_query_result_vector(results);
	
#ifdef STRUCT_OR
	tag_score = 1.0 - tag_score;
#else
#ifdef STRUCT_AVG
	tag_score /= results.size();
#else
#ifdef STRUCT_SUM
	tag_score /= doc_list.get_size();
#ifdef ST_DEBUG
	cerr << "size: " << doc_list.get_size() << endl;
#endif
#endif
#endif
#endif

	return tag_score;
}

/*
void vector_search::print() {

	stem.print();
	cout << "\n";
	int idx;
	for (idx=0; idx<capacity; idx++) {
		if (_keys[idx]!="") {
			cout << "vector_search::_keys[" << idx << "] = " << _keys[idx]
				 << "; postList[" << idx << "] contains " << postList[idx].get_numDocs()
				 << " node: \n";
			if (postList[idx].is_empty())
				cout << "NULL\n";
			else {
				vector<posting_list>::iterator _i=&postList[idx];
				postList[idx].print();
			}
		}
	}
	cout << "\n";
	docList.print();
}
*/

/*
void vector_search::revision_add(vector<string> text, const string _docName, 
								  const string _tagName) {

	char buf[20];
	int read_pos, write_pos, num_revisions, revision_size;

	fstream file;
	file.open(FILE_NAME.c_str(), ios::in | ios::out | ios::binary);

	//get number of bytes in snapshot
	file.seekg(0);
	file.read(buf, sizeof(string));
	int snapshot_size = atoi(buf);

	//get number of revisions (just for updating)
	read_pos = snapshot_size;
	file.seekg(read_pos);
	file.read(buf, sizeof(string));
	num_revisions = atoi(buf);
	read_pos+=sizeof(string);

	//increment and rewrite
	num_revisions++;
	write_pos = snapshot_size;
	file.seekp(write_pos);
	file.write((char*)_itoa(num_revisions, buf, 10), sizeof(string));
	write_pos+=sizeof(string);

	//get number of bytes in revision data
	int revSize_pos = read_pos;
	file.read(buf, sizeof(string));
	revision_size=atoi(buf);
	read_pos+=sizeof(string);

	//find end of revision data
	write_pos=read_pos+revision_size;
	file.seekp(write_pos);

	//write char 'a' for add
	char* char_a = new char('a');
	file.write(char_a, sizeof(char));
	write_pos+=sizeof(char);

	//save space to write size of this entry
	int thisSize_pos=write_pos;
	write_pos+=sizeof(string);

	char* dum = new char[sizeof(string)*(2+text.size())];
	char* array_pos=dum;

	//write _docName and _tagName into dum
	file.seekp(write_pos);
	memcpy((void*)array_pos, (void*)_docName.c_str(), sizeof(string));
	array_pos+=sizeof(string);
	memcpy((void*)array_pos, (void*)_tagName.c_str(), sizeof(string));
	array_pos+=sizeof(string);

	int idx;
	for (idx=0; idx<text.size(); idx++) {
		
		char* temp = (char*)text[idx].c_str();		//read in string at from[idx]
		//count letters in string	
		int word_size;
		for (word_size=0; temp[word_size]!='\0'; word_size++) {}
		word_size++;			//for null_char

		memcpy((void*)array_pos, (void*)temp, word_size);		//add word to buffer
		array_pos+=word_size;

	}
	int file_size=array_pos-dum;

	//write contents of array to disk
	file.write(dum, file_size);

	//write size of *this* add revision data 
	file.seekp(thisSize_pos);
	file.write((char*)_itoa(file_size, buf, 10), sizeof(string));

	//go back and rewrite number of bytes in revision data - this includes revision type char
	file.seekp(revSize_pos);
	file.write((char*)_itoa(revision_size+file_size+sizeof(char), buf, 10), sizeof(string));
}


void vector_search::revision_remove(const string _docName, const string _tagName) {

	char buf[20];
	int read_pos, write_pos, num_revisions, revision_size;

	fstream file;
	file.open(FILE_NAME.c_str(), ios::in | ios::out | ios::binary);

	//get number of bytes in snapshot
	file.seekg(0);
	file.read(buf, sizeof(string));
	int snapshot_size = atoi(buf);

	//get number of revisions (just for updating)
	read_pos = snapshot_size;
	file.seekg(read_pos);
	file.read(buf, sizeof(string));
	num_revisions = atoi(buf);
	read_pos+=sizeof(string);

	//increment and rewrite
	num_revisions++;
	write_pos = snapshot_size;
	file.seekp(write_pos);
	file.write((char*)_itoa(num_revisions, buf, 10), sizeof(string));
	write_pos+=sizeof(string);

	//get number of bytes in revision data
	int revSize_pos = read_pos;
	file.read(buf, sizeof(string));
	revision_size=atoi(buf);
	read_pos+=sizeof(string);

	//find end of revision data
	write_pos=read_pos+revision_size;
	file.seekp(write_pos);

	//write char 'r' for add
	char* char_r = new char('r');
	file.write(char_r, sizeof(char));
	write_pos+=sizeof(char);

	//no need to write size of remove data - it will always = 2*sizeof(string)
	char* dum = new char[2*sizeof(string)];
	char* array_pos=dum;

	//write _docName and _tagName into dum
	memcpy((void*)array_pos, (void*)_docName.c_str(), sizeof(string));
	array_pos+=sizeof(string);
	memcpy((void*)array_pos, (void*)_tagName.c_str(), sizeof(string));
	array_pos+=sizeof(string);

	//write array to file
	file.write(dum, 2*sizeof(string));

	//go back and rewrite number of bytes in revision data - this includes revision type char
	file.seekp(revSize_pos);
	file.write((char*)_itoa(revision_size+(2*sizeof(string))+sizeof(char), buf, 10), sizeof(string));
}

void vector_search::writeDisk() {

	map<int, int> write_map;

	int node_num=0;
	char buf[20];
	int file_size;

	fstream file;
	file.open(FILE_NAME.c_str(), ios::out | ios::binary);

	//save space to write total size of snapshot
	int totalSize_end = 0;
	totalSize_end+=sizeof(string);

	int stem_end = stem.writeDisk(totalSize_end, file);

	int term_end = writeHash(stem_end, file);

	//DO WE NEED THIS HERE????
	//write numDocs - size of docList
	int numDocs_end = term_end;
	file.write((char*)_itoa(numDocs, buf, 10), sizeof(string));
	numDocs_end+=sizeof(string);

	//write capacity of docList
	int capacity_end = numDocs_end;
	file.write((char*)_itoa(docList.get_capacity(), buf, 10), sizeof(string));
	capacity_end+=sizeof(string);

	int post_pos = capacity_end;

	//write contents of posting_list to file
	char* null_char = new char('\0');

	//save space to write byte size of postList
	file.seekp((int)file.tellp()+sizeof(string));
	post_pos+=sizeof(string);

	//DO WE NEED THIS HERE???
	//write capacity size of postList
	file.write((char*)_itoa(postList.capacity(), buf, 10), sizeof(string));
	post_pos+=sizeof(string);

	//enter posting_node info
	int idx;
	for (idx=0; idx<postList.capacity(); idx++) {
		if (postList[idx].is_empty()) {
			file.write(null_char, sizeof(char));
			post_pos++;
		}
		else 
			post_pos = postList[idx].writeDisk(post_pos, file, write_map, node_num);
	}

	//go back and write file_size 
	file_size = post_pos-(term_end+3*sizeof(string));
	file.seekp(capacity_end);
	file.write((char*)_itoa(file_size, buf, 10), sizeof(string));

	//docList returns the point at which snapshot writing stops
	int snapshot_size = docList.writeDisk(post_pos, file);
	
	//write number of addendums to snapshot - right now that = 0
	file.write((char*)_itoa(0, buf, 10), sizeof(string));

	//write size of addendum list - again, this = 0
	file.write((char*)_itoa(0, buf, 10), sizeof(string));

	//now go back to beginning and write size of snapshot	
	file.seekp(0);
	file.write((char*)_itoa(snapshot_size, buf, 10), sizeof(string));

	file.close();
}

void vector_search::readDisk() {

	map<int, int> read_map;
	int node_num=0;

	char buf[20];
	int file_size;
//	int capacity;

	fstream file;
	file.open(FILE_NAME.c_str(), ios::in | ios::binary);

	//skip over total size of snapshot
	file.seekg((int)file.tellg()+sizeof(string));
	int totalSize_end = 0;
	totalSize_end+=sizeof(string);

	int stem_end = stem.readDisk(totalSize_end, file);

	int term_end = readHash(stem_end, file);

	//read numDocs - size of docList
	int numDocs_end = term_end;
	file.read(buf, sizeof(string));
	numDocs = atoi(buf);
	numDocs_end+=sizeof(string);

	//read capacity of docList - need this to resize docList before postList additions
	int capacity_end = numDocs_end;
	file.read(buf, sizeof(string));
	int doc_capacity = atoi(buf);
	capacity_end+=sizeof(string);

	//set docList capacity
	docList.set_capacity(doc_capacity);

	int post_pos = capacity_end;

	//read in file_size as string, store as int - discard, don't need for this function
	file.seekg(post_pos);
	file.read(buf, sizeof(string));
	file_size=atoi(buf);

	//read in size of postList vector
	file.read(buf, sizeof(string));
	file_size=atoi(buf);

	//increment position pointer
	post_pos+=2*sizeof(string);

	//retrieve posting_node info
	int idx;
	for (idx=0; idx<postList.capacity(); idx++) {
		if (file.peek()!='\0') {
			pair<vector<posting_node*>, int> result = postList[idx].readDisk(post_pos, file, read_map, node_num);
			post_pos = result.second;
			vector<posting_node*> nodes = result.first;
			int g;
			for (g=0; g<nodes.size(); g++)
				docList.read_add(nodes[g]);
		}
		else {
			file.seekg((int)file.tellg()+sizeof(char));
			post_pos+=sizeof(char);
		}			
	}

	int doc_end = docList.readDisk(post_pos, file);

	//read in number of revisions
	file.read(buf, sizeof(string));
	int num_revisions = atoi(buf);
	int numRev_end = doc_end+sizeof(string);

	//skip over size of revision list
	file.read(buf, sizeof(string));
	int rev_size = atoi(buf);
	int sizeRev_end = numRev_end+sizeof(string);

	int rev_end = sizeRev_end;

	//read in each revision
	int ct;
	for (ct=0; ct<num_revisions; ct++)
		rev_end = process_revision(file, rev_end);

	file.close();
}

int vector_search::process_revision(fstream& file, int start_pos) {

	char* func_char=new char;

	file.seekg(start_pos);
	file.read(func_char, sizeof(char));
	if (*func_char=='a') 
		return read_add(file, start_pos+sizeof(char));
	else {
		assert(*func_char=='r');
		return read_remove(file, start_pos+sizeof(char));
	}
}

int vector_search::read_add(fstream& file, int start_pos) {

	char buf[20];
	//int vector_size, data_size;
	int data_size;
	char* doc_buf = new char[sizeof(string)];
	char* tag_buf = new char[sizeof(string)]; 
	string docName, tagName;
	vector<string> text;

	file.seekg(start_pos);

	//read size of add revision data - size of all strings in text + docName and tagName
	file.read(buf, sizeof(string));
	data_size=atoi(buf);

	char* dum = new char[data_size];
	char* array_pos=dum;

	//read in data from disk
	file.read(dum, data_size);
	
	//read docName and tagName from dum
	memcpy((void*)doc_buf, (void*)array_pos, sizeof(string));
	docName=(string)doc_buf;
	array_pos+=sizeof(string);
	memcpy((void*)tag_buf, (void*)array_pos, sizeof(string));
	tagName=(string)tag_buf;
	array_pos+=sizeof(string);

	int num_words=0;
	while (array_pos-dum<data_size) {
		int word_size;
		for (word_size=0; *(array_pos+word_size)!='\0'; word_size++) {}	//count letters in this word
		word_size++;				//to count null_char

		char* word_buf = new char[word_size];			
		memcpy((void*)word_buf, (void*)array_pos, word_size);	//copy word into word_buf
		text.push_back((string)word_buf);		//add to to
				
		array_pos+=(word_size);		//increment pos, ignore null_char
		num_words++;
	}

	add(text, docName, tagName);

	return start_pos+data_size;
}

int vector_search::read_remove(fstream& file, int start_pos) {

	string docName, tagName;
	char* doc_buf = new char[sizeof(string)];
	char* tag_buf = new char[sizeof(string)]; 

	//no need to read size of remove data - it will always = 2*sizeof(string)
	char* dum = new char[2*sizeof(string)];
	char* array_pos=dum;

	file.seekg(start_pos);
	file.read(dum, 2*sizeof(string));

	//write _docName and _tagName into dum
	memcpy((void*)doc_buf, (void*)array_pos, sizeof(string));
	docName=(string)doc_buf;
	array_pos+=sizeof(string);
	memcpy((void*)tag_buf, (void*)array_pos, sizeof(string));
	tagName=(string)tag_buf;
	array_pos+=sizeof(string);

	remove_elem(docName, tagName);

	return start_pos+(2*sizeof(string));
}



*/

