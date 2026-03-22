section .rodata

MIN_CASE         EQU 'b'
MAX_CASE         EQU 'x'

BUFFER_SIZE      EQU 512d

jumpTable:
            align 8

            dq printBin

            dq printChar

            dq printDec

            times ('o' - 'd' - 1) dq .default

            dq printOct

            times ('s' - 'o' - 1) dq .default

            dq printStr

            times ('x' - 's' - 1) dq .default

            dq printHex

section .text

global _start

_start:

myPrintf:
                push r9
                push r8
                push rcx
                push rdx
                push rsi

                push rbx
                mov rbx, rsp
                add rbx, 8

                push rbp
                mov rbp, rsp

                cld
                xor rcx, rcx        ;buffer counter
                xor r10, r10        ;printed symbols counter

                mov rsi, rdi

                sub rsp, BUFFER_SIZE
                mov rdi, rsp


nextChar:       lodsb
                test al, al
                jz .enpPrintf

                cmp al, '%'
                je .switchFormat

                stosb
                inc rcx

                cmp rcx, BUFFER_SIZE
                jne .continue
                call printBuffer

.continue:      jmp nextChar

.switchFormat:
                lodsb

                sub al, MIN_CASE
                js .default

                cmp al, (MAX_CASE - MIN_CASE)
                ja .default

                movzx rdx, al
                jmp [jumpTable + rdx * 8]

.enpPrintf:
                call printBuffer
                mov rax, r10

                pop rbp
                pop rbx

                pop rsi
                pop rdx
                pop rcx
                pop r8
                pop r9

                ret


printBuffer:
            add r10, rcx

            mov rax, 1
            mov rdi, 1

            lea rsi, [rbp - BUFFER_SIZE]
            mov rdx, rcx
            syscall

            xor rcx, rcx

            lea rdi, [rbp - BUFFER_SIZE]

            ret

printChar:
            mov rax, [rbx]
            add rbx, 8

            stosb
            inc rcx

            cmp rcx, BUFFER_SIZE
            jne .continue
            call printBuffer

            jmp nextChar


printHex:
                    mov r9, [rbx]
                    add rbx, 8

                    test r9, r9
                    jnz .notZero

                    mov al, '0'
                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .end
                    call printBuffer
                    jmp .end


.notZero:           xor r8, r8

                    mov rdx, 64d

.nextHexSymbol:     sub rdx, 4d
                    mov rax, r9
                    shr rax, rdx
                    call printHexSymbol

                    test rdx, rdx
                    jnz .nextHexSymbol

                    jmp nextChar

printHexSymbol:
                    and al, 00001111b
                    test al, al
                    jz .isZero
                    inc r8

.isZero:            add al, '0'
                    cmp al, '9'

                    jbe .notLetter

                    add al, 'A' - '0' + 1

                    test r8, r8
                    jz .end

.notLetter:
                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .end
                    call printBuffer

.end:               ret


printBin:
                    mov r9, [rbx]
                    add rbx, 8

                    test r9, r9
                    jnz .notZero

                    mov al, '0'
                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .end
                    call printBuffer
                    jmp .end


.notZero:           xor r8, r8

                    mov rdx, 64d

.nextBinSymbol:
                    dec rdx
                    mov rax, r9
                    shr rax, rdx

                    and al, 00000001b
                    test al, al
                    jz .isZero
                    inc r8

.isZero:            add al, '0'

                    test r8, r8
                    jz .skipLeadingZero

                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .skipLeadingZero
                    call printBuffer

.skipLeadingZero:
                    test rdx, rdx
                    jnz .nextBinSymbol

.end                jmp nextChar


printOct:
                    mov r9, [rbx]
                    add rbx, 8

                    test r9, r9
                    jnz .notZero

                    mov al, '0'
                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .end
                    call printBuffer
                    jmp .end

.notZero            xor r8, r8

                    mov rdx, 63d

.nextOctSymbol:
                    mov rax, r9
                    shr rax, rdx
                    call printOctSymbol

                    sub rdx, 3
                    test rdx, rdx
                    jge .nextOctSymbol

                    nextChar

printOctSymbol:
                    and al, 00000111b
                    test al, al
                    jz .isZero
                    inc r8

.isZero:            add al, '0'

                    test r8, r8
                    jz .end

                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .end
                    call printBuffer

.end:               ret

printStr:

                    push rsi
                    mov rsi, [rbx]
                    add rbx, 8

.nextStrChar:
                    lodsb
                    test al, al
                    jz .enpPrintStr

                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .continue
                    call printBuffer

                    jmp .nextStrChar

.enpPrintStr:
                    pop rsi
                    jmp nextChar



default:
                    mov al, '%'
                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .continue
                    call printBuffer

.continue           mov al, [rsi - 1]
                    stosb
                    inc rcx

                    cmp rcx, BUFFER_SIZE
                    jne .end
                    call printBuffer

.end                jmp nextChar


printDec:









