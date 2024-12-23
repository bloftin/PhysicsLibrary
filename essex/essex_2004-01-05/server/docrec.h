#ifndef _DOCREC_H
#define _DOCREC_H

#include "intmap.h"
#include "config.h"

// a document record (element of the "forward" index)

typedef struct doc_rec {

	intmap<char>* words;	// vector-form of the contents of the document 
							// (wordids are keys, values are counts)

	float mag;	// place to cache document magnitude, so we dont have to 
	 			// calculate this at query-time

} docrec;

#endif
