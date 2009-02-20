#!/bin/bash

gcc -fPIC -ggdb3 --std=c99 -c getkey.S exception.S interpret.S
gcc --shared -Wl,-soname,libfource.so -o libfource.so getkey.o exception.o interpret.o
gcc -ldl -o fource fource.c

