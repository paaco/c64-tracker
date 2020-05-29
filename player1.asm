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
            ; DEBUG make sure to wait at least a single rasterline
            lda $d012
-           cmp $d012
            beq -
            jmp --


;-------------
; mini player
;-------------

    *= $1000

!addr SID = $D400

; SID registers
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

music_init:
            jmp .music_init

music_play:
            ldx #0                  ; voice offset (0,7,14)
            dec trackdelay
            bmi .do_tracks
            bpl .do_wavetable
            ;ldx #7                  ; voice offset (0,7,14)
            ;jsr .do_wavetable
    	    ;ldx #14                 ; voice offset (0,7,14)
            ;bne .do_wavetable

.do_tracks:
            lda #6
            sta trackdelay
            ldy trackoff
            iny
            cpy #TRACK_LEN
            bmi +
            ldy #0
+           sty trackoff
            ;jsr .do_track
            ;ldx #7                  ; voice offset (0,7,14)
            ;jsr .do_track
    	    ;ldx #14                 ; voice offset (0,7,14)
            ; fall-through

.do_track:
            ; get track data
            ldy trackoff
            lda music_tracks,y
            beq .do_wavetable       ; 0=do nothing
            ; A=iiiinnnn
            pha
            and #$F0
            tay                     ; Y=instrument offset ($10,$20..$F0)
            pla
            and #$0F                ; A=note offset (0..15)
            clc
            adc music_instruments+INS_RN,y  ; add instrument root note
            sta v1note,x
            ; restart instrument
            lda music_instruments+INS_WT,y
            sta v1waveidx,x
            lda music_instruments+INS_AD,y
            sta SID+AD,x
            lda music_instruments+INS_SR,y
            sta SID+SR,x
            lda music_instruments+INS_PM,y
            sta v1pulsemod,x
            lda music_instruments+INS_P0,y
            sta v1pulse,x
            beq +                   ; don't set pulsewidth if 0
            jsr .set_pulsewidth
+           lda music_instruments+INS_FF,y
            tay
            bne +
            ldy v1note,x
            ; set note frequency
+           lda music_freq_lo,y
            sta SID+FL,x
            lda music_freq_hi,y
            sta SID+FH,x
            sta v1freqh,x
            ; fall-through

.do_wavetable:
            ldy v1waveidx,x
            lda music_wavetable,y
            beq ++
+           sta SID+WV,x
            inc v1waveidx,x
++          rts

            ; TODO include code ---------------------------------------------

            ; freq sweep
            lda v1sweeph,x
            beq +
            clc
            adc v1freqh,x
            sta v1freqh,x
            sta SID+FH,x
            ; pulse modulate
+           lda v1pulsemod,x
            beq +
            clc
            adc v1pulse,x
            sta v1pulse,x
+
            ; TODO /include code --------------------------------------------

.set_pulsewidth:
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
            sta SID+PH,x
            ora #$01 ; avoid silence
            sta SID+PL,x
            rts


.music_init:
            ldx #$18
-           lda music_SID_init,x
            sta SID,x
            dex
            bpl -
            ; reset song pointers TODO add this to SID_init block?
            lda #$FF
            sta trackoff
            lda #$00
            sta trackdelay
            rts


; --------------
;  dynamic data
;---------------

; voice data (3x7 bytes; could be in ZP)
v1note:         !byte 0
v1waveidx:      !byte 0
v1pulse:        !byte 0
v1pulsemod:     !byte 0
v1freqh:        !byte 0
v1sweeph:       !byte 0
                !fill 1,0
                !fill 7,0 ; v2 copy
                !fill 7,0 ; v3 copy

; player data (could be ZP)
trackoff:       !byte 0
trackdelay:     !byte 0


; -------------
;  music data
; -------------

; instrument data
INS_AD = 0
INS_SR = 1
INS_WT = 2 ; wavetable offset
INS_P0 = 3 ; instrument pulse-width init
INS_PM = 4 ; instrument pulse-width modulate
INS_RN = 5 ; root note
INS_FF = 6 ; <>0 first frequency override use 28 for FFFF

