# About
Pasm is a pong clone written in x86-64 assembly using raylib.
This project was made as a learning exercise to improve my understanding of x86-64 assembly language

# Status
Not yet finished!

# Dependencies
- [Raylib (I used 5.5)](https://github.com/raysan5/raylib)
- [Nasm](https://www.nasm.us/)
- LibX11

# How to build
Simply run ```make pasm```
This project will only run on a Linux or Linux-like system.
The makefile hardcodes a path to the dynamic linker.
This path is the default on some but not all systems so you may have to modify it manually.

