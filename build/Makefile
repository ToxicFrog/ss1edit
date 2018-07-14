# build process
ss1trans-win64.zip: blank.zip ss1trans.exe README.txt
	zip -O ss1trans-win64.zip blank.zip ss1trans.exe README.txt

ss1trans.exe: lovec.exe ss1trans.love
	cat lovec.exe ss1trans.love > ss1trans.exe

README.txt: ../ss1trans/README.txt
	cp ../ss1trans/README.txt ./

lovec.exe blank.zip: love-11.1-win64.zip
	unzip love-11.1-win64.zip
	mv love-11.1.0-win64/lovec.exe ./
	cd love-11.1.0-win64 && rm *.exe *.ico *.txt && zip -r ../blank.zip ./
	rm -rf love-11.1.0-win64
	touch lovec.exe  # make sure it has a more recent timestamp than the source zip!

ss1trans.love: ../ss1trans/*.lua
	rm -f ss1trans.love
	cd ../ss1trans && zip -r ../build/ss1trans.love ./

love-11.1-win64.zip:
	wget "https://bitbucket.org/rude/love/downloads/love-11.1-win64.zip"
