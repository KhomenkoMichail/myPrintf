%macro PUT_CHAR 1
    mov al, %1
    stosb
    inc r11
    cmp r11, BUFFER_MAX_SIZE
    jne %%skip
    call printBuffer
%%skip:
%endmacro

DEFAULT REL
extern printf

MIN_CASE             EQU 'b'
MAX_CASE             EQU 'x'

BUFFER_MAX_SIZE      EQU 512d

MANTIS_MASK          EQU 0xFFFFFFFFFFFFF

section .rodata

align 16

notSignMask     dq 0x7FFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF

number                  db "0123456789abcdef"

numberSystemMask        db 0x00, 0x01, 0x03, 0x07, 0x0F

formatString    db "%d %s %x %d%%%c%b", 10, 0
strArg          db "love", 0

            align 8
jumpTable:

            dq printBin - jumpTable

            dq printChar - jumpTable

            dq printDec - jumpTable

            dq printDefault - jumpTable

            dq printDouble - jumpTable

            times ('o' - 'f' - 1) dq printDefault - jumpTable

            dq printOct - jumpTable

            times ('s' - 'o' - 1) dq printDefault - jumpTable

            dq printStr - jumpTable

            times ('x' - 's' - 1) dq printDefault - jumpTable

            dq printHex - jumpTable

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
                        pop r10                             ; save callMyPrintf return address

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
                        lea rdi, [formatString]
                        mov rsi, -1
                        lea rdx, [strArg]
                        mov rcx, 3802
                        mov r8, 100
                        mov r9, 33
                        push 126

                        mov al, 0
                        call printf wrt ..plt
                        add rsp, 8
                        pop r10

                        push r10                            ; push callMyPrintf return address
                        ret                                 ; in stack


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

                        lea r14, [rbp + 8 * 2]              ; r14 contains address of current
                                                            ; double argument


                        cld

                        xor r8, r8                          ; printed symbols counter

                        xor r11, r11                        ; buffer counter

                        xor r13, r13                        ; printDec mode flag
                                                            ; (clean for printing %d,
                                                            ; set for printing integer part of %f)

                        xor r15, r15                        ; processed double arguments counter


                        mov rsi, [rbp + 8 * 2 + 64]

                        sub rsp, BUFFER_MAX_SIZE
                        mov rdi, rsp                        ; rdi is a pointer to the next
                                                            ; free element in the buffer

nextFormatStringChar:
                        lodsb
                        test al, al                         ; cmp al, '\0'
                        jz .enpPrintf

                        cmp al, '%'
                        je .switchFormat

                        PUT_CHAR al

                        jmp nextFormatStringChar

.switchFormat:
                        lodsb

                        sub al, MIN_CASE                    ; al = curChar - 'b'
                        js printDefault

                        cmp al, (MAX_CASE - MIN_CASE)
                        ja printDefault

                        movzx rdx, al                       ; rdx = curChar - 'b'
                        lea r9, [jumpTable]
                        movsxd r12, dword [r9 + rdx * 8]
                        add r9, r12
                        jmp r9

.enpPrintf:
                        call printBuffer
                        mov rax, r8                         ; in rax printf returns the
                                                            ; number of peinted characters

                        add rsp, BUFFER_MAX_SIZE

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

                        mov rax, 1                                 ; write
                        mov rdi, 1                                 ; stdout

                        lea rsi, [rbp - BUFFER_MAX_SIZE - 4 * 8]       ; buffer address
                        mov rdx, r11                               ; buffer size
                        syscall

                        xor r11, r11                               ; bufferSize = 0

                        lea rdi, [rbp - BUFFER_MAX_SIZE - 4 * 8]       ; clean buffer

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
                        mov rax, [rbx]                          ; take argument from the stack
                        add rbx, 8                              ; inc arg address

                        PUT_CHAR al

                        jmp nextFormatStringChar


