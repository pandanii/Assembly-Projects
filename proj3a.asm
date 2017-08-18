MyStack SEGMENT STACK              ; Keyword "STACK" required

        DW 256 DUP (?)             ; A stack of nothing special.

MyStack ENDS                       ; End Segment
;------------------------------------------------------------------------
MyData SEGMENT

    inFile      DB    10 DUP (?) 
    ;inFile      DB    "numbers.txt", 0
    fileName    DB    "output.dat" , 0
    numNum      DW    ?
    buffer      DB    ?
    outBuffer   DB    10 DUP(5 DUP (' '), 13, 10)    
    outBuffSize EQU   $-outBuffer
    handle      DW    ?
    outHandle   DW    ?
    brackets    DW    10 DUP (3)
    openError   DW    ?
    EOFflag     DB    0

MyData ENDS                        ; End Segment
;------------------------------------------------------------------------
MyCode SEGMENT
        ASSUME CS:MyCode, DS:MyData    ; Tell the assembler what segments the segment 
                                       ; registers refer to in the following code.

MainProg  PROC                     ; This serves as the "user transfer address".

    MOV     AX, MyData             ; Make DS address a data segment.  Two statements
    MOV     DS, AX                 ; required since it is illegal to move
                                   ; data directly into a segment register.
    CALL    getFileName

    MOV     AX, 0B800h             ; Makes ES a segment register address for screen memory.
    MOV     ES, AX
   
    CALL    openFile
mainLoop:    
    CALL    getNextNum
    CALL    putInBrackets
    CMP     EOFflag, 0
    JE      mainLoop
    CALL    closeInFile
    CALL    createOutputFile
    CALL    convertNumberToAscii
    CALL    writeOutputFile
    CALL    closeFile
   
    MOV     AH, 4Ch                ; These instructions use an interrupt    
    INT     21h                    ; to release the memory for the project.
                                       
                                            
MainProg ENDP
;------------------------------------------------------------------------
openFile PROC
PUSH AX DX

    MOV    AH, 3Dh        ; open file
    LEA    DX, inFile 
    INT    21h
    MOV    handle, AX
    JC     errorOpen
    JMP    openDone
errorOpen:
     MOV    ES:[160*24 + 140], WORD PTR 'E' + 256*12
openDone:
 
POP DX AX
    RET
openFile ENDP
;------------------------------------------------------------------------
closeInFile PROC
  PUSH AX BX
    MOV    AH, 3Eh       ; close the file
    MOV    BX, handle
    INT    21h
    JC     errorClose
    JMP    closedIn
errorClose:    
    MOV    ES:[160*5 + 64], WORD PTR 'C' + 256*4    
closedIn:

  POP BX AX  
    RET
closeInFile ENDP    
;------------------------------------------------------------------------
readFile PROC

    PUSH AX BX CX 
    MOV    CX, 1           ; read exactly one byte
    MOV    AH, 3Fh         ; read file
    LEA    DX, buffer          ; load buffer into dx
    MOV    BX, handle
    INT    21h
    JC     errorInRead

    CMP    AX, 0           ; is ax 0
    JG     readDone        ; if not, done
    MOV    EOFflag, 1          ; if so quit
    JMP    readDone

errorInRead:
     MOV    ES:[160*24 + 140], WORD PTR 'R' + 256*12
     MOV    EOFflag, 1
readDone:

    POP  CX BX AX
    RET
 readFile ENDP
;------------------------------------------------------------------------
getNextNum PROC
 PUSH AX BX CX DX

    MOV    BH, 0 
nextNumTop:    
    CALL   readFile      ; read 1 byte of the file
    CMP    EOFflag, 1        ; check for EOFflag
    JE     endGet        ; if EOFflag, quit
    MOV    BL, buffer        ; if not move buffer into dl
    CMP    BL, ' '       ; compare dl to whitespace
    JLE    nextNumTop        ; if not white space find numS

   
    MOV    AX, 0
    MOV    CX, 10
