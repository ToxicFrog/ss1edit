SRCS=$(shell find . -name "*.lua")

all: maps/map.html maps/ss1maps.zip maps/*.js

maps/{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}.js: bin/map ARCHIVE.RES map/template.js
	bin/map --res ARCHIVE.RES --prefix maps

maps/map.html: bin/map maps/template.html
	bin/map --res ARCHIVE.RES --prefix maps --html-only

maps/ss1maps.zip: maps/*.html maps/*.js maps/*.png
	zip -9 -r maps/ss1maps.zip maps/ -x ss1maps.zip

map: $(SRCS)
	touch map

# Generate a decompressed version of ARCHIVE.DAT to make subsequent runs
# much, much faster. You will of course have to provide your own ARCHIVE.DAT.
ARCHIVE.RES: ARCHIVE.DAT
	./res --decompress --res ARCHIVE.DAT -o ARCHIVE.RES