;----------------------------------------------------------------------------------------------
; Places the character representation of the argument
; of power of two number system into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   rdx    =  power of two of the current number system
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printPowerOfTwo:
                        mov r9, [rbx]                       ; take argument from the stack
                        add rbx, 8                          ; inc argument address

                        test r9, r9
                        jnz .notZero                        ; if (arg == 0)

                        PUT_CHAR '0'
                        jmp .end


.notZero:               xor r12, r12                        ; r12 is a non-zero
                                                            ; characters counter

                        mov rcx, 64d                        ; cl contains number of bits to
                                                            ; shift in current iteration

                        cmp rdx, 3
                        jne .nextSymbol
                        add rcx, 2                          ; to divide by three in oct system


.nextSymbol:
                        sub rcx, rdx
                        mov rax, r9
                        shr rax, cl

                        lea rsi, [numberSystemMask]
                        and al, [rsi + rdx]

                        test al, al
                        jz .isZero
                        inc r12

.isZero:

                        test r12, r12                       ; if symbol is a leading zero
                        jz .skipLeadingZero                 ; do not print it


                        lea rsi, [number]
                        movsx rax, al
                        mov al, [rsi + rax]

                        PUT_CHAR al
.skipLeadingZero:
                        test cl, cl
                        jg .nextSymbol

.end:                   ret


;----------------------------------------------------------------------------------------------
; Places the character representation of the Hex argument into the buffer
; (by calling printPowerOfTwo).
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printHex:
                        mov rdx, 4

                        push rsi
                        call printPowerOfTwo
                        pop rsi

                        jmp nextFormatStringChar


;----------------------------------------------------------------------------------------------
; Places the character representation of the octal argument into the buffer.
; (by calling printPowerOfTwo).
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printOct:
                        mov rdx, 3

                        push rsi
                        call printPowerOfTwo
                        pop rsi

                        jmp nextFormatStringChar


;----------------------------------------------------------------------------------------------
; Places the character representation of the binary argument into the buffer.
; (by calling printPowerOfTwo).
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printBin:
                        mov rdx, 1

                        push rsi
                        call printPowerOfTwo
                        pop rsi

                        jmp nextFormatStringChar


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

                        mov rsi, [rbx]                      ; take string address from the stack
                        add rbx, 8                          ; inc argument address

.nextStrChar:
                        lodsb
                        test al, al                         ; cmp al, '\0'
                        jz .enpPrintStr

                        PUT_CHAR al
                        jmp .nextStrChar

.enpPrintStr:
                        pop rsi
                        jmp nextFormatStringChar


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
                        PUT_CHAR '%'

                        mov al, [rsi - 1]                   ; take char after '%'
                        cmp al, '%'                         ; if '%' print only one (already done)
                        je .end

                        PUT_CHAR al
.end:                   jmp nextFormatStringChar


;----------------------------------------------------------------------------------------------
; Places the character representation of the decimal argument into the buffer.
;Entry:             [rbx]  =  current printf argument
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;                   r13    =  printDec mode flag
;                             (clean for printing %d, set for printing integer part of %f)
;Exit:
;Expected:
;Destroyed: rax, rbx, rdx, rdi, r12, r9, r8, r11
;----------------------------------------------------------------------------------------------
printDec:
                        test r13, r13                       ; check printDec mode flag
                        jnz .processDec

                        movsxd r9, [rbx]                    ; if print %d take arg from stack
                        add rbx, 8                          ; inc argument address

.processDec:
                        test r9, r9
                        jnz .notZero

                        PUT_CHAR '0'
                        jmp .end

.notZero:
                        test r9, r9
                        jns .isPositive

                        neg r9
                        PUT_CHAR '-'

.isPositive:
                        mov rax, r9


                        xor r12, r12                        ; r12 is a numCounter
                        mov r9, 10                          ; divider

.nextNum:
                        xor rdx, rdx
                        div r9

                        push rdx                            ; push remainder
                        inc r12

                        test rax, rax                       ; while (quotient  != 0)
                        jnz .nextNum


