.ONESHELL:

pasm: main.o
	ld main.o -o pasm
	rm main.o

main.o: main.asm
	nasm -felf64 main.asm -o main.o

