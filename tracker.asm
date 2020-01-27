;
; tracker
;

; layout:
;  4 rijen van 24 dots. Dit zijn alle ticks

FREQL = 0
FREQH = 1
PWL = 2
PWH = 3
WAVE = 4
AD = 5
SR = 6

        * = $0801
        !byte $0c,$08,<2020,>2020,$9e,$20,$32,$30,$36,$32,$00,$00,$00
start:
        jsr music_init
        jsr $E544

        ldx #0
        lda #'.'
-       sta $0400+(40-24)/2+5*40,x
        sta $0400+(40-24)/2+6*40,x
        sta $0400+(40-24)/2+7*40,x
        sta $0400+(40-24)/2+8*40,x
        inx
        cpx #24
        bne -

        ; in de interrupt
--      lda $D012
        cmp #$80
        bne --
        inc $D020
        jsr music_play
        dec $D020
        jmp --

;---------------------------
; player
;---------------------------

        * = $1000

music_init:
        clc
        bcc .music_init

music_play:
        ; copy SID registers from previous loop
        ldx #0
-       lda SID,x
        sta $D400,x
        inx
        cpx #$19
        bne -

        ; play pattern
        ldx voice_0_pattern_offset
        lda music_pattern,x
        ; 0 = do nothing
        beq .voice_done
        cmp #$FF
        bne .voice_not_FF
        ; 255 = gate off
        lda SID+WAVE
        and #$FE
        sta SID+WAVE
.voice_not_FF:
        cmp #16                      ; MAX #INSTR
        bcs .voice_done
        ; 1-15 = select instrument and restart wave table
        sbc #0 ; 0..14
        asl
        asl
        tax
        ; ADSR
        lda music_instr,x
        sta SID+AD
        lda music_instr+1,x
        sta SID+SR
        ; init wave table
        lda music_instr+2,x
        sta voice_0_wavetable_offset
        ; frequency TODO now just max value for hihat (could come from wave table or pattern data)
        lda #$FF
        sta SID+FREQL
        sta SID+FREQH
        ; cycle wave table
        ldx voice_0_wavetable_offset
        lda music_wavetable,x
        cmp #$FF
        beq .voice_done
        sta SID+WAVE
        inc voice_0_wavetable_offset
.voice_done:
        rts

.music_init:
        lda #0
        tax
-       sta SID,x
        inx
        cpx #$18
        bcc -
        beq +
        bne music_play
+       lda #$0F                     ; master volume and filter mode
        bne -

        ; shadow copy of SID registers
SID:    !fill 25,0

        ; music counters
voice_0_pattern_offset:
        !byte 0
voice_0_wavetable_offset:
        !byte 0

;---------------------------
; instruments
;---------------------------

music_instr:
        ; AD,SR,wavetable_offset,0
        !byte $00,$F4,0,0

;---------------------------
; wave table
;---------------------------

music_wavetable:
        !byte $81           ; waveform
        !byte $FF           ; stop

;---------------------------
; patterns
;---------------------------

music_pattern:
        !byte 1,0,0,0,0,0, $ff,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0
        !byte 1,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0
        !byte 1,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0
        !byte 1,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0

; docs

    !if 0 {
; $D400/54272/SID+0     Voice 1: Frequency Control - Low-Byte
; $D401/54273/SID+1     Voice 1: Frequency Control - High-Byte
; $D402/54274/SID+2     Voice 1: Pulse Waveform Width - Low-Byte
; $D403/54275/SID+3     Voice 1: Pulse Waveform Width - High-Nybble (4-bits)
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