convertLoop:  

    MUL    CX
    SUB    BL, '0'
    ADD    AX, BX

    CALL   readFile
    CMP    EOFflag, 1 
    JE     endGet
    MOV    BL, buffer        ; if not move buffer into d
    CMP    BL, ' '
    JlE    endGet
    JMP    convertLoop

endGet:
    MOV    numNum, AX
 POP DX CX BX AX
    RET
getNextNum ENDP    
;------------------------------------------------------------------------
createOutputFile PROC

   MOV    ES:[160*20 + 4], WORD PTR '%' + 256*12 
   
  PUSH AX CX DX
    MOV    AH, 3Ch      ; create file
    LEA    DX, fileName
    MOV    CL, 0         ; attributes
    INT    21h
    MOV    outHandle, AX
    JC     errorInOpen
    JMP    createDone
errorInOpen:
    MOV    ES:[160*24 + 64], WORD PTR 'I' + 256*12
createDone:

  POP DX CX AX  
    RET
createOutputFile ENDP    
;------------------------------------------------------------------------
writeOutputFile PROC
MOV    ES:[160*22 + 4], WORD PTR '%' + 256*12

PUSH AX BX CX DX

    MOV    AH, 40h        ; write to file
    MOV    BX, outHandle
    MOV    CX, outBuffSize
    LEA    DX, outBuffer
    INT    21h
    JC     errorInWrite
    JMP    writeDone

errorInWrite:
    MOV    ES:[160*4 + 64], WORD PTR 'T' + 256*4
writeDone:

POP DX CX BX AX
     RET
writeOutputFile ENDP
;------------------------------------------------------------------------
closeFile PROC
  PUSH AX BX
    MOV    AH, 3Eh       ; close the file
    MOV    BX, outHandle
    INT    21h
    JC     errorInClose
    JMP    closed
errorInCLose:    
    MOV    ES:[160*5 + 64], WORD PTR 'C' + 256*4    
closed:

  POP BX AX  
    RET
closeFile ENDP    
;------------------------------------------------------------------------
convertNumberToAscii PROC

PUSH AX BX CX DX
    LEA    SI, brackets
    LEA    DI, [outBuffer+4]
    MOV    CX, 10
    MOV    BX, 10
    MOV    DX, 0
process:
    MOV    AX, [SI]      ; get next digit

    PUSH DI 
    
innerLoop:

    MOV    DX, 0
    DIV    BX         ;
    ADD    DX, '0'
    MOV    [DI], DL
    DEC    DI
    CMP    AX, 0
    JNE     innerLoop

    POP DI
    ADD    DI, 7
    ADD    SI, 2
    DEC    CX
    CMP    CX, 0
    JG    process

 doneConvert:
 

    POP DX CX BX AX 
    RET
convertNumberToAscii ENDP    
;------------------------------------------------------------------------
getFileName PROC
; ES:[80] contains length of command tail
PUSH BX CX DI SI
    LEA    DI, inFile
    MOV    SI, 80h
    MOV    CH, 0
    MOV    CL, ES:[SI]
    ADD    SI, 2
    DEC    CX
copyName:
    MOV    BL, ES:[SI]
    MOV    [DI], BL
    INC    SI
    INC    DI
    LOOP   copyName
    
    MOV    [DI], BYTE PTR 0
POP SI DI CX BX
    RET
getFileName ENDP
;------------------------------------------------------------------------
putInBrackets PROC
; on entry numNum contains value to be counted
    PUSH AX BX CX DX
    MOV    CX, 10
    MOV    DX, 0

    MOV    AX, numNum

    CMP    AX, 0
    JNE     pib1
    INC    brackets
    JMP    endBrackets
pib1:    
    SUB    AX, 1
    MOV    BX, 100
    DIV    BX
    LEA    DI, brackets
    ADD    DI, AX
    SUB    CX, AX
    ADD    DI, AX
bracketsLoop:
    INC    WORD PTR [DI]
    ADD    DI, 2
    LOOP   bracketsLoop
    
endBrackets:    
    
    POP DX CX BX AX
    RET
putInBrackets ENDP
;------------------------------------------------------------------------
MyCode ENDS                        ; End Segment

END MainProg                      ; End of the main proc