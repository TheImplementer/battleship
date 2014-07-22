
public drawGrid,clrScr,fillCell,charOut,printStr,selectCell,fillGrid,moveCursor,clearLastLine,charIn

GfxS		segment para public 'code'
			assume cs:GfxS,ds:DataS

;Definizione delle costanti che determinano il colore, la dimensione e la posizione della griglia
gridColor	equ 7
cellSize	equ 17
gridTop		equ	9
gridLeft	equ 56

;*******************************************************
;PROCEDURA: drawGrid
;DESCRIZIONE: Disegna la griglia del campo di battaglia
;*******************************************************

drawGrid	proc far
			
			push bp
			mov bp,sp
			sub sp,2						;Allocazione di una variabile locale (2 byte) sullo stack
											;per il calcolo della dimensione totale della griglia
											
			mov ax,cellSize					;Calcolo della dimensione totale della griglia
			mov dl,10
			mul dl
			add ax,10
			inc ax
			mov [bp-2],ax
			
			mov ax,gridTop					;Disegno della griglia di gioco utilizzando le costanti dichiarate
			mov bx,gridLeft					;in precedenza
			mov dx,gridColor
			
			mov cx,11
gridRowLoop:								;Ciclo per il disegno delle linee orizzontali della griglia
			push cx
			mov cx,[bp-2]
			call drawRow
			add ax,cellSize
			inc ax
			pop cx
			loop gridRowLoop
			
			mov ax,gridTop
			mov cx,11
gridColLoop:								;Ciclo per il disegno delle linee verticali della griglia
			push cx
			mov cx,[bp-2]
			call drawCol
			add bx,cellSize
			inc bx
			pop cx
			loop gridColLoop

			mov sp,bp
			pop bp
			
			ret

drawGrid	endp

;**********************************************************
;PROCEDURA: drawRow
;DESCRIZIONE: Disegna una linea orizzontale sullo schermo
;PARAMETRI: AX/BX - Posizione di partenza della linea (Y/X)
;           CX - Lunghezza della linea
;			DL - Colore della linea
;**********************************************************

drawRow		proc near
			
			push ax							;Salvataggio dei registri
			push bx
			push cx
			push dx
			
			mov dx,320						;Calcolo della posizione iniziale all'interno della memoria video
			mul dx
			add bx,ax
			pop dx
rowLoop:									;Ciclo di disegno della linea
			mov es:[bx],dl
			inc bx
			loop rowLoop
			
			pop cx							;Ripristino dei registri
			pop bx
			pop ax
			
			ret
drawRow		endp

;**********************************************************
;PROCEDURA: drawCol
;DESCRIZIONE: Disegna una linea verticale sullo schermo
;PARAMETRI: AX/BX - Posizione di partenza della linea (Y/X)
;           CX - Lunghezza della linea
;			DL - Colore della linea
;**********************************************************

drawCol		proc near
			
			push ax							;Salvataggio dei registri
			push bx
			push cx
			push dx
			
			mov dx,320						;Calcolo della posizione iniziale all'interno della memoria video
			mul dx
			add bx,ax
			pop dx
colLoop:									;Ciclo di disegno della linea
			mov es:[bx],dl
			add bx,320
			loop colLoop
			
			pop cx							;Ripristino dei registri
			pop bx
			pop ax
			
			ret
drawCol		endp

;*****************************************************
;PROCEDURA: clrScr
;DESCRIZIONE: Pulisce l'intera schermata del programma
;*****************************************************

clrScr		proc far

			push ax							;Salvataggio dei registri
			push cx
			
			xor ax,ax
			xor di,di
			mov cx,32000
			cld
clrLoop:									;Ciclo di pulizia
			stosw							;Copia della word 0000H nella memoria video puntata da ES:DI
			loop clrLoop
			
			pop cx							;Ripristino dei registri
			pop ax

			ret
clrScr		endp

