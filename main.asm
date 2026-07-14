global _start
section .text

;; Libc
extern _exit

;; Raylib
extern InitWindow
extern CloseWindow
extern WindowShouldClose
extern BeginDrawing
extern EndDrawing
extern ClearBackground

_start:
   xor rbp, rbp
   and rsp, -16
   sub rsp, 8

   call main
   xor rdi, rdi
   call _exit

main:
   push rbp
   mov rbp, rsp
   sub rsp, 40

   mov rdi, 800
   mov rsi, 600
   mov rdx, WIN_TITLE
   call InitWindow

.window_loop_cond:
   call WindowShouldClose
   test rax, rax
   jnz .window_loop_end
.window_loop_body:
   call BeginDrawing
   mov rdi, 0xFF181818
   call ClearBackground
   call EndDrawing
   jmp .window_loop_cond
.window_loop_end:

   call CloseWindow
   mov rsp, rbp
   pop rbp
   ret

section .data
WIN_WIDTH: dd 800
WIN_HEIGHT: dd 600
WIN_TITLE: db "Pasm", 0

