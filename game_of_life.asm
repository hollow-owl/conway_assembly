%include 'functions.asm'
section .data
msg:    db  'Hello World!', 0h

section .bss
height: resb 4
width:  resb 4
curr:   resb 8
old:    resb 8
section .text
global _start

; initialize vector
; run game
;; copy map
;; loop through each cell and apply rules
;; display map
;; sleep for x seconds
;; do it again
_start:
    pop ecx         ; num of args
    pop edx         ; program name
    dec ecx
    cmp ecx, 2      ; need two args
    jne .exit

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
    mov [curr], esp     ; first map
    sub esp, eax
    mov [old], esp      ; second map

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
    mov byte[esp+ecx], 0x2e ; map[i] = '.'
    jmp .setupEnd
.setupAlive:
    mov byte[esp+ecx], 0x23 ; map[i] = '#'
.setupEnd:
    inc ecx
    jmp .setupLoop
.setupFinish:
    mov eax,[curr]
    jmp main
main:
    call displayMap
    call evolve
.exit:
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

; void evolve(eax map)
; out eax new map
evolve:
; eax = current map
; ebx = new map

; for(ecx = 0; ecx < width; ecx += 1)
; for(edx = 0; edx < height; edx += 1)
; neighbors eax+ (ecx+[-1..1])%width + (width*(edx+[-1..1]))%height
; neightbors-- if eax+ecx+width*edx == #
; new_cell = (n == 3 || (n == 2 && curr[i] == #)