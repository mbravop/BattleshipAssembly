;PROYECTO PRIMER PARCIAL - ORGANIZACION DE COMPUTADORES
;MAURICIO BRAVO - DERECK SANTANDER
;2023 - 1

.model small
.data
;MENSAJES PARA ENTRAR AL JUEGO
msgProyecto db '                        Proyecto Battleship $'
msgAutores db '                  Mauricio Bravo - Dereck Santander $'
msgEnter db 'Presione la tecla ENTER para empezar $'
msgConf db 'Has presionado ENTER $'
msgError db 'No has presionado ENTER $'
msgOtraVez db 'Nuevamente $'

;MENSAJES PARA TERMINAR EL JUEGO
msgIntentos db 'Te has quedado sin intentos $'
msgGanador db 'Has derribado todos los barcos. Felicidades $'
msgFinal db 'Te faltaron estos barcos (x) $'

;SALTO DE LINEA
msgSaltoLinea db '',10,13,'$' 

;MENSAJE JUEGO TERMINADO
msgFin db 'Desea jugar otra vez? S/N $'

;ELEMENTOS MATRICES
msgColumnas db '   A   B   C   D   E   F   G$'
celdaAbrir db '[$'
celdaCerrar db '] $'
msgDobleSaltoLinea db '',10,10,13,'$'
    
numeroFilas dw 7
numeroColumnas dw 7
    
contadorColumna db 30h                                          
    
valorCelda db ?

;MATRIZ COMPUTADORA
matrixPC db 7 dup('0','0','0','0','0','0','0')
cantidadSubmarino db 1
cantidadCrucero db 1
cantidadPortaviones db 1

;ALEATORIEDAD
valorRandom dw 6h

filaRandom db ?
columnaRandom db ?

orientacion dw ?  ;0 para horizontal, 1 para vertical
         
;MATRIZ USUARIO
matrixUser db 7 dup(' ',' ',' ',' ',' ',' ',' ')

;MENSAJES MISILES
msgMisil db 'Misil $'
msgPedir db ', ingrese la celda a atacar: $'
msgPuntos db '......$'
msgNoImpacto db 'Sin impacto $'
msgImpacto db 'Impacto confirmado $'
msgErrorCelda db '......Celda erronea',10,13,'$'

msgSubmarino db ';submarino hundido.$'
msgCrucero db ';crucero hundido.$'
msgPortaviones db ';portaviones hundido.$'


;COORDENADAS USUARIO
usuarioX db ?
usuarioY db ?

;COMPARACION COORDENADAS
coordenadaBuscada dw ?
barcoAtacado db ?

;TRACKING DE BARCOS
contadorSubmarino db 3
contadorCrucero db 4
contadorPortaviones db 5

;CONDICIONES TERMINAR JUEGO
intentosUsuario db 1
todosBarcos db 0
finalMostrado db 0



.code
.start

call Principal           ;Se llama al programa principal que ejecutara el juego.

principal proc              ;Muestra informacion del proyecto y autores.
    mov ah, 09h
    lea dx, msgProyecto
    int 21h
    mov ah, 09h
    lea dx, msgDobleSaltoLinea
    int 21h
    mov ah, 09h
    lea dx, msgAutores
    int 21h
    mov ah, 09h
    lea dx, msgDobleSaltoLinea
    int 21h
    call inicioJuego           ;Inicia la partida
    call juegoTerminado        ;Terminacion de la partida
principal endp


inicioJuego proc                   ;Este procedimiento se encarga que cada que se inicie el juego, volver a los valores originales
                                   ;las variables de control.
    mov contadorSubmarino, 3       ;Num de partes de las que se compone cada barco
    mov contadorCrucero, 4
    mov contadorPortaviones, 5
    mov cantidadPortaviones, 1     ;Cantidad de barcos que hay por tipo
    mov cantidadCrucero, 1
    mov cantidadSubmarino, 1
    mov intentosUsuario, 1         ;Los intentos de usuario empiezan en 1.
    mov finalMostrado, 0           ;Reinicio el estado de si se ha mostrado el final
    
    mov ah, 09h
    lea dx, msgEnter
    int 21h
    mov ah, 01h
    int 21h
    cmp al, 05                     ;Valida si se ha usado la combinacion de escape (ctrl + E)
    jz salir
    cmp al, 0Dh                    ;Valida si la tecla ingresada es el ENTER.
    jnz noPresiono
    je siPresiono
    ret
inicioJuego endp

;PARTE ALEATORIA
obtenerOrientacion:       ;Etiqueta que se encarga de obtener la orientacion del barco a colocar en la matrixPC.
    mov ah, 2Ch           ;Obtiene system time
    int 21h
    mov ax, dx
    mov ah, 00h           ;Se trabaja solo con la aprte de milisegundos.
    mov cx, 02h           ;Verifico si es valor par o impar.
    div cl
    mov bx, 0
    mov bl, ah
    mov orientacion, bx   ;Se guarda el modulo de la division (0 = Horizontal, 1=Vertical)
    cmp cantidadPortaviones, 0   ;Se revisa que barco ya ha sido colocado para colocar los siguientes.
    jg colocarPortaviones
    cmp cantidadCrucero, 0
    jg colocarCruceros
    cmp cantidadSubmarino, 0
    jg colocarSubmarinos
    ret

colocarPortaviones:                ;Etiqueta que se encarga de colocar al portaviones en la matrixPC. Representandolo con '5's en la matriz.
    dec cantidadPortaviones        ;Disminuye en 1 la cantidad de portaviones por colocar.
    cmp orientacion, 0
    jz colocarPortavionesHorizontal  ;Se revisa si hay que colocar vertical u horizontal.
    jnz colocarPortavionesVertical
    jmp obtenerOrientacion
   
colocarPortavionesHorizontal:      ;Etiqueta que coloca el portaviones si es horizontal.
    ;Obtener fila random
    mov valorRandom, 07h           ;Si el portaviones es horizontal se puede colocar en todas las filas.
    call aleatorizar
    mov filaRandom, dl
    ;Obtener columna random
    mov valorRandom, 03h           ;Pero la primera pieza solo puede ser colocada hasta la columna 3, sino no entra.
    call aleatorizar
    mov columnaRandom, dl
    ;Acceder a coordenadas
    mov ah, 00h
    mov al, filaRandom
    mov bh, 7                      ;Para acceder a la coordenada se multiplica la fila x 7 y se suma la columna.
    mul bh
    add al, columnaRandom
    mov si, offset matrixPC        ;Se guarda la direccion de memoria para reemplazar en matrixPC.
    add si, ax
    mov cx, 5
    ponerPAH:                      ;Repite el loop por cada pieza del barco.
        mov byte ptr [si],'5'      ;Se coloca un 5 en cada espacio representando el portaviones.
        inc si                     ;La direccion de memoria aumenta en 1 ya que se coloca de manera continua (es horizontal).
        loop ponerPAH
    jmp obtenerOrientacion
    
colocarPortavionesVertical:        ;Similar al proceso anterior de colocar portaviones horizontal.
    ;Obtener fila random
    mov valorRandom, 03h           ;Solo puede ocupar hasta la 3era fila.
    call aleatorizar
    mov filaRandom, dl
    ;Obtener columna random
    mov valorRandom, 07h           ;En cualquier columna 
    call aleatorizar
    mov columnaRandom, dl
    ;Acceder a coordenadas
    mov ah, 00h
    mov al, filaRandom
    mov bh, 7
    mul bh
    add al, columnaRandom
    mov si, offset matrixPC
    add si, ax
    mov cx, 5
    ponerPAV:
        mov byte ptr [si],'5'
        add si, 7                  ;En este caso aumenta en 7 ya que es por cada fila.
        loop ponerPAV
    jmp obtenerOrientacion
    
colocarCruceros:                   ;Etiqueta que coloca al crucero en la matrixPC,  
    dec cantidadCrucero            ;Disminye en 1 la cantidad de este barco, ya que se va a colocar.
    cmp orientacion, 0
    jz colocarCruceroHorizontal    ;Verifica si se coloca vertical u horizontal.
    jnz colocarCruceroVertical
    

colocarCruceroHorizontal:          ;Se coloca el crucero de manera horizontal en la matriz. Representando con '4's en la matriz.
    ;Obtener fila random
    mov valorRandom, 07h           ;Puede ser colocado en cualquier fila.
    call aleatorizar
    mov filaRandom, dl
    ;Obtener columna random
    mov valorRandom, 04h           ;Solo hasta la 4ta columna
    call aleatorizar
    mov columnaRandom, dl
    ;Acceder a coordenadas
    mov ah, 00h
    mov al, filaRandom
    mov bh, 7
    mul bh
    add al, columnaRandom
    mov si, offset matrixPC
    add si, ax
    mov cx, 4
    ponerCruH:
         mov al, byte ptr [si]
         mov bl, '5'
         cmp al, bl                 ;Se revisa si en ese espacio no hay una pieza de portaviones.
         jz empezarLimpiezaCruceros ;Si es que hay se llama a limpieza de cruceros.
         mov byte ptr [si],'4'      ;Coloca '4's en los espacios.
         inc si                     ;Aumenta en 1 porque se colocan continuamente.
         loop ponerCruH
    jmp obtenerOrientacion
    
colocarCruceroVertical:             ;Coloca al crucero de manera vertical, colocando '4's en los espacios de la matrixPC.
    ;Obtener fila random
    mov valorRandom, 04h            ;Solo hasta la 4ta fila.
    call aleatorizar
    mov filaRandom, dl
    ;Obtener columna random
    mov valorRandom, 07h            ;Todas las columnas.
    call aleatorizar
    mov columnaRandom, dl
    ;Acceder a coordenadas
    mov ah, 00h
    mov al, filaRandom
    mov bh, 7
    mul bh
    add al, columnaRandom
    mov si, offset matrixPC
    add si, ax
    mov cx, 4
    ponerCruV:
         mov al, byte ptr [si]
         mov bl, '5'                ;Se revisa si no hay pieza de portaviones colocada previamente.
         cmp al, bl
         jz empezarLimpiezaCruceros ;Si la hay, se limpian los cruceros.
         mov byte ptr [si],'4'
         add si,7                   ;Aumenta en 7 porque se coloca 1 pieza por cada fila.
         loop ponerCruV
    jmp obtenerOrientacion
    
empezarLimpiezaCruceros:            ;Etiqueta que coloca en cx 49 para procesar toda la matriz. 
    mov cx, 49
    mov si, offset matrixPC
    jmp limpiarCruceros

limpiarCruceros:                    ;Etiqueta que recorre la matriz, y donde encuentre un '4' se lo reemplaza.
    mov al, byte ptr [si]
    mov bl, '4'
    cmp al, bl
    je reemplazarCruceros
    seguirlimpiezaCruceros:
        inc si
        loop limpiarCruceros
        mov cantidadCrucero, 1      ;Al terminar el proceso, como no se pudo colocar el crucero, la cantidad vuelve a 1.
    jmp obtenerOrientacion
       

colocarSubmarinos:                  ;Etiqueta que se encarga de colocar submarino segun orientacion.
    dec cantidadSubmarino
    cmp orientacion, 0
    jz colocarSubmarinoHorizontal
    jnz colocarSubmarinoVertical
    

colocarSubmarinoHorizontal:         ;Etiqueta que coloca al submarino de manera horizontal con '3's en la matrixPC.
    ;Obtener fila random
    mov valorRandom, 07h            ;Puede estar en cualquier fila.
    call aleatorizar
    mov filaRandom, dl
    ;Obtener columna random
    mov valorRandom, 05h            ;Hasta la 5ta columna.
    call aleatorizar
    mov columnaRandom, dl
    ;Acceder a coordenadas
    mov ah, 00h
    mov al, filaRandom
    mov bh, 7
    mul bh
    add al, columnaRandom
    mov si, offset matrixPC
    add si, ax
    mov cx, 3
    ponerSubH:
         mov al, byte ptr [si]
         mov bl, '3'
         cmp al, bl                    ;Se revisa que no haya cruceros ('4') o portaviones ('5')
         jg empezarLimpiezaSubmarinos  ;Si se encuentra otro barco, se debe limpiar las piezas del submarino ya colocadas.
         mov byte ptr [si],'3'
         inc si                        ;Aumenta en 1 porque se coloca continuamente.
         loop ponerSubH
    jmp obtenerOrientacion
                                       
