    DOSSEG
    .MODEL SMALL
    .STACK 32
    .DATA
nume DB 'Ion'
lenn equ $-nume
prenume DB 'Cezar'
lenm equ $-prenume
alfabet DB 'Bqmgp86CPe9DfNz7R1wjHIMZKGcYXiFtSU2ovJOhW41y5EkrqsnAxubTV03a=L/d'
encoded     DB  80 DUP(0)
temp        DB  '0x', 160 DUP(0)
fileHandler DW  ?
filename    DB  'in\in.txt', 0          ; Trebuie sa existe acest fisier 'in/in.txt'!
outfile     DB  'out\out.txt', 0        ; Trebuie sa existe acest director 'out'!
message     DB  80 DUP(0)
message_copie     DB  80 DUP(0)
msglen      DW  ?
padding     DW  0
iterations  DW  0 
x           DW  ?
x0          DW  ?
a           DW  0
b           DW  0
    .CODE
START:
    MOV     AX, @DATA
    MOV     DS, AX

    CALL    FILE_INPUT                  ; NU MODIFICATI!
    
    CALL    SEED                        ; TODO - Trebuie implementata

    CALL    ENCRYPT                     ; TODO - Trebuie implementata
    
    CALL    COPY_MESSAGE


    CALL    ENCODE                      ; TODO - Trebuie implementata
    
                                        ; Mai jos se regaseste partea de
                                        ; afisare pe baza valorilor care se
                                        ; afla in variabilele x0, a, b, respectiv
                                        ; in sirurile message si encoded.
                                        ; NU MODIFICATI!
    MOV     AH, 3CH                     ; BIOS Int - Open file
    MOV     CX, 0
    MOV     AL, 1                       ; AL - Access mode ( Write - 1 )
    MOV     DX, OFFSET outfile          ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    CALL    WRITE                       ; NU MODIFICATI!

    MOV     AH, 4CH                     ; Bios Int - Terminate with return code
    MOV     AL, 0                       ; AL - Return code
    INT     21H
FILE_INPUT:
    MOV     AH, 3DH                     ; BIOS Int - Open file
    MOV     AL, 0                       ; AL - Access mode ( Read - 0 )
    MOV     DX, OFFSET fileName         ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    MOV     AH, 3FH                     ; BIOD Int - Read from file or device
    MOV     BX, [fileHandler]           ; BX - File handler
    MOV     CX, 80                      ; CX - Number of bytes to read
    MOV     DX, OFFSET message          ; DX - Data buffer
    INT     21H
    MOV     [msglen], AX                ; Return: AX - number of read bytes

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H

    RET
SEED:
    MOV     AH, 2CH                     ; BIOS Int - Get System Time
    INT     21H
    ;3600*CH
    MOV AL,CH
    MOV AH,0
    MOV BX,3600
    PUSH DX
    MUL BX
    ;Rezultatul se afla in AX
    ;60*CL
    MOV SI,AX
    MOV AL,CL
    MOV AH,0
    MOV BX,60
    MUL BX
    ;Adunarea celor doua
    ADD SI,AX
    ;+DH
    POP DX
    MOV AX,0
    MOV AL,DH
    MOV AH,0
    ADD SI,AX
    MOV CX,DX
    ;Gata prima paranteza
    ;*100
    MOV AX,SI
    MOV BX,100
    MUL BX
    ;+DL
    
    MOV BX,0
    MOV BL,CL    
    ADD AX,BX
    ;MOD 255
    MOV BX,255
    DIV BX
    ;restul impartirii ramane in DX
    MOV [x0],DX
    MOV AX,[x0]
    MOV [x],AX
    ;Calculare a
    MOV AX,0 
    MOV DX,0
    MOV CX,0
    MOV SI, OFFSET prenume
    MOV CX,lenm
    LOOP_A:
    MOV BX,[SI]
    MOV BH,0
    ADD AX,BX
    INC SI
    LOOP LOOP_A
    MOV BX,255
    DIV BX
    MOV [a],DX
    ;Calculare b
    MOV AX,0
    MOV DX,0
    MOV CX,lenn
    MOV SI,OFFSET nume
    LOOP_B:
    MOV BX,[SI]
    MOV BH,0
    ADD AX,BX
    INC SI
    LOOP LOOP_B 
    MOV BX,255
    DIV BX
    MOV [b],DX
  
    RET
ENCRYPT:
    MOV     CX, [msglen]
    MOV     SI, OFFSET message
    XOR_EN:
    
    MOV AX,[SI]
    MOV BH,AH
    MOV AH,0
    XOR AX,[x]
    MOV AH,BH
    MOV [SI],AX
    INC SI   
    CALL RAND
    LOOP XOR_EN

    RET

RAND:
    MOV     AX, [x]
    MOV BX,[a]
    MUL BX
    MOV BX,[b]
    ADD AX,BX
    MOV BX,255
    DIV BX
    MOV [x],DX
       
   
    RET
