SRCS=$(shell find . -name "*.lua")

all: maps/index.html

maps/index.html: map ARCHIVE.RES map.html map.js
	./map ARCHIVE.RES maps/

map: $(SRCS)
	touch map
