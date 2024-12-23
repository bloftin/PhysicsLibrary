/*****************************************************************************
 *
 * configuration options
 *
 *****************************************************************************/

#ifndef _CONFIG_H_
#define _CONFIG_H_

using namespace std;

/* uncomment below to get some debug printing */

//#define VS_DEBUG 1
//#define ST_DEBUG 1

/* uncomment to make serial unindexing O(nm) (rather than O(nmlog m)), where
 * n is the number of documents being unindexed and m is the average number
 * of postings list occurrences.  */

#define SUPER_FAST_UNINDEXING 1

/* uncomment below to log indexing events.  this will slow things down. */

//#define LOG_INDEXING 1

/* define relax postings list: allows 4 billion documents instead of 16.7 
 * million, 256 tf values instead of 16, and 256 tags instead of 16 */

//#define RELAX_POSTINGS 1

/* define if query structure inference is to be supported.  you might want to
 * turn this off if you aren't going to use it, since it maintains rather large
 * dictionaries of its own */

#define STRUCTURE_QUERIES 1

/* use field frequencies to complement idf in weighting.   this is done with
 * ftf (field "tf", the number of times the term occurs in the specified field),
 * and fdf (field "df", the number of different fields the term occurs in in
 * the entire corpus).
 *
 * FF_WEIGHTING is only for query structure inference mode, currently.
 */

#define FF_WEIGHTING 1

/* stemmer hash init size. not very important */

const int STEM_HASH_SIZE = 500;

#endif
