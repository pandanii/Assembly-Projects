MyStack SEGMENT STACK              ; Keyword "STACK" required

        DW 256 DUP (?)             ; A stack of nothing special.

MyStack ENDS                       ; End Segment

;------------------------------------------------------------------------
MyData SEGMENT
	
	fakeScreen	DW  2000  DUP ('?' + 0c00h)
	readyToUpdate	DW	0
	nextTimeUpdate	DW	0
	currentTicks	DW	0
	delayTicks	DW	0
	howOften	DW	20
	percentSnow	DW	10
	randNum		DW	0
	
	offsetUL	DW	1352	; ULcorner of box 1352
	lineType	DB	1	; 0 for SLine and 1 for DLine
	foreground	DB	1101b	; must OR F and B 
	background	DB	0100b	; together to put in AH
	height		DB	8
	
	singleLine	DB	0B3h, 0C4h, 0DAh, 0BFh, 0C0h, 0D9h
	doubleLine	DB	0BAh, 0CDh, 0C9h, 0BBh, 0C8h, 0BCh
	
	vertLine	EQU	0
	horiLine	EQU	1
	ULcorner	EQU	2
	URcorner	EQU	3
	LLcorner	EQU	4
	LRcorner	EQU	5
	
	zRow		DW	0
	zCol		DW	0
	
MyData ENDS                        ; End Segment

;------------------------------------------------------------------------
MyCode SEGMENT
        ASSUME CS:MyCode, DS:MyData    ; Tell the assembler what segments the segment 
                                       ; registers refer to in the following code.

MainProg  PROC                     ; This serves as the "user transfer address".

    MOV     AX, MyData             ; Make DS address a data segment.  Two statements
    MOV     DS, AX                 ; required since it is illegal to move
                                   ; data directly into a segment register.

    MOV     AX, 0B800h             ; Makes ES a segment register address for screen memory.
    MOV     ES, AX
    
    
    MOV	    AX, 0                  ; Get timer ticks
    INT     1Ah			   ; Interrupt
    MOV     nextTimeUpdate, DX     ; Move timer ticks into var
    MOV     AX, howOften	    
    ADD     nextTimeUpdate, AX
    
    ;MOV    nextTimeUpdate, howOften
    ;MOV    randNum, nextTimeUpdate
   
    CALL    drawBox
    CALL    keyDown
    
    
    
    MOV     AH, 4Ch                ; These instructions use an interrupt
    INT     21h                    ; to release the memory for the project.
                                                                             	    
MainProg ENDP
;------------------------------------------------------------------------
drawBox PROC
    PUSH AX BX CX
	
	MOV	AH, 00h		; clear ah
	MOV	AL, background	; move background to al
	SHL	AL, 4		; shift bytes left by 4
	MOV	CH, 00h		; clears ch
	MOV	CL, foreground	; move foregound to cl
	OR	AL, CL		; combined the F and B
	MOV	AH, AL		; puts color in ah
	
	MOV	DI, offsetUL	; puts ULcorner in DI
	
	LEA	SI, doubleLine		;
	CMP	lineType, 1
	JE	oneL
	LEA	SI, singleLine	
    oneL:
	MOV 	AL, [SI + ULcorner ]
	
	MOV 	ES:[DI], AX		; put on the screen
	
	MOV	CH, 00h			; clear CH
	MOV	CL, height		; move height into cl
	ADD	CL, CL			; double the height
	ADD	CL, CL			; width
	SUB	CL, 2			; -2 to account for corners
	
	ADD	DI, CX			; put width in DI	
	MOV 	AL, [SI + URcorner ]	; load char into al
	MOV	ES:[DI], AX		; put URcorner on screen
	
	PUSH	AX BX
	MOV	AL, height		; move height into al
	DEC	AL			; subtract 1 from height
	MOV	BL, 160			; height-1 *160
	MUL	BL			; AX := AL*BL
	ADD	DI, AX			; add offset to DI offset
	POP	BX AX
				
	MOV 	AL, [SI + LRcorner ]	;
	MOV	ES:[DI], AX		; put on screen
	
	MOV	CH, 00h			; clear ch
	MOV	CL, height		; put height into cl
	ADD	CL, CL			; create width
	ADD	CL, CL
	SUB	CL, 2			; accoutn for corners
		
	SUB	DI, CX			; lower left corner
	
	MOV 	AL, [SI + LLcorner ]	;
	MOV	ES:[DI], AX
	
	MOV	BX, offsetUL		; put UL corner in bx
	ADD	BX, 160			; moves to next line down
	
	MOV	CH, 00h
	MOV	CL, height
	ADD	CL, CL
	ADD	CL, CL
	SUB	CL, 2
	MOV 	DI, CX
	
	MOV	CL, height
	SUB	CL, 2
	
	vertLoop:
			MOV	AL, [SI + vertLine]
			Mov	ES:[BX], AX
			MOV	ES:[BX + DI], AX
			ADD	BX, 160		; INC BX
			DEC	CL		; Dec the loop so it stops at height 0
			CMP	CL, 0		; Is height 0
	    	    	JG	vertLoop	; No, do it again.
	    	    	
	    	
	    	MOV	CL, height
	    	ADD	CL, height
	    	SUB	CL, 2
	    	
	    	PUSH	AX BX
		MOV	AL, height		; move height into al
		MOV	BL, 160			; height *160
		MUL	BL			; AX := AL*BL
		MOV	DI, AX			; move offset to DI offset
		SUB	DI, 160
		POP	BX AX
	    	
	    	MOV	BX, offsetUL
	    	INC	BX
	    	INC	BX
	    	
	    	horizontalLoop:
	    		MOV	AL, [SI + horiLine]
			Mov	ES:[BX], AX
			MOV	ES:[BX + DI], AX
			ADD	BX, 2		; INC BX by 2
			DEC	CL		; Dec the loop so it stops at width 0
			CMP	CL, 0		; Is width 0?
    	    	JG	horizontalLoop		; No, do it again.
	
    POP CX BX AX
