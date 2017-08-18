
MyStack SEGMENT STACK              ; Keyword "STACK" required

        DW 256 DUP (?)             ; A stack of nothing special.

MyStack ENDS                       ; End Segment

;------------------------------------------------------------------------
MyData SEGMENT



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
    
   
    MOV	    CL, 25		   ; Variable to control the outer loop
    
    MOV    SI, 0		; Points to first spot &
    MOV    DI, 158		; points to last spot in the rows
    
    topOfLoop:
    	    CALL   flipRow	; Call to the flipRow fucntion
    	    
    	    ADD    SI, 160	; Moves the pointer to the next line
    	    ADD    DI, 160  	; Moves the last pointer to the next line
    	    
    	    DEC	   CL		; Dec the loop so it stops at 25
    	    CMP    CL, 0	; Is it the bottom of screen?
    	    JG     topOfLoop	; No, do it again.
    	  	    

    MOV     AH, 4Ch                ; These instructions use an interrupt
    INT     21h                    ; to release the memory for the project.
                                   
                                   	    
MainProg ENDP
;------------------------------------------------------------------------
flipRow PROC
    PUSH   AX BX CX SI DI
      MOV    CH, 40		   ; Variable to control inner loop
 
    flipLoop:
    	    MOV    AX, ES:[SI]	   ;These two lines point to each 
    	    MOV    BX, ES:[DI]	   ;side of the screen.
    	    
    	    CMP    AH, 'A'	   ; Is the char between A and Z?
	    JL	   color	   ; If not, color it.
	    CMP    AH, 'Z'	   ; char between A and Z?
	    JLE	   continue	   ; If yes, do not color.
	    CMP	   AH, 'a'         ; **Is char between a and z?
	    JL 	   color 	   ; If not, color.
	    CMP	    AH, 'z'	   ;**
	    JLE	    continue	   ; If yes, do not color.
	    
	    color:
	          MOV	AH, BYTE PTR 01111100b
	    	
	    continue:
	    	    CMP	    BH, 'A'		; Is the char between A and Z?
	    	    JL	    color2		; If not, color it.
	    	    CMP	    BH, 'Z'		; char between A and Z?
	    	    JLE	    done		; If yes, do not color.
	    	    CMP	    BH, 'a'		; **Is char between a and z?
	    	    JL 	    color2		; If not, color.
	    	    CMP	    BH, 'z'		;**
	            JLE	    done		; If yes, do not color.
	            
	     color2:
	     	    MOV	    BH, BYTE PTR 01111100b
	     	
	    
		done:
			;MOV    ES:[160*4 + 140], WORD PTR '*' + 256*4		;Debugging
    			;INC BYTE PTR ES:[160*20 +82]				;Debugging
	
    	    
    	    MOV    ES:[DI], AX     ; These two swap the screen 
    	    MOV    ES:[SI], BX	   ; horizontally.
    	    
    	    ADD    SI, 2	 ; Advances the screen flip forward
    	    SUB    DI,2		 ; De-vances the screen flip backward
    	    
    	    DEC	   CH		 ; Stops the screen in the middle
	    CMP    CH, 0	 ; Is it the end of the loop?
    	    JG     flipLoop	 ; No, go back and do it again.
    	    
    POP    DI SI CX BX AX
    RET
flipRow ENDP
;------------------------------------------------------------------------
MyCode ENDS                        ; End Segment

END MainProg                      ; End of the main proc



