IDIR=/usr/include/ImageMagick-6
CC=gcc
CFLAGS=-Wall -I$(IDIR) -fopenmp -DMAGICKCORE_HDRI_ENABLE=0 -DMAGICKCORE_QUANTUM_DEPTH=16 
LIBS=-lMagickCore-6.Q16
ODIR=obj
_DEPS = data.h
DEPS = $(patsubst %,$(IDIR)/%,$(_DEPS))

_OBJ = MAP.o PRE-MAP.o LOGIC.o 
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))

$(ODIR)/%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

MAP: $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS) $(LIBS)

.PHONY : clean

clean :
	rm -f $(ODIR)/*.o *~ core $(INCDIR)/*~
