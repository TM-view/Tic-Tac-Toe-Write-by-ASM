.include "m328Pdef.inc"        ; รวมไฟล์กำหนดค่าพื้นฐานของไมโครคอนโทรลเลอร์ ATmega328P

.cseg                        ; ระบุว่าโค้ดต่อไปนี้อยู่ในส่วนของโค้ด (code segment)

.def temp    = r16           ; ตัวแปรชั่วคราว
.def choice1 = r17           ; ตัวเลือกผู้เล่น 1
.def choice2 = r18           ; ตัวเลือกผู้เล่น 2
.def score1  = r19           ; คะแนนผู้เล่น 1
.def score2  = r20           ; คะแนนผู้เล่น 2
.def check   = r21           ; ตัวแปรตรวจสอบจำนวนบิต
.def invalid = r22           ; ตัวแปรบอกความผิดพลาด

.org 0x0000
rjmp Setup

.org 0x0006
rjmp Interrupt

;======================
; SETUP
;======================
Setup:
    ldi temp, 0x00
    out DDRC, temp

    ldi temp, 0xFF
    out DDRD, temp

    ldi temp, 0x0F
    out DDRB, temp

    ldi temp, 0x01
    sts PCICR, temp

    ldi temp, 0x10
    sts PCMSK0, temp

    sei

    clr score1
    clr score2
    clr temp

;======================
; MAIN LOOP
;======================
Loop:
    clr invalid

    rcall ReadDIPSwitch
    rcall ValidateInput

    cpi invalid, 1
    breq Loop

    rcall CompareChoices

    cpi r24, 0x01
    breq Loop

    rcall Display
    rcall Delay3Sec
    rjmp Loop

;======================
; INTERRUPT
;======================
Interrupt:
    rcall ResetScores
    reti

;======================
ResetScores:
    clr score1
    clr score2
    rcall Display
    ret

;======================
ReadDIPSwitch:
    in temp, PINC

    mov choice1, temp
    andi choice1, 0x07

    mov choice2, temp
    andi choice2, 0x38
    lsr choice2
    lsr choice2
    lsr choice2
    ret

;======================
ValidateInput:
    cpi choice1, 0
    breq Nothing

    cpi choice2, 0
    breq Nothing

    ldi temp, 0x01
    rcall Check1
End_Detect:
    ret

Nothing:
    inc invalid
    rjmp End_Detect

;======================
Check1:
    clr check

    sbrc choice1, 0
    inc check
    sbrc choice1, 1
    inc check
    sbrc choice1, 2
    inc check

    cp temp, check
    brlo Check1Fall

    rcall Check2
End_Check1:
    ret

Check1Fall:
    inc invalid
    rjmp End_Check1

;======================
Check2:
    clr check

    sbrc choice2, 0
    inc check
    sbrc choice2, 1
    inc check
    sbrc choice2, 2
    inc check

    cp temp, check
    brlo Check2Fall
End_Check2:
    ret

Check2Fall:
    inc invalid
    rjmp End_Check2

;======================
CompareChoices:
    clr temp
    ldi r24, 0x00

    cp choice1, choice2
    breq Tie

    cpi choice1, 1
    breq Select1
    cpi choice1, 2
    breq Select2
    cpi choice1, 4
    breq Select4
EndCompare:
    ret

Tie:
    inc r24
    rjmp EndCompare

Select1:
    cpi choice2, 2
    breq P1Wins
    cpi choice2, 4
    breq P2Wins
    rjmp EndCompare

Select2:
    cpi choice2, 4
    breq P1Wins
    cpi choice2, 1
    breq P2Wins
    rjmp EndCompare

Select4:
    cpi choice2, 1
    breq P1Wins
    cpi choice2, 2
    breq P2Wins
    rjmp EndCompare

P1Wins:
    inc score1
    sbrc score1, 3
    rcall ResetScores
    rjmp EndCompare

P2Wins:
    inc score2
    sbrc score2, 3
    rcall ResetScores
    rjmp EndCompare

;======================
Display:
    mov r25, score2
    rcall BIN_TO_7SEG
    out PORTB, r25

    mov r25, score1
    rcall BIN_TO_7SEG
    out PORTD, r25
    ret

;======================
BIN_TO_7SEG:
    ldi temp, 0x00

    cpi r25, 0
    breq ZERO
    cpi r25, 1
    breq ONE
    cpi r25, 2
    breq TWO
    cpi r25, 3
    breq THREE
    cpi r25, 4
    breq FOUR
    cpi r25, 5
    breq FIVE
    cpi r25, 6
    breq SIX
    cpi r25, 7
    breq SEVEN
End_trans:
    ret

ZERO:   ldi r25, 0b00000000
        rjmp End_trans
ONE:    ldi r25, 0b00000001
        rjmp End_trans
TWO:    ldi r25, 0b00000010
        rjmp End_trans
THREE:  ldi r25, 0b00000011
        rjmp End_trans
FOUR:   ldi r25, 0b00000100
        rjmp End_trans
FIVE:   ldi r25, 0b00000101
        rjmp End_trans
SIX:    ldi r25, 0b00000110
        rjmp End_trans
SEVEN:  ldi r25, 0b00000111
        rjmp End_trans

;======================
Delay3Sec:
    push r29
    push r30
    push r31

    ldi r29, 240

Checktime:
    cpi r29, 240
    breq ShowTime3
    cpi r29, 180
    breq ShowTime2
    cpi r29, 120
    breq ShowTime1
    cpi r29, 60
    breq ShowTime0

OuterLoop:
    ldi r30, 250
MiddleLoop:
    ldi r31, 250
InnerLoop:
    dec r31
    brne InnerLoop
    dec r30
    brne MiddleLoop

    dec r29
    brne Checktime

    pop r31
    pop r30
    pop r29
    ret

ShowTime3:
    ldi r26, 0x30
    or r26, r25
    out PORTD, r26
    rjmp OuterLoop

ShowTime2:
    ldi r26, 0x20
    or r26, r25
    out PORTD, r26
    rjmp OuterLoop

ShowTime1:
    ldi r26, 0x10
    or r26, r25
    out PORTD, r26
    rjmp OuterLoop

ShowTime0:
    out PORTD, r25
    rjmp OuterLoop
