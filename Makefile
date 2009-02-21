all:	
	if [ ! -e bin ]; then mkdir bin; fi
	make core frontend

core:	bin/fource.a
frontend: core bin/fource

bin/fource.a:
	cd core && make && cp bin/*.a ../bin
	cd ..

bin/fource:
	cd frontend && make && cp bin/fource ../bin
	cd ..

clean:
	cd core && make clean
	cd ..
	cd frontend && make clean
	cd ..
	rm bin/*
