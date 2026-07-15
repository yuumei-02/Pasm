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
   mov rdi, enemy
   call handle_ball_collision
   mov rdi, player
   call handle_ball_collision
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
   jnz .ball_launched
.ball_not_launched:
   mov rax, [player.x]
   mov [ball.x], rax
   jmp .over
.ball_launched:
   movd xmm0, [ball.x]
   movd xmm1, [ball.y]
   movd xmm2, [ball.vx]
   movd xmm3, [ball.vy]

   addss xmm0, xmm2
   addss xmm1, xmm3

   movd [ball.x], xmm0
   movd [ball.y], xmm1
.over:
   mov rsp, rbp
   pop rbp
   ret

;; xmm0: f32 launch paddle rotation
;; ---
;; void
launch_ball:
   push rbp
   mov rbp, rsp

   ;; @Todo: early return when the ball has already been launched.
   mov eax, [ball_launched]
   test eax, eax
   jnz .early_out

   call angle_to_rad
   movd ebx, xmm0

   call cosf
   movss xmm1, [BALL_SPEED]
   movss xmm2, [FLOAT_NEG_MASK]
   xorps xmm1, xmm2
   mulss xmm1, xmm0
   movss [ball.vx], xmm1

   movd xmm0, ebx
   call sinf
   movss xmm1, [BALL_SPEED]
   movss xmm2, [FLOAT_NEG_MASK]
   xorps xmm1, xmm2
   mulss xmm1, xmm0
   movss [ball.vy], xmm1

.early_out:
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

.KEY_SPACE_COND:
   mov rdi, 32
   call IsKeyDown
   test rax, 65
   jz .KEY_SPACE_END
.KEY_SPACE_BODY:
   movd xmm0, [player.z]
   call launch_ball
   mov dword [ball_launched], 1
.KEY_SPACE_END:
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

;; xmm0: f32 val
;; xmm1: f32 min
;; xmm2: f32 max
;; ---
;; xmm0: f32 val
clamp_f32:
   push rbp
   mov rbp, rsp

   comiss xmm0, xmm1
   ja .more_than_min
.less_than_min:
   movss xmm0, xmm1
   jmp .return
.more_than_min:
   comiss xmm0, xmm2
   jb  .return
.more_than_max:
   movss xmm0, xmm2

.return:
   mov rsp, rbp
   pop rbp
   ret

;; rdi: Paddle* paddle
;; ---
;; xmm0: f32 left
;; xmm1: f32 right
;; xmm2: f32 top
;; xmm3: f32 bottom
calculate_enemy_bounds:
   push rbp
   mov rbp, rsp

   ;; paddle.width / 2.0f
   mov eax, __float32__(2.0)
   movd xmm4, eax
   movss xmm5, [rdi+12]
   divss xmm5, xmm4

   ;; paddle.height / 2.0f
   movss xmm6, [rdi+16]
   divss xmm6, xmm4

   ;; xmm5: paddle.width / 2.0f
   ;; xmm6: paddle.height / 2.0f

   ;; left
   movss xmm0, [rdi]
   subss xmm0, xmm5

   ;; right
   movss xmm1, [rdi]
   addss xmm1, xmm5

   ;; top
   movss xmm2, [rdi+4]
   addss xmm2, xmm6

   ;; bottom
   movss xmm3, [rdi+4]
   subss xmm3, xmm6

   mov rsp, rbp
   pop rbp
   ret

;; xmm0: f32 left
;; xmm1: f32 right
;; xmm2: f32 top
;; xmm3: f32 bottom
;; ---
;; xmm0: f32 closest_x
;; xmm1: f32 closest_y
calculate_closest_point_on_paddle_to_ball_center:
   push rbp
   mov rbp, rsp

   push r12
   push r13
   push r14
   sub rsp, 8

   movd r12d, xmm2
   movd r13d, xmm3

   movss xmm2, xmm1
   movss xmm1, xmm0
   movss xmm0, [ball.x]
   call clamp_f32
   movd r14d, xmm0 ;; closest_x

   movss xmm0, [ball.y]
   movd xmm1, r13d
   movd xmm2, r12d
   call clamp_f32
   movss xmm1, xmm0
   movd xmm0, r14d

   add rsp, 8
   pop r14
   pop r13
   pop r12

   mov rsp, rbp
   pop rbp
   ret

;; xmm0: f32 closest_x
;; xmm1: f32 closest_y
;; ---
;; xmm0: f32 dist_sq
;; xmm1: f32 radius_sq
calculate_distance_from_ball_to_closest_point:
   push rbp
   mov rbp, rsp

   ;; xmm2: f32 dx
   ;; xmm3: f32 dy
   movss xmm2, [ball.x]
   movss xmm3, [ball.y]
   subss xmm2, xmm0
   subss xmm3, xmm1

   ;; dist_sq
   mulss xmm2, xmm2
   mulss xmm3, xmm3
   addss xmm2, xmm3
   movss xmm0, xmm2

   ;; radius_sq
   movss xmm1, [ball.size]
   mulss xmm1, xmm1

   mov rsp, rbp
   pop rbp
   ret

