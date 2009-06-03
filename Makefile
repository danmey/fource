all:	
	echo `test ! -d bin && mkdir bin` > /dev/null
	cd core && ./build.sh
	cp core/bin/libfource-core.a bin/libfource-core.a
	cd frontend && make && cp bin/* ../bin
.PHONY : clean



clean:
	-cd core && make clean
	cd ..
	cd frontend && make clean
	cd ..
	-rm bin/*
