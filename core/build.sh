#/bin/bash
ignore_directives="\.\(section\)\|\(file\)\|\(text\)\|\(type\)\|\(size\)\|\(ident\)\|\(globl\)"
export SFLAGS="-I../shared -c -ggdb3 -Wa,-g"
#gcc -c -S vm_init.c
#grep -v ${ignore_directives} vm_init.s > temp.s && mv temp.s vm_init.s
# gcc ${SFLAGS} interpret.S -o bin/interpret.o
# gcc ${SFLAGS} literal.S -o bin/literal.o
# gcc ${SFLAGS} getkey.S -o bin/getkey.o
# gcc ${SFLAGS} mem.S -o bin/mem.o
# gcc ${SFLAGS} exception.S -o bin/exception.o
# gcc ${SFLAGS} dict.S -o bin/dict.o
# gcc ${SFLAGS} image-tags/image-end.S -o bin/image-end.o
# gcc ${SFLAGS} image-tags/image-start.S -o bin/image-start.o

test -d bin || mkdir bin
rm -f bin/*
gcc ${SFLAGS} main.S -o bin/main.o
gcc ${SFLAGS} gc/gc.c -o bin/gc.o
#cd bin && ar rcs libfource-core.a image-start.o interpret.o literal.o getkey.o mem.o exception.o dict.o image-end.o
cd bin && ar rcs libfource-core.a main.o
cd ..

