#!/bin/sh


#m4 fource.S > __main.S
#gcc -Os -fomit-frame-pointer -o fource __main.S
# gcc -g -Os -fomit-frame-pointer -o fource engine.S fource.c
gcc  -c -ggdb3  -Os -fomit-frame-pointer -o fource.o  fource.c
gcc  -c -g cont.S -o cont.o
gcc -o fource cont.o fource.o
