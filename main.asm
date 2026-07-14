global _start
section .text

extern printf
extern _exit

_start:
   mov rdi, msg
   call printf

   xor rdi, rdi
   call _exit

section .data
msg: db "Zhyivannye miratte!", 10, 0
msg_len: equ ($ - msg) - 1

