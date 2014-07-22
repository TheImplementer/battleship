;Progetto Esame Calcolatori Elettronici II
;Autore: Pelizzon Enrico
;Data: 17/09/2010
;Descrizione: Il progetto prevede la realizzazione di un programma che simula il gioco della battaglia
;navale. Compilare utilizzando la versione 5 dell'assemblatore MASM.

;Inclusione del file contenente le routine per la gestione della grafica
include		Gfx.asm

;Definizione del segmento dati e dichiarazione delle variabili utilizzate all'interno del programma
DataS		segment para public 'data'

;Variabile per il ripristino della modalità video originale al termine del programma
orgVideo	db ?
;Vettori contenenti lo stato delle celle del campo di battaglia (10x10)
;I 4 bit più significativi indicano se la cella è visibile (1) o nascosta (0)
plOne		db 100 dup(11h)
plTwo		db 100 dup(11h)
;Variabili per il salvataggio della posizione del cursore all'interno della griglia
plRow		db 0
plCol		db 0
;Vettore contenente la dimensione dei pezzi da posizionare
pieceSequence db 1,1,1,1,2,2,2,3,3,4,0
;Variabile per la memorizzazione del giocatore corrente
plTurn		db 1
;Stringhe di informazione
strText1	db "Esame Calcolatori Elettronici II",0
strText2	db "Appello del giorno 17/09/2010",0
strText3	db "Progetto: Battaglia Navale",0
strText4	db "Posizionamento navi",0
strText5	db "-Premere le frecce per spostare la nave.",0
strText6	db "-Premere R per ruotare la nave.",0
strText7	db "-Premere SPAZIO per confermare la posizione.",0
strText8	db "Giocatore 1",0
strText9	db "Giocatore 2",0
strText10	db "Colpito!",0
strText11	db "Mancato!",0
strText12 	db " vince la partita!",0
strText13	db "Gioco",0
strText14	db "-Utilizzare le frecce per muovere il    cursore all'interno della griglia.",0
strText15	db "-Premere SPAZIO per fare fuoco.",0
strText16	db "-Premere ESC per uscire dal gioco.",0
DataS		ends

;Definizione del segmento stack (1024 byte)
StackS		segment stack
			db 1024 dup (0)
StackS		ends

;Definizione del segmento codice
CodeS		segment para public 'code'
			assume cs:CodeS, ds:DataS, ss:StackS

pStart		proc far

			mov ax,seg DataS				;Inizializzazione del registro di segmento DS
			mov ds,ax
			
			mov ah,0fh						;Salvataggio della modalità video originale con la funzione
			int 10h							;0Fh del BIOS (int 10h)
			mov [orgVideo],al
			
			mov ax,13h						;Passaggio alla modalità grafica 13h (AL) con la funzione
			int 10h							;00h del BIOS (320x200x256)
			
			mov ax,0a000h					;Inizializzazione del registro di segmento ES con l'indirizzo
			mov es,ax						;della memoria video
			
			
			mov dx,0b05h					;Stampa di messaggi di informazione e aiuto per l'utente
			call moveCursor
			mov si,offset strText1
			call printStr
			
			mov dx,0c06h
			call moveCursor
			mov si,offset strText2
			call printStr
			
			mov dx,0d08h
			call moveCursor
			mov si,offset strText3
			call printStr
			
			call charIn
			
			call clrScr
			
			mov dx,0a0ah
			call moveCursor
			mov si,offset strText4
			call printStr
			
			mov dx,0c00h
			call moveCursor
			mov si,offset strText5
			call printStr
			
			mov dx,0d00h
			call moveCursor
			mov si,offset strText6
			call printStr
			
			mov dx,0e00h
			call moveCursor
			mov si,offset strText7
			call printStr
			
			mov dx,0f00h
			call moveCursor
			mov si,offset strText16
			call printStr
			
			call charIn
			
			call clrScr
			
			mov dx,0c0dh
			call moveCursor
			mov si,offset strText8
			call printStr
			
			call charIn
			
			
			mov ax,offset plOne				;Richiamo della procedura "placePieces" per il posizionamento
			push ax							;dei pezzi del primo giocatore
			call placePieces
			
			cmp ax,1
			jne plOneOK
			jmp terminateGame
plOneOK:
			call hideCells					;Richiamo della procedura "hideCells" per rendere invisibili
			add sp,2						;le celle del campo di battaglia
			
			call clrScr
			
			mov dx,0c0dh
			call moveCursor
			mov si,offset strText9
			call printStr
			
			call charIn
			
			mov ax,offset plTwo				;Richiamo della procedura "placePieces" per il posizionamento
			push ax							;dei pezzi del secondo giocatore
			call placePieces
			
			cmp ax,1
			jne plTwoOK
			jmp terminateGame
