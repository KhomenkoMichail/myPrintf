section .rodata

MIN_CASE         EQU 'b'
MAX_CASE         EQU 'x'

BUFFER_SIZE      EQU 512d

jumpTable:
            align 8

            dq printBin

            dq printChar

            dq printDec

            dq printDefault

            dq printDouble

            times ('o' - 'f' - 1) dq printDefault

            dq printOct

            times ('s' - 'o' - 1) dq printDefault

            dq printStr

            times ('x' - 's' - 1) dq printDefault

            dq printHex

section .text

global callMyPrintf

global myPrintf


;----------------------------------------------------------------------------------------------
; Wrapper function for calling myPrintf in systemVABI
;Entry:                 rdi            =  first argument (format string)
;                       rsi            =  second argument
;                       rdx            =  third argument
;                       rcx            =  fourth argument
;                       r8             =  fifth argument
;                       r9             =  sixth argument
;                       [rsp + 8]      =  seventh argument
;                       [rsp + 8 * 2]  =  eighth argument
;                       ...
;Exit:
;Expected:
;Destroyed: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11, r12
;----------------------------------------------------------------------------------------------
callMyPrintf:
                        pop r10

                        push r9
                        push r8
                        push rcx
                        push rdx
                        push rsi
                        push rdi

                        sub rsp, 64

                        movsd [rsp + 56], xmm7
                        movsd [rsp + 48], xmm6
                        movsd [rsp + 40], xmm5
                        movsd [rsp + 32], xmm4
                        movsd [rsp + 24], xmm3
                        movsd [rsp + 16], xmm2
                        movsd [rsp + 8],  xmm1
                        movsd [rsp],      xmm0



                        call myPrintf


                        add rsp, 8*6 + 64
                        push r10
                        ret


;----------------------------------------------------------------------------------------------
; My cDecl printf function, which supports specifiers %x, %d, %o, %b, %c and %s
;Entry:
;Exit:      rax = number of printed characters
;Expected:
;Destroyed: rax, rcx, rdx, rsi, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
myPrintf:
                        push rbp
                        mov rbp, rsp

                        push rbx
                        push r13
                        push r14
                        push r15

                        lea rbx, [rbp + 8 * 2 + 64 + 8]
                                                        ; rbx contains address of current
                                                        ; printf integer argument or stack
                                                        ; double argument

                        lea r14, [rbp + 8 * 2]          ; r14 contains address of current
                                                        ; double argument


                        cld

                        xor r8, r8                  ; printed symbols counter

                        xor r11, r11                ; buffer counter

                        xor r13, r13                ; printDec mode flag
                                                    ; (clean for printing %d,
                                                    ; set for printing integer part of %f)

                        xor r15, r15                ; processed double arguments counter


                        mov rsi, [rbp + 8 * 2 + 64]

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
                        mov rax, r8

                        add rsp, BUFFER_SIZE

                        pop r15
                        pop r14
                        pop r13
                        pop rbx

                        pop rbp
                        ret


;----------------------------------------------------------------------------------------------
; Prints the contents of the stack buffer to the console.
;Entry:         rbp  =  address of the end of the buffer
;               r8  =  printed characters counter
;               r11  =  number of characters in the buffer
;
;Exit:
;Expected:
;Destroyed: rax, rdx, rdi, r8, r11
;----------------------------------------------------------------------------------------------
printBuffer:
                        push rsi
                        push rcx
                        add r8, r11

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


;----------------------------------------------------------------------------------------------
; Places an argument of type char into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r8, r11
;----------------------------------------------------------------------------------------------
printChar:
                        mov rax, [rbx]
                        add rbx, 8

                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer

.end:                   jmp nextChar


;----------------------------------------------------------------------------------------------
; Places the character representation of the Hex argument into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printHex:
                        mov r9, [rbx]
                        add rbx, 8

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
                        xor r12, r12
                        mov cl, 60d

.nextHexSymbol:
                        mov rax, r9
                        shr rax, cl
                        call printHexSymbol

                        sub cl, 4d
                        jge .nextHexSymbol

.end:                   jmp nextChar


;----------------------------------------------------------------------------------------------
; Сonverts the lower 4 bits of the al register to a hexadecimal character
; and places it in the buffer
;Entry:                 4 lower bits of al  =  current symbol of the hex number
;                       r12  =  the number of non-zero characters of the number
;                              preceding the current one
;                       rdi    =  pointer to the current free element in the buffer
;                       r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rdx, rdi, r12, r8, r11
;----------------------------------------------------------------------------------------------
printHexSymbol:
                        and al, 00001111b
                        test al, al
                        jz .isZero
                        inc r12

.isZero:                test r12, r12
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