COPY_MESSAGE:
    MOV CX,[msglen]
    MOV SI,OFFSET message
    MOV DI,OFFSET message_copie
    LOOP_COPY:
    MOV AX,[SI]
    MOV [DI],AX
    INC SI 
    INC DI 
    LOOP LOOP_COPY
    RET
ENCODE:
    MOV CX,0
    MOV SI,OFFSET message_copie
    MOV AX,[msglen]
    MOV BL,3
    DIV BL
    ;restul ramane in AH,catul in AL
    
    MOV CL,AL
    MOV [iterations],0
    MOV DI,OFFSET alfabet
    CMP AH,0
    JE L_3BLOCK
    L_3BLOCK:
    ;aducem primul octet din mesajul criptat si shiftam la dreapta cu 2 pozitii
    MOV AX,[SI]
    MOV AH,0
    MOV BX,AX
    ;shiftam la dreapta cu 2 biti, pentru a retine primul calup de 6 biti
    SHR AL,2
    ;acum avem primii 6 biti, adica primul caracter din encoded
    ADD DI,AX
    MOV AX,[DI]
    MOV AH,0
    PUSH SI 
    MOV SI,OFFSET encoded
    ADD SI,[iterations]
    MOV DX,[DI]
    MOV DH,0
    MOV [SI],DX
    POP SI
    ;salvam in BX care acum contine AX-ul initial,ultimii doi biti din AX
    AND BL,00000011b
    ;aducem urmatorul octet
    INC SI
    MOV AX,[SI]
    MOV AH,0
    ;salvam in DX acest octet
    MOV DX,AX
    ;shiftam cu 4 pozitii la dreapta
    SHR AL,4
    ;adaugam ultimii 2 biti din primul octet
    SHL BL,4
    ADD AL,BL 
    ;am format al doilea calup de 6 biti
    MOV DI,OFFSET alfabet
    ADD DI,AX    
    PUSH SI 
    MOV SI,OFFSET encoded
    ADD SI,[iterations]
    INC SI
    MOV BX,[DI]
    MOV BH,0
    MOV [SI],BX
    POP SI
    ;aducem si al treilea octet
    INC SI
    MOV AX,[SI]
    MOV AH,0 
    ;shiftam cu 6 poztii, pentru a retine primii 2 biti
    SHR AL,6
    ;adaugam ultimii 4 biti de la precedentul octet
    AND DL,00001111b
    SHL DL,2
    ADD DL,AL
    MOV DH,0
    ;iar acum avem al treilea calup de 6 biti in AX
    MOV DI,OFFSET alfabet
    ADD DI,DX
    CALL ADD_PENULTIMUL_OCTET
    CALL ULTIMUL_OCTET
    ADD [iterations],3
    LOOP L_3BLOCK
    JMP JMP_RET
    ADD_PENULTIMUL_OCTET:
        MOV DI,OFFSET alfabet
    ADD DI,DX
    PUSH SI 
    MOV SI,OFFSET encoded
    ADD SI,[iterations]
    ADD SI,2
    MOV BX,[DI]
    MOV BH,0
    MOV [SI],BX
    POP SI
    RET
    ULTIMUL_OCTET:
    MOV AX,[SI]
    MOV AH,0
    AND AL,00111111b
    MOV AH,0
    MOV DI,OFFSET alfabet
    ADD DI,AX
    MOV BX,[DI]
    MOV BH,0
    PUSH SI
    MOV SI,OFFSET encoded
    ADD SI,[iterations]
    ADD SI,3
    MOV [SI],BX
    ADD [iterations],1
    POP SI
    RET
JMP_RET:
    
                        
    RET
WRITE_HEX:
    MOV     DI, OFFSET temp + 2
    XOR     DX, DX
DUMP:
    MOV     DL, [SI]
    PUSH    CX
    MOV     CL, 4

    ROR     DX, CL
    
    CMP     DL, 0ah
    JB      print_digit1

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     next_digit

print_digit1:  
    OR      DL, 30h
    MOV     byte ptr [DI] ,DL
next_digit:
    INC     DI
    MOV     CL, 12
    SHR     DX, CL
    CMP     DL, 0ah
    JB      print_digit2

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     AGAIN

print_digit2:    
    OR      DL, 30h
    MOV     byte ptr [DI], DL
AGAIN:
    INC     DI
    INC     SI
    POP     CX
    LOOP    dump
    
    MOV     byte ptr [DI], 10
    RET
WRITE:
    MOV     SI, OFFSET x0
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21h

    MOV     SI, OFFSET a
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET b
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET x
    MOV     CX, 1
    CALL    WRITE_HEX    
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET message
    MOV     CX, [msglen]
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, [msglen]
    ADD     CX, [msglen]
    ADD     CX, 3
    INT     21h

    MOV     AX, [iterations]
    MOV     BX, 4
    MUL     BX
    MOV     CX, AX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET encoded
    INT     21H

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H
    RET
    END START