plTwoOK:
			call hideCells
			add sp,2
			
			call clrScr
			
			mov dx,0a11h
			call moveCursor
			mov si,offset strText13
			call printStr
			
			mov dx,0c00h
			call moveCursor
			mov si,offset strText14
			call printStr
			
			mov dx,0e00h
			call moveCursor
			mov si,offset strText15
			call printStr
			
			mov dx,0f00h
			call moveCursor
			mov si,offset strText16
			call printStr
			
			call charIn			

plTurnLoop:									;Inizio del ciclo di gioco
			cmp byte ptr [plTurn],1			;Verifica del giocatore corrente
			je turnPlOne
			mov ax,offset strText9
			push ax
			mov ax,offset plOne
			jmp doTurn
turnPlOne:
			mov ax,offset strText8
			push ax
			mov ax,offset plTwo
doTurn:
			push ax
			call gameLoop					;Richiamo della procedura "gameLoop" per la gestione
											;del turno
			cmp ax,1
			je terminateGame
			
			call checkWin					;Richiamo della procedura "checkWin" per il controllo della vincita
			add sp,2
			
			cmp ax,0						;In caso di vincita di un giocatore, esce dal ciclo di gioco
			jne playerWin
			
			add sp,2
			
			xor byte ptr [plTurn],3			;Aggiornamento del giocatore corrente
			
			jmp plTurnLoop

playerWin:									;Stampa del messaggio del giocatore vincente
			call clrScr
			mov dx,0c05h
			call moveCursor
			pop si
			call printStr
			mov si,offset strText12
			call printStr
			
			call charIn
			jmp normalWin
terminateGame:
			add sp,2
normalWin:
	
			xor ah,ah						;Ripristino della modalità video originale
			mov al,[orgVideo]
			int 10h
			
			mov ax,4c00h					;Fine del programma
			int 21h
			
pStart		endp

;*************************************************************************************************
;PROCEDURA: placePieces
;DESCRIZIONE: Si occupa di gestire il posizionamento dei pezzi all'interno del campo di battaglia
;PARAMETRI: STACK - Indirizzo del vettore contenente lo stato della griglia (2 byte)
;*************************************************************************************************

placePieces	proc near

			push bp
			mov bp,sp
			sub sp,2						;Allocazione di 2 byte sullo stack per il salvataggio
											;dell'orientazione e della posizione corretta del pezzo
			
			call clrScr						;Pulizia dello schermo e disegno della griglia
			call drawGrid
			
			mov bx,[bp+4]					;Riempimento della griglia allo stato iniziale
			push bx
			call fillGrid
			add sp,2
	
			xor si,si

placingLoop:
			mov al,pieceSequence[si]		;Recupero di un pezzo dal vettore di sequenza e verifica
			cmp al,0						;della validità dello stesso
			jne labelApp
			jmp endPlacing
labelApp:
			mov byte ptr [bp-1],0			
			mov byte ptr [plCol],0
			mov byte ptr [plRow],0

pieceDrawing:
			
			push bx
			call fillGrid
			add sp,2			
			
			mov al,pieceSequence[si]
			
			xor cx,cx
			mov cl,al
			xor ax,ax
			mov al,byte ptr [plCol]
			xor dx,dx
			mov dl,byte ptr [plRow]
			mov byte ptr [bp-2],0
			
pieceDrawLoop:
			push ax
			push ax
			push dx
			call getArrayPos
			add sp,4
			mov di,ax
			pop ax
			cmp byte ptr ds:[bx+di],11h		;Verifica che la cella sia libera
			je pieceGreen
			mov di,28h						;Se la cella è occupata il colore della parte sarà rosso
			mov byte ptr [bp-2],1
			jmp drawPiece
pieceGreen:
			mov di,30h						;Se la cella è libera il colore della parte sarà verde
drawPiece:
			push di
			push ax
			push dx			
			call fillCell					;Riempimento della cella con la procedura fillCell
			add sp,6

			cmp byte ptr [bp-1],0			;Verifica dell'orientazione del pezzo per il disegno
			je incRow
			inc al
			jmp nextPart
incRow:
			inc dl
nextPart:
			
			loop pieceDrawLoop

shadowKeyLoop:
			call charIn
			
			cmp al,1bh
			jne notEsc
			mov ax,1
			jmp escEndPlacing			