RET
drawBox ENDP
;------------------------------------------------------------------------
keyDown PROC ;On entry, proc will loop waiting for a key to be pressed 
;On exit, program will have been terminated
	
	outerLoop:
	
		INC BYTE PTR ES:[160*4 +44]
		
		MOV	AH,11h			;
		INT	16h
		JZ	noKey
		
		MOV	AH, 10h
		INT	16h
		CMP	AL, 1Bh		;ESC key pressed?
		JE	terminate	;If so terminate, else continue.
		
		CMP	AX, 4BE0h		;Left arrow?
		JE	leftArrow	;If so move to call LA proc
		
		CMP	AX, 48E0h		;Up arrow?
		JE	upArrow		;IF so go to UA proc
		
		CMP	AX, 4DE0h		;Right arrow?
		JE	rightArrow	;If so call RA proc
		
		CMP	AX, 50E0h		;Down Arrow?
		JE	downArrow	;IF so call DA proc
		
		CMP	AX, 8DE0h	;Crtl up?
		JE	crtlUp		;If so make bigger in cUp proc
		
		CMP	AX, 91E0h	;Crtl down?
		JE	crtlDown	;If so make smaller in cD proc
		
		CMP	AX, 3B00h	;F1?
		JE	f1Key		;If so make lines toggle
		
		CMP	AX, 3C00h	;F2?
		JE	f2Key		;If so toggle foreground colors
		
		CMP	AX, 3D00h	;F3?
		JE	f3Key		;If so toggle background color
		
		CMP	AX, 4000h	;F6?
		JE	f6Key		;If so slow down % of *
		
		CMP	AX, 4100h	;F7?
		JE	f7Key		;If so speed up %  of *
		
		CMP	AX, 4200h	;F8?
		JE	f8Key		;If so slow down * rate
		
		CMP	AX, 4300h	;F9?
		JE	f9Key		;If so speed up * rate
		
	noKey:
		;Background work
		CALL	checkTime
		CMP	readyToUpdate, 0
		JE	notReady
		
		CALL	getRandNum		
		CALL	fakeScreenDown
		CALL	fillTopLine
		;CALL    showFake
		;CALL	copyFakeToPortal
	notReady:
		JMP	outerLoop
		
	terminate:
		CALL	terminateProj
		
	leftArrow:
		CALL	moveLeft
		JMP	outerLoop
		
	upArrow:
		CALL	moveUp
		JMP	outerLoop
	
	rightArrow:
		CALL	moveRight
		JMP	outerLoop
		
	downArrow:
		CALL	moveDown
		JMP	outerLoop
	
	crtlUp:
		CALL	makeBigger
		JMP	outerLoop
	
	crtlDown:
		CALL	makeSmaller
		JMP	outerLoop
	
	f1Key:
		CALL	toggleLines
		JMP	outerLoop
	
	f2Key:
		CALL	toggleForeground
		JMP	outerLoop
		
	f3Key:	
		CALL	toggleBackground
		JMP	outerLoop
		
	f6Key:
		CALL	slowAmount
		JMP	outerLoop
	
	f7Key:
		CALL	speedAmount
		JMP	outerLoop
		
	f8Key:
		CALL	SlowRate
		JMP	outerLoop
	
	f9Key:
		CALL	speedRate
		JMP	outerLoop
		
	RET
