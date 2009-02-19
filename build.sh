#!/bin/sh


#m4 fource.S > __main.S
#gcc -Os -fomit-frame-pointer -o fource __main.S
# gcc -g -Os -fomit-frame-pointer -o fource engine.S fource.c
gcc  -ggdb3 -Os -fomit-frame-pointer -o fource  fource.c getkey.S exception.S
