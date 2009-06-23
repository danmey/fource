#!/bin/bash
ignore_directives="\.\(section\)\|\(file\)\|\(text\)\|\(type\)\|\(size\)\|\(ident\)\|\(globl\)\|\(bss\)"

export SFLAGS="-I../shared -c -ggdb3 -Wa,-g"

prep_c4image() {
    local file_name=$1
    shift 1
    gcc -c -S $* $file_name -o ${file_name%.c}.s
    grep -v ${ignore_directives} ${file_name%.c}.s > temp.S
    sed -i 's/^[ \t]*\(\.comm[ \t]\+\)\([^,]\+\),\([^,]\+\).*$/\2: .FILL \3,1,0/' temp.S 
    grep -i '\.fill' temp.S > trailer.S
    grep -vi '\.fill' temp.S > ${file_name%.c}.S

}

export WITH_GC=
for opt in $*; do
    case $opt in
	(--with-gc) WITH_GC=yes
    esac
done

export OPT_MOD=${WITH_GC:+-DWITH_GC}

test -d bin || mkdir bin
rm -f bin/*

if [[ -n ${WITH_GC} ]]; then
    prep_c4image gc/gc.c ${FLAGS}
fi

gcc ${SFLAGS} ${OPT_MOD} main.S -o bin/main.o
cd bin && ar rcs libfource-core.a main.o
cd ..

