; synthesizer test

        * = $0801
        !byte $0c,$08,<2020,>2020,$9e,$20,$32,$30,$36,$32,$00,$00,$00
start:
		jsr $E544			;cls

		lda #0
		sta $FB
		lda #4
		sta $FC
		ldy #$00

-		lda text,y
		beq +
		sta ($FB),y
		iny
		bne -
+		ldy #120

		lda #0
		ldx #0
-		sta $D400,x
		inx
		cpx #$18
		bne -

		; volume and filter ($10=LP $20=BP $40=HP)
		lda #$0F
		sta $D418
		jsr puthex
		lda #$00		; reso + voice (1=v1 2=v2 4=v3)
		sta $D417
		jsr puthex
		iny

		; filter (11-bit max 7FF) (3 lowest in $15, upper 8 in $16) $75B = ‭%1110.1011.011‬ dus $D415=3 $D416=$EB
		; 70 corresponds to 30 + 70 * 5.8 = ca 440 Hz
FILTER=70
		lda #>FILTER	; high
		sta $FF
		ldx #<FILTER	; low
		stx $D415
		jsr puthex
		txa
		jsr puthex
		txa
		lsr $FF
		ror
		lsr $FF
		ror
		lsr $FF
		ror
		sta $D416
		iny

		; pulsewidth (12-bit max FFF) $800 is 50%, 0 == 2047
PULSE=$800
		lda #>PULSE
		sta $D403
		jsr puthex
		lda #<PULSE
		sta $D402
		jsr puthex

		iny
		iny

		;ADSR
		lda #$8C
		sta $D405
		jsr puthex
		lda #$44
		sta $D406
		jsr puthex
		iny

		; freq (A-4) 440hz
		lda #>$1D46
		sta $D401
		jsr puthex
		lda #<$1D46
		sta $D400
		jsr puthex
		iny

loop:	jsr waitkey
		cmp #'Q'
		bne .not_end

		; volume off
 		lda #$00
		sta $D418
		rts

.not_end:
		ldx #$10	; tri
		cmp #$31			;'1'
		beq +
		ldx #$20	; saw
		cmp #$32
		beq +
		ldx #$30    ; tri+saw
		cmp #$33
		beq +
		ldx #$40	; pulse
		cmp #$34
		beq +
		ldx #$80

		; gate-on
+		txa
		ora #$01
		sta $D404
		sta $FE
		jsr puthex
		dey
		dey

		jsr waitkey

		; gate-off
		lda $FE
		and #$FE
		sta $D404
		jsr puthex
		dey
		dey

		jmp loop

;		      1234567890123456789012345678901234567890
text:	!scr "1/2/3/4/8=wave q=quit              synth"
        !scr "                                        "
		!scr "fmrv filt puls  adsr freq wv"
		!scr 0


; hexadecimal output
; A=input
; (FB/FC) is output location, offset by Y
; assumes PETSCI charset (1-6=A-F, 48-58=digits)
puthex:
		pha
		lsr
		lsr
		lsr
		lsr
		jsr .nibble
		pla
		and #$0F
.nibble:
		clc
		adc #48
		cmp #58
		bmi .isdigit
		sbc #57		; letter
.isdigit:
		sta ($FB),y
		iny
		rts

waitkey:
		sty $FF
-		jsr $FFE4		; getin (returns ASCII, e.g. $31='1' $41='A')
		beq -
		;jsr puthex ; DEBUG
		ldy $FF
		rts