.printNum:
                        pop rax                             ; pop remainder
                        add al, '0'                         ; num to ASCII
                        PUT_CHAR al

                        dec r12                             ; numCounter--
                        test r12, r12
                        jnz .printNum

                        test r13, r13                       ; if (set %f mode flag)
                        jnz returnInPrintDouble             ; return to returnInPrintDouble

.end:                   jmp nextFormatStringChar


;----------------------------------------------------------------------------------------------
; Places the character representation of the double argument into the buffer.
;Entry:             rbx    =  joint arguments stack pointer
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;                   r14    =  xmm arguments stack pointer
;                   r15    =  number of the used xmm arguments
;Exit:
;Expected:
;Destroyed: rax, rbx, rcx, rdi, r9, r11, r14, r15, xmm0, xmm1
;----------------------------------------------------------------------------------------------
printDouble:
                        cmp r15, 8                          ; if all 8 xmm regs argument are used
                        je .getArgFromJointStack            ; take them from the joint stack

                        movq xmm0, [r14]
                        mov rax, [r14]                      ; r14 = xmm arguments stack pointer
                        add r14, 8
                        inc r15
                        jmp .processDouble

.getArgFromJointStack:
                        movq xmm0, [rbx]
                        mov rax, [rbx]                      ; rbx = joint arguments stack pointer
                        add rbx, 8

.processDouble:
                        mov r9, rax
                        shr r9, 52
                        and r9, 0x7FF                       ; r9 contains exponent of the num
                        cmp r9, 0x7FF
                        je special

                        cvttsd2si r9, xmm0                  ; r9 contains integer part of the xmm0
                        cvtsi2sd xmm1, r9                   ; xmm1 contains integer part of the xmm0


                        subsd xmm0, xmm1                    ; xmm0 contains fractional part

                        test r9, r9
                        jns .notNegative
                        andpd xmm0, [notSignMask]

.notNegative:

                        inc r13                             ; set %f mode printDec flag
                        jmp printDec
returnInPrintDouble:    xor r13, r13                        ; clean %f mode printDec flag

                        PUT_CHAR '.'

                        mov rax, 1000000
                        cvtsi2sd xmm1, rax

                        mulsd xmm0, xmm1

                        roundsd xmm0, xmm0, 0
                        cvttsd2si rax, xmm0                 ; rax contains fractional part of double
                                                            ; multiplied by 1000000


                        call printFractionalPart
                        jmp printDoubleEnd

special:
                        mov r9, rax
                        mov rcx, MANTIS_MASK
                        and r9, rcx                         ; r9 contains mantis of the num
                        test r9, r9
                        jnz .printNan

                        test rax, rax
                        jns .printInf
                        PUT_CHAR '-'

.printInf:
                        PUT_CHAR 'i'
                        PUT_CHAR 'n'
                        PUT_CHAR 'f'
                        jmp printDoubleEnd

.printNan:
                        PUT_CHAR 'n'
                        PUT_CHAR 'a'
                        PUT_CHAR 'n'

printDoubleEnd:
                        jmp nextFormatStringChar


;----------------------------------------------------------------------------------------------
; Places the character representation of the fractionalpart of double argument into the buffer.
;Entry:             rax    =  fractional part of double multiplied by 1000000
;                   rdi    =  pointer to the current free element in the buffer
;                   r11    =  buffer size counter
;Exit:
;Expected:
;Destroyed: rax, rcx, rdi, r9, r11
;----------------------------------------------------------------------------------------------
printFractionalPart:
                        mov r9, 10                          ; divider

                        mov rcx, 6                          ; rcx = number of characters after '.'
.nextNum:
                        xor rdx, rdx
                        div r9
                        push rdx                            ; push remainder

                        loop .nextNum

                        mov rcx, 6                          ; rcx = number of characters after '.'
.printNum:
                        pop rax                             ; pop remainder
                        add al, '0'                         ; to ASCII
                        PUT_CHAR al


                        loop .printNum
                        ret
