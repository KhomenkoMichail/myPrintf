
section .rodata

MIN_CASE         EQU 'b'
MAX_CASE         EQU 'x'

BUFFER_SIZE      EQU 512d

jumpTable:
    align 8

    dq .printBin

    dq .printChar

    dq .printDec

    times ('o' - 'd' - 1) dq .default

    dq .printOct

    times ('s' - 'o' - 1) dq .default

    dq .printStr

    times ('x' - 's' - 1) dq .default

    dq .printHex

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

                push ebp
                mov ebp, esp

                cld

                sub rsp, 512d
                mov rsi, rsp

.nextChar:      lodsb
                test al, al
                jz .enpPrintf

                cmp al, '%'
                je .switchFormat

                mov byte [rsi + rdx], al
                inc rdx

                cmp rdx, BUFFER_SIZE
                jne .continue
                call .printBuffer

.continue:      jmp .nextChar

.switchFormat:
                lodsb

                sub al, MIN_CASE
                js .default

                cmp al, (MAX_CASE - MIN_CASE)
                ja .default

                movzx rdx, al
                jmp [jumpTable + rdx * 8]

.enpPrintf:
                call .printBuffer
                mov rax, rdx

                pop ebp
                pop rbx

                pop rsi
                pop rdx
                pop rcx
                pop r8
                pop r9

                ret


.printBuffer:

            mov rax, 1
            mov rdi, 1
            syscall

            xor rdx, rdx
            ret

.printChar:
            mov rax, [rbp]
            inc rbp

            mov byte [rsi + rdx], al
            inc rdx

            cmp rdx, BUFFER_SIZE
            jne .continue
            call .printBuffer

            ret


.printHex:
                    mov rax, [rbp]
                    inc rbp

                    xor r8, r8

                    mov rcx, 64d

.nextHexSymbol:     mov rbx, rax
                    shr rbx, rcx
                    call printHexSymbol

                    sub rcx, 4d
                    test rcx, rcx
                    jnz .nextHexSymbol

                    ret

printHexSymbol:
                    and bl, 00001111b
                    test bl, bl
                    jz .isZero
                    inc r8

.isZero:            add bl, '0'
                    cmp bl, '9'

                    jbe .notLetter

                    add bl, 'A' - '0' + 1

                    test r8, r8
                    jz .end

.notLetter:
                    mov byte [rsi + rdx], bl
                    inc rdx

                    cmp rdx, BUFFER_SIZE
                    jne .continue
                    call .printBuffer

.end:               ret

.printBin:
                    mov rax, [rbp]
                    inc rbp

                    xor r8, r8

                    mov rcx, 64d

.nextBinSymbol:
                    mov rbx, rax
                    shr rbx, rcx

                    and bl, 00000001b
                    test bl, bl
                    jz .isZero
                    inc r8

.isZero:            add bl, '0'

                    test r8, r8
                    jz .skipLeadingZero

                    mov byte [rsi + rdx], bl
                    inc rdx

                    cmp rdx, BUFFER_SIZE
                    jne .continue
                    call .printBuffer

.skipLeadingZero:
                    dec rcx
                    test rcx, rcx
                    jnz .nextBinSymbol

                    ret


.printOct:
                    mov rax, [rbp]
                    inc rbp

                    xor r8, r8

                    mov rcx, 64d

.nextOctSymbol:     mov rbx, rax
                    shr rbx, rcx
                    call printOctSymbol

                    sub rcx, 3d
                    test rcx, rcx
                    jnz .nextOctSymbol

                    ret

printOctSymbol:
                    and bl, 00000111b
                    test bl, bl
                    jz .isZero
                    inc r8

.isZero:            add bl, '0'

                    test r8, r8
                    jz .end

                    mov byte [rsi + rdx], bl
                    inc rdx

                    cmp rdx, BUFFER_SIZE
                    jne .continue
                    call .printBuffer

.end:               ret

.printStr:
                    mov rax, [rbp]
                    inc rbp

.nextStrChar:       lodsb
                    test al, al
                    jz .enpPrintStr

                    mov byte [rsi + rdx], al
                    inc rdx

                    cmp rdx, BUFFER_SIZE
                    jne .continue
                    call .printBuffer

                    jmp .nextStrChar

.endPrintStr:       ret

.printDec:



