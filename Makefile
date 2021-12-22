AS=nasm
ASFLAGS=-f elf
LD=ld
LDFLAGS=-m elf_i386
RM=rm -rf
SOURCES=$(wildcard *.asm)
OBJECTS=$(SOURCES:.asm=.o)
TARGET='game'
%.o: %.asm
	$(AS) $(ASFLAGS) $^

all: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(TARGET).out

build: $(TARGET).o
	$(LD) $(LDFLAGS) $(TARGET).o -o $(TARGET).out

run: build
	./$(TARGET).out
clean:
	$(RM) $(OBJECTS) *.out
