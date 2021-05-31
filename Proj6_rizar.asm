TITLE Designing low level I/O procedures  (Proj6_rizar.asm)

; Author: Ron Riza
; Last Modified: 5/31/21
; OSU email address: rizarD@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:       6          Due Date: 6/7/21
; Description: This program contains procedures ReadVal, which converts an ascii string
; entered by a user into a numerical value, and WriteVal, which convers a numerical value
; into a string and displays it to a user. The main procedure prompts a user for 10 signed numbers,
; converts them into integers, and then displays them along with their sum and average.

INCLUDE Irvine32.inc


;-------------------------
; Name: mGetString
; Prompts user to enter a string and reads it
; Receives:
; prompt = address of user prompt
; bufferSize = value of maximum allowed size
; bufferAddress = address of memory location for string to be stored
; bytesEntered = address of memory location for string length to be stored
;----------------------------
mGetString MACRO prompt, bufferSize, bufferAddress, bytesEntered
	pushad

	mov  EDX, prompt
	call WriteString
	mov  EDX, bufferAddress
	mov  ECX, bufferSize
	call ReadString
	mov  EBX, bytesEntered				
	mov  [EBX], EAX

	popad
ENDM

;-----------------------------
; Name: mDisplayString
; Prints a string
; Receives: stringLocation = address of string to be printed
;-------------------------------
mDisplayString MACRO stringLocation
	push EDX

	mov  EDX, stringLocation
	call WriteString

	pop  EDX
ENDM



MAXSIZE = 15
NUM_OF_INPUTS = 2

.data

userPrompt		BYTE   "Please enter a signed number: ",0
inputError		BYTE   "Error: You did not enter an signed number or your number was too big.",13,10,0
space			BYTE   " ",0
introduction    BYTE   "PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,"Written by: Ron Riza",13,10,13,10
				BYTE   "Please enter 10 signed decimal integers.",13,10,"Each number must be able to fit in a 32-bit register. After you have",13,10
				BYTE   "entered your numbers, I will display the numbers back to you, along with their sum and average",13,10,13,10,0
enteredString	BYTE   "You have entered the following numbers:",13,10,0
sumString		BYTE   "The sum of these numbers is: ",0
averageString	BYTE   "The rounded average is: ",0
farewell		BYTE   "Thanks for playing!",0
inputString  	BYTE   MAXSIZE DUP(?)			; buffer for input string
stringLen		DWORD  ?						; holds the length of string entered
inputArray		SDWORD NUM_OF_INPUTS DUP(?)		; array of user-entered numbeers
outputString	BYTE   MAXSIZE DUP(?)			; string to be printed
revString		BYTE   MAXSIZE DUP(?)			; reversed string (for computational purposes)


.code
main PROC

	mDisplayString OFFSET introduction

; ----------------------------
; repeatedly asks a user to enter a number,
; converts the entered string into an integer,
; and stores that number into an array
;--------------------------------
	mov EDI, OFFSET inputArray					; sets destination to input array
	mov ECX, NUM_OF_INPUTS						; sets loop counter

_inputLoop:

	push OFFSET inputError
	push EDI
	push OFFSET stringLen
	push OFFSET inputString
	push MAXSIZE
	push OFFSET userPrompt
	call ReadVal
	add  EDI, 4									; moves to next element of array
	LOOP _inputLOOP

	call Crlf

;-----------------------
; prints each number in the array
;------------------------
	mDisplayString OFFSET enteredString

	mov ESI, OFFSET inputArray					; sets source to input array
	mov ECX, NUM_OF_INPUTS						; sets loop counter

_outputLoop:
	push OFFSET revString
	push OFFSET outputString
	push [ESI]
	call WriteVal								; prints current element
	mDisplayString OFFSET space
	add  ESI, 4									; moves to next element of array
	LOOP _outputLoop
	call Crlf

;------------------------------
; prints the sum of the numbers in the array
;--------------------------------
	mDisplayString OFFSET sumString

	mov ESI, OFFSET inputArray					; sets source to input array
	mov ECX, NUM_OF_INPUTS						; sets loop counter
	mov EAX, 0									; initializes the sum to 0

_sumLoop:
	add  EAX, [ESI]								; adds current element to sum
	add  ESI, 4									; moves to next element
	LOOP _sumLoop

	push OFFSET revString
	push OFFSET outputString
	push EAX
	call WriteVal								; prints total sum
	call Crlf

;----------------------------
; prints the truncated average (without fractional part)
; of the numbers in the input array
;---------------------------
	mDisplayString OFFSET averageString
	CDQ
	mov  EBX, NUM_OF_INPUTS
	IDIV EBX									; divide sum (still in EAX) by number of inputs

	push OFFSET revString
	push OFFSET outputString
	push EAX									; EAX holds the average (without fractional part)
	call WriteVal								; prints average)
	call Crlf
	call Crlf

	mDisplayString OFFSET farewell

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; --------------------------------
; Name: ReadVal
; Asks a user to input a number, and converts the ascii characters into an SDWORD integer. 
;Receives:
;	[EBP+8]: address of user prompt string
;	[EBP+12]: value of maximum allowed size
;	[EBP+16]: address of input string buffer
;	[EBP+20]: address of memory loction for string length to be stored
;	[EBP+24]: address of memory location for number to be stored
;	[EBP+26]: address of error message string
;Returns: number and string length stored in memory
;-----------------------------------
ReadVal PROC
	push EBP
	mov  EBP, ESP
	pushad

