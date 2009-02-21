bin/libfource-core.a:	*.S *.h.S
	echo "image-start.S" \
	     	`ls -1 *.S | grep -v '(image-start.S|image-end.S)'` \
	      "image-end.S"  | xargs gcc -I../shared -c -ggdb3
	ar rcs libfource-core.a *.o
	mv *.a *.o bin


clean:
	rm -f *.a *.o
	rm -f bin/*
