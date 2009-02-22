
bin/fource: *.c *.h ../bin/libfource-core.a
	gcc  -L../bin -I../shared -ldl -lfource-core --std=c99 -ggdb3  -o bin/fource   *.c ../bin/libfource-core.a


# fource.img: save-image.c getkey.S exception.S interpret.S
# 	gcc  -ldl --std=c99 -o save-image save-image.c \
# 	image-start.S \
# 		getkey.S exception.S interpret.S \
# 	image-end.S  
# 	 ./save-image fource.img && rm ./save-image
# 	 rm -f *.o
clean:
	rm -f *.o
	cd bin && rm -f *
	cd ..