keyDown ENDP
;------------------------------------------------------------------------
terminateProj PROC
;On entry ESC key was pressed
;On exit the program terminates

	MOV	AH, 4Ch		; These instructions use an interrupt	
	INT	21h		; to release the memory for the project.
	
	RET
terminateProj ENDP
;------------------------------------------------------------------------
 moveLeft PROC
;On entry box is in previous possition
;On exit box will be moved left one DW
		
	PUSH BX CX
		MOV	CX, offsetUL	; move offset into CX
		CALL	rowCol		; get the col
		MOV	BX, zCol	; put col in BX
		CMP	BX, 0		; is row 0?
		JE	corner		; if so no moves

		SUB	CX, 2		; move UL left one place
		MOV	offsetUL, CX
		CALL	clearScreen
		PUSH CX
		CALL	drawBox		; redraw box 
		POP CX
	corner:	

	POP CX BX
	RET
moveLeft ENDP
;------------------------------------------------------------------------
 moveUp PROC
;On entry box is in previous position
;On exit box will be redrawn a line above previous position
;
	PUSH CX	
	
		MOV	CX, offsetUL	; move offset into CX
		CMP	offsetUL, 158
		JL	notUP
		SUB	CX, 160		; move offset up a row
		MOV	offsetUL, CX	; put new offset back into CX
		CALL	clearScreen
		PUSH CX	
		CALL	drawBox		; redraw box in new position
		POP CX
	notUP:
	
	POP CX
	RET
moveUp ENDP
;------------------------------------------------------------------------
moveRight PROC
;On entry box is in previous position
;On exit box will be shifted right a DW
;
	PUSH BX CX DX

		CALL	rowCol
		MOV	CX, zCol
		MOV	BH, 00
		MOV	BL, height
		ADD	BX, BX
		ADD	CX, BX
		MOV	DX, 80
		CMP	CX, DX
		JE	notRight
		MOV	CX, offsetUL
		ADD	CX, 2
		MOV	offsetUL, CX
		CALL	clearScreen
		PUSH CX
		CALL	drawBox
		POP CX
	notRight:

	POP DX CX BX
	RET
moveRight ENDP
;------------------------------------------------------------------------
moveDown PROC
;On entry
;On exit

	PUSH BX CX DX 

		MOV	CX, offsetUL		; UL corner in CX
		CALL	rowCol			; convert offset to R C
		MOV	BX, zRow		; put the UL row in BX
		MOV	DH, 00			; clear DH
		MOV	DL, height		; put height into DL
		ADD	BX, DX			; add height to UL
		CMP	BX, 25			; is row 25
		JE	notDOwn			; if so, do not move down
		
		ADD	CX, 160			; move the UL corner down 1
		MOV	offsetUL, CX		; put new UL into offset
		CALL	clearScreen
		PUSH CX		
		CALL	drawBox
		POP CX
		
	notDown:

	POP DX CX BX
	RET
moveDown ENDP
;------------------------------------------------------------------------
makeBigger PROC
;On entry
;On exit	
	PUSH DX CX BX 
	
		MOV	CX, offsetUL		; UL corner in CX
		CALL	rowCol			; convert offset to R C
		MOV	BX, zRow		; put the UL row in BX
		MOV	DH, 00			; clear DH
		MOV	DL, height		; put height into DL
		ADD	BX, DX			; add height to UL
		CMP	BX, 25			; is row 25
		JGE	notBigger		; if so not bigger
		
		MOV	BX, zCol		; put UL col in BX
		ADD	DX, DX			; put width in DX
		ADD	BX, DX			; add width to UL
		CMP	BX, 80			; is it 80
		JGE 	notBigger		; if so not bigger
		
		MOV	CH, 00h			; else clear CH
		MOV	CL, height		; put height in CL		
		ADD	CL, 1			; add 1 to height
		MOV	height, CL		; put the new height in height
		;CALL	clearScreen
		PUSH CX
		CALL	drawBox
		POP CX
	notBigger:

	POP BX CX DX
	RET
