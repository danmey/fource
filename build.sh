#!/bin/sh


#m4 fource.S > __main.S
#gcc -Os -fomit-frame-pointer -o fource __main.S
gcc -Os -fomit-frame-pointer -o fource engine.S fource.c