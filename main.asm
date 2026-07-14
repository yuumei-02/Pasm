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
extern DrawFPS
extern SetConfigFlags
extern GetRenderWidth
extern GetRenderHeight
extern DrawCircleV

_start:
   xor rbp, rbp
   call main
   xor rdi, rdi
   call _exit

main:
   push rbp
   mov rbp, rsp

   ;;       0x00000040 // VSYNC
   ;;       0x00002000 // HIGHDPI support
   ;;       0x00000004 // Window resizable
   mov rdi, 0x00002044
   call SetConfigFlags

   mov rdi, [WINDOW.width]
   mov rsi, [WINDOW.height]
   mov rdx, WINDOW.title
   call InitWindow

.window_loop_cond:
   call WindowShouldClose
   test rax, rax
   jnz .window_loop_end
.window_loop_body:
   call GetRenderWidth
   mov dword [WINDOW.width], eax
   call GetRenderHeight
   mov dword [WINDOW.height], eax

   call BeginDrawing
   mov rdi, 0xFF181818
   call ClearBackground

   call handle_input

   mov rdi, enemy
   call reposition_paddle
   mov rdi, player
   call reposition_paddle

   call update_ball
   call draw_ball

   mov rdi, enemy
   call draw_paddle
   mov rdi, player
   call draw_paddle

   xor rdi, rdi
   xor rsi, rsi
   call DrawFPS

   call EndDrawing
   jmp .window_loop_cond
.window_loop_end:

   call CloseWindow
   mov rsp, rbp
   pop rbp
   ret

draw_ball:
   push rbp
   mov rbp, rsp

   movq xmm0, [ball]
   movd xmm1, [ball.size]
   mov edi, [BALL_COLOR]

   call DrawCircleV

   mov rsp, rbp
   pop rbp
   ret

;; rdi: Paddle* paddle
;; ---
;; void
draw_paddle:
   push rbp
   mov rbp, rsp

   ;; Rectangle
   pxor xmm0, xmm0
   pxor xmm2, xmm2
   mov  rdx,  [rdi]    ;; x and y
   movq xmm1, [rdi+12] ;; width and height
   movq xmm0, rdx

   ;; Origin
   movq xmm2, [PADDLE_ORIGIN]

   ;; Rotation
   movss xmm3, [rdi+20]

   ;; Color
   xor edi, edi
   mov edi, [PADDLE_COLOR]

   call DrawRectanglePro

   mov rsp, rbp
   pop rbp
   ret

update_ball:
   push rbp
   mov rbp, rsp

   mov eax, [ball_launched]
   test eax, eax
   jnz .over
.ball_not_launched:
   mov rax, [player.x]
   mov [ball.x], rax
.over:
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

;; edi: i32 screen-width
;; esi: i32 screen-height
;; ---
;; xmm0: f32 center-x
;; xmm1: f32 center-y
compute_screen_center:
   push rbp
   mov rbp, rsp

   mov eax, __float32__(2.0)
   movd xmm1, eax
   movd xmm2, eax

.handle_width:
   cvtsi2ss xmm0, edi
   test edi, edi
   jz .handle_height
.cx_is_non_zero:
   divss xmm0, xmm1

.handle_height:
   cvtsi2ss xmm1, esi
   test esi, esi
   jz .over
.cy_is_non_zero:
   divss xmm1, xmm2

.over:
   mov rsp, rbp
   pop rbp
   ret

;; xmm0: f32 rad
;; ---
;; xmm0: f32 angle
rad_to_angle:
   push rbp
   mov rbp, rsp

   ;; rad * (180.0 / pi)
   movd xmm1, [RAD_AND_DEG_CONST]
   movd xmm2, [PI]
   divss xmm1, xmm2
   mulss xmm0, xmm1

   ;; 90 deg offset
   mov eax, __float32__(90.0)
   movd xmm1, eax
   addss xmm0, xmm1

   mov rsp, rbp
   pop rbp
   ret

