MAPRES=ARCHIVE.RES
MAPLEVELS=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
COMMA=,
MAPJS=$(patsubst %,%.js,$(subst ${COMMA}, ,${MAPLEVELS}))
ZIPNAME=../build/$(shell basename ${CURDIR}).zip

all: ${ZIPNAME}

${ZIPNAME}: map.html $(shell echo *.html *.js *.png) ${MAPJS}
	rm -f ${ZIPNAME}
	zip -9 -r ${ZIPNAME} ./ -x ${MAPRES}

0.js: ../bin/map ${MAPRES} template.js
	cd .. && bin/map --res=${CURDIR}/${MAPRES} --prefix=${CURDIR} --levels=${MAPLEVELS}

map.html: ../bin/map ${MAPRES} template.html
	cd .. && bin/map --res=${CURDIR}/${MAPRES} --prefix=${CURDIR} --levels=${MAPLEVELS} --html-only
