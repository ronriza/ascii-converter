TITLE Program Template     (template.asm)

; Author: 
; Last Modified:
; OSU email address: ONID_ID@oregonstate.edu
; Course number/section:   CS271 Section ???
; Project Number:                 Due Date:
; Description: This file is provided as a template from which you may work
;              when developing assembly projects in CS271.

INCLUDE Irvine32.inc

mGetString MACRO prompt, bufferSize, bufferAddress, bytesEntered

pushad
mov EDX, prompt
call WriteString
mov EDX, bufferAddress
mov ECX, bufferSize
call ReadString
mov EBX, bytesEntered
mov [EBX], EAX

popad
ENDM

mDisplayString MACRO stringLocation
push EDX
mov EDX, stringLocation
call WriteString
pop EDX
ENDM




MAXSIZE = 15
NUM_OF_INPUTS = 2

.data

userPrompt BYTE "Please enter a signed number: ",0
inputString  	BYTE MAXSIZE DUP(?)
stringLen	DWORD ?
inputArray	SDWORD 10 DUP(?)
inputError BYTE "Error: You did not enter an signed number or your number was too big.",13,10,0
outputString BYTE MAXSIZE DUP(?)
revString BYTE MAXSIZE DUP(?)
space BYTE " ",0
introduction BYTE "PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,"Written by: Ron Riza",13,10,13,10
				BYTE "Please enter 10 signed decimal integers.",13,10,"Each number must be able to fit in a 32-bit register. After you have",13,10
				BYTE "entered your numbers, I will display the numbers back to you, along with their sum and average",13,10,13,10,0
enteredString BYTE "You have entered the following numbers:",13,10,0
sumString BYTE "The sum of these numbers is: ",0
averageString BYTE "The rounded average is: ",0
farewell BYTE "Thanks for playing!",0


.code
main PROC
mDisplayString OFFSET introduction


mov EDI, OFFSET inputArray
mov ECX, NUM_OF_INPUTS

_inputLoop:

push OFFSET inputError
push EDI
push OFFSET stringLen
push OFFSET inputString
push MAXSIZE
push OFFSET userPrompt
call ReadVal

add EDI, 4

LOOP _inputLOOP
call Crlf

mDisplayString OFFSET enteredString

mov ESI, OFFSET inputArray
mov ECX, NUM_OF_INPUTS

_outputLoop:
push OFFSET revString
push OFFSET outputString
push [ESI]
call WriteVal
mDisplayString OFFSET space
add ESI, 4
LOOP _outputLoop
call Crlf

mDisplayString OFFSET sumString

mov ESI, OFFSET inputArray
mov ECX, NUM_OF_INPUTS
mov EAX, 0
_sumLoop:
add EAX, [ESI]
add ESI, 4
LOOP _sumLoop
push OFFSET revString
push OFFSET outputString
push EAX
call WriteVal
call Crlf

mDisplayString OFFSET averageString
CDQ
mov EBX, NUM_OF_INPUTS
IDIV EBX


;_print:
push OFFSET revString
push OFFSET outputString
push EAX
call WriteVal
call Crlf
call Crlf

mDisplayString OFFSET farewell



	Invoke ExitProcess,0	; exit to operating system
main ENDP


; --------------------------------
; EBP+8: user prompt
; EBP+12: MAXSIZE
; EBP+16: inputString
; EBP+20: string length
; EBP+24: number storage
; EBP+26: error message

;-----------------------------------
ReadVal PROC
push EBP
mov EBP, ESP
pushad

_askAgain:
mGetString [EBP+8], [EBP+12], [EBP+16], [EBP+20]
mov ESI, [EBP+16]
mov EDI, [EBP+24]
mov ECX, [EBP+20]
mov ECX, [ECX]
mov EBX, 0
mov EAX, 0
CLD

LODSB

cmp AL, 45
je _negativeCheckLength
cmp AL, 43
je _positiveCheckLength
jmp _positiveLoop

_negativeCheckLength:
cmp ECX, 1
je _invalid
jmp _negativeNext

_positiveCheckLength:
cmp ECX, 1
je _invalid
jmp _positiveNext




_positiveLoop:
cmp Al, 48
jl _invalid

cmp AL, 57
jg _invalid

sub AL, 48
imul EBX, 10
jo _invalid
add EBX, EAX
jo _invalid

_positiveNext:

LODSB
LOOP _positiveLoop


jmp _end



_negativeLoop:

cmp Al, 48
jl _invalid

cmp AL, 57
jg _invalid

sub AL, 48
imul EBX, 10
jo _invalid
js _negative
imul EBX, -1
_negative:
sub EBX, EAX
jo _invalid

_negativeNext:

LODSB
LOOP _negativeLoop

jmp _end


_invalid:
mDisplayString [EBP+28]				
jmp _askAgain

_end:
mov [EDI], EBX

popad
pop EBP
RET 24
ReadVal ENDP

;------------------------
; EBP+8: value
; EBP+12: output string
; EBP+16: reversed string

;-------------------------

WriteVal PROC
push EBP
mov EBP, ESP

pushad

mov EAX, [EBP+8]
mov EDI, [EBP+12]
mov ECX, 0

cmp EAX, 0
jl _negativeLoop

_positiveLoop:

CDQ
mov EBX, 10
IDIV EBX
add EDX, 48
mov [EDI], DL
add EDI, 1
add ECX, 1
cmp EAX, 0
jne _positiveLoop
mov [EDI], BYTE PTR 0
jmp _reverse



_negativeLoop:
CDQ
mov EBX, 10
IDIV EBX
NEG EDX
add EDX, 48
mov [EDI], DL
add EDI, 1
add ECX, 1
cmp EAX, 0
jne _negativeLoop


jne _negativeLoop
mov [EDI], BYTE PTR 45
add EDI, 1
add ECX, 1
mov [EDI], BYTE PTR 0




_reverse:
mov ESI, [EBP+12]
mov EDI, [EBP+16]
add ESI, ECX
dec ESI

_revLoop:
STD
LODSB
CLD
STOSB
LOOP _revLoop
mov [EDI], BYTE PTR 0


mDisplayString [EBP+16]



popad
pop EBP
RET 12

WriteVal ENDP




END main
