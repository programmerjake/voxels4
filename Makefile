DC=gdc
SOURCES=$(wildcard *.d */*.d */*/*.d */*/*/*.d)
OBJECTS=$(SOURCES:.d=.o)
EXECUTABLE=voxels
.PHONY : all
all: $(SOURCES) $(EXECUTABLE)
	
$(OBJECTS): %.o: %.d
	$(DC) -c -Wall $< -o $@
             
$(EXECUTABLE): $(OBJECTS)
	$(DC) $(OBJECTS) -ldl -o $@

.PHONY : clean
clean :
	-rm $(EXECUTABLE) $(OBJECTS)