colocarSubmarinoVertical:              ;Coloca al submarino vertical, colocando '3's en la matrixPC.
    ;Obtener fila random
    mov valorRandom, 05h               ;Solo pueden ser colocados hasta la 5ta fila.
    call aleatorizar
    mov filaRandom, dl
    ;Obtener columna random            
    mov valorRandom, 07h               ;En cualquier columna
    call aleatorizar
    mov columnaRandom, dl
    ;Acceder a coordenadas
    mov ah, 00h
    mov al, filaRandom
    mov bh, 7
    mul bh
    add al, columnaRandom
    mov si, offset matrixPC
    add si, ax
    mov cx, 3
    ponerSubV:
         mov al, byte ptr [si]
         mov bl, '3'
         cmp al, bl
         jg empezarLimpiezaSubmarinos    ;Revisa que no haya otra pieza de barco, si la hay se deben retirar las piezas de submarino ya colocadas.
         mov byte ptr [si],'3'
         add si,7                        ;Aumenta en 7 porque es una pieza por fila.
         loop ponerSubV
    jmp obtenerOrientacion
    
empezarLimpiezaSubmarinos:               ;Etiqueta que coloca el 49 como contador para procesar toda la matriz y poder limpiar las piezas de submarino colocadas.
    mov cx, 49
    mov si, offset matrixPC
    jmp limpiarSubmarinos

limpiarSubmarinos:                       ;Etiqueta que se encarga de recorrer la matriz completa en busca de submarinos ('3') para quitarlos.
    mov al, byte ptr [si]
    mov bl, '3'                          ;Si se encuentra un submarino, este es reemplazado.
    cmp al, bl
    jz reemplazarSubmarinos
    seguirLimpiezaSubmarinos:
        inc si
        loop limpiarSubmarinos
    mov cantidadSubmarino, 1
    jmp obtenerOrientacion

reemplazarCruceros:                     ;Reemplaza el '4' por un '0' en la matrixPC.
    mov byte ptr [si], '0'
    jmp seguirLimpiezaCruceros
    
    
reemplazarSubmarinos:                   ;Reemplaza el '3' por un '0' en la matrixPC.
    mov byte ptr [si], '0'
    jmp seguirLimpiezaSubmarinos      
   
aleatorizar:                            ;Proceso que obtiene un valor random definido en un rango desde 0 hasta valorRandom.
    mov ah, 2Ch
    int 21h
    mov ax, dx
    mov ah, 00h
    mov cx, valorRandom
    div cl                              ;Se realiza la division para obtener el modulo, este valor estara dentro de [0, valorRandom)
    mov dl, ah
    ret

matrizVacia:                            ;Se encarga de colocar ' ' en cada elemento de la matriz del usuario.
    mov si, offset MatrixUser
    mov cx, 49
    limpiarTodo:
        mov byte ptr [si], ' '
        inc si
    loop limpiarTodo
    ret
    
matrizVaciaPC:                          ;Se encarga de colocar '0's en cada elemento de la matrixPC.
    mov si, offset MatrixPC
    mov cx, 49
    limpiarTodoPC:
        mov byte ptr [si], '0'
        inc si
    loop limpiarTodoPC
    ret
    
imprimirSaltoLinea:                   ;Etiqueta para imprimir un salto de linea.
    mov ah,09h
    lea dx, msgSaltoLinea
    int 21h
    ret
    
siPresiono:                       ;Etiqueta que continua el proceso despues que el usuario haya presionado ENTER.
    call matrizVaciaPC            
    call obtenerOrientacion       ;Poner matriz PC con barcos aleatorios
    call matrizVacia              ;pone vacia la matriz del usuario 
    jmp limpiarPantalla

noPresiono:                       ;Etiqueta que pide nuevamente el ENTER del usuario para iniciar el juego.
    call imprimirSaltoLinea
    mov ah, 09h
    lea dx, msgError
    int 21h
    call imprimirSaltoLinea 
    jmp inicioJuego

limpiarPantalla:                  ;Etiqueta que hace un 'clear screen' para presentar la matrixUser.
    mov ax, 0
    mov bx,0
    mov dx,0
    mov al, 3
    int 10h
    mov ah, 2
    mov dl, 0
    mov bh, 0
    int 10h
    mov contadorColumna, 30h
    jmp MostrarMatriz
                                
