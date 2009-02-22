all:	
	echo `test ! -e bin && mkdir bin` > /dev/null
	make core frontend
.PHONY : all
.PHONY : clean


all: 
	cd core && make
	cp core/bin/libfource-core.a bin/libfource-core.a
	cd frontend && make && cp bin/* ../bin

clean:
	-cd core && make clean
	cd ..
	cd frontend && make clean
	cd ..
	-rm bin/*
