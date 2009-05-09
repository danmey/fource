TARGET_DIR := ./bin
SOURCES = $(shell echo "image-start.S" \
	     	`ls -1 *.S | grep -v '(image-start.S|image-end.S|.*h.S$)'` \
	        "image-end.S")
HEADERS = $(shell -1 *.h.S)

#TODO: Image_start and Image_end must be at each of the ends
OBJECTS = $(shell ls -1 *.S| grep -v '\.h\.S' | sed -e 's,\([^.]\+[^hH]\).S,bin/\1.o,g')
SFLAGS := -I../shared -c -ggdb3 -Wa,-g


$(TARGET_DIR)/libfource-core.a: bin/main.o 
#$(OBJECTS)
#	cd $(TARGET_DIR) && ar rcs libfource-core.a ../image-tags/image-start.o *.o 
	cd $(TARGET_DIR) && ar rcs libfource-core.a main.o 
#../image-tags/image-end.o
	cd ..

#TODO: Track dependencies on *.h.S
# $(TARGET_DIR)/%.o: %.S *.h.S image.c
# 	gcc -c --std=c99 image.c -o $(TARGET_DIR)/image.o
# 	gcc $(SFLAGS) $< -o $(TARGET_DIR)/$*.o
# 	gcc $(SFLAGS) image-tags/image-start.S -o image-tags/image-start.o
# 	gcc $(SFLAGS) image-tags/image-end.S -o image-tags/image-end.o
bin/main.o: main.S
	gcc $(SFLAGS) main.S -o bin/main.o



.PHONY clean:
	cd $(TARGET_DIR) && rm -f *.a *.o
	rm image-tags/*.o
	cd ..
