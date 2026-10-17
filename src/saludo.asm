; src/saludo.asm - Programa 1: salida de texto en DOS con INT 21h
; Ensamble (desde C:\): nasm -f bin src\saludo.asm -o bin\saludo.com
; Formato .COM: un solo segmento, el programa inicia en CS:0100h.

org 0x100

section .text
inicio:
    ; El programa carga en AH la funcion 09h (imprimir cadena terminada en "$").
    mov ah, 09h
    ; DX recibe el desplazamiento donde inicia la cadena.
    mov dx, nombre
    ; El sistema operativo DOS imprime la cadena.
    int 21h

    ; El programa termina con la funcion 4Ch (AL = 00h es el codigo de salida).
    mov ax, 4C00h
    int 21h

section .data
nombre db "Laboratorio 5 - DOSBox y Ensamblador", 0Dh, 0Ah
       db "Estudiante: Diego Alferez", 0Dh, 0Ah
       db "Unidad 5 - Arquitectura de Computadores", 0Dh, 0Ah, "$"
