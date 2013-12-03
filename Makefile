DC=ldc2
SOURCES=$(wildcard *.d */*.d */*/*.d */*/*/*.d)
OBJECTS=$(SOURCES:.d=.o)
EXECUTABLE=voxels
.PHONY : all
all: $(SOURCES) $(EXECUTABLE)
	
$(OBJECTS): %.o: %.d
	$(DC) -c -g -w $< -of=$@
             
$(EXECUTABLE): $(OBJECTS)
	$(DC) -L-ldl $(OBJECTS) -of=$@

.PHONY : clean
clean :
	-rm $(EXECUTABLE) $(OBJECTS)
