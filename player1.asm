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

!addr SID = $D400

FL = 0
FH = 1
PL = 2
PH = 3
WV = 4
AD = 5
SR = 6
FILT_LO = $15
FILT_HI = $16
FILT_VOICES = $17
FILT_VOL = $18

; instrument data
INS_P0 = 2 ; instrument pulse-width init
INS_PM = 3 ; instrument pulse-width modulate
INS_WV = 4
INS_AD = 5
INS_SR = 6

music_init:
            clc
            bcc .music_init

music_play:
            ldx #0 ; voice offset (0,7,14)

            ldy note ; 4 octaves of 7 notes (0..27)
            lda music_freq_hi,y
            sta SID+FH,x
            lda music_freq_lo,y
            sta SID+FL,x

            ldy #$00 ; only use high-nibble
            lda music_instruments+INS_AD,y
            sta SID+AD,x
            lda music_instruments+INS_SR,y
            sta SID+SR,x
            lda music_instruments+INS_WV,y
            sta SID+WV,x
            ;lda music_instruments+INS_PM,y
            ;sta v1pulsemod,x
            ;lda music_instruments+INS_P0,y
            ;sta v1pulse,x
            ;bne .set_pulsewidth

.pulsemod:
            ; pulse modulate
            lda v1pulsemod,x
            beq .no_pulsemod
            clc
            adc v1pulse,x
            sta v1pulse,x
.set_pulsewidth
            bpl +
            eor #$FF
+           cmp #$80
            rol
            cmp #$80
            rol
            cmp #$80
            rol
            cmp #$80
            rol
.no_pulsemod:
            sta SID+PH,x
            ora #$01 ; avoid silence
            sta SID+PL,x

            dec delay
            bne +
            lda #6 ; restart
            sta delay

            inc note
            lda note
            cmp #4*7-1
            bne +
            lda #0
            sta note
+           rts

.music_init:
            ldx #$18
-           lda music_SID_init,x
            sta SID,x
            dex
            bpl -
            ; TODO reset song pointers
            rts


            !align 255,0,0 ; just to see how long each part gets
; --------------
;  dynamic data
;---------------

; voice data (3x7 bytes; could be in ZP)
v1pulse:        !byte $3F
v1pulsemod:     !byte $01
                !byte 0,0,0,0,0

delay:      !byte 6
note:       !byte 0


            !align 255,0,0 ; just to see how long each part gets
; -------------
;  music data
; -------------

; instruments ($10 bytes each)
;              ------register init-------
;              FL  FH  P0  PM  WV  AD  SR
music_instruments:
        !byte   0,  0,$3F,$F7,$41,$8C,$44, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; pulse lead

; TODO instrument wavetable
;   TODO wavetable freq sweep (drum)
;   TODO wavetable 81 FFFF step (burst)
;   TODO wavetable wave
;   TODO wavetable delay
;   TODO wavetable end
;   TODO wavetable hold-until-gateoff
;   TODO wavetable set pulsemod
;   TODO wavetable set pulsewidth
;   TODO wavetable arp
; TODO patterns
;   TODO pattern start instrument at note
;   TODO pattern gate-off
;   TODO pattern delay
;   TODO pattern set note (glissando)
; TODO tracks
; TODO song


; 4 octaves of 7 notes octave 2,3,4 and 5 in key Cmin:
;              0      1      2      3      4      5      6
;              C      D      Eb     F      G      Ab     Bb
music_freq_hi:
        !byte >$045a,>$04e2,>$052d,>$05cf,>$0685,>$06e8,>$07c1 ; C-2
        !byte >$08b4,>$09c5,>$0a5a,>$0b9e,>$0d0a,>$0dd1,>$0f82 ; C-3
        !byte >$1168,>$138a,>$14b3,>$173c,>$1a15,>$1ba2,>$1f04 ; C-4
        !byte >$22d0,>$2714,>$2967,>$2e79,>$3429,>$3744,>$3e08 ; C-5
music_freq_lo:
        !byte <$045a,<$04e2,<$052d,<$05cf,<$0685,<$06e8,<$07c1 ; C-2
        !byte <$08b4,<$09c5,<$0a5a,<$0b9e,<$0d0a,<$0dd1,<$0f82 ; C-3
        !byte <$1168,<$138a,<$14b3,<$173c,<$1a15,<$1ba2,<$1f04 ; C-4
        !byte <$22d0,<$2714,<$2967,<$2e79,<$3429,<$3744,<$3e08 ; C-5

; $18 bytes SID init
music_SID_init:
        !byte 0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0
FILTER=0
        !byte (FILTER & $F)     ; filter cutoff bits 3-0
        !byte (FILTER >> 4)     ; filter cutoff bits 11-4
        !byte $00               ;        reso | ext v3 v2 v1
        !byte $0F               ; V3 HP BP LP | VOL