makeBigger ENDP
;------------------------------------------------------------------------
makeSmaller PROC
;On entry
;On exit
	PUSH CX
		MOV	CH, 00h
		MOV	CL, height
		CMP	CL, 6		; Is height 6?
		JE	doNothing	; Yes, do not shrink box anymore
		SUB	CL, 1		; if not, shrink box
		MOV	height, CL
		PUSH CX
		CALL	drawBox		; redraw box smaller
		POP CX
	doNothing:
	
	POP CX
	RET
makeSmaller ENDP
;------------------------------------------------------------------------
toggleLines PROC
;On entry default box is double line
;On exit line will change based on button press
;
	XOR	lineType, 1
	CALL	drawBox
	RET
toggleLines ENDP
;------------------------------------------------------------------------
toggleForeground PROC
;On entry FG color is the same, and put into CX
;On exit FG color changes. no registers are changed
;
		MOV	CH, 0000b
		MOV	CL, foreground
		ADD	CL, 1
		AND	CL, 1111b
		MOV	foreground, CL
		CALL	drawBox
	
	RET
toggleForeground ENDP
;------------------------------------------------------------------------
toggleBackground PROC
;On entry BG put into CL CX cleared
;On exit BG color changes, no registers are changed
;
		MOV	CH, 0000b
		MOV	CL, background
		ADD	CL, 1
		AND	CL, 1111b
		MOV	background, CL
		CALL	drawBox
	RET
toggleBackground ENDP
;------------------------------------------------------------------------
rowCol PROC
; on entry AX contains screen offset
; on exit offset is converted into a row and col
	PUSH AX BX DX
;zRow := x/160
	MOV	DX, 00h
	MOV	AX, offsetUL		; put offset into AX
	MOV	BX, 160			; put 160 into BX
	DIV	BX			; AX := DX:AX/BX
	MOV	zRow, AX		; put the row in zRow
;zCol := (x%160)/2
	SHR	DX, 1			; divide by 2			
	MOV	zCol, DX

	POP DX BX AX

	RET
rowCol ENDP
;------------------------------------------------------------------------
clearScreen PROC
; on entry previous box is on screen
; on exit screen has been cleared
    PUSH DI CX AX
        MOV     DI, 0
        MOV     CX, 2000
        MOV     AX, 0720h
    cls:
	MOV	ES:[DI], AX
	ADD	DI, 2
	SUB	CX, 2
	LOOP	cls
	
    POP AX CX DI

    RET
clearScreen ENDP
;------------------------------------------------------------------------
checkTime PROC
; on entry
; on exit
    PUSH CX
        MOV     readyToUpdate, 0
        MOV	AX, 0                  ; Get timer ticks
        INT     1Ah			   ; Interrupt
        MOV     AX, howOften	    
        ADD     nextTimeUpdate, AX
        CMP     DX, nextTimeUpdate
        JB      notYet

        MOV     readyToUpdate, 1
        MOV     CX, nextTimeUpdate
        ADD     CX, howOften	
        
        ;MOV    nextTimeUpdate, howOften
	;MOV    randNum, nextTimeUpdate
    notYet:	

    POP CX
    RET
checkTime ENDP
;------------------------------------------------------------------------
fakeScreenDown PROC
; on entry
; on exit

	PUSH ES			; save screen
	PUSH DS
	POP ES
	 PUSH CX
	LEA    SI, fakeScreen
	MOV    CX, offsetUL
	MOV    DS:[DI], CX
	;ADD	DS:[DI], 158
	
	STD		       
	MOV	CX, 3840	; first 24 lines to move
	REP MOVSW		; Moves one line into another
	
	POP CX ES

	RET
fakeScreenDown ENDP
;------------------------------------------------------------------------
fillTopLine PROC
; on entry CX contains loop counter
; on exit no registers are changed, and the top line has snow
    PUSH CX BX  
        LEA     DI, fakeScreen
        MOV     CX, 80
    topOfLoop:
        CALL    getRandNum
        MOV	BX, percentSnow
        CMP     BX, randNum
        JG      noFlake
       
        MOV	DS:[DI], WORD PTR '*' + 256*4
        
        INC	DI
        INC	DI
        
        DEC     CX
        CMP     CX, 0
        JG      topOfLoop
    noFlake:  
    	 MOV	DS:[DI], WORD PTR ' '
	DEC     CX
	JG      topOfLoop
    POP BX CX
	RET