notEsc:
			mov al,pieceSequence[si]
			
			cmp ah,13h						;Verifica del tasto premuto
			je pieceRotate
			cmp ah,50h
			je placeKeyDown
			cmp ah,4bh
			je placeKeyLeft
			cmp ah,4dh
			je placeKeyRight
			cmp ah,48h
			je placeKeyUp
			cmp ah,39h
			je placeKeySpace
			jmp shadowKeyLoop
			
pieceRotate:								;Codice per la gestione della rotazione del pezzo
			cmp byte ptr [bp-1],0
			je rotateHor
			add al,[plRow]
			cmp al,10
			ja endPlaceKey
			mov byte ptr [bp-1],0
			jmp endPlaceKey
rotateHor:
			add al,[plCol]
			cmp al,10
			ja endPlaceKey
			mov byte ptr [bp-1],1
			jmp endPlaceKey
			
placeKeyDown:								;Codice per la gestione della pressione delle frecce direzionali
			cmp byte ptr [bp-1],0
			jne keyDownOK
			add al,[plRow]
			cmp al,10
			je endPlaceKey
keyDownOK:
			cmp byte ptr [plRow],9
			je endPlaceKey
			inc byte ptr [plRow]
			jmp endPlaceKey
placeKeyLeft:
			cmp byte ptr [plCol],0
			je endPlaceKey
			dec byte ptr [plCol]
			jmp endPlaceKey
placeKeyRight:
			cmp byte ptr [bp-1],1
			jne keyRightOK
			add al,[plCol]
			cmp al,10
			je endPlaceKey
keyRightOK:
			cmp byte ptr [plCol],9
			je endPlaceKey
			inc byte ptr [plCol]
			jmp endPlaceKey
placeKeyUp:
			cmp byte ptr [plRow],0
			je endPlaceKey
			dec byte ptr [plRow]
endPlaceKey:
			jmp pieceDrawing
			
placeKeySpace:								;Codice per il salvataggio del pezzo nella posizione corrente
			cmp byte ptr [bp-2],0			;Verifica della validità della posizione
			je	savePiece
			jmp shadowKeyLoop
savePiece:
			xor cx,cx
			mov cl,al
			
			xor ax,ax						;Utilizzo della procedura getArrayPos per l'ottenimento della posizione
			mov al,byte ptr [plCol]			;iniziale del pezzo all'interno dell'array di stato
			push ax
			mov al,byte ptr [plRow]
			push ax
			call getArrayPos
			add sp,4
			
			push bx
			add bx,ax
saveLoop:									;Ciclo per il salvataggio del pezzo
			mov byte ptr [bx],1fh			
			cmp byte ptr [bp-1],0
			je saveIncRow
			inc bx
			jmp saveNext
saveIncRow:
			add bx,10
saveNext:
			loop saveLoop
			
			pop bx
			inc si
			jmp placingLoop
			
endPlacing:
			
			push bx
			call fillGrid
			add sp,2
			
			call charIn
			
			xor ax,ax
escEndPlacing:
			
			mov sp,bp
			pop bp
			
			ret
placePieces	endp

;*********************************************************************************************************
;PROCEDURA: gameLoop
;DESCRIZIONE: Procedura che si occupa della gestione di un turno di gioco
;PARAMETRI: STACK - Indirizzo della stringa identificativa del giocatore corrente (2 byte)
;                   Indirizzo del vettore contenente lo stato della griglia  del giocatore opposto(2 byte)
;*********************************************************************************************************

gameLoop	proc near

			push bp
			mov bp,sp
			
			call clrScr						;Pulizia dello schermo e disegno della griglia
			call drawGrid
			
			mov byte ptr [plCol],0			;Inizializzazione della riga e della colonna corrente
			mov byte ptr [plRow],0
			
			call clearLastLine				;Stampa del messaggio di identificazione del giocatore corrente
			mov dx,180dh
			call moveCursor
			mov si,[bp+6]
			call printStr

			mov si,[bp+4]
commandLoop:
			push si							;Riempimento della griglia utilizzando il vettore di stato del
			call fillGrid					;giocatore opposto
			add sp,2
			
			xor ax,ax						;Selezione della cella corrente utilizzando la procedura selectCell
			mov al,[plCol]
			mov ah,[plRow]
			push ax
			call selectCell
			add sp,2
			
			call charIn
			cmp al,1bh
			jne checkOtherKeys
			mov ax,1
			jmp endGame

checkOtherKeys:								;Verifica del tasto premuto
			cmp ah,50h
			je keyDown
			cmp ah,4bh
			je keyLeft
			cmp ah,4dh
			je keyRight
			cmp ah,48h
			je keyUp
			cmp ah,39h
			je keySpace
			jmp commandLoop
			