; instruments ($10 bytes each)
music_instruments:
        !fill 16,0 ; instrument 0 is not used
;               AD  SR  WVTBL    P0  PM  RN FF
        !byte  $02,$C3, WVTBL0, $00,$00,  7, 0, 0,0,0,0,0,0,0,0,0 ; deep tom
;       !byte  $25,$83, $81,    $00,$00,  0, 0, 0,0,0,0,0,0,0,0,0 ; snare
;       !byte  $00,$60, $81,    $00,$00,  0, 0, 0,0,0,0,0,0,0,0,0 ; tick
;       !byte  $8C,$44, WVTBL1, $3F,$F7,  0, 0, 0,0,0,0,0,0,0,0,0 ; pulse lead
        !byte  $52,$82, WVTBL1, $20,$F7,  14, 0, 0,0,0,0,0,0,0,0,0 ; pulse bass

; TODO instrument wavetable
;   TODO wavetable freq sweep (drum)
;   DONE wavetable wave
;   TODO wavetable delay
;   DONE wavetable end
;   TODO wavetable hold-until-gateoff (.E?)
;   TODO wavetable set pulsemod
;   TODO wavetable set pulsewidth
;   TODO wavetable arp
; TODO tracks
;   DONE track start instrument at note: A=iiii_nnnn
;   TODO track gate-off:                 A=FF
;   DONE track delay:                    A=00 do nothing
;   TODO track set note (legato):        A=1111_nnnn (E0..FF)
; TODO song


TRACK_LEN = 32
;32 bytes per track (each byte represents 6 rasterlines)
music_tracks:
        ; drum pattern
        !byte $10,$00,$00,$14, $14,$00,$14,$00, $14,$00,$00,$00, $00,$00,$00,$00
        !byte $20,$21,$22,$23, $24,$25,$26,$27, $20,$00,$00,$00, $00,$00,$00,$00
        !byte $10,$00,$00,$14, $14,$00,$14,$00, $14,$00,$00,$00, $14,$00,$00,$00


; wavetable is 1 byte per rasterline (max 256 bytes)
music_wavetable:
        WVTBL0 = *-music_wavetable
        !byte $81
        !byte $11
        ;!byte $AF ; freqh sweep depth 16 (already sweeps)
        ;!byte 4   ; <16 is delay
        !byte $11
        !byte $11
        !byte $11
        !byte $11
        !byte $10 ; gate-off
        !byte $00 ; stop
        ;$90-$9F ARP
        ;$A0-$AF sweep down
        WVTBL1 = *-music_wavetable
        !byte $41
        !byte $41
        !byte $41
        !byte $41
        !byte $41
        !byte $40
        !byte $00 ; stop


; 4 octaves of 7 notes octave 2,3,4 and 5 in key Cmin:
;              0      1      2      3      4      5      6
;              C      D      Eb     F      G      Ab     Bb
music_freq_hi:
        !byte >$045a,>$04e2,>$052d,>$05cf,>$0685,>$06e8,>$07c1 ; C-2
        !byte >$08b4,>$09c5,>$0a5a,>$0b9e,>$0d0a,>$0dd1,>$0f82 ; C-3
        !byte >$1168,>$138a,>$14b3,>$173c,>$1a15,>$1ba2,>$1f04 ; C-4
        !byte >$22d0,>$2714,>$2967,>$2e79,>$3429,>$3744,>$3e08 ; C-5
        !byte $ff ; note 28 is max freq
music_freq_lo:
        !byte <$045a,<$04e2,<$052d,<$05cf,<$0685,<$06e8,<$07c1 ; C-2
        !byte <$08b4,<$09c5,<$0a5a,<$0b9e,<$0d0a,<$0dd1,<$0f82 ; C-3
        !byte <$1168,<$138a,<$14b3,<$173c,<$1a15,<$1ba2,<$1f04 ; C-4
        !byte <$22d0,<$2714,<$2967,<$2e79,<$3429,<$3744,<$3e08 ; C-5
        !byte $ff ; note 28 is max freq


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