fillTopLine ENDP
;------------------------------------------------------------------------
copyFakeToPortal PROC
; on entry
; on exit
    ;PUSH
        MOV     CH, 00h
        MOV     CL, height
    outerFakeLoop:
        PUSH DI
        MOV     CL, height
        ADD     CX, CX
        SUB     CX, 2
     innerFakeLoop:
        MOV     AX, [SI]
        MOV    DS:[DI], AX
        ADD    SI, 2
        ADD    DI, 2
        LOOP   innerFakeLoop
        POP DI
        ADD    DI, 160
        ADD    SI, 160
        LOOP   outerFakeLoop
     
    ;POP
    RET
copyFakeToPortal ENDP
;------------------------------------------------------------------------
slowAmount PROC
; on entry
; on exit  no registers are changed
MOV    ES:[160*8 + 64], WORD PTR '*' + 256*4
INC BYTE PTR ES:[160*16 +120]
    PUSH CX
	MOV     CX, percentSnow          ; Move percertage into CX
	CMP     CX, 0                    ; Is percentage 0?
	JE      noSNow                   ; If so, it can not snow.
        SUB     CX, 2                    ; Lower the percentage by 2
        MOV     percentSnow, CX          ; Put new percentage back
        CALL    fakeScreenDown
        CALL    fillTopLine
        CALL    copyFakeToPortal
    noSnow:	

    POP CX
	RET
slowAmount ENDP
;------------------------------------------------------------------------
speedAmount PROC
; on entry
; on exit no registers are changed
MOV    ES:[160*6 + 60], WORD PTR '*' + 256*4
INC BYTE PTR ES:[160*18 +80]
    PUSH CX
        MOV     CX, percentSnow          ; Move PS into CX
        CMP     CX, 100                  ; Is percentage 100?
        JE      blizzard                 ; If so, it is already a blizzard
        ADD     CX, 2                    ; Raise the percentage by 2
        MOV     percentSnow, CX          ; Put the new Percent back
        CALL    fakeScreenDown
        CALL    fillTopLine
        CALL    copyFakeToPortal
    blizzard:
    
    POP CX
	RET
speedAmount ENDP
;------------------------------------------------------------------------
slowRate PROC
; on entry
;on exit
MOV    ES:[160*4 + 60], WORD PTR '*' + 256*4
	INC BYTE PTR ES:[160*14 +60]
    PUSH CX
        MOV     CX, howOften          ; Move howOften to CX
        CMP     CX, 100               ; Is howOften 100?
        JE      noSlower              ; If so, don't go slower
        ADD     CX, 2                 ; ADD 2 from HO
        MOV     howOften, CX
        ;CALL    ????????
    noSlower:
    
    POP CX
	RET
slowRate ENDP
;------------------------------------------------------------------------
speedRate PROC
; on entry
; on exit no regitsers are changed
MOV    ES:[160*2 + 40], WORD PTR '*' + 256*4
INC BYTE PTR ES:[160*12 +82]
    PUSH CX
        MOV     CX, howOften          ; Move howOften to CX
        CMP     CX, 0                 ; Is howOften 0?
        JE      noFaster              ; If so, don't go faster
        SUB     CX, 2                 ; SUB 2 from HO
        MOV     howOften, CX
    noFaster:
    
    POP CX
	RET
speedRate ENDP
;------------------------------------------------------------------------
getRandNum PROC
; on entry randNum contains 0
; on exit no regitster are changed and a random num is put in randNum
; randNum := a * randNum + b

    PUSH AX CX DX
       MOV     AX, 419
       MOV     CX, randNum
       MUL     CX
       MOV     CX, 661
       ADD     AX, CX
       AND     AX, 1111111111b
       MOV     randNum, AX

    POP DX CX AX
    RET
getRandNum ENDP
;------------------------------------------------------------------------
 showFake PROC
     PUSH AX SI DI CX
         LEA     SI, fakeScreen
         MOV     DI, 0
         MOV     CX, 2000
     fakeScreenLoop:
         MOV     AX, [SI]
         MOV     ES:[DI], AX
         ADD     SI, 2
         ADD     DI, 2
         LOOP    fakeScreenLoop
     POP CX DI SI AX
     RET
showFake ENDP   
;------------------------------------------------------------------------
MyCode ENDS                        ; End Segment

END MainProg                      ; End of the main proc