;; xmm0: f32 angle
;; ---
;; xmm0: f32 rad
angle_to_rad:
   ;; @Todo: Make macros for common operations such as procedure prologue and epilogue
   push rbp
   mov rbp, rsp
   movss xmm2, xmm0

   ;; converter = PI / 180.0
   movd xmm0, [RAD_AND_DEG_CONST]
   movd xmm1, [PI]
   divss xmm1, xmm0

   ;; rotation * converter
   movss xmm0, xmm2
   mulss xmm0, xmm1
   
   mov rsp, rbp
   pop rbp
   ret

;; rdi: Paddle* addr
;; ---
;; void
reposition_paddle:
   push rbp
   mov rbp, rsp

   ;; rbx: Paddle* paddle
   ;; r12d: f32 cx
   ;; r13d: f32 cy
   ;; r14d: f32 x
   ;; r15d: f32 y
   mov rbx, rdi

   mov edi, [WINDOW.width]
   mov esi, [WINDOW.height]
   call compute_screen_center
   movd r12d, xmm0
   movd r13d, xmm1

   ;; angle_rad = angle_to_rad(paddle rotation)
   movd xmm0, [rbx+8]
   call angle_to_rad
   movd r15d, xmm0 ;; Temporarly save angle_rad

   ;; x = cx + (distance * cos(angle_rad))
   call cosf
   movd xmm1, [PLAYING_FIELD]
   mulss xmm1, xmm0
   movd xmm0, r12d
   addss xmm0, xmm1
   movd r14d, xmm0

   ;; y = cy + (distance * sin(angle_rad))
   movd xmm0, r15d
   call sinf
   movd xmm1, [PLAYING_FIELD]
   mulss xmm1, xmm0
   movd xmm0, r13d
   addss xmm0, xmm1
   movd r15d, xmm0

   ;; Save x and y to paddle.x and paddle.y
   movd xmm1, r8d
   mov dword [rbx], r14d
   mov dword [rbx+4], r15d

   ;; xmm0: f32 dy
   ;; xmm1: f32 dx

   ;; dx = cx - x
   movd xmm1, r12d
   movd xmm0, r14d
   subss xmm1, xmm0

   ;; dy = cy - y
   movd xmm2, r15d
   movd xmm0, r13d
   subss xmm0, xmm2

   ;; new paddle rotation = atan2f(dy, dx) * (180.0 / pi)
   call atan2f
   call rad_to_angle
   movd [rbx+20], xmm0

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
   player.x:        dd 0.0
   player.y:        dd 0.0
   player.z:        dd 0.0
   player.width:    dd 150.0
   player.height:   dd 25.0
   player.rotation: dd 0.0
   align 4

align 4
enemy:
   enemy.x:        dd 0.0
   enemy.y:        dd 0.0
   enemy.z:        dd 180.0
   enemy.width:    dd 150.0
   enemy.height:   dd 25.0
   enemy.rotation: dd 0.0
   align 4

align 4
ball:
   ball.x:      dd 0.0
   ball.y:      dd 0.0
   ball.vx:     dd 0.0
   ball.vy:     dd 0.0
   ball.size:   dd 25.0
   align 4

ball_launched: dd 0

;; Game settings
BALL_SPEED:    dd 100.0
PADDLE_SPEED:  dd 200.0
PLAYING_FIELD: dd 375.0
PADDLE_COLOR:  dd 0xffffffff
BALL_COLOR:    dd 0xffffffff

;; Math constants
RAD_AND_DEG_CONST: dd 180.0
PI: dd 3.14159265358979323846

align 4
PADDLE_ORIGIN:
   dd 75.0  ;; x
   dd -75.0 ;; y
   align 4

debug_i32_fmt: db "%d", 10, 0
debug_i32_i32_fmt: db "%d | %d", 10, 0