mostrarMatriz:                  ;Etiqueta que se encarga de mostrar cada elemento de la matrixUser.
    mov ax, @data
    mov ds, ax

    lea si, matrixUser ; Cargar direccion base de la matriz

    mov bx, 0 ; Inicializar contador de fila 
    mov ah, 09h
    lea dx, msgColumnas ;Lo primero es colocar las etiquetas de las columnas.
    int 21h

    recorrerFila:
        inc contadorColumna
        mov di, 0 ; Inicializar contador de columna
        mov ah, 09h
        lea dx, msgDobleSaltoLinea  ;Un doble salto de linea para darle mayor espaciado a cada fila.
        int 21h
        mov ah, 02h
        mov dl, contadorColumna
        int 21h
            
        mov ah, 02h
        mov dl, 0h
        int 21h
        recorrerColumna:
            
            mov al, [si] ; Cargar elemento de la matriz
            mov valorCelda, al
            
            mov ah, 09h
            lea dx, celdaAbrir ;Imprime un [.
            int 21h
            
            mov dx, 0
            mov dl, valorCelda ; Mover el numero al registro DL
            mov ah, 02h
            int 21h
            
            mov ah, 09h
            lea dx, celdaCerrar ;Imprime un ].                           
            int 21h

            inc si ; Avanzar al siguiente elemento de la matriz
            inc di ; Incrementar contador de columna

            cmp di, numeroColumnas ; Comparar con numero de columnas
            jl recorrerColumna ; Saltar si es menor
            

        inc bx ; Incrementar contador de fila

        cmp bx, numeroFilas ; Comparar con numero de filas
        jl recorrerFila ; Saltar si es menor
        
        
    mov ah,09h
    lea dx, msgDobleSaltoLinea ;Mayor espaciado para pedir lanzamiento de misil.
    int 21h
    jmp mostrarMisil


mostrarMisil:   ;Etiqueta que valida si se ha terminado el juego, y pide al usuario una coordenada para lanzar misil.
    mov ax, 0
    add al, contadorSubmarino
    add al, contadorCrucero
    add al, contadorPortaviones
    cmp al, 0     ;Si ya no queda ni un barco es porque el jugador gano.             
    je ganador
    cmp finalMostrado,1
    je ultimoMensaje
    cmp intentosUsuario, 16h  ; Se coloca el numero de intentos +1 que el usuario tiene (22 = 16h).
    je noMasIntentos
    mov ah, 09h
    lea dx, msgMisil
    int 21h
    call colocarMisiles
    mov ah, 09h
    lea dx, msgPedir
    int 21h
    mov ah, 01h
    int 21h
    cmp al, 05                ;Se verifica la combinacion de escape en la posicion de columna.
    jz salir
    call convertirLetraColumna
    mov ah, 01h
    int 21h
    cmp al, 05                ;Se verifica la combinacion de escape en la posicion de fila.
    jz salir
    mov usuarioX, al
    sub usuarioX, 31h         ;Se resta 31h = '0', para verificar si es un numero valido.
    cmp usuarioX, 0h
    jl  msgCeldaErronea
    cmp usuarioX,7h 
    jge  msgCeldaErronea
    inc intentosUsuario  ;Una vez se coloca una coordenada valida, aumenta en 1 los intentos.
    call modificarMatriz
    jmp limpiarPantalla
    
colocarMisiles:    ;Etiqueta que coloca el numero de misiles = intentos del usuario.
    mov ax, 0
    mov cx, 0
    mov al, intentosUsuario
    call convertirMisilesDecimal
    ret

convertirMisilesDecimal:   ;Etiqueta que permite convertir de hex a decimal el numero de misil actual.
    mov bl, 10
    div bl
    mov dh, ah
    mov dl, al
    mov ah, 00h
    mov al, dh
    push ax
    mov ax, 000h
    mov al, dl
    add cx, 1
    cmp dl, 0
    jnz convertirMisilesDecimal
    mov ah, 02h
    mov dl, 0h
    int 21h
    jz  mostrarNumMisiles
    ret

mostrarNumMisiles:     ;Se muestra el numero de misil actual.
    sub cx, 1
    pop ax
    mov ah, 02h
    mov dl, al
    add dl, 30h
    int 21h
    cmp cx, 0
    jnz mostrarNumMisiles
    ret                  
      