_askAgain:
	mGetString [EBP+8], [EBP+12], [EBP+16], [EBP+20]
	mov ESI, [EBP+16]								; source is address of string
	mov EDI, [EBP+24]								; destination is address of integer
	mov ECX, [EBP+20]								; moves address of string length into ECX
	mov ECX, [ECX]									; moves value of string length into ECX
	mov EBX, 0										; EBX will hold the integer at the end of conversion
	mov EAX, 0										; clears EAX
	
;-----------------------------
; This conversion algorithm has 2 seperate loops:
; one for positive numbers and one for negative numbers.
; We determine which loop to use by looking at the first
; character of the string. If no symbol was entered we
; assume it is positive.
;---------------------------------
	CLD
	LODSB

	; checks if first character is (-) or (+)
	cmp AL, 45								
	je  _negativeCheckLength						; if first element is (-) we must check the length
	cmp AL, 43
	je  _positiveCheckLength						; if first element is (+) we must check the length
	jmp _positiveLoop								; if first element is not (-) or (+) we move on to positive loop

_negativeCheckLength:
	cmp ECX, 1
	je  _invalid									; if first char is (-) and length is 1, number is invalid
	jmp _negativeNext								; otherwise, number is negative and we can move to next character

_positiveCheckLength:
	cmp ECX, 1
	je  _invalid									; if first char is (+) and length is 1, number is invalid
	jmp _positiveNext								; otherwise, number is positive and we can mvoe to next character

; ---------------------
; positive conversion loop in pseudocode:
; EBX = 0
; for char in string:
;	if 48 <= char <= 57:
;		EBX = 10 * EBX + (char-48)
;---------------------------
_positiveLoop:
	; checks if char is a digit
	cmp Al, 48
	jl  _invalid									
	cmp AL, 57
	jg  _invalid								
	
	; update EBX
	sub  AL, 48										
	imul EBX, 10									
	jo   _invalid									; if there is an overflow, entered number cannot fit in 32-bit register
	add  EBX, EAX
	jo   _invalid									; checks overflow again

_positiveNext:
	LODSB											; moves to next char
	LOOP _positiveLoop
	jmp  _end

; ---------------------
; negative conversion loop in pseudocode:
; EBX = 0
; for char in string:
;	if 48 <= char <= 57:
;		EBX = 10 * EBX - (char-48)
;---------------------------
_negativeLoop:
	; checks if char is a digit
	cmp Al, 48
	jl  _invalid
	cmp AL, 57
	jg  _invalid

	; updates EBX
	sub  AL, 48
	imul EBX, 10
	jo   _invalid								; if there is an overflow, entered number cannot fit in 32-bit register
	sub  EBX, EAX
	jo   _invalid								; check overflow again

_negativeNext:
	LODSB										; moves to next char
	LOOP _negativeLoop
	jmp  _end

_invalid:
	mDisplayString [EBP+28]						; error message is printed
	jmp _askAgain								; user is asked to enter another number

_end:
	mov [EDI], EBX								; moves the result into the memory address specified

	popad
	pop EBP
	RET 24
ReadVal ENDP

;------------------------
; Name: WriteVal
; Converts and SDWORD integer into a string and prints it 
; Receives:
;	[EBP+8]: value of integer to be converted
;	[EBP+12]: address output string
;	[EBP+16]: address of reversed string (for computation purposes)
;-------------------------
WriteVal PROC
	push EBP
	mov  EBP, ESP
	pushad

;----------------------------
; String is first written in reverse order. It is then
; reversed for the final output string
;-----------------------------------
	mov EAX, [EBP+8]							; moves integer into EAX
	mov EDI, [EBP+16]							; destination is set to reversed string buffer
	mov ECX, 0									; ECX is used to keep track of string length

	cmp EAX, 0
	jl  _negativeLoop							; if number is negative, we use the negative loop

;----------------------------------
; this conversion algorithm has 2 seperate loops:
; one for positive numbers and one for negative numbers.
; the positive loop will repeatedly divide the number by 10.
; the remainder is the last current digit.  it then adds 48 to the remainder 
; to get the ascii value of the digit. it then stores this value in the string.
; ----------------------------------------------------

_positiveLoop:
	CDQ
	mov  EBX, 10
	IDIV EBX									; divide by 10
	add  EDX, 48								; add 48 to remainder to convert to ascii
	push EAX									
	mov  AL, DL									; moves the ascii value into the accumulator
	STOSB									    ; stores the ascii value in the string
	pop  EAX
	add  ECX, 1									; increments the string length counter
	cmp  EAX, 0									
	jne  _positiveLoop

	mov  [EDI], BYTE PTR 0						; null terminate the string
	jmp  _reverse

;------------------------------------
; The negative loop behaves similarly to the 
; positive loop, except after each division,
; the remainder is negated (because if the dividend
; is negative, IDIV will produce a negative remainder).
;-----------------------------------------
_negativeLoop:
	CDQ
	mov  EBX, 10
	IDIV EBX
	NEG  EDX
	add  EDX, 48
	push EAX									
	mov  AL, DL									
	STOSB									    
	pop  EAX
	add  ECX, 1
	cmp  EAX, 0
	jne  _negativeLoop

	mov [EDI], BYTE PTR 45						; adds negative sign to the end of string
	add EDI, 1
	add ECX, 1
	mov [EDI], BYTE PTR 0						; null terminate string

_reverse:
	mov ESI, [EBP+16]							; sets the source to the reversed string
	mov EDI, [EBP+12]							; sets the destination to the output string
	add ESI, ECX								
	dec ESI										; sets ESI to the last character in reversed string

_revLoop:
	STD											
	LODSB										
	CLD											
	STOSB										
	LOOP _revLoop
	mov [EDI], BYTE PTR 0						; null terminates string

	mDisplayString [EBP+12]						; prints string

	popad
	pop EBP
	RET 12

WriteVal ENDP


END main
