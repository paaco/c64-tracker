;
; player1
;

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00

start:
            jsr $1000
--
            lda #$80
-           cmp $D012
            bne -
            inc $D020
            jsr $1003
            dec $D020
            jmp --

;-------------
; mini player
;-------------

    *= $1000

!addr SID = $50     ; shadow copy of 3x7 SID registers in ZP

FREQL = 0
FREQH = 1
PWL = 2
PWH = 3
WAVE = 4
AD = 5
SR = 6

music_init:
            clc
            bcc .music_init

music_play:
            ldx #13
-           lda SID,x
            sta $D400,x
.init:      dex
            bpl -

            lda note
            asl         ; account for words
            tay

            ; ; octave up
            ; lda freq_table,y
            ; ;asl
            ; sta SID+FREQL
            ; lda freq_table+1,y
            ; ;rol
            ; sta SID+FREQH

            ; octave down
            lda freq_table+1,y
            ;lsr
            sta SID+FREQH
            lda freq_table,y
            ;ror
            sta SID+FREQL

            ; double down
            ; lda freq_table+1+14,y
            ; sta SID+FREQH
            ; lda freq_table+14,y
            ; sta SID+FREQL
            ; lsr SID+FREQH
            ; ror SID+FREQL
            ; lsr SID+FREQH
            ; ror SID+FREQL

            lda #$8C
            sta SID+AD
            lda #$44
            sta SID+SR
            lda #$41
            sta SID+WAVE

            inc pulse
            lda pulse ; pulse-width
            bpl +
            eor #$FF
+           ; TODO pretty expensive way to flip nibbles
            cmp #$80
            rol
            cmp #$80
            rol
            cmp #$80
            rol
            cmp #$80
            rol
            sta SID+PWL
            sta SID+PWH

            dec delay
            bne +
            lda #6 ; restart
            sta delay

            inc note
            inc note
            lda note
            cmp #6
            bne +
            lda #0
            sta note
+           rts

.music_init:
            lda #0
            tax
-           sta SID,x
            inx
            cpx #$18
            bcc -
            beq +
            ; TODO init song values
            bne .init
+           lda #$0F ; set volume
            bne -

delay:      !byte 6
note:       !byte 0
pulse:      !byte 0

; -------------
;  music data
; -------------

; 14-note octave 4 and 5 in key Cmin: C D Eb F G Ab Bb
freq_table:
            !word $1168 ; C-4
            ;!word $1271 ; C#4
            !word $138a ; D-4
            !word $14b3 ; D#4 Eb4
            ;!word $15ee ; E-4
            !word $173c ; F-4
            ;!word $189e ; F#4
            !word $1a15 ; G-4
            !word $1ba2 ; G#4 Ab4
            ;!word $1d46 ; A-4
            !word $1f04 ; A#4 Bb4
            ;!word $20dc ; B#4
            !word $22d0 ; C-5
            ;!word $24e2 ; C#5
            !word $2714 ; D-5
            !word $2967 ; D#5 Eb5
            ;!word $2bdd ; E-5
            !word $2e79 ; F-5
            ;!word $313c ; F#5
            !word $3429 ; G-5
            !word $3744 ; G#5 Ab5
            ;!word $3a8d ; A-5
            !word $3e08 ; A#5 Bb5
            ;!word $41b8 ; B#5

; instruments ($10 bytes each)
;                  AD  SR  PW
music_data_instruments:
            !byte $00,$00,$00, 0,0,0,0,0,0,0,0,0,0,0,0,0