;----------------------------------------------------------------------------------------------
; Places the character representation of the binary argument into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printBin:
                        mov r9, [rbx]
                        add rbx, 8

                        test r9, r9
                        jnz .notZero

                        mov al, '0'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer
                        jmp .end


.notZero:               xor r12, r12

                        mov cl, 64d

.nextBinSymbol:
                        dec cl
                        mov rax, r9
                        shr rax, cl

                        and al, 00000001b
                        test al, al
                        jz .isZero
                        inc r12

.isZero:                add al, '0'

                        test r12, r12
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


;----------------------------------------------------------------------------------------------
; Places the character representation of the octal argument into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printOct:
                        mov r9, [rbx]
                        add rbx, 8

                        test r9, r9
                        jnz .notZero

                        mov al, '0'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer
                        jmp .end

.notZero:               xor r12, r12

                        mov cl, 63d

.nextOctSymbol:
                        mov rax, r9
                        shr rax, cl
                        call printOctSymbol

                        sub cl, 3
                        test cl, cl
                        jge .nextOctSymbol

.end:                   jmp nextChar


;----------------------------------------------------------------------------------------------
; Сonverts the lower 3 bits of the al register to a octal character
; and places it in the buffer
;Entry:                 3 lower bits of al  =  current symbol of the octal number
;                       r12  =  the number of non-zero characters of the number
;                              preceding the current one
;                       rdi    =  pointer to the current free element in the buffer
;                       r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rdx, rdi, r12, r8, r11
;----------------------------------------------------------------------------------------------
printOctSymbol:
                        and al, 00000111b
                        test al, al
                        jz .isZero
                        inc r12

.isZero:                add al, '0'

                        test r12, r12
                        jz .end

                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer

.end:                   ret


;----------------------------------------------------------------------------------------------
; Copies the string argument to the buffer
;Entry:             [rbx]  =  string address
;                   r11    =  buffer size counter
;                   rdi    =  pointer to the current free element in the buffer
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r8, r11
;----------------------------------------------------------------------------------------------
printStr:

                        push rsi
                        mov rsi, [rbx]
                        add rbx, 8

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


;----------------------------------------------------------------------------------------------
; Handles '%' output cases that are not included in the jump table.
; Stores the '%' character in the buffer in case of "%%", otherwise copies all
; the characters to the buffer.
;Entry:             rsi    =  pointer to the current format string element
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rdx, rdi, r8, r11
;----------------------------------------------------------------------------------------------
printDefault:
                        mov al, '%'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .continue
                        call printBuffer

.continue:              mov al, [rsi - 1]
                        cmp al, '%'
                        je .end

                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .end
                        call printBuffer
.end:                   jmp nextChar


;----------------------------------------------------------------------------------------------
; Places the character representation of the decimal argument into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printDec:
                        test r13, r13
                        jnz .processDec

                        movsxd r9, [rbx]
                        add rbx, 8

.processDec:
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


                        xor r12, r12          ;numCounter
                        mov r9, 10            ;divider

.nextNum:
                        xor rdx, rdx
                        div r9

                        push rdx
                        inc r12

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

.continue:              dec r12
                        test r12, r12
                        jnz .printNum

                        test r13, r13
                        jnz returnInPrintDouble

.end:                   jmp nextChar




printDouble:
                        cmp r15, 8
                        je .getArgFromJointStack

                        movq xmm0, [r14]
                        add r14, 8
                        inc r15
                        jmp .processDouble

.getArgFromJointStack:
                        movq xmm0, [rbx]
                        add rbx, 8

.processDouble:

                        cvttsd2si r9, xmm0              ; r9 contains integer part of the xmm0
                        cvtsi2sd xmm1, r9               ; xmm1 contains integer part of the xmm0


                        subsd xmm0, xmm1                ; xmm0 contains fractional part

                        inc r13
                        jmp printDec
returnInPrintDouble:    xor r13, r13

                        mov al, '.'
                        stosb
                        inc r11
                        cmp r11, BUFFER_SIZE
                        jne .continue
                        call printBuffer
.continue:

                        mov rax, 1000000
                        cvtsi2sd xmm1, rax
                        mulsd xmm0, xmm1
                        cvttsd2si rax, xmm0             ; rax contains fractional part of double
                                                        ; multiplied by 1000000


                        call printFractionalPart

                        jmp nextChar



printFractionalPart:
                        mov r9, 10          ;divider

                        mov rcx, 6
.nextNum:
                        xor rdx, rdx
                        div r9
                        push rdx

                        loop .nextNum

                        mov rcx, 6
.printNum:
                        pop rax
                        add al, '0'
                        stosb
                        inc r11

                        cmp r11, BUFFER_SIZE
                        jne .continue
                        call printBuffer

.continue:
                        loop .printNum
                        ret
