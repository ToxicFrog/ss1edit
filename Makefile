SRCS=$(shell find . -name "*.lua")

all: maps/map.html maps/ss1maps.zip

maps/map.html: map ARCHIVE.RES map.html map.js
	./map ARCHIVE.RES maps/

maps/ss1maps.zip: maps/map.html
	zip -9 -r maps/ss1maps.zip maps/ -x ss1maps.zip

map: $(SRCS)
	touch map
