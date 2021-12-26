; int atoi(eax buf) -> eax int
atoi:
    push ebx
    push ecx
    push edx
    push esi
    mov esi, eax    ; esi = string buffer
    mov eax, 0
    mov ecx, 0

.multiplyLoop:
    xor ebx,ebx     ; reset ebx
    mov bl, [esi+ecx]   ; move single byte to ebx register
    
    ; check if 48 < bl < 57
    cmp bl, 48
    jl  .finished
    cmp bl, 57
    jg  .finished

    sub bl, 48
    add eax, ebx    ; add ebx to total
    mov ebx, 10
    mul ebx         ; total*10
    inc ecx
    jmp .multiplyLoop

.finished:
    cmp ecx, 0
    je  .restore    ; no integer args were passed
    mov ebx, 10
    div ebx         ; remove excess multiply by 10

.restore:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
; void print(eax integer)
iprint:
    push eax
    push ecx
    push edx
    push esi

    mov ecx, 0
divideLoop:
    inc ecx
    mov edx, 0
    mov esi, 10
    idiv esi    ; eax/esi, eax is quotient, edx is remainder
    add edx, 48 ; convert to ascii digit
    push edx   
    cmp eax, 0  ; loop if it is able to divde
    jnz divideLoop
printLoop:
    dec ecx
    mov eax, esp
    call sprint
    pop eax
    cmp ecx, 0 
    jnz printLoop

    pop esi
    pop edx
    pop ecx
    pop eax
    ret

iprintLF:
    call iprint

    push eax
    mov eax, 0Ah
    push eax
    mov eax, esp
    call sprint
    pop eax
    pop eax
    ret
; int slen
slen:
    push ebx
    mov ebx, eax
nextchar:
    cmp byte [eax], 0
    jz finished
    inc eax
    jmp nextchar
finished:
    sub eax, ebx
    pop ebx
    ret

; void sprintn(ecx msg, edx n)
; print msg of length n
sprintn:
    push ebx
    push eax

    mov ebx, 1
    mov eax, 4
    int 80h

    pop eax
    pop ebx
    ret


; void sprintnLF
sprintnLF:
    call sprintn

    push eax    ; save eax
    mov eax, 0Ah    ; eax = \n
    push eax
    mov eax, esp    ; eap points to memory of \n
    call sprint
    pop eax
    pop eax
    ret
; void sprint
; input eax msg buffer
; touches edx, ecx, ebx, eax
sprint:
    ; save registers
    push edx
    push ecx
    push ebx
    push eax

    call slen       ; eax is now len

    mov edx, eax    ; len
    pop eax         ; restore msg buffer
    
    mov ecx, eax    ; buffer
    mov ebx, 1      ; stdout
    mov eax, 4      ; write syscall
    int 80h

    ; restore registers
    pop ebx
    pop ecx
    pop edx
    ret

; void sprintLF
sprintLF:
    call sprint

    push eax    ; save eax
    mov eax, 0Ah    ; eax = \n
    push eax
    mov eax, esp    ; eap points to memory of \n
    call sprint
    pop eax
    pop eax
    ret

printLF:
    push eax
    mov eax, 0Ah
    push eax
    mov eax, esp
    call sprint
    pop eax
    pop eax
    ret
; void exit
quit:
    mov ebx, 0
    mov eax, 1
    int 80h
    ret