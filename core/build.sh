#/bin/bash
ignore_directives="\.\(section\)\|\(file\)\|\(text\)\|\(type\)\|\(size\)\|\(ident\)\|\(globl\)"
export SFLAGS="-I../shared -c -ggdb3 -Wa,-g"
#gcc -c -S vm_init.c
#grep -v ${ignore_directives} vm_init.s > temp.s && mv temp.s vm_init.s
gcc ${SFLAGS} main.S -o bin/main.o
gcc ${SFLAGS} gc.c -o bin/gc.o
test -d bin || mkdir bin
cd bin && ar rcs libfource-core.a gc.o main.o 
cd ..