convertirLetraColumna:     ;Permite la conversion de letra a un numero para ser identificado como coordenada en la matriz.
    mov usuarioY,al 
    sub usuarioY, 32       ;Se resta 32 para pasar letra minuscula a mayuscula.
    cmp usuarioY, 41h      ;Se compara si el codigo ascii de usuarioY corresponde a una mayuscula ya que seria mayor que 'A'.
    jl  case_minus         ;si lo que se ingreso inicialmente fue una mayuscula, se realiza el proceso.
    sub usuarioY,65        ;Se resta con 65 = 41h = 'A' para saber a que columna corresponde.
    cmp usuarioY,0h
    jl  msgCeldaErronea    ;Si la diferencia es menor que 0, se ha ingresado otro caracter.
    cmp usuarioY,7h
    jge  msgCeldaErronea   ;Si es mayor que 7 se ha ingresado una letra mayor o igual que 'H'.
    ret
    
case_minus:                ;Etiqueta que reconvierte la letra mayuscula ingresada a su valor original 
    add usuarioY, 32
    sub usuarioY,65        ;Se repite el proceso de verificacion del rango de la etiqueta convertirLetraColumna.
    cmp usuarioY, 0h
    jl msgCeldaErronea
    cmp usuarioY, 7h
    jge msgCeldaErronea
    ret
    
msgCeldaErronea:           ;Si hay una coordenada no valida, se muestra un mensaje de error.
    mov ah,09h
    lea dx, msgErrorCelda
    int 21h
    jmp mostrarMisil
        
modificarMatriz:          ;Se busca acceder a la coordenada ingresada por el usuario y mostrar el status de ataque.
    mov ah, 00h
    mov al, usuarioX      
    mov bh, 7             ;Se accede a la coordenada con la operacion (fila * 7) + columna.
    mul bh
    add al, usuarioY
    mov coordenadaBuscada, ax ;Se accede a la coordenada ingresada.
    mov si, offset matrixPC
    add si, coordenadaBuscada
    mov al, byte ptr [si]
    mov barcoAtacado, al
    mov bx, 0
    mov bl, '0'
    cmp al, bl            ;Se compara con '0' el valor encontrado en la matrixPC.
    jg ataqueImpacto      ;Mayor que '0' es porque hay un barco.
    je ataqueFallado      ;Igual a '0' es porque no hay nada.
    jl ataqueRepetido     ;Si se encuentra otro caracter es porque se repitio el lanzamiento.
    ret
    
ataqueImpacto:                ;Reemplaza valores en la matrixPC y matrixUser para notar que ya se ha lanzado un misil en esa coordanada y se muestra el mensaje de impacto confirmado.
    mov si, offset matrixPC
    add si, coordenadaBuscada
    mov byte ptr [si],'/'     ;Coloca el '/' (ascii menor que '0') para tener control si el usuario repite lugar.
    mov si, offset matrixUser
    add si, coordenadaBuscada
    mov byte ptr [si],'1'     ;Coloca un '1' en la matriz de usuario para mostrar que se ha impactado un barco.
    mov ah, 09h
    lea dx, msgPuntos
    int 21h
    mov ah,09h
    lea dx, msgImpacto
    int 21h
    call revisarBarco         ;Se busca revisar cual fue el barco impactado.
    mov ah, 86h               ;Interrupcion similar a un sleep para permitir leer la informacion.
    mov cx, 20
    int 15h
    ret

ataqueFallado:           ;Etiqueta que muestra en la matrixUser un '0' por ataque fallado e imprime "Sin impacto"
    mov ah, 00h
    mov al, usuarioX
    mov bh, 7
    mul bh
    add al, usuarioY
    mov si, offset matrixUser
    add si, coordenadaBuscada
    mov byte ptr [si],'0'    ;Coloca el '0' donde fallo el usuario.
    mov ah, 09h
    lea dx, msgPuntos
    int 21h
    mov ah, 09h
    lea dx, msgNoImpacto
    int 21h
    mov ah, 86h         ;Interrupcion similar a sleep.
    mov cx, 20
    int 15h
    ret

