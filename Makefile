SRCS=$(shell find . -name "*.lua")

all: maps/map.html maps/ss1maps.zip

maps/map.html: map ARCHIVE.RES map.html map.js
	./map ARCHIVE.RES maps/

maps/ss1maps.zip: maps/*.html maps/*.js maps/*.png
	zip -9 -r maps/ss1maps.zip maps/ -x ss1maps.zip

map: $(SRCS)
	touch map

# Generate a decompressed version of ARCHIVE.DAT to make subsequent runs
# much, much faster. You will of course have to provide your own ARCHIVE.DAT.
ARCHIVE.RES: ARCHIVE.DAT
	./res d ARCHIVE.DAT ARCHIVE.RES
