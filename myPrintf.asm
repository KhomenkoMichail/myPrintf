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


;----------------------------------------------------------------------------------------------
; My cDecl printf function, which supports specifiers %x, %d, %o, %b, %c and %s
;Entry:
;Exit:      rax = number of printed characters
;Expected:
;Destroyed: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11, r12
;----------------------------------------------------------------------------------------------
myPrintf:

                        push rbx
                        mov rbx, rsp
                        add rbx, 8 * 3      ; rbx contains address of second printf argument

                        push rbp
                        mov rbp, rsp

                        cld
                        xor r11, r11        ; buffer counter
                        xor r10, r10        ; printed symbols counter

                        ;mov rsi, rdi
                        mov rsi, [rsp + 8 * 3]

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

;----------------------------------------------------------------------------------------------
; Prints the contents of the stack buffer to the console.
;Entry:         rbp  =  address of the end of the buffer
;               r10  =  printed characters counter
;               r11  =  number of characters in the buffer
;
;Exit:
;Expected:
;Destroyed: rax, rdx, rdi, r10, r11
;----------------------------------------------------------------------------------------------
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


;----------------------------------------------------------------------------------------------
; Places an argument of type char into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r12    =  address of the systemV wrapper function return address
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r10, r11
;----------------------------------------------------------------------------------------------
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


;----------------------------------------------------------------------------------------------
; Places the character representation of the Hex argument into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   r12    =  address of the systemV wrapper function return address
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r8, r9, r10, r11
;----------------------------------------------------------------------------------------------
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


;----------------------------------------------------------------------------------------------
; Сonverts the lower 4 bits of the al register to a hexadecimal character
; and places it in the buffer
;Entry:                 4 lower bits of al  =  current symbol of the hex number
;                       r8  =  the number of non-zero characters of the number
;                              preceding the current one
;                       rdi    =  pointer to the current free element in the buffer
;                       r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rdx, rdi, r8, r10, r11
;----------------------------------------------------------------------------------------------
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


;----------------------------------------------------------------------------------------------
; Places the character representation of the binary argument into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   r12    =  address of the systemV wrapper function return address
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r8, r9, r10, r11
;----------------------------------------------------------------------------------------------
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


;----------------------------------------------------------------------------------------------
; Places the character representation of the octal argument into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   r12    =  address of the systemV wrapper function return address
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r8, r9, r10, r11
;----------------------------------------------------------------------------------------------
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


;----------------------------------------------------------------------------------------------
; Сonverts the lower 3 bits of the al register to a octal character
; and places it in the buffer
;Entry:                 3 lower bits of al  =  current symbol of the octal number
;                       r8  =  the number of non-zero characters of the number
;                              preceding the current one
;                       rdi    =  pointer to the current free element in the buffer
;                       r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rdx, rdi, r8, r10, r11
;----------------------------------------------------------------------------------------------
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


;----------------------------------------------------------------------------------------------
; Copies the string argument to the buffer
;Entry:             [rbx]  =  string address
;                   r11    =  buffer size counter
;                   r12    =  address of the systemV wrapper function return address
;                   rdi    =  pointer to the current free element in the buffer
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r10, r11
;----------------------------------------------------------------------------------------------
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


;----------------------------------------------------------------------------------------------
; Handles '%' output cases that are not included in the jump table.
; Stores the '%' character in the buffer in case of "%%", otherwise copies all
; the characters to the buffer.
;Entry:             rsi    =  pointer to the current format string element
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;                   r12    =  address of the systemV wrapper function return address
;Exit:
;Expected:
;Destroyed: rax, rdx, rdi, r10, r11
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
;                   r12    =  address of the systemV wrapper function return address
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r8, r9, r10, r11
;----------------------------------------------------------------------------------------------
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
;Destroyed: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
;----------------------------------------------------------------------------------------------
callMyPrintf:

    push r12
    mov r12, rsp     ; save rsp to get systemV stack arguments

    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    call myPrintf

    add rsp, 8*6
    pop r12
    ret

;printfFloat:
;
;
;            cvttsd2si r9, xmm0
;            cvtsi2sd xmm1, r9
;
;            subsd xmm0, xmm1
;
;
;
;            mov r9, rax
;            call
;
;
;           mov al, '.'
;            stosb
;            inc r12
;
;            mov rax, 1000000
;            cvtsi2sd xmm1, rax
;            mulsd xmm0, xmm1
;            cvttsd2si rax, xmm0
;
;
;            mov rcx, 6
;            call
;
;            jmp nextChar
