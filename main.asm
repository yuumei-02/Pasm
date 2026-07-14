DEFAULT REL
BITS 64

global _start
section .text

;; Libc
extern _exit
extern printf

;; Libm
extern cosf
extern sinf
extern atan2f

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
   call reposition_player
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
   mov  rdx,  [player.x] ;; Includes y
   movq xmm1, [player.width] ;; Includes height
   movq xmm0, rdx

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
   test rax, 65 ;; DO NOT TOUCH
   jz .KEY_A_END
.KEY_A_BODY:
   call GetFrameTime
   movss xmm1, [PADDLE_SPEED]
   mulss xmm1, xmm0
   movss xmm0, [player.z]
   subss xmm0, xmm1
   movd [player.z], xmm0
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
   movss xmm0, [player.z]
   addss xmm0, xmm1
   movd [player.z], xmm0
.KEY_D_END:
   mov rsp, rbp
   pop rbp
   ret

reposition_player:
   ;; @Todo: Some registers are callee saved and others are caller saved.
   ;;        Look up which registers you need to save and which ones you can discard
   ;;        and modify the assembly accordingly

   push rbp
   mov rbp, rsp

   mov eax, __float32__(400.0) ;; Center x
   mov ebx, __float32__(300.0) ;; Center y
   mov ecx, __float32__(350.0) ;; Distance

   ;; angle_rad = rotation * (PI / 180.0)
   mov esi, __float32__(180.0)
   movd xmm0, [PI]
   movd xmm1, esi
   divss xmm0, xmm1
   movd xmm1, [player.z]
   mulss xmm1, xmm0
   movd esi, xmm1
   push rsi

   ;; x = cx + distance * cos(angle_rad)
   ;; cos(angle_rad)
   push rax
   push rbx
   push rcx
   movss xmm0, xmm1
   call cosf
   pop rcx
   pop rbx
   pop rax
   ;; distance * cos(angle_rad)
   movd xmm1, ecx
   mulss xmm1, xmm0
   ;; cx + distance
   movd xmm0, eax
   addss xmm0, xmm1
   movd esi, xmm0
   pop r8 ;; angle_rad
   push rsi

   ;; y = cy + distance * sin(angle_rad)
   ;; sin(angle_rad)
   push rax
   push rbx
   push rcx
   movd xmm0, r8d
   call sinf
   pop rcx
   pop rbx
   pop rax
   ;; distance * sin(angle_rad)
   movd xmm1, ecx
   mulss xmm1, xmm0
   ;; cy + distance
   movd xmm0, ebx
   addss xmm0, xmm1
   movd r9d, xmm0 ;; y
   pop r8         ;; x

   movd xmm1, r8d
   movd [player.x], xmm1
   movd [player.y], xmm0

   ;; dy = cy - y
   movd xmm0, ebx
   movd xmm1, r9d
   subss xmm0, xmm1
   movd r9d, xmm0

   ;; dx = cx - x
   movd xmm0, eax
   movd xmm1, r8d
   subss xmm0, xmm1
   movss xmm1, xmm0

   ;; rad = atan2f(dy, dx)
   movd xmm0, r9d
   call atan2f
   movss xmm2, xmm0

   ;; rad * (180.0 / pi)
   mov eax, __float32__(180.0)
   movd xmm0, eax
   movd xmm1, [PI]
   divss xmm0, xmm1
   mulss xmm2, xmm0
   mov eax, __float32__(90.0) ;; offset
   movd xmm0, eax
   addss xmm2, xmm0
   movd [player.rotation], xmm2

   mov rsp, rbp
   pop rbp
   ret

section .data
align 4
WINDOW:
   WINDOW.width:  dd 800
   WINDOW.height: dd 600
   WINDOW.title:  db "Pasm", 0
   align 4

align 4
player:
   player.x:        dd 400.0
   player.y:        dd 300.0
   player.z:        dd 0.0
   player.width:    dd 150.0
   player.height:   dd 25.0
   player.rotation: dd 0.0
   align 4

align 4
PADDLE_ORIGIN:
   dd 75.0 ;; x
   dd 150.0 ;; y
   align 4

PADDLE_COLOR: dd 0xffffffff
PADDLE_SPEED: dd 350.0

PI: dd 3.14159265358979323846

debug_i32_fmt: db "%d", 10, 0

