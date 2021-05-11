ASSUME cs:CODE, ds:DATA, ss:STACK

STACK SEGMENT stack
	dw 128 dup(?)
STACK ends

DATA SEGMENT
	ovl1 db "seg1.ovl", 0
	ovl2 db "seg2.ovl", 0
	program dw 0
	memoryDTA db 43 dup(0)
	memoryFlag db 0
	posCL db 128 dup(0)
	addrOVL dd 0
	pspKeep dw 0

	EOF db 0dh, 0ah, '$'
	McbCrashError db 'ERROR: mcb crashed', 0dh, 0ah, '$'
	NoMemoryError db 'ERROR: not enough memory for this function', 0dh, 0ah, '$'
	AddressError db 'ERROR: invalid memory address', 0dh, 0ah, '$'
	NoFunctionError db 'ERROR: unexistable function', 0dh, 0ah, '$'
	NotFoundFileError db 'LOAD ERROR: file not found', 0dh, 0ah, '$'

	RouteError db 'LOAD ERROR: route not found', 0dh, 0ah, '$'
	ManyFilesError db 'ERROR: too many files were opened', 0dh, 0ah, '$'
	NoAccessError db 'ERROR: no access', 0dh, 0ah, '$'
	NotEnoughMemoryError db 'ERROR: not enough memory', 0dh, 0ah, '$'
	EnvError db 'ERROR: wrong string of environment ', 0dh, 0ah, '$'
	str_all_file_error db  'ALLOCATION MEMOTY ERROR: file not found' , 0dh, 0ah, '$'
	str_all_route_error db  'ALLOCATION MEMOTY ERROR: route not found' , 0dh, 0ah, '$'

	InfoFreeMemory db 'Memory was freed successfully!' , 0dh, 0ah, '$'
	InfoLoaded db  'Loaded successfully!', 0dh, 0ah, '$'
	InfoAllocatedSuccess db  'Allocation of memory was successfully!', 0dh, 0ah, '$'
	dataEnd db 0
DATA ends

CODE segment

PRINT proc
 	push ax
 	mov ah, 09h
 	int 21h
 	pop ax
 	ret
PRINT endp

FREE_MEMORY proc
	push ax
	push bx
	push cx
	push dx

	lea ax, dataEnd
	lea bx, EXIT
	add bx, ax

	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h

	jnc FreeMemoryEnd
	mov memoryFlag, 1

CrashMCB:
	cmp ax, 7
	jne NoMemory
	lea dx, McbCrashError
	call PRINT
	jmp EndFreeMemory

NoMemory:
	cmp ax, 8
	jne CheckAddress
  lea dx, NoMemoryError
	call PRINT
	jmp EndFreeMemory

CheckAddress:
	cmp ax, 9
  lea dx, AddressError
	call PRINT
	jmp EndFreeMemory

FreeMemoryEnd:
	mov memoryFlag, 1
  lea dx, InfoFreeMemory
	call PRINT

EndFreeMemory:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEMORY endp

load_proc proc
	push ax
	push bx
	push cx
	push dx
	push ds
	push es

	mov ax, data
	mov es, ax
	lea bx, addrOVL
	lea dx, posCL
	mov ax, 4b03h
	int 21h

	jnc LoadSuccess

WrongFunction:
	cmp ax, 1
	jne FileNotFound
	lea dx, EOF
	call PRINT
	lea dx, NoFunctionError
	call PRINT
	jmp LoadErrorExit

FileNotFound:
	cmp ax, 2
	jne RouteNotFound
	lea dx, NotFoundFileError
	call PRINT
	jmp LoadErrorExit

RouteNotFound:
	cmp ax, 3
	jne ManyFiles
  lea dx, EOF
	call PRINT
	lea dx, RouteError
	call PRINT
	jmp LoadErrorExit

ManyFiles:
	cmp ax, 4
	jne NoAccess
	lea dx, ManyFilesError
	call PRINT
	jmp LoadErrorExit

NoAccess:
	cmp ax, 5
	jne LittleMemory
	lea dx, NoAccessError
	call PRINT
	jmp LoadErrorExit

LittleMemory:
	cmp ax, 8
	jne WrongEnv
	lea dx, NotEnoughMemoryError
	call PRINT
	jmp LoadErrorExit

WrongEnv:
	cmp ax, 10
	lea dx, EnvError
	call PRINT
	jmp LoadErrorExit

LoadSuccess:
	lea dx, InfoLoaded
	call PRINT

	mov ax, word ptr addrOVL
	mov es, ax
	mov word ptr addrOVL, 0
	mov word ptr addrOVL + 2, ax

	call addrOVL
	mov es, ax
	mov ah, 49h
	int 21h

LoadErrorExit:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret
load_proc endp

Route proc
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	mov program, dx

	mov ax, pspKeep
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0

FindROUTE:
	inc bx
	cmp byte ptr es:[bx - 1], 0
	jne FindROUTE

	cmp byte ptr es:[bx + 1], 0
	jne FindROUTE

	add bx, 2
	mov di, 0

RouteLOOP:
	mov dl, es:[bx]
	mov byte ptr [posCL+di], dl
	inc di
	inc bx
	cmp dl, 0
	je EndRouteLOOP
	cmp dl, '\'
	jne RouteLOOP
	mov cx, di
	jmp RouteLOOP

EndRouteLOOP:
	mov di, cx
	mov si, program

EndFN:
	mov dl, byte ptr [si]
	mov byte ptr [posCL + di], dl
	inc di
	inc si
	cmp dl, 0
	jne EndFN

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
Route endp

AllocationMemory proc
	push ax
	push bx
	push cx
	push dx

	push dx
	lea dx, memoryDTA
	mov ah, 1ah
	int 21h
	pop dx
	mov cx, 0
	mov ah, 4eh
	int 21h

	jnc AllocatedCuccess

LoadErrorFiles:
	cmp ax, 2
	je AllocateRouteError
	lea dx, str_all_file_error
	call PRINT
	jmp AllocateEnd

AllocateRouteError:
	cmp ax, 3
	lea dx, str_all_route_error
	call PRINT
	jmp AllocateEnd

AllocatedCuccess:
	push di
	mov di, offset memoryDTA
	mov bx, [di + 1ah]
	mov ax, [di + 1ch]
	pop di
	push cx
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	pop cx
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	mov word ptr addrOVL, ax
	lea dx, InfoAllocatedSuccess
	call PRINT

AllocateEnd:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
AllocationMemory endp

LoadOVL proc
	push dx
	call Route
	lea dx, posCL
	call AllocationMemory
	call load_proc
	pop dx
	ret
LoadOVL endp

BEGIN proc far
	push ds
	xor ax, ax
	push ax
	mov ax, data
	mov ds, ax
	mov pspKeep, es
	call FREE_MEMORY
	cmp memoryFlag, 0
	je QUIT

	lea dx, ovl1
	call LoadOVL
	lea dx, EOF
	call PRINT
	lea dx, ovl2
	call LoadOVL

QUIT:
	xor al, al
	mov ah, 4ch
	int 21h

BEGIN endp

EXIT:
CODE ends
end BEGIN
