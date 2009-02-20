
all:	fource fource.img

fource:	fource.c getkey.S exception.S interpret.S
	@gcc  -ldl --std=c99 -ggdb3 -o fource fource.c \
	image-start.S \
		getkey.S exception.S interpret.S \
	image-end.S

fource.img: save-image.c getkey.S exception.S interpret.S
	@gcc  -ldl --std=c99 -o save-image save-image.c \
	image-start.S \
		getkey.S exception.S interpret.S \
	image-end.S  
	@ ./save-image fource.img && rm ./save-image
	@ rm -f *.o


