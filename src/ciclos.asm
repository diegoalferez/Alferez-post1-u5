; src/ciclos.asm - Programa 3: medicion del tiempo real de un bucle de trabajo fijo
; Ensamble (desde C:\): nasm -f bin src\ciclos.asm -o bin\ciclos.com
; El numero de iteraciones es constante en el codigo; el tiempo real que tarda
; depende del valor "cycles" configurado en dosbox.conf.

org 0x100

section .text
inicio:
    mov ah, 09h
    mov dx, msg_inicio
    int 21h

    ; La funcion 2Ch de INT 21h devuelve CH=horas, CL=minutos, DH=segundos, DL=centesimas.
    ; El programa guarda la hora inicial en los cuatro bytes de t1.
    mov ah, 2Ch
    int 21h
    mov [t1], ch
    mov [t1+1], cl
    mov [t1+2], dh
    mov [t1+3], dl

    ; Bucle de trabajo fijo: 300 repeticiones externas x 65535 internas.
    ; Si el bucle dura muy poco o demasiado en el equipo, se ajusta el valor de CX externo.
    mov cx, 300
trabajo_ext:
    push cx
    mov cx, 0FFFFh
trabajo_int:
    inc ax                  ; operacion aritmetica trivial, sin efecto util
    loop trabajo_int
    pop cx
    loop trabajo_ext

    ; El programa guarda la hora final en los cuatro bytes de t2.
    mov ah, 2Ch
    int 21h
    mov [t2], ch
    mov [t2+1], cl
    mov [t2+2], dh
    mov [t2+3], dl

    ; El programa imprime la hora inicial.
    mov ah, 09h
    mov dx, msg_t1
    int 21h
    mov si, t1
    call print_tiempo

    ; El programa imprime la hora final.
    mov ah, 09h
    mov dx, msg_t2
    int 21h
    mov si, t2
    call print_tiempo

    mov ah, 09h
    mov dx, msg_fin
    int 21h

    mov ax, 4C00h
    int 21h

; Subrutina: imprime hh:mm:ss:cc a partir de los 4 bytes apuntados por SI.
print_tiempo:
    mov al, [si]
    call print_dec2
    mov ah, 09h
    mov dx, sep
    int 21h
    mov al, [si+1]
    call print_dec2
    mov ah, 09h
    mov dx, sep
    int 21h
    mov al, [si+2]
    call print_dec2
    mov ah, 09h
    mov dx, sep
    int 21h
    mov al, [si+3]
    call print_dec2
    ret

; Subrutina: imprime AL (0-99) como dos digitos decimales usando AAM.
print_dec2:
    aam                     ; AH = AL / 10 (decena), AL = AL % 10 (unidad)
    xchg ah, al             ; AL = decena, AH = unidad
    push ax
    add al, 30h
    mov dl, al
    mov ah, 02h
    int 21h
    pop ax
    mov al, ah
    add al, 30h
    mov dl, al
    mov ah, 02h
    int 21h
    ret

section .data
msg_inicio db "Midiendo bucle de trabajo fijo.", 0Dh, 0Ah, "$"
msg_t1     db "Hora inicial (hh:mm:ss:cc): $"
msg_t2     db 0Dh, 0Ah, "Hora final (hh:mm:ss:cc): $"
msg_fin    db 0Dh, 0Ah, "Medicion completa. Compare el campo cc (centesimas).", 0Dh, 0Ah, "$"
sep        db ":$"
t1         db 0, 0, 0, 0
t2         db 0, 0, 0, 0
