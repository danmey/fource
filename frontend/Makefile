
bin/fource: *.c *.h ../bin/libfource-core.a
	echo `test ! -d bin && mkdir bin` > /dev/null
	gcc  -L ~/libsigsegv-2.6/lib -L../bin/ -I ~/libsigsegv-2.6/include -I../shared -L../bin -ldl -ggdb3  fource.c -lfource-core -lsigsegv -o bin/fource

clean:
	rm -f *.o
	cd bin && rm -f *
	cd ..
