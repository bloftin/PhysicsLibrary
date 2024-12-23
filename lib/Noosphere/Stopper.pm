package Noosphere;
use strict;

# modified by Aaron Krowne on 2002-02-21: de-objectified; plugged into PM.
#
#  ----------------------------------------------------------------------
# | Trivial Information Retrieval System                                 |
# | Hussein Suleman                                                      |
# | May 2001                                                             |
#  ----------------------------------------------------------------------
# |  Virginia Polytechnic Institute and State University                 |
# |  Department of Computer Science                                      |
# |  Digital Libraries Research Laboratory                               |
#  ----------------------------------------------------------------------
#

# run the stopper on a list, returning a new (possibly smaller) list
# (added by APK)
#
sub stopList {
  
  my @inlist=@_;

  my @outlist=();

  foreach my $word (@inlist) {
    push @outlist, $word if (stop($word));
  }

  return @outlist;
}

# stop an individual word
#
sub stop {

   my $aword=shift; 

   my $stopwords={ qw (
                       a 1 has 1 same 1 about 1 have 1 several 1 
                       among 1 however 1 some 1 all 1 such 1 an 1 
                       and 1 are 1 if 1 as 1 in 1 than 1 at 1 into 1 
                       that 1 is 1 the 1 it 1 their 1 its 1 these 1 
                       be 1 they 1 been 1 this 1 between 1 those 1 both 1 
                       made 1 through 1 but 1 make 1 to 1 by 1 many 1 
                       toward 1 more 1 most 1 must 1 do 1 upon 1 
                       during 1 used 1 using 1 no 1 not 1 each 1 was 1
                       either 1 were 1 of 1 what 1 on 1 which 1 or 1 
                       while 1 for 1 who 1 found 1 will 1 from 1 with 1 
                        further 1 within 1 would 1 i 1
                      )
                  };
   
   if (exists $stopwords->{$aword}) { 
     return ''; 
   } else { 
     return $aword; 
   }
}
   
sub testStopper
{
   my @words = qw (in hmmmm out and finalize i a wordlist and the);

   foreach my $word (@words)
   {
      print stop ($word)." ";
   }
   print "\n";
}

1;

