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
extern DrawRectanglePro

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
   call draw_player
   call EndDrawing
   jmp .window_loop_cond
.window_loop_end:

   call CloseWindow
   mov rsp, rbp
   pop rbp
   ret

draw_player:
   push rbp
   mov rbp, rsp

   ;; Rectangle
   pxor xmm0, xmm0
   pxor xmm2, xmm2
   mov  rdx,  [PADDLE_RECT]
   movq xmm1, [PADDLE_RECT+8] ;; width and height
   movq xmm0, rdx             ;; x and y

   ;; Origin
   movq xmm2, [PADDLE_ORIGIN]

   ;; Rotation
   movss xmm3, [PADDLE_ROTATION]

   ;; Color
   xor edi, edi
   mov edi, [PADDLE_COLOR]

   call DrawRectanglePro

   mov rsp, rbp
   pop rbp
   ret

section .data
WIN_WIDTH: dd 800
WIN_HEIGHT: dd 600
WIN_TITLE: db "Pasm", 0

PADDLE_RECT:
   dd 50.0   ;; x
   dd 50.0   ;; y
   dd 100.0 ;; width
   dd 100.0 ;; height

PADDLE_ORIGIN:
   dd 1.0 ;; x
   dd 1.0 ;; y

PADDLE_ROTATION: dd 0.0
PADDLE_COLOR: dd 0xffffffff