;; xmm0: f32 left
;; xmm1: f32 right
;; xmm2: f32 top
;; xmm3: f32 bottom
;; ---
;; xmm0: f32 overlap_left
;; xmm1: f32 overlap_right
;; xmm2: f32 overlap_top
;; xmm3: f32 overlap_bottom
calculate_ball_overlap:
   push rbp
   mov rbp, rsp

   ;; overlap_left
   movss xmm4, [ball.x]
   addss xmm4, [ball.size]
   subss xmm4, xmm0

   ;; overlap_right
   movss xmm4, [ball.x]
   subss xmm4, [ball.size]
   subss xmm1, xmm4

   ;; overlap_top
   movss xmm4, [ball.y]
   addss xmm4, [ball.size]
   subss xmm4, xmm2
   movss xmm2, xmm4

   ;; overlap_bottom
   movss xmm4, [ball.y]
   subss xmm4, [ball.size]
   subss xmm3, xmm4

   mov rsp, rbp
   pop rbp
   ret

;; xmm0: f32 overlap_left
;; xmm1: f32 overlap_right
;; xmm2: f32 overlap_top
;; xmm3: f32 overlap_bottom
;; ---
;; eax: i32 collision_side
calculate_collision_side:
   push rbp
   mov rbp, rsp

   ;; xmm4: f32 min_overlap
   ;; eax: f32 collision_side
   movss xmm4, xmm0
   xor eax, eax

.right_cond:
   ucomiss xmm1, xmm4
   jae .right_over
.right_body:
   movss xmm4, xmm1
   mov eax, 1
.right_over:

.top_cond:
   ucomiss xmm2, xmm4
   jae .top_over
.top_body:
   movss xmm4, xmm2
   mov eax, 2
.top_over:

.bottom_cond:
   ucomiss xmm3, xmm4
   jae .bottom_over
.bottom_body:
   movss xmm4, xmm3
   mov eax, 3
.bottom_over:
   mov rsp, rbp
   pop rbp
   ret

;; edi: i32 collision_side
;; ---
;; void
bounce_ball_from_collision_side:
   push rbp
   mov rbp, rsp
   movss xmm1, [FLOAT_NEG_MASK]

   test edi, edi
   je .reverse_x
   cmp edi, 1
   jne .reverse_y
.reverse_x:
   movss xmm0, [ball.vx]
   xorps xmm0, xmm1
   movss [ball.vx], xmm0
   jmp .finish
.reverse_y:
   movss xmm0, [ball.vy]
   xorps xmm0, xmm1
   movss [ball.vy], xmm0
.finish:
   mov rsp, rbp
   pop rbp
   ret

;; rdi: Paddle* paddle
;; ---
;; void
handle_ball_collision:
   push rbp
   mov rbp, rsp

   push r12
   push r13
   push r14
   push r15

   call calculate_enemy_bounds
   ;; xmm0: f32 left
   ;; xmm1: f32 right
   ;; xmm2: f32 top
   ;; xmm3: f32 bottom

   movd r12d, xmm0
   movd r13d, xmm1
   movd r14d, xmm2
   movd r15d, xmm3

   call calculate_closest_point_on_paddle_to_ball_center
   ;; xmm0: f32 closest_x
   ;; xmm1: f32 closest_y

   call calculate_distance_from_ball_to_closest_point
   ;; xmm0: f32 dist_sq
   ;; xmm1: f32 radius_sq

   ucomiss xmm0, xmm1
   ja .early_out
.collision_detected:
   movd xmm0, r12d
   movd xmm1, r13d
   movd xmm2, r14d
   movd xmm3, r15d
   call calculate_ball_overlap
   ;; xmm0: f32 overlap_left
   ;; xmm1: f32 overlap_right
   ;; xmm2: f32 overlap_top
   ;; xmm3: f32 overlap_bottom

   call calculate_collision_side
   ;; eax: i32 collision_side
   mov edi, eax
   call bounce_ball_from_collision_side

   ;; mov rdi, debug_i32_fmt
   ;; mov rsi, 69420
   ;; xor rax, rax
   ;; call printf
.early_out:
   pop r15
   pop r14
   pop r13
   pop r12

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
BALL_SPEED:    dd 10.0
PADDLE_SPEED:  dd 200.0
PLAYING_FIELD: dd 375.0
PADDLE_COLOR:  dd 0xffffffff
BALL_COLOR:    dd 0xffffffff

;; Math constants
RAD_AND_DEG_CONST: dd 180.0
PI: dd 3.14159265358979323846
FLOAT_NEG_MASK: dd 0x80000000

align 4
PADDLE_ORIGIN:
   dd 75.0  ;; x
   dd -75.0 ;; y
   align 4

debug_i32_fmt: db "%d", 10, 0
debug_i32_i32_fmt: db "%d | %d", 10, 0
debug_f32_f32_fmt: db "%f | %f", 10, 0