keyDown:									;Se il tasto premuto è una freccia direzionale avviene il semplice
			cmp byte ptr [plRow],9			;aggiornamento della posizione del cursore
			je commandLoop
			inc byte ptr [plRow]
			jmp commandLoop
keyLeft:
			cmp byte ptr [plCol],0
			je commandLoop
			dec byte ptr [plCol]
			jmp commandLoop
keyRight:
			cmp byte ptr [plCol],9
			je commandLoop
			inc byte ptr [plCol]
			jmp commandLoop
keyUp:
			cmp byte ptr [plRow],0
			je commandLoop
			dec byte ptr [plRow]
			jmp commandLoop
			
keySpace:									;Codice per la gestione del tasto SPAZIO
			xor ax,ax
			mov al,[plCol]
			push ax
			mov al,[plRow]
			push ax
			call getArrayPos
			add sp,4
			
			add si,ax
			test byte ptr [si],10h			;Verifica che la cella corrente sia nascosta
			jz discoverPiece
			sub si,ax
			
			jmp commandLoop
discoverPiece:								;Rivela la cella corrente e riempie nuovamente la griglia
			or byte ptr [si],10h
			
			push si
			
			sub si,ax
			push si
			call fillGrid
			add sp,2
			
			pop si
			
			call clearLastLine				;Stampa del messaggio "Colpito!" o "Mancato!"
			mov dx,180fh
			call moveCursor
			cmp byte ptr [si],1fh
			je pieceHitted
			mov si,offset strText11
			jmp hitMissPrint
pieceHitted:
			mov si,offset strText10
hitMissPrint:
			call printStr
			
			call charIn
			
			xor ax,ax

endGame:	
			mov sp,bp
			pop bp
			
			ret

gameLoop	endp

;************************************************************************************************************
;PROCEDURA: getArrayPos
;DESCRIZIONE: Calcola l'indirizzo all'interno del vettore di stato partendo da riga e colonna di una cella
;PARAMETRI: STACK - Colonna (2 byte)
;                   Riga (2 byte)
;************************************************************************************************************

getArrayPos	proc near

			push bp
			mov bp,sp
			
			push dx
			
			mov dl,10
			mov ax,[bp+4]
			mul dl
			add ax,[bp+6]
			
			pop dx
			
			mov sp,bp
			pop bp
			
			ret
getArrayPos	endp

;************************************************************************************************************
;PROCEDURA: hideCells
;DESCRIZIONE: Nasconde tutte le celle del campo di battaglia azzerando i 4 bit più significativi di ogni byte
;del vettore passato come parametro sullo stack
;PARAMETRI: STACK - Indirizzo del vettore contenente lo stato della griglia (2 byte)
;************************************************************************************************************

hideCells	proc near

			push bp
			mov bp,sp
			
			push cx							;Salvataggio dei registri
			push si
			
			mov cx,100
			mov si,[bp+4]
			
hideLoop:
			and byte ptr [si],0fh			;Azzeramento dei 4 bit più significativi del byte che descrive
			inc si							;lo stato della cella
			loop hideLoop
			
			pop si							;Ripristino dei registri
			pop cx
			
			mov sp,bp
			pop bp
			
			ret

hideCells	endp

;***********************************************************************************************************
;PROCEDURA: checkWin
;DESCRIZIONE: Esamina il vettore passato come parametro sullo stack per determinare se un giocatore ha vinto
;la partita, verificando che le celle rorrispondenti ai pezzi posizionati siano tutte scoperte
;PARAMETRI: STACK - Indirizzo del vettore contenente lo stato della griglia (2 byte)
;VALORE DI RITORNO: AL = 1 - Vittoria
;                   AL = 0 - Gioco non ancora terminato
;***********************************************************************************************************

checkWin	proc near

			push bp
			mov bp,sp
			
			push cx							;Salvataggio dei registri
			push si
			
			mov ax,1
			mov si,[bp+4]
			mov cx,100
checkWinLoop:								;Ciclo per la verifica delle celle
			mov ah,byte ptr [si]			;Recupero di un byte dal vettore
			and ah,0fh						;Verifica che il byte corrisponda a un pezzo
			cmp ah,0fh
			jne nextCellWin
			mov ah,byte ptr [si]
			and ah,0f0h						;Verifica che il pezzo sia visibile
			cmp ah,0
			jne nextCellWin
			mov al,0						;Se il pezzo è nascosto il gioco non è ancora terminato
			jmp notWin
nextCellWin:
			inc si
			loop checkWinLoop

notWin:
			xor ah,ah
			
			pop si							;Ripristino dei registri
			pop cx
			
			mov sp,bp
			pop bp
			
			ret

checkWin	endp

CodeS		ends
			end pStart