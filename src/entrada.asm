; src/entrada.asm - Programa 2: lectura de teclado y eco con codigo ASCII en hexadecimal
; Ensamble (desde C:\): nasm -f bin src\entrada.asm -o bin\entrada.com

org 0x100

section .text
inicio:
    ; El programa muestra el mensaje que pide una letra.
    mov ah, 09h
    mov dx, prompt
    int 21h

    ; La funcion 07h lee un caracter sin eco y deja su codigo ASCII en AL.
    mov ah, 07h
    int 21h
    ; BL conserva el caracter leido, porque AL se reutiliza mas adelante.
    mov bl, al

    ; El programa muestra el texto de confirmacion.
    mov ah, 09h
    mov dx, msg_ok
    int 21h

    ; La funcion 02h muestra en pantalla el caracter guardado en DL.
    mov ah, 02h
    mov dl, bl
    int 21h

    ; El programa muestra el texto previo al codigo hexadecimal.
    mov ah, 09h
    mov dx, msg_cod
    int 21h

    ; El nibble alto del codigo se desplaza a la parte baja de AL y se imprime.
    mov al, bl
    shr al, 4
    call print_hex_nibble

    ; El nibble bajo del codigo se aisla con una mascara y se imprime.
    mov al, bl
    and al, 0Fh
    call print_hex_nibble

    ; El programa imprime un salto de linea y termina.
    mov ah, 09h
    mov dx, nl
    int 21h

    mov ax, 4C00h
    int 21h

; Subrutina: imprime el nibble contenido en AL como un digito hexadecimal.
print_hex_nibble:
    cmp al, 9
    jle .digito
    ; Para A-F se suma 7 y el caracter resultante cae entre 'A' y 'F'.
    add al, 7
.digito:
    ; Se suma 30h para convertir el valor a su caracter ASCII.
    add al, 30h
    mov ah, 02h
    mov dl, al
    int 21h
    ret

section .data
prompt  db "Ingrese una letra (se mostrara su codigo ASCII): $"
msg_ok  db 0Dh, 0Ah, "Caracter recibido: $"
msg_cod db 0Dh, 0Ah, "Codigo ASCII (hex): $"
nl      db 0Dh, 0Ah, "$"
