TESTPC SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H
START:
        JMP BEGIN

UNAVAILABLE_ADDRESS db  'Address of unavailable memory:    ',0DH, 0AH, '$'
ENVIROMENT_ADDRESS  db  'Address of the environment:      ',0DH, 0AH, '$'
TAIL_MESSAGE        db  'Command line tail: ','$'
NO_TAIL             db  'No arguments',0DH, 0AH, '$'
ENVIRONMENT_MESSAGE db  'Content of environment: ',0DH, 0AH,'$'
PATH_MESSAGE        db  'Path of the module: ','$'
PATH_MODULE         db   83 DUP(0DH,'$')
TAIL                db   83 DUP(0DH, 0AH,'$')
ENVIRONMENT_CONTENT db   128 DUP('$')

TETR_TO_HEX PROC near
      and AL,0Fh
      cmp AL,09
      jbe NEXT
      add AL,07
NEXT: add AL,30h
      ret
      TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
      ; байт AL переводится в два символа 16с.с. числа в AX
            push CX
            mov AH,AL
            call TETR_TO_HEX
            xchg AL,AH
            mov CL,4
            shr AL,CL
            call TETR_TO_HEX 
            pop CX 
            ret
        BYTE_TO_HEX ENDP

        WRD_TO_HEX PROC near
        ;   в AX - число, DI - адрес последнего символа
            push BX
            mov BH,AH
            call BYTE_TO_HEX
            mov [DI],AH
            dec DI
            mov [DI],AL
            dec DI
            mov AL,BH
            call BYTE_TO_HEX
            mov [DI],AH
            dec DI
            mov [DI],AL
            pop BX
            ret
        WRD_TO_HEX ENDP

        PRINT  PROC NEAR    ; вывод строки на экран
              push ax
              mov ah, 9h
              int 21h
              pop ax
              ret
        PRINT ENDP

BEGIN:
  mov ax, ds:[2h]
  lea di, UNAVAILABLE_ADDRESS
  add di, 34
	call WRD_TO_HEX
	lea dx, UNAVAILABLE_ADDRESS
	call PRINT

  mov ax, ds:[2Ch]
  lea di, ENVIROMENT_ADDRESS
  add di, 32
	call WRD_TO_HEX
	lea dx,  ENVIROMENT_ADDRESS
	call PRINT

  lea dx, TAIL_MESSAGE
  call PRINT
  mov cl, ds:[80h]
  cmp cl, 0
  je EMPTY
  mov si, 0
  lea bx, TAIL

WRITE_TAIL:
     mov dl, ds:[81h+si]
     mov [bx+si], dl
     inc si
     loop WRITE_TAIL
     lea dx, TAIL
     call PRINT
     jmp ENVIRONMENT

EMPTY:
    lea dx, NO_TAIL
    call PRINT

ENVIRONMENT:
    lea dx, ENVIRONMENT_MESSAGE
    call PRINT
    lea di, ENVIRONMENT_CONTENT
    mov		ax, ds:[2Ch]
    mov		ds, ax
    mov si, 0

READ:
    lodsb
    cmp 	al, 0
    jne 	END_

END_LINE:
    mov al, 0Ah
    stosb
    lodsb
    cmp 	al, 0h
    jne END_
    mov byte ptr [di], 0Dh
    mov byte ptr [di+1], '$'
    mov bx, ds
    mov ax, es
    mov ds, ax
    lea dx, ENVIRONMENT_CONTENT
    call PRINT
    jmp READING_PATH

END_:
    stosb
    jmp READ

READING_PATH:
     lea dx, PATH_MESSAGE
     call PRINT
     add si, 2
     mov  ds, ds:[2Ch]
     lea di, PATH_MODULE
CYCLE_PATH:
     lodsb
     cmp  al, 0
     je  END_CYCLE
     stosb
     jmp     CYCLE_PATH
 END_CYCLE:
     mov  bx, ds
     mov  ax, es
     mov  ds, ax
     lea dx, PATH_MODULE
     call PRINT

  xor al, al
	mov AH, 4Ch
	int 21h
  TESTPC ENDS
      END START
