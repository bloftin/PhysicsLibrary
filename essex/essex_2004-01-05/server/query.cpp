/******************************************************************************

 Some query-related functions.

******************************************************************************/

#include "query.h"

/* this is really ugly. the above structs should all be objects, so that when
 * a container containing them is disposed, their contents are automatically
 * freed. */

void free_query_vector(vector<query_node>& query) {
/*	vector<query_node>::iterator it;
	for (it = query.begin(); it != query.end(); it++) {
		it->elemName = "";
		it->queryTerm = "";
	}
*/}

void free_query_result_vector(vector<query_result>& query_results) {
/*	vector<query_result>::iterator it;
	for (it = query_results.begin(); it != query_results.end(); it++) {
		it->docID = "";
	}
*/}

void free_query_score_vector(vector<query_score>& scores) {
/*
	vector<query_score>::iterator it;
	for (it = scores.begin(); it != scores.end(); it++) {
		free_query_vector(it->query);
	}
*/}

