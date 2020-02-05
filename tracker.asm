;
; tracker
;

; layout:
;  4 rows of 4 x 6 dots, all raster ticks in a 16-row bar

        * = $0801
        !byte $0c,$08,<2020,>2020,$9e,$20,$32,$30,$36,$32,$00,$00,$00
start:
        ; lda #0 ; C      DEBUG
        ; ldy #5 ; 0=major 5=minor
        ; jsr calc_scale
        ; ldx #1 ; b-signs
        ; jsr calc_signs
        ; ; D (actually the calculated note name C=0,D=1..B=6)
        ; lda scale_indices+1
        ; sta calc_chord_input
        ; lda scale_indices+3
        ; sta calc_chord_input+1
        ; lda scale_indices+5
        ; sta calc_chord_input+2
        ; jsr calc_chord
        ; jmp calc_chord_2

        jsr music_init
;--      jsr music_play ; DEBUG
;        jmp --         ; DEBUG

        jsr $E544

        ldx #0
-       lda music_pattern,x
        sta $0400+(40-24)/2+5*40,x
        lda music_pattern+24,x
        sta $0400+(40-24)/2+6*40,x
        lda music_pattern+24*2,x
        sta $0400+(40-24)/2+7*40,x
        lda music_pattern+24*3,x
        sta $0400+(40-24)/2+8*40,x
        inx
        cpx #24
        bne -

        ; lowercase
        lda $D018
        ora #2
        sta $D018

        ldx #0
.lp1    lda notes,x
        sta $0400+23*40,x
        lda notes+24,x
        sta $0400+24*40,x
        inx
        cpx #24
        bne .lp1

        ldx #0
.lp2    lda instrument_example,x
        sta $0400+23+40,x
        lda instrument_example+16,x
        sta $0400+23+80,x
        lda instrument_example+32,x
        sta $0400+23+120,x
        inx
        cpx #16
        bne .lp2
        ; simulate cursor
        lda $0400+23+80
        ora #$80
        sta $0400+23+80
        lda #$07
        sta $D800+23+80

        ; in interrupt
        sei
--      lda $D012
        cmp #$80
        bne --
        inc $D020
        inc $D021
        jsr music_play
        dec $D020
        dec $D021
        jmp --