;****************************************************
;PROCEDURA: fillCell
;DESCRIZIONE: Colora una cella del campo di battaglia
;PARAMETRI: STACK - Colore della cella (2 byte)
;                   Colonna (2 byte)
;                   Riga (2 byte)
;****************************************************

fillCell	proc far

			push bp
			mov bp,sp
			
			push ax							;Salvataggio dei registri
			push bx
			push cx
			push dx
			
			mov ax,cellSize					;Calcolo della posizione iniziale della cella all'interno
			inc ax							;della memoria video utilizzando i parametri passati
			mov dx,[bp+8]					;sullo stack
			mul dl
			add ax,gridLeft
			mov bx,ax
			inc bx
			
			mov ax,cellSize
			inc ax
			mov dx,[bp+6]
			mul dl
			add ax,gridTop
			inc ax
			
			mov dx,[bp+10]					;Recupero del colore dallo stack
			mov cx,cellSize
fillLoop:									;Ciclo per il riempimento della cella utlizzando la procedura drawRow
			push cx	
			mov cx,cellSize
			call drawRow
			inc ax
			pop cx
			loop fillLoop
			
			pop dx							;Ripristino dei registri
			pop cx
			pop bx
			pop ax
			
			mov sp,bp
			pop bp

			ret
fillCell	endp

;**********************************************
;PROCEDURA: charOut
;DESCRIZIONE: Stampa un carattere sullo schermo
;PARAMETRI: AL - Carattere da stampare
;**********************************************

charOut		proc far

			push ax							;Salvataggio dei registri utilizzati
			push bx
			push cx
			
			mov ah,9 						;Utilizzo della funzione 09H del BIOS per la stampa del carattere
			mov cx,1	
			mov bl,7
			int 10h
			
			pop cx							;Ripristino dei registri
			pop bx
			pop ax
			
			ret
			
charOut		endp

;****************************************************************
;PROCEDURA: printStr
;DESCRIZIONE: Stampa una stringa,con terminatore 0, sullo schermo
;PARAMETRI: DS:SI - Indirizzo della stringa da stampare
;****************************************************************

printStr	proc far

strLoop:
			lodsb							;Caricamento di un carattere della stringa in AL
			cmp al,0						;e verifica di fine stringa
			je strEnd
			call charOut					;Stampa del carattere
			call cursorNext					;Aggiornamento del cursore
			jmp strLoop
strEnd:
			ret
			
printStr	endp

;**********************************************************************************
;PROCEDURA: cursorNext
;DESCRIZIONE: Aggiorna la posizione del cursore del testo alla posizione successiva
;**********************************************************************************

cursorNext	proc near

			push ax							;Salvataggio dei registri utilizzati all'interno della procedura
			push bx
			push cx
			push dx
			
			mov ah,3						;Utilizzo della funzione 03H del BIOS per ottenere la posizione
			xor bx,bx						;corrente del cursore
			int 10h
			
			inc dl							;Incremento della colonna del cursore e verifica della stessa
			cmp dl,40						;Se la colonna aggiornata ha valore 40 si passa alla riga successiva
			jne cursorOK
			xor dl,dl
			inc dh
cursorOK:
			mov ah,2						;Utilizzo della funzione 02H del BIOS per l'aggiornamento della
			int 10h							;posizione del cursore
			
			pop dx							;Ripristino dei registri
			pop cx
			pop bx
			pop ax
			
			ret
			
cursorNext	endp

;**********************************************************
;PROCEDURA: moveCursor
;DESCRIZIONE: Sposta il cursore nella posizione specificata
;PARAMETRI: DH - Riga
;           DL - Colonna
;**********************************************************

moveCursor	proc far

			push ax							;Salvataggio dei registri
			push bx
			
			xor bx,bx
			mov ah,2						;Utilizzo della funzione 02H del BIOS per il posizionamento del cursore
			int 10h
			
			pop bx							;Ripristino dei registri
			pop ax
			
			ret
			
