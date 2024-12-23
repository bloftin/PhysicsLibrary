/******************************************************************************

 Some query-related data structures and delcarations.

******************************************************************************/
 
#ifndef QUERY_H
#define QUERY_H

#include <string>
#include <vector>

using namespace std;

struct query_node {
	char qualifier;
	string elemName;
	string queryTerm;
};

struct query_result {
	string docID;
	float sim;
};

struct query_score {
	vector<query_node> query;
	double score;
};

/* this is really ugly. the above structs should all be objects, so that when
 * a container containing them is disposed, their contents are automatically
 * freed. */

void free_query_vector(vector<query_node>& query);

void free_query_result_vector(vector<query_result>& query_results);

void free_query_score_vector(vector<query_score>& scores);

#endif