; A=key note (0=C, 1=C#, etc, 11=B)
; Y=0 for major scale, Y=5 for minor scale
calc_scale:
        ; determine starting note
        cmp #2              ; C or C# is OK
        bcc .scale_make     ; lt
        clc
        adc scale_steps,y
        cmp #12
        bcc +               ; lt
        sbc #12
+       iny
        cpy #7
        bne calc_scale
        ldy #0
        beq calc_scale
.scale_make:
        ; A = starting note (0 or 1), Y = position in scale steps (0..6), C=0
        ldx #0
-       sta scale_indices,x
        adc scale_steps,y
        iny
        cpy #7
        bne +
        ldy #0
+       inx
        cpx #7
        bne -
        rts

; Use X=0 for #, X=1 for b
; Generates 7 scale_signs with $FF for b, $00 for whole and $01 for #
calc_signs:
        ldy #0
.next:  lda scale_indices,y
        sec
        sbc scale_wholes,x
        cpx #7
        bne +
        ldx #0
+       sta scale_signs,x
        inx
        iny
        cpy #7
        bne .next
        rts

; major scale steps start at index #0, minor scale steps start at index #5
scale_steps:
        !byte 2,2,1,2,2,2,1

scale_wholes:
        !byte 0,2,4,5,7,9,11,12
;             C,D,E,F,G,A,B

; the 7 notes indices (0..11) of the calculated scale in ascending order
scale_indices:
        !byte 0,0,0,0,0,0,0
;             C,D,E,F,G,A,B

; the 7 note signs (00 is whole, FF is b, 01 is #)
scale_signs:
        !byte 0,0,0,0,0,0,0

calc_chord_input: !byte 0,0,0

; Calculate chord names for each of the 7 indices
; Names depend on the step difference to the second and third note of the chord
; Input: 3 note indices (ascending) in calc_chord_input,+1,+2
; Output: A=0 unknown, 1=dim(036), 2=min(037), 3=maj(047), 4=aug(048)
calc_chord: ; 58 bytes
        lda calc_chord_input+1
        sec
        sbc calc_chord_input
        cmp #3
        beq .chord_dim_min
        cmp #4
        beq .chord_maj_aug
.chord_unknown:
        lda #0
        rts
.chord_dim_min:
        lda calc_chord_input+2
        sbc calc_chord_input
        cmp #7
        bne .chord_dim
        lda #2 ; MIN
        rts
.chord_dim:
        cmp #6
        bne .chord_unknown
        lda #1 ; DIM
        rts
.chord_maj_aug:
        lda calc_chord_input+2
        sbc calc_chord_input
        cmp #7
        bne .chord_aug
        lda #3 ; MAJ
        rts
.chord_aug:
        cmp #8
        bne .chord_unknown
        lda #4 ; AUG
        rts

; Input: 3 note indices (ascending) in calc_chord_input,+1,+2
; Output: A=0 unknown, 1=dim(036), 2=min(037), 3=maj(047), 4=aug(048)
calc_chord_2:
        lda calc_chord_input+1
        clc
        adc calc_chord_input+2
        sec
        sbc calc_chord_input
        sbc calc_chord_input
        sbc #8
        beq .chord_invalid ; eq (A=0)
        bcc .chord_invalid ; lt (A<0)
        cmp #5
        bcc .chord_ok      ; lt (A<5)
.chord_invalid:
        lda #0
.chord_ok:
        rts


notes:
; key B/g#  with 5#/7b contains Fb and Cb
; key F#/gb with 6#/6b contains both F and F#, making the former E#. Key gb has Cb instead of B
; key Db/bb with 7#/5b contains E# and B#
;             0 1 2 3 4 5 6 7 8 9 1011
        !scr "C-C#D-D#E-F-F#G-G#A-A#B-"
        !scr "C-DbD-EbE-F-GbG-AbA-BbB-"

instrument_example:
        !scr "WV FQ ADSR      "
        !scr "03 C0 2583 Snare"
        !scr "03:8181818180FF "


; PAL frequency table (8 * 12 = 96 notes)
nt_freqtbl:
        !word $0117,$0127,$0139,$014b,$015f,$0174
        !word $018a,$01a1,$01ba,$01d4,$01f0,$020e
        !word $022d,$024e,$0271,$0296,$02be,$02e8
        !word $0314,$0343,$0374,$03a9,$03e1,$041c
        !word $045a,$049c,$04e2,$052d,$057c,$05cf
        !word $0628,$0685,$06e8,$0752,$07c1,$0837
        !word $08b4,$0939,$09c5,$0a5a,$0af7,$0b9e
        !word $0c4f,$0d0a,$0dd1,$0ea3,$0f82,$106e
        !word $1168,$1271,$138a,$14b3,$15ee,$173c
        !word $189e,$1a15,$1ba2,$1d46,$1f04,$20dc
        !word $22d0,$24e2,$2714,$2967,$2bdd,$2e79
        !word $313c,$3429,$3744,$3a8d,$3e08,$41b8
        !word $45a1,$49c5,$4e28,$52cd,$57ba,$5cf1
        !word $6278,$6853,$6e87,$751a,$7c10,$8371
        !word $8b42,$9389,$9c4f,$a59b,$af74,$b9e2
        !word $c4f0,$d0a6,$dd0e,$ea33,$f820,$ffff


;---------------------------
; player
;---------------------------

!addr SID = $50                         ; shadow copy of 3x7 SID registers in ZP

FREQL = 0
FREQH = 1
PWL = 2
PWH = 3
WAVE = 4
AD = 5
SR = 6

        * = $1000

music_init:
        clc
        bcc .music_init

music_play:
        lda SID+FREQL
        sta $D400+FREQL
        lda SID+FREQH
        sta $D400+FREQH
        lda SID+WAVE
        sta $D400+WAVE
        lsr
        bcc pattern_play                ; skip ADSR on gate-off
        lda SID+AD
        sta $D400+AD
        lda SID+SR
        sta $D400+SR
        clc
        bcc pattern_play

.music_init:
        lda #0
        tax
-       sta SID,x
        sta $D400,x
        inx
        cpx #7
        bcc -
        sta $D415                       ; filter freq (low 3 bits)
        lda #$40                        ; filter frequency (high 8 bits)
        sta $D416
        lda #$00                        ; X0 resonance; 01=voice1 02=voice2 04=voice3
        sta $D417
        lda #$0F                        ; 0X volume; filter 10=lp 20=bp 40=hp
        sta $D418
        lda #$FF                        ; reset song
        sta pattern_offset
        bne pattern_play


;--------------
; dynamic data and ptrs to music data go in first page for easier relocation
;--------------

; counters for each voice
pattern_offset:
        !byte 0
wavetable_offset:
        !byte 0
note_offset:
        !byte 0


;----------------
; pattern player
;----------------

pattern_play:
        ldx pattern_offset
        inx
        cpx #6*4*4                       ; PATTERN LENGTH
        bne .do_note
        ; restart pattern
        ldx #0
.do_note:
        stx pattern_offset
        lda music_pattern,x
        ; patt 00 = do nothing
        beq .do_wavetable
        ; patt 0F = gate off
        cmp #$0F
        beq .note_gateoff
        cmp #$1F
        bcs .do_wavetable
        ; patt 10-1F = play instrument 0X at root-note and restart wave table
.note_instrument:
        and #$0F
        asl
        asl
        tax
        ; ADSR
        lda music_instr,x
        sta SID+AD
        lda music_instr+1,x
        sta SID+SR
        ; restart wave table
        lda music_instr+2,x
        sta wavetable_offset
        ; root-note
        lda music_instr+3,x
        asl
        tax
        lda freq_table,x
        sta SID+FREQL
        lda freq_table+1,x
        sta SID+FREQH
        bne .do_wavetable
.note_gateoff:
        lda SID+WAVE
        and #$FE
        sta SID+WAVE
.do_wavetable:
        ; cycle wave table
        ldx wavetable_offset
        lda music_wavetable,x
        ; wavetable 00 = end
        beq .wavetable_done
.wavetable_wave:
        sta SID+WAVE
        inc wavetable_offset
.wavetable_done:
        rts

;---------------------------
; MUSIC DATA
;---------------------------

        * = $1200

; 8 octaves of 12 notes = 2 * 8 * 12 = 192 = $C0 bytes
freq_table:
        !word $0117,$0127,$0139,$014b,$015f,$0174
        !word $018a,$01a1,$01ba,$01d4,$01f0,$020e
        !word $022d,$024e,$0271,$0296,$02be,$02e8
        !word $0314,$0343,$0374,$03a9,$03e1,$041c
        !word $045a,$049c,$04e2,$052d,$057c,$05cf
        !word $0628,$0685,$06e8,$0752,$07c1,$0837
        !word $08b4,$0939,$09c5,$0a5a,$0af7,$0b9e
        !word $0c4f,$0d0a,$0dd1,$0ea3,$0f82,$106e
        !word $1168,$1271,$138a,$14b3,$15ee,$173c
        !word $189e,$1a15,$1ba2,$1d46,$1f04,$20dc
        !word $22d0,$24e2,$2714,$2967,$2bdd,$2e79
        !word $313c,$3429,$3744,$3a8d,$3e08,$41b8
        !word $45a1,$49c5,$4e28,$52cd,$57ba,$5cf1
        !word $6278,$6853,$6e87,$751a,$7c10,$8371
        !word $8b42,$9389,$9c4f,$a59b,$af74,$b9e2
        !word $c4f0,$d0a6,$dd0e,$ea33,$f820,$ffff ; 95
; OR 8 octaves of 7 notes would be  = 2 * 8 * 7  = 112 = $70 bytes

;-------------
; instruments
;-------------

music_instr:
        ; AD,SR,wavetable_offset,root-note
        !byte $00,$60,0,95               ; tick
        !byte $25,$83,3,90               ; snare

;-------------
; wave tables
;-------------

music_wavetable:
        !byte $81           ; waveform
        !byte $80           ; waveform
        !byte $00           ; stop

        !byte $81           ; waveform
        !byte $81           ; waveform
        !byte $81           ; waveform
        !byte $81           ; waveform
        !byte $80           ; waveform
        !byte $00           ; stop

;----------
; tracks
;----------

;----------
; patterns
;----------

; 6 * 4 * 4 bytes = 96 bytes per pattern, max 96*256 = 24576 ($6000) bytes uncompressed
music_pattern:
        !byte $10,0,0,0,0,0, $10,0,0,0,0,0, $10,0,0,0,0,0, $10,0,0,0,0,0
        !byte $11,0,0,0,0,0, $10,0,0,0,0,0, $10,0,0,0,0,0, $10,0,0,0,0,0
        !byte $10,0,0,0,0,0, $10,0,0,0,0,0, $10,0,0,0,0,0, $10,0,0,0,0,0
        !byte $11,0,0,0,0,0, $10,0,0,0,$11,0, 0,0,0,0,$11,0, $11,0,0,$11,0,0

; docs

    !if 0 {
; $D400/54272/SID+0     Voice 1: Frequency Control - Low-Byte
; $D401/54273/SID+1     Voice 1: Frequency Control - High-Byte
; $D402/54274/SID+2     Voice 1: Pulse Waveform Width - Low-Byte
; $D403/54275/SID+3     Voice 1: Pulse Waveform Width - High-Nybble (4-bits)
   12-bit pulse waveform duty cycle 0..4095
   A value of 0  or 4095  ($FFF)  in  the  Pulse Width registers  will  produce a  constant  DC output
; $D404/54276/SID+4     Voice 1: Control Register
   | Bit 7 |   Select Random Noise Waveform, 1 = On               |
   | Bit 6 |   Select Pulse Waveform, 1 = On                      |
   | Bit 5 |   Select Sawtooth Waveform, 1 = On                   |
   | Bit 4 |   Select Triangle Waveform, 1 = On                   |
   | Bit 3 |   Test Bit: 1 = Disable Oscillator                   |
   | Bit 2 |   Ring Modulate Osc. 1 with Osc. 3 Output, 1 = On    |
   | Bit 1 |   Synchronize Osc. 1 with Osc. 3 Frequency, 1 = On   |
   | Bit 0 |   Gate Bit: 1 = Start Att/Dec/Sus, 0 = Start Release |
; $D405/54277/SID+5     Voice 1: Attack / Decay Cycle Control
; $D406/54278/SID+6     Voice 1: Sustain / Release Cycle Control
; $D407/54279/SID+7     Voice 2: Frequency Control - Low-Byte
; $D408/54280/SID+8     Voice 2: Frequency Control - High-Byte
; $D409/54281/SID+9     Voice 2: Pulse Waveform Width - Low-Byte
; $D40A/54282/SID+10    Voice 2: Pulse Waveform Width - High-Nybble (4-bits)
; $D40B/54283/SID+11    Voice 2: Control Register
; $D40C/54284/SID+12    Voice 2: Attack / Decay Cycle Control
; $D40D/54285/SID+13    Voice 2: Sustain / Release Cycle Control
; $D40E/54286/SID+14    Voice 3: Frequency Control - Low-Byte
; $D40F/54287/SID+15    Voice 3: Frequency Control - High-Byte
; $D410/54288/SID+16    Voice 3: Pulse Waveform Width - Low-Byte
; $D411/54289/SID+17    Voice 3: Pulse Waveform Width - High-Nybble (4-bits)
; $D412/54290/SID+18    Voice 3: Control Register
; $D413/54291/SID+19    Voice 3: Attack / Decay Cycle Control
; $D414/54292/SID+20    Voice 3: Sustain / Release Cycle Control
; $D415/54293/SID+21    Filter Cutoff Frequency: Low-Nybble (3-bits)
; $D416/54294/SID+22    Filter Cutoff Frequency: High-Byte
   FREQUENCY = (REGISTER VALUE * 5.8) + 30 Hz 11-bits, highest 8 in d416 + 3 lowest in d415
   values range from 0..2047 or 0..$800 corresponding to 30 Hz to 12000 Hz
   Voice frequency ranges from 16 Hz to 4000 Hz but you get higher harmonics
; $D417/54295/SID+23    Filter Resonance Control / Voice Input Control
   | Bits 7-4 |   Select Filter Resonance: 0-15 (linear steps)    |
   | Bits 3   |   Filter External Input: 1 = Yes, 0 = No          |
   | Bits 2   |   Filter Voice 3 Output: 1 = Yes, 0 = No          |
   | Bits 1   |   Filter Voice 2 Output: 1 = Yes, 0 = No          |
   | Bits 0   |   Filter Voice 1 Output: 1 = Yes, 0 = No          |
; $D418/54296/SID+24    Select Filter Mode and Volume
   | Bits 7   |   Cut-Off Voice 3 Output: 1 = On, 0 = Off         |
   | Bits 6   |   Select Filter High-Pass Mode: 1 = On            |
   | Bits 5   |   Select Filter Band-Pass Mode: 1 = On            |
   | Bits 4   |   Select Filter Low-Pass Mode: 1 = On             |
   | Bits 3-0 |   Select Output Volume: 0-15 (linear steps)       |

; 1 50Hz frame is 20 ms; 1 60Hz frame is 16,5ms

     VALUE    ATTACK    DECAY/RELEASE
   +-------+----------+---------------+
   |   0   |    2 ms  |      6 ms     |
   |   1   |    8 ms  |     24 ms     |
   |   2   |   16 ms  |     48 ms     |
   |   3   |   24 ms  |     72 ms     |
   |   4   |   38 ms  |    114 ms     |
   |   5   |   56 ms  |    168 ms     |
   |   6   |   68 ms  |    204 ms     |
   |   7   |   80 ms  |    240 ms     |
   |   8   |  100 ms  |    300 ms     |
   |   9   |  240 ms  |    720 ms     |
   |   10  |  500 ms  |    1.5 s      |
   |   11  |  800 ms  |    2.4 s      |
   |   12  |    1 s   |      3 s      |
   |   13  |    3 s   |      9 s      |
   |   14  |    5 s   |     15 s      |
   |   15  |    8 s   |     24 s      |
   +-------+----------+---------------+

  Frequency:
  ----------

   To calculate the frequency corresponding to the 16-bit value in
   $D400+$D401, $D407+$D408, $D40E+$D40F use the following formula:

    Freq = 16Bit-Value * Phi2 / 16777216 Hz

   where Phi2 is the system-clock, 985248 Hz for PAL-systems,
   1022727 Hz for NTSC-systems.

   A good approximation for both systems is the formula:

    Freq = 16Bit-Value / 17.03

  Pulse-Width:
  ------------

   To calculate the pulse width (in %) corresponding to the 12-bit value in
   $D402+$D403, $D409+$D40A, $D410+$D411 use the following formula:

    PulseWidth = (16Bit-Value / 40.96) %

}