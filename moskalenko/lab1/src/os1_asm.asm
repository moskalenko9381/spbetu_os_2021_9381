DOSSEG                                      ; Задание сегментов под ДОС
.MODEL  SMALL                               ; Модель памяти-SMALL(Малая)
.STACK  100h
.DATA

Type_PC     db    'PC type: PC',0DH,0AH,'$'
Type_XT     db    'PC type: PC/XT',0DH,0AH,'$'
Type_AT     db    'PC type: AT',0DH,0AH,'$'
Type_PS30   db    'PC type: PS2 model 30',0DH,0AH,'$'
Type_PS50   db    'PS2 model 50 or 60',0DH,0AH,'$'
Type_PS80   db    'PS2 model 80',0DH,0AH,'$'
Type_PCjr   db    'PC type: PCjr',0DH,0AH,'$'
Type_PCCont db    'PC type: PC Сonvertible',0DH,0AH,'$'
Type_Unknown db    '   ', 0DH, 0AH, '$'

System_version db   'System version: ', '$'
Number_OEM     db   'OEM number:    ', 0DH, 0AH, '$'
Number_User    db   'User serial number:         ', 0DH, 0AH, '$'
Number_Version db   '  .  ', 0DH, 0AH, '$'

.CODE

START:
        JMP BEGIN

TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07

NEXT: add AL,30h
      ret
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC near
; байт AL переводится в два символа 16с.с. числа в AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ; в AL старшая цифра 
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
;перевод в 16 с.с. 16-ти разрядного числа
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

BYTE_TO_DEC PROC near
; перевод в 10с.с., SI - адрес поля младшей цифры
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10

loop_bd:
    div CX
    or DL,30h
    mov [SI],DL
    dec SI
    xor DX,DX
    cmp AX,10
    jae loop_bd
    cmp AL,00h
    je end_l
    or AL,30h
    mov [SI],AL

end_l:
    pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP


PRINT  PROC NEAR    ; вывод строки на экран
      push ax
      mov ah, 9h
      int 21H
      pop ax
      ret
PRINT ENDP

CHECK_PC PROC NEAR      ;проверка типа PC
      mov ax, 0F000h
      mov es, ax
      mov al, es:[0FFFEh] ;получаем байт

      cmp al, 0FFh
      je PC
      cmp al, 0FEh
      je XT
      cmp al, 0FBh
      je XT
      cmp al, 0FCh
      je AT
      cmp al, 0FAh
      je PS30
      cmp al, 0FCh
      je PS50
      cmp al, 0F8h
      je PS80
      cmp al, 0FDh
      je PCjr
      cmp al, 0F9h
      je PCCont
      jmp UNKNOWN

PC:
     lea dx, Type_PC
     jmp PRINT_STR

XT:
    lea dx, Type_XT
    jmp PRINT_STR

AT:
    lea dx, Type_AT
    jmp PRINT_STR

PS30:
    lea dx, Type_PS30
    jmp PRINT_STR

PS50:
    lea dx, Type_PS50
    jmp PRINT_STR
PS80:
    lea dx, Type_PS80
    jmp PRINT_STR

PCjr:
    lea dx, Type_PCjr
    jmp PRINT_STR

PCCont:
    lea dx, Type_PCCont
    jmp PRINT_STR

UNKNOWN:              ;неизвестный тип
    call BYTE_TO_HEX
    lea si, Type_Unknown
    mov [si], ax
    mov dx, si

PRINT_STR:
    call PRINT
    ret
CHECK_PC ENDP

BEGIN:
    push ax
    push dx
    push es
    push si
    mov  ax, @data       ; Загрузка в DS адреса начала
    mov  ds,ax           ; сегмента данных
    call CHECK_PC
    pop si
    pop es
    pop dx
    pop ax

    mov AH, 30H
    int 21h

    lea dx, System_version
    call PRINT

    lea si, Number_Version      ;  номер версии системы
    mov dl, ah
    inc si
    call BYTE_TO_DEC
    mov al, dl
    add si, 3             ; "перешагиваем" через точку
    call BYTE_TO_DEC
    lea dx, Number_Version
    call PRINT

    lea si, Number_OEM     ;номер OEM
    add si, 14
    mov al, bh
    call BYTE_TO_DEC
    lea dx, Number_OEM
    call PRINT

; номер пользователя
    mov	AX,CX
    lea di, Number_User
    add	di, 26
    call	WRD_TO_HEX

    mov al, bl
    call BYTE_TO_HEX
    sub di, 2
    mov [di], ax

    lea dx, Number_User
    call PRINT

    xor AL,AL
    mov AH,4Ch
    int 21H
END START
    END START ; конец модуля, START - точка входа
