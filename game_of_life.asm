%include 'functions.asm'
section .data
msg:    db  'Hello World!', 0h
alive_cell: equ 0x23    ; '#'
dead_cell:  equ 0x2e    ; '.'
section .bss
height: resb 4
width:  resb 4
map1:   resb 8
map2:    resb 8
section .text
global _start

; initialize vector
; run game
;; loop through each cell and apply rules
;; display map
;; sleep for x seconds
;; do it again
_start:
    pop ecx             ; num of args
    pop edx             ; program name
    dec ecx
    cmp ecx, 2          ; need two args
    jne exit

    pop eax             ; gets width
    call atoi
    mov [width], eax
    
    pop eax             ; gets height
    call atoi
    mov [height], eax

    ; initialize map
    mov ebx, [width]
    mul ebx             ; height * width
    mov ebp, esp        ; save curr stack pointer
    sub esp, eax
    mov [map1], esp     ; first map
    sub esp, eax
    mov [map2], esp     ; second map

    ; fill map with random bytes
    mov ebx, 2
    mul ebx             ; eax = 2*height*width
    
    mov edx, 0          ; flags
    mov ecx, eax        ; size of both maps
    mov ebx, esp        ; maps
    mov eax, 0x163      ; random bytes
    int 80h             ; sys_getrandom(*buf, count, flags) 

    ; set the bytes
    mov ecx, 0          ; counter
                        ; eax size
                        ; esp start
                        ; ebx = map[i]
.setupLoop:
    cmp ecx, eax
    jz  .setupFinish
    xor ebx,ebx
    mov bl, [esp+ecx]

    cmp bl, 0x22
    jl  .setupAlive
    mov byte[esp+ecx], dead_cell    ; map[i] = '.'
    jmp .setupEnd
.setupAlive:
    mov byte[esp+ecx], alive_cell   ; map[i] = '#'
.setupEnd:
    inc ecx
    jmp .setupLoop
.setupFinish:
    mov eax,[map2]
    mov ecx, 10
main:
    push ecx
    call displayMap
    call evolve
    call printLF 
    call printLF

    push eax
    mov eax, 1
    call sleepN
    pop eax

    jmp main

exit:
    call quit


; void displayMap(eax map)
displayMap:
    ;prologue
    push edx
    push ecx
    push ebx
    push eax

    ; edx = size
    push eax
    mov eax, [height]
    mov ebx, [width]
    mul ebx
    mov edx, eax
    pop eax

    mov ecx, 0
.loop:                  ; for(ecx = eax|map, ecx < edx|size+map, ecx+=width)
    cmp ecx, edx
    jge .loopFinish

    push edx
    push ecx
    add ecx, eax                    ; ecx = row buf
    mov edx, [width]
    call sprintnLF
    pop ecx
    pop edx
    add ecx, [width]
    jmp .loop
.loopFinish:

    ; epilouge
    pop eax
    pop ebx
    pop ecx
    pop edx
    ret

; void evolve(eax old_map)
; out eax new map
evolve:
    ; prologue
    push ebx
    push ebp
    mov ebp, esp
    sub esp, 16
	; new_map = (old_map == map1) ? map2 : map1;
    call find_other_map
	; save to local variables
    mov dword [ebp-4], eax          ; ebp-4 = old_map
    mov dword [ebp-8], ebx          ; [ebp-8] = new_map
 
    mov dword [ebp-12], 0           ; [ebp-12] = y
 .for_y:
    mov ebx, [height]
    cmp [ebp-12], ebx
    jge .end_y

    mov dword [ebp-16], 0           ; [ebp-16] = x
 .for_x:
    mov ebx, [width]
    cmp [ebp-16], ebx
    jge .end_x
	; for_y for_x {
    ;   neighbors(map, x, y)
    mov ecx, [ebp-12]   ; y
    mov ebx, [ebp-16]   ; x
                        ; eax old_map
    call neighbors
	; 	new[y][x] = (n == 3 || (n == 2 && univ[y][x]));
    call set_new
	; }

    inc dword [ebp-16]
    jmp .for_x
.end_x:

    inc dword [ebp-12]
    jmp .for_y
.end_y:
    mov eax, [ebp-8]
    ; epilogue
    add esp, 16
    pop ebp

    pop ebx
    ret

; find_new_map(eax map) -> ebx other_map
; changes: ebx
find_other_map:
    cmp eax, [map1]
    je .other2
    mov ebx, [map1]
    jmp .end
.other2:
    mov ebx, [map2]
.end:
    ret

; neighbors(eax old_map,ebx x,ecx y) -> edx n
neighbors:
    push 0  ; n = 0

    ; 0 | 1 | 2
    ; 3 | 4 | 5
    ; 6 | 7 | 8

    dec ebx
    call is_alive   ; 3
    jne .L2
    inc dword [esp]
.L2:
    dec ecx
    call is_alive   ; 0
    jne .L3
    inc dword [esp]
.L3:
    inc ebx
    call is_alive   ; 1
    jne .L4
    inc dword [esp]
.L4:
    inc ebx
    call is_alive   ; 2
    jne .L5
    inc dword [esp]
.L5:
    inc ecx
    call is_alive   ; 5
    jne .L6
    inc dword [esp]
.L6:
    inc ecx
    call is_alive   ; 8
    jne .L7
    inc dword [esp]
.L7:
    dec ebx
    call is_alive   ; 7
    jne .L8
    inc dword [esp]
.L8:
    dec ebx
    call is_alive   ; 6
    jne .L9
    inc dword [esp]
.L9:
    ; reset x, y
    inc ebx
    dec ecx
    pop edx
    ret

; bool is_alive(eax map, ebx x, ecx y)
; cmp (map + (x+[width])%[width] + [height]*(ecx+[height])%[height])
is_alive:
    push edx
    push ecx
    push ebx

    call get_offset
    cmp byte[eax+ebx], alive_cell   ; [ebx] cmp '#'
    pop ebx
    pop ecx
    pop edx
    ret

; get_cell(eax map, ebx x, ecx y) -> ebx offset
; changes ebx ecx
get_offset:
    push edx
    push eax
    xor edx, edx

    mov eax, ecx
    mov ecx, [height]
    add eax, ecx
    idiv ecx            ; (y+[height])%[height]
    mov eax, edx
    mul ecx
    mov ecx, eax        ; ecx = [height] * (y+[height])%[height]

    mov eax, ebx
    mov ebx, [width]
    add eax, ebx
    idiv ebx
    mov ebx, edx        ; ebx = (x+[width])%[width]

    pop eax
    pop edx
    add ebx, ecx        ; ebx =  (map + (x+[width])%[width] + [height]*(ecx+[height])%[height])
    ret

; set_new(eax old_map, ebx x, ecx y, edx n, [ebp-8] new_map) void
; changes edx
set_new:
    push eax

    cmp edx, 3              ; n == 3
    je .alive

    cmp edx, 2              ; n == 2 && map[x][y] = '#'
    jne .dead
    call is_alive
    jne .dead
.alive:                     ; if (n==3 || (n==2 && map[x][y] == '#'))
    xor edx, edx            ; all 32 bit edx = 0
    mov edx, alive_cell     ; '#''
    jmp .epilogue
.dead:                      ; else
    xor edx, edx            ; all 32 bit edx = 0
    mov edx, dead_cell      ; '.'
.epilogue:              
    mov eax, [ebp-8]

    push ecx                ; new_map[x][y] = edx
    push ebx
    call get_offset
    mov byte[eax+ebx], dl   ; lower 8 bits of edx
    pop ebx
    pop ecx

    pop eax
    ret