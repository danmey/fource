all:	
	echo `test ! -e bin && mkdir bin` > /dev/null
	make all
.PHONY : all
.PHONY : clean


all: 
	cd core && ./build.sh
	cp core/bin/libfource-core.a bin/libfource-core.a
	cd frontend && make && cp bin/* ../bin

clean:
	-cd core && make clean
	cd ..
	cd frontend && make clean
	cd ..
	-rm bin/*