ataqueRepetido:        ;Etiqueta que muestra el mensaje de sin impacto a un lugar donde ya se ha lanzado el misil.
    mov ah,09h
    lea dx, msgPuntos
    int 21h
    mov ah, 09h
    lea dx, msgNoImpacto
    int 21h
    mov ah, 86h             ;Interrupcion similar a sleep.
    mov cx, 20
    int 15h
    ret
    
revisarBarco:           ;Etiqueta que revisa que barco fue atacado segun el valor guardado en barcoAtacado.
    cmp barcoAtacado,'3'
    jz submarinoAtacado
    cmp barcoAtacado, '4'
    jz cruceroAtacado
    cmp barcoAtacado, '5'
    jz portavionesAtacado
    ret

submarinoAtacado:       ;Etiqueta que mantiene control de las piezas de los submarinos.
    dec contadorSubmarino
    cmp contadorSubmarino,0
    jz mostrarSubmarinoDerribado
    mov barcoAtacado, '0'
    jmp revisarBarco
    
mostrarSubmarinoDerribado:  ;Si ya no hay mas partes del submarino se muestra mensaje de submarino hundido.
    mov ah, 09h
    lea dx, msgSubmarino
    int 21h
    ret
    
cruceroAtacado:        ;Etiqueta que mantiene control de las piezas del crucero.
    dec contadorCrucero
    cmp contadorCrucero,0
    jz mostrarCruceroDerribado
    mov barcoAtacado, '0'
    jmp revisarBarco
    
mostrarCruceroDerribado:; Si ya no quedan partes del crucero se muestra mensaje de crucero hundido.
    mov ah, 09h
    lea dx, msgCrucero
    int 21h
    ret

portavionesAtacado:  ;Etiqueta que mantiene control de las piezas del portaviones.
    dec contadorPortaviones
    cmp contadorPortaviones,0
    jz mostrarPortavionesDerribado
    mov barcoAtacado, '0'
    jmp revisarBarco
    
mostrarPortavionesDerribado:  ;Si ya no quedan partes del portaviones, muestra mensaje de portaviones hundido.
    mov ah, 09h
    lea dx, msgPortaviones
    int 21h
    ret 

ganador:           ;Etiqueta que muestra mensaje de felicidades si el usuario gano.
    mov ah, 09h
    lea dx, msgGanador
    int 21h
    mov ah, 86h
    mov cx, 20
    int 15h
    jmp juegoTerminado   ;Se pregunta si quiere jugar otra vez.
    
    
noMasIntentos:    ;Etiqueta que muestra mensaje que ya no quedan mas intentos y prepara direcciones de memoria para mostrar donde quedaban barcos.
    mov ah, 09h
    lea dx, msgIntentos
    int 21h
    mov cx, 49
    mov si, offset matrixPC
    mov di, offset matrixUser
    mov finalMostrado, 1
    jmp solucionFinal  ;Muestra la solucion.
    
solucionFinal:     ;Etiqueta que recorre ambas matrices, y verifica en la matrixPC quedo un caracter mayor que '0'(quedan partes de barcos).
    mov al, byte ptr [si]
    cmp al, '0'
    jg reemplazarEquis
    seguirSolucion:
        inc si
        inc di
        loop solucionFinal
    jmp limpiarPantalla
    
    
reemplazarEquis:    ;Donde se haya encontrado una pieza de barco en la matrixPC, se mostrara una x en matrixUser.
    mov byte ptr [di], 'x'
    jmp seguirSolucion
    
ultimoMensaje:       ;Etiqueta que muestra mensaje informativo sobre el relleno de 'x' en la matrixUser.
    mov ah, 09h
    lea dx, msgFinal
    int 21h
    mov ah, 86h
    mov cx, 20
    int 15h
    jmp juegoTerminado    
        
juegoTerminado proc   ;Proceso que pregunta si se desea volver a jugar con una S/N segun el caracter, repite todo el juego o no. Si no se ingresa alguno de estos se seguira pidiendo.
    call imprimirSaltoLinea
    mov ah, 09h
    lea dx, msgFin
    int 21h
    mov ah, 01h
    int 21h 
    mov bh,al
    cmp al, 53h
    call imprimirSaltoLinea
    jz inicioJuego
    cmp bh, 05
    jz salir
    cmp bh,78
    jz salir
    jnz juegoTerminado
juegoTerminado endp

salir:
    hlt