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
            bpl .do_wavetable       ; DEBUG remove this and uncomment below for 3 voices
            ;jsr .do_wavetable
            ;ldx #7                  ; voice offset (0,7,14)
            ;jsr .do_wavetable
    	    ;ldx #14                 ; voice offset (0,7,14)
            ;bne .do_wavetable

.do_tracks:
            lda #6                  ; TODO 5 for NTSC?
            sta trackdelay
            ldy trackoff
            iny
            cpy #$20
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
            ; A=iiinnnnn
            pha
            lsr
            and #$F0
            tay                     ; Y=instrument offset ($00,$10,..,$70)
            ; start instrument
            lda music_instruments+INS_AD,y
            sta SID+AD,x
            lda music_instruments+INS_SR,y
            sta SID+SR,x
            lda music_instruments+INS_P0,y
            sta v1pulse,x
            lda music_instruments+INS_PM,y
            sta v1pulsemod,x
            ; start wavetable
            lda music_instruments+INS_WT,y
            sta v1waveidx,x
            tay
            ; handle 81 FFFF burst
            lda music_wavetable,y
            cmp #$8F                ; 81 FFFF burst
            bne +
            pla
            and #$1F
            sta v1note,x
            lda #$81
            sta SID+WV,x
            and #$FE     ; DEBUG immediate gate-off
            sta SID+WV,x ; DEBUG immediate gate-off
            lda #$FF
            sta SID+FL,x
            sta SID+FH,x
            sta v1freqh,x
            rts
+           sta SID+WV,x
            and #$FE     ; DEBUG immediate gate-off
            sta SID+WV,x ; DEBUG immediate gate-off
            pla
            and #$1F
            tay                     ; Y=note offset 4 octaves of 7 notes (0..27)
            lda music_freq_lo,y
            sta SID+FL,x
            lda music_freq_hi,y
            sta SID+FH,x
            sta v1freqh,x
            ; fall-through

.do_wavetable:
            rts

            ; TODO include code ---------------------------------------------

            ; freq sweep
            lda v1sweeph,x
            beq .pulsemod
            clc
            adc v1freqh,x
            sta v1freqh,x
            sta SID+FH,x

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

            ; TODO /include code --------------------------------------------


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


            !align 255,0,0 ; just to see how long each part gets
; --------------
;  dynamic data
;---------------

; voice data (3x7 bytes; could be in ZP)
v1waveidx:      !byte 0
v1wavedelay:    !byte 0
v1pulse:        !byte 0
v1pulsemod:     !byte 0
v1freqh:        !byte 0
v1sweeph:       !byte 0
v1note:         !byte 0
                !fill 7,0 ; v2 copy
                !fill 7,0 ; v3 copy


; player data (could be ZP)
trackoff:       !byte 0
trackdelay:     !byte 0


            !align 255,0,0 ; just to see how long each part gets
; -------------
;  music data
; -------------

; instrument data
INS_AD = 0
INS_SR = 1
INS_WT = 2 ; wavetable offset
INS_P0 = 3 ; instrument pulse-width init
INS_PM = 4 ; instrument pulse-width modulate

; instruments ($10 bytes each)
;               AD  SR  WVTBL    P0  PM
music_instruments:
        !byte  $02,$83, WVTBL0, $00,$00, 0,0,0,0,0,0,0,0,0,0,0 ; deep tom
;       !byte  $25,$83, $81,    $00,$00, 0,0,0,0,0,0,0,0,0,0,0 ; snare
;       !byte  $00,$60, $81,    $00,$00, 0,0,0,0,0,0,0,0,0,0,0 ; tick
;       !byte  $8C,$44, $41,    $3F,$F7, 0,0,0,0,0,0,0,0,0,0,0 ; pulse lead

; TODO instrument wavetable
;   TODO wavetable freq sweep (drum)
;   TODO wavetable wave
;   TODO wavetable delay
;   TODO wavetable end
;   TODO wavetable hold-until-gateoff (.E?)
;   TODO wavetable set pulsemod
;   TODO wavetable set pulsewidth
;   TODO wavetable arp
; TODO tracks
;   DONE track start instrument at note: A=iii_nnnnn
;   TODO track gate-off:                 A=FF
;   TODO track delay:                    A=00 do nothing
;   TODO track set note (glissando):     A=111_nnnnn (E0..FF)
; TODO song


;32 bytes per track (each byte represents 6 rasterlines)
music_tracks:
        ; drum pattern
        !byte $10,$00,$00,$14,$14,$00,$14,$00,$14,$00,$00,$00,$00,$00,$00,$00
        !byte $10,$00,$00,$14,$14,$00,$14,$00,$14,$00,$00,$00,$14,$00,$00,$00


; wavetable is 1 byte per rasterline
music_wavetable:
        WVTBL0 = *-music_wavetable
        !byte $8F ; $81 with $FFFF burst
        !byte $11 ; resets actual note frequency because of $8F
        !byte $AF ; freqh sweep depth 16 (already sweeps)
        !byte 4   ; <16 is delay
        !byte $10 ; gate-off
        !byte $00 ; stop
        ;$90-$9F ARP
        ;$A0-$AF sweep down
        WVTBL1 = *-music_wavetable
        !byte $00 ; stop


; 4 octaves of 7 notes octave 2,3,4 and 5 in key Cmin:
;              0      1      2      3      4      5      6
;              C      D      Eb     F      G      Ab     Bb
music_freq_hi:
        !byte >$045a,>$04e2,>$052d,>$05cf,>$0685,>$06e8,>$07c1 ; C-2
        !byte >$08b4,>$09c5,>$0a5a,>$0b9e,>$0d0a,>$0dd1,>$0f82 ; C-3
        !byte >$1168,>$138a,>$14b3,>$173c,>$1a15,>$1ba2,>$1f04 ; C-4
        !byte >$22d0,>$2714,>$2967,>$2e79,>$3429,>$3744,>$3e08 ; C-5
        !byte $ff ; note 29 is max freq
music_freq_lo:
        !byte <$045a,<$04e2,<$052d,<$05cf,<$0685,<$06e8,<$07c1 ; C-2
        !byte <$08b4,<$09c5,<$0a5a,<$0b9e,<$0d0a,<$0dd1,<$0f82 ; C-3
        !byte <$1168,<$138a,<$14b3,<$173c,<$1a15,<$1ba2,<$1f04 ; C-4
        !byte <$22d0,<$2714,<$2967,<$2e79,<$3429,<$3744,<$3e08 ; C-5
        !byte $ff ; note 29 is max freq


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
