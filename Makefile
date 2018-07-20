SRCS=$(shell find . -name "*.lua")
MAPDIR=maps
MAPRES=ARCHIVE.RES

default:
	@echo "Use 'make mapviewer|ss1trans|all'"

all: allmaps ss1trans

ss1trans:
	${MAKE} -C build ss1trans-win64.zip

allmaps: maps rewired_maps

maps: bin/map
	${MAKE} -C $@ all

rewired_maps: bin/map
	${MAKE} -C $@ MAPRES=archive.dat MAPLEVELS=0,1,3,10,14,15 all

bin/map: $(shell find ss1/ deps/ -name "*.lua")
	touch bin/map

# Generate a decompressed version of ARCHIVE.DAT to make subsequent runs
# much, much faster. You will of course have to provide your own ARCHIVE.DAT.
ARCHIVE.RES: ARCHIVE.DAT
	./res --decompress --res ARCHIVE.DAT -o ARCHIVE.RES

.PHONY: all allmaps maps rewired_maps ss1trans