moveCursor	endp

;**********************************************************
;PROCEDURA: selectCell
;DESCRIZIONE: Evidenzia una cella all'interno della griglia
;PARAMETRI: STACK - Riga (1 byte)
;                   Colonna (1 byte)
;**********************************************************

selectCell	proc far

			push bp
			mov bp,sp
			
			push ax							;Salvataggio dei registri
			push bx
			push cx
			push dx
			
			mov ax,cellSize					;Calcolo della posizione della cella all'interno della
			inc ax							;memoria video
			mov dl,[bp+6]
			mul dl
			add ax,gridLeft
			mov bx,ax
			inc bx
			
			mov ax,cellSize
			inc ax
			mov dl,[bp+7]
			mul dl
			add ax,gridTop
			inc ax
			
			mov dx,28h						;Selezione della cella utilizzando le procedure drawRow e drawCol
			mov cx,cellSize
			
			call drawRow
			push ax
			add ax,cellSize
			dec ax
			call drawRow
			pop ax
			
			call drawCol
			add bx,cellSize
			dec bx
			call drawCol
			
			pop dx							;Ripristino dei registri
			pop cx
			pop bx
			pop ax
			
			mov sp,bp
			pop bp

			ret
selectCell	endp

;***********************************************************************************
;PROCEDURA: fillGrid
;DESCRIZIONE: Riempie la griglia di gioco
;PARAMETRI: STACK - Indirizzo del vettore contenente lo stato della griglia (2 byte)
;***********************************************************************************

fillGrid 	proc far

			push bp
			mov bp,sp
			
			push ax							;Salvataggio dei registri
			push bx
			push cx
			push dx
			push si

			xor si,si						;Inizializzazione dei registri
			xor ax,ax
			xor dx,dx
			mov cx,100
			mov bx,[bp+6]
			
			push bp
			mov bp,bx
			
fillGridLoop:			
			mov bl,byte ptr ds:[bp+si]		;Recupero di un byte dal vettore
			test bl,0f0h					;Verifica della visibilità della cella
			jz cellHidden
			and bl,0fh
			xor bh,bh
			push bx
			jmp fillNow
cellHidden:									;Se la cella è nascosta viene colorata di nero
			xor bx,bx
			push bx
			
			jmp fillNow
fillNow:
			push ax							;Riempimento della cella utilizzando la procedura fillCell
			push dx
			call fillCell
			add sp,6
			
			inc ax							;Spostamento alla cella successiva
			cmp ax,10
			jne nextCell
			xor ax,ax
			inc dx
nextCell:
			inc si
			loop fillGridLoop
			
			pop bp
			
			pop si							;Ripristino dei registri
			pop dx
			pop cx
			pop bx
			pop ax
						
			mov sp,bp
			pop bp
			
			ret
fillGrid	endp

;************************************************************
;PROCEDURA: clearLastLine
;DESCRIZIONE: "Pulisce" l'ultima linea di testo dello schermo
;************************************************************

clearLastLine proc far

			push ax							;Salvataggio dei registri
			push dx
			push cx
			
			mov di,61440					;Indirizzo di partenza all'interno della memoria video
			mov cx,2560						;Numero di byte da azzerare
			xor ax,ax						;Byte 00H da copiare nella memoria video
			cld
lastLineLoop:								;Ciclo di pulizia
			stosb
			loop lastLineLoop
			
			pop cx							;Ripristino dei registri
			pop dx
			pop ax
			
			ret
clearLastLine endp

;**********************************************
;PROCEDURA: charIn
;DESCRIZIONE: Legge un carattere dalla tastiera
;**********************************************

charIn		proc far
			
			xor ax,ax						;Utilizzo della funzione 00H dell'interrupt 16H per la lettura
			int 16h							;del carattere (AL)
			
			ret
			
charIn		endp

GfxS		ends