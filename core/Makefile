TARGET_DIR := ./bin
SOURCES = $(shell echo "image-start.S" \
	     	`ls -1 *.S | grep -v '(image-start.S|image-end.S|.*h.S$)'` \
	        "image-end.S")
HEADERS = $(shell -1 *.h.S)

#TODO: Image_start and Image_end must be at each of the ends
OBJECTS = $(shell ls -1 *.S| grep -v '\.h\.S' | sed -e 's,\([^.]\+[^hH]\).S,bin/\1.o,g')
SFLAGS := -I../shared -c -ggdb3


$(TARGET_DIR)/libfource-core.a: $(OBJECTS)
	cd $(TARGET_DIR) && ar rcs libfource-core.a *.o
	cd ..

#TODO: Track dependencies on *.h.S
$(TARGET_DIR)/%.o: %.S *.h.S
	gcc $(SFLAGS) $< -o $(TARGET_DIR)/$*.o

.PHONY clean:
	cd $(TARGET_DIR) && rm -f *.a *.o
	cd ..
