.ONESHELL:

pasm: main.o
	ld main.o -o pasm -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc
	rm main.o

main.o: main.asm
	nasm -felf64 main.asm -o main.o

