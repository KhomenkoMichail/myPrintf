section .rodata

MIN_CASE         EQU 'b'
MAX_CASE         EQU 'x'

BUFFER_SIZE      EQU 512d

jumpTable:
            align 8

            dq printBin

            dq printChar

            dq printDec

            times ('o' - 'd' - 1) dq printDefault

            dq printOct

            times ('s' - 'o' - 1) dq printDefault

            dq printStr

            times ('x' - 's' - 1) dq printDefault

            dq printHex

section .text

global callMyPrintf

global myPrintf

myPrintf:

                        push rbx
                        mov rbx, rsp
                        add rbx, 8*2

                        push rbp
                        mov rbp, rsp

                        cld
                        xor r11, r11        ;buffer counter
                        xor r10, r10        ;printed symbols counter

                        mov rsi, rdi

                        sub rsp, BUFFER_SIZE
                        mov rdi, rsp


nextChar:               lodsb
                        test al, al
                        jz .enpPrintf

                        cmp al, '%'
                        je .switchFormat

                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .continue
                        call printBuffer

.continue:              jmp nextChar

.switchFormat:
                        lodsb

                        sub al, MIN_CASE
                        js printDefault

                        cmp al, (MAX_CASE - MIN_CASE)
                        ja printDefault

                        movzx rdx, al
                        jmp [jumpTable + rdx * 8]

.enpPrintf:
                        call printBuffer
                        mov rax, r10

                        add rsp, BUFFER_SIZE
                        pop rbp
                        pop rbx

                        ret


printBuffer:
                        push rsi
                        push rcx
                        add r10, r11

                        mov rax, 1
                        mov rdi, 1

                        lea rsi, [rbp - BUFFER_SIZE]
                        mov rdx, r11
                        syscall

                        xor r11, r11

                        lea rdi, [rbp - BUFFER_SIZE]

                        pop rcx
                        pop rsi
                        ret

printChar:
                        mov rax, [rbx]
                        add rbx, 8
                        cmp rbx, r12
                        jne .notSystemVStackArgument
                        add rbx, 8 * 2

.notSystemVStackArgument:
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer

.end:                   jmp nextChar


printHex:
                        mov r9, [rbx]
                        add rbx, 8
                        cmp rbx, r12
                        jne .notSystemVStackArgument
                        add rbx, 8 * 2

.notSystemVStackArgument:

                        test r9, r9
                        jnz .notZero

                        mov al, '0'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer
                        jmp .end


.notZero:
                        xor r8, r8
                        mov cl, 60d

.nextHexSymbol:
                        mov rax, r9
                        shr rax, cl
                        call printHexSymbol

                        sub cl, 4d
                        jge .nextHexSymbol

.end:                   jmp nextChar

printHexSymbol:
                        and al, 00001111b
                        test al, al
                        jz .isZero
                        inc r8

.isZero:                test r8, r8
                        jz .end

                        add al, '0'
                        cmp al, '9'

                        jbe .notLetter

                        add al, 'A' - ('9' + 1)


.notLetter:
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer

.end:                   ret


printBin:
                        mov r9, [rbx]
                        add rbx, 8
                        cmp rbx, r12
                        jne .notSystemVStackArgument
                        add rbx, 8 * 2

.notSystemVStackArgument:

                        test r9, r9
                        jnz .notZero

                        mov al, '0'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer
                        jmp .end


.notZero:               xor r8, r8

                        mov cl, 64d

.nextBinSymbol:
                        dec cl
                        mov rax, r9
                        shr rax, cl

                        and al, 00000001b
                        test al, al
                        jz .isZero
                        inc r8

.isZero:                add al, '0'

                        test r8, r8
                        jz .skipLeadingZero

                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .skipLeadingZero
                        call printBuffer

.skipLeadingZero:
                        test cl, cl
                        jnz .nextBinSymbol

.end:                   jmp nextChar


printOct:
                        mov r9, [rbx]
                        add rbx, 8
                        cmp rbx, r12
                        jne .notSystemVStackArgument
                        add rbx, 8 * 2

.notSystemVStackArgument:

                        test r9, r9
                        jnz .notZero

                        mov al, '0'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer
                        jmp .end

.notZero:               xor r8, r8

                        mov cl, 63d

.nextOctSymbol:
                        mov rax, r9
                        shr rax, cl
                        call printOctSymbol

                        sub cl, 3
                        test cl, cl
                        jge .nextOctSymbol

.end:                   jmp nextChar

printOctSymbol:
                        and al, 00000111b
                        test al, al
                        jz .isZero
                        inc r8

.isZero:                add al, '0'

                        test r8, r8
                        jz .end

                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer

.end:                   ret

printStr:

                        push rsi
                        mov rsi, [rbx]
                        add rbx, 8
                        cmp rbx, r12
                        jne .notSystemVStackArgument
                        add rbx, 8 * 2

.notSystemVStackArgument:

.nextStrChar:
                        lodsb
                        test al, al
                        jz .enpPrintStr

                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .nextStrChar
                        call printBuffer

                        jmp .nextStrChar

.enpPrintStr:
                        pop rsi
                        jmp nextChar



printDefault:
                        mov al, '%'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .continue
                        call printBuffer

.continue:              mov al, [rsi - 1]
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer

.end:                   jmp nextChar


printDec:
                        movsxd r9, [rbx]
                        add rbx, 8
                        cmp rbx, r12
                        jne .notSystemVStackArgument
                        add rbx, 8 * 2

.notSystemVStackArgument:

                        test r9, r9
                        jnz .notZero

                        mov al, '0'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer
                        jmp .end

.notZero:
                        test r9, r9
                        jns .isPositive

                        neg r9
                        mov al, '-'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .isPositive
                        call printBuffer

.isPositive:
                        mov rax, r9


                        xor r8, r8          ;numCounter
                        mov r9, 10          ;divider

.nextNum:
                        xor rdx, rdx
                        div r9

                        push rdx
                        inc r8

                        test rax, rax
                        jnz .nextNum


.printNum:
                        pop rax
                        add al, '0'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .continue
                        call printBuffer

.continue:              dec r8
                        test r8, r8
                        jnz .printNum

.end:                   jmp nextChar



callMyPrintf:

    push r12
    mov r12, rsp     ; save rsp to get systemV stack arguments

    push r9
    push r8
    push rcx
    push rdx
    push rsi

    call myPrintf

    add rsp, 8*5
    pop r12
    ret



