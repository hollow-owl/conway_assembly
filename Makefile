AS=nasm
ASFLAGS=-F dwarf -g -f elf32
LD=ld
LDFLAGS=-m elf_i386
RM=rm -rf
SOURCES=$(wildcard *.asm)
OBJECTS=$(SOURCES:.asm=.o)
TARGET=game_of_life
ARGS=5 4
%.o: %.asm
	$(AS) $(ASFLAGS) $^

all: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(TARGET).out

build: $(TARGET).o
	$(LD) $(LDFLAGS) $(TARGET).o -o $(TARGET).out

run: build
	./$(TARGET).out

debug: build
	gdb --args ./$(TARGET).out $(ARGS)

build-game:
	gcc -Wall -Wextra -pedantic-errors -g game.c -o game.out

game: build-game
	./game.out

clean:
	$(RM) $(OBJECTS) *.out
