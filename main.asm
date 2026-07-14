DEFAULT REL
BITS 64

global _start
section .text

;; Libc
extern _exit
extern printf

;; Raylib
extern InitWindow
extern CloseWindow
extern WindowShouldClose
extern BeginDrawing
extern EndDrawing
extern ClearBackground
extern DrawRectanglePro
extern GetFrameTime
extern IsKeyDown

_start:
   xor rbp, rbp
   call main
   xor rdi, rdi
   call _exit

main:
   push rbp
   mov rbp, rsp

   mov rdi, [WINDOW.width]
   mov rsi, [WINDOW.height]
   mov rdx, WINDOW.title
   call InitWindow

.window_loop_cond:
   call WindowShouldClose
   test rax, rax
   jnz .window_loop_end
.window_loop_body:
   call BeginDrawing
   mov rdi, 0xFF181818
   call ClearBackground

   call handle_input
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
   mov  rdx,  [player]
   movq xmm1, [player+8] ;; width and height
   movq xmm0, rdx        ;; x and y

   ;; Origin
   movq xmm2, [PADDLE_ORIGIN]

   ;; Rotation
   movss xmm3, [player.rotation]

   ;; Color
   xor edi, edi
   mov edi, [PADDLE_COLOR]

   call DrawRectanglePro

   mov rsp, rbp
   pop rbp
   ret

handle_input:
   push rbp
   mov rbp, rsp

   ;; Wtf!?!?
   ;; For some reason, jz always fires when I test rax against itself regardless of key input.
   ;; When I printf rax it gives me the following number 5159424.
   ;; It returns this number regardless of what input I press.
   ;; This is fine if it was consistent but for some magical reason.
   ;; When I test rax against 65, it magically starts working.
   ;; Yes... That is the only change... 65 instead of rax fixes the return value magically.
   ;; One that never changes...
   ;; Wtf
   ;; - Yuumei-02 14-07-2026 19:00

.KEY_A_COND:
   mov rdi, 65 ;; KEY_A
   call IsKeyDown
   test rax, 65
   jz .KEY_A_END
.KEY_A_BODY:
   call GetFrameTime
   movss xmm1, [PADDLE_SPEED]
   mulss xmm1, xmm0
   movss xmm0, [player.x]
   subss xmm0, xmm1
   movd [player.x], xmm0
.KEY_A_END:
.KEY_D_COND:
   mov rdi, 68 ;; KEY_D
   call IsKeyDown
   test rax, 65
   jz .KEY_D_END
.KEY_D_BODY:
   call GetFrameTime
   movss xmm1, [PADDLE_SPEED]
   mulss xmm1, xmm0
   movss xmm0, [player.x]
   addss xmm0, xmm1
   movd [player.x], xmm0
.KEY_D_END:
   mov rsp, rbp
   pop rbp
   ret

section .data
WINDOW:
   WINDOW.width:  dd 800
   WINDOW.height: dd 600
   WINDOW.title:  db "Pasm", 0
   align 8

player:
   player.x:        dd 50.0
   player.y:        dd 50.0
   player.width:    dd 125.0
   player.height:   dd 30.0
   player.rotation: dd 0.0
   align 4

PADDLE_ORIGIN:
   dd 1.0 ;; x
   dd 1.0 ;; y
   align 4

PADDLE_COLOR: dd 0xffffffff
PADDLE_SPEED: dd 350.0

debug_i32_fmt: db "%d", 10, 0

