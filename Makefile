all:	
	make core frontend
.PHONY : core
.PHONY : frontend
.PHONY : clean



core:
	-cd core && make \
		&& test bin/libfource-core.a -nt ../bin/libfource-core.a \
		|| cp bin/libfource-core.a ../bin/libfource-core.a
	cd ..

frontend:
	cd frontend && make && cp bin/* ../bin
	cd ..

clean:
	-cd core && make clean
	cd ..
	cd frontend && make clean
	cd ..
	-rm bin/*
