;              T         T               T


                   ifnd       CINTER_MANUAL_DMA
CINTER_MANUAL_DMA  set        0
                   endc

CINTER_DEGREES = 16384

                   rsreset
c_SampleState      rs.l       4
c_PeriodTable      rs.w       36+1
c_TrackSize        rs.w       1
c_InstPointer      rs.l       1
c_MusicPointer     rs.l       1
c_MusicEnd         rs.l       1
c_MusicLoop        rs.l       1
c_MusicState       rs.l       4*3
                   ifeq       CINTER_MANUAL_DMA
c_dma              rs.w       1
c_waitline         rs.w       1
                   endc
c_Instruments      rs.l       32*2
c_Sinus            rs.w       CINTER_DEGREES
c_SIZE             rs.w       0

                   ;printt     "c_TrackSize"
                   ;printv     c_TrackSize
                   ;printt     "c_Instruments"
                   ;printv     c_Instruments
                   ;printt     "c_SIZE"
                   ;printv     c_SIZE

CinterInit:
	; A2 = Music data
	; A4 = Instrument space
	; A6 = Cinter working memory

	; Raw instrument data must be copied to the start of the
	; instrument space before or after CinterInit is called.

CinterMakeSinus:
                   lea        c_Sinus(a6),a0
                   addq.l     #2,a0
                   lea.l      CINTER_DEGREES/2*2-2(a0),a1

                   moveq.l    #1,d7
.loop:
                   move.w     d7,d1
                   mulu.w     d7,d1
                   lsr.l      #8,d1

                   move.w     #2373,d0
                   mulu.w     d1,d0
                   swap.w     d0
                   neg.w      d0
                   add.w      #21073,d0
                   mulu.w     d1,d0
                   swap.w     d0
                   neg.w      d0
                   add.w      #51469,d0
                   mulu.w     d7,d0
                   lsr.l      #8,d0
                   lsr.l      #5,d0

                   move.w     d0,(a0)+
                   move.w     d0,-(a1)
                   neg.w      d0
                   move.w     d0,CINTER_DEGREES/2*2(a1)
                   move.w     d0,CINTER_DEGREES/2*2-2(a0)

                   addq.w     #1,d7
                   cmp.w      #CINTER_DEGREES/4,d7
                   blt.b      .loop

                   neg.w      d0
                   move.w     d0,-(a1)
                   neg.w      d0
                   move.w     d0,CINTER_DEGREES/2*2(a1)

; Sample parameters:
; short length, replength
; short mpitch, mod, bpitch
; short attack, distortions, decay
; short mpitchdecay, moddecay, bpitchdecay

; Sample state:
; long mpitch, mod, bpitch
; short ampdelta,amp

LONGMUL            macro
                   move.w     d0,d1
                   swap.w     d0
                   mulu.w     d2,d0
                   mulu.w     d2,d1
                   clr.w      d1
                   swap.w     d1
                   add.l      d1,d0
                   endm

CinterMakeInstruments:
                   lea        c_Instruments(a6),a5

	; Loop through instruments
                   move.w     (a2)+,d7
                   bpl.b      .instrumentloop
                   not.w      d7
	; Raw instruments
.rawloop:
	; Read length
                   clr.l      d5
                   move.w     (a2),d5
                   move.l     (a2)+,(a5)+
                   move.l     a4,(a5)+
                   add.l      d5,d5

                   add.l      #$200,a3
                   add.l      d5,a4
                   dbf        d7,.rawloop

                   move.w     (a2)+,d7

	; a0 = sinus			= lea c_Sinus(a6),a0
	; a1 = ok
	; a2 = "music data"		= 22* instrunum
	; a3 = ok
	; a4 = "instrument space"	= lea InstrumentSpace,a4
	; a5 = instruments (in c.w.m.)	= c_Instruments + (8*instrunum)
	; a6 = cinter working memory	= CinterSpace
	; d0-d6 = ok
	; d7 = "number of instruments"

	; Generated instruments
.instrumentloop:
	; Read length
	;move.l	(a2)+,(a5)+

                   clr.l      d5
                   move.w     (a2),d5
                   add.l      d5,d5

                   jsr        CinterGenerateJITCode(pc)

                   add.l      d5,a4

                   add.l      #$200,a3
                   add        #22,a2
                   add        #8,a5
                   dbf        d7,.instrumentloop

CinterComputePeriods:
                   lea        c_Sinus(a6),a0
                   lea        c_PeriodTable(a6),a1
                   move.w     #$e2b3,d0
                   move.l     #$0fc0fd20,d2
                   moveq.l    #0,d6
                   moveq.l    #36,d7                                                 ; Write extra dummy for alignment
.loop1:            mulu.w     #61865,d0
                   swap.w     d0
                   move.w     d0,d1
                   lsr.w      #6,d1
                   add.l      d2,d2
                   subx.w     d6,d1
                   move.w     d1,(a1)+
                   dbf        d7,.loop1

CinterParseMusic:
;	lea	c_TrackSize(a6),a1
                   move.w     (a2)+,d1
                   move.w     (a2)+,d0
                   move.w     d1,(a1)+
                   move.l     a2,(a1)+
                   add.w      d0,a2
                   move.l     a2,(a1)+
                   move.w     -(a2),d0
                   add.w      d1,a2
                   move.l     a2,(a1)+
                   add.w      d0,a2
                   move.l     a2,(a1)+
CinterInitEnd:
                   rts




CinterPlay1:
	; A6 = Cinter working memory

	; No filter!
                   bset.b     #1,$bfe001

	; Read music data
                   lea.l      $dff000,a3
                   lea        c_TrackSize(a6),a0
                   move.w     (a0)+,d1
                   move.l     (a0)+,a2
                   move.l     (a0)+,a1

	; Loop when end is reached
                   cmp.l      (a0)+,a1
                   bls.b      .notend
                   move.l     (a0),a1
                   move.l     a1,-8(a0)
.notend:

	; Turn off DMA for triggered channels
                   moveq.l    #0,d0
                   rept       4
                   move.w     (a1),d2
                   add.w      d1,a1
                   add.w      d2,d2
                   addx.w     d0,d0
                   endr
                   move.w     d0,$096(a3)

                   ifeq       CINTER_MANUAL_DMA
	; Save line and dma
                   move.w     $006(a3),d1
                   movem.w    d0/d1,c_dma-c_MusicLoop(a0)
                   endc
                   rts

CinterPlay2:
	; A6 = Cinter working memory

	; Advance position
                   lea.l      $dff000,a3
                   lea        c_TrackSize(a6),a0
                   move.w     (a0)+,d1
                   move.l     (a0)+,a2
                   move.l     (a0),a1
                   addq.l     #2,(a0)+
                   addq.l     #8,a0

	; Write to audio registers
                   lea.l      $0e0(a3),a3
                   clr.l      d5
                   moveq.l    #4-1,d7
.channelloop:
                   move.l     (a0)+,d3
                   move.l     (a0)+,a4
                   move.l     (a0),d2                                                ; Period|Volume
                   move.w     (a1),d0
                   add.w      d1,a1
                   bmi.b      .trigger

	; Adjust volume
                   rol.w      #7,d0
                   add.w      d0,d2
                   and.w      #63,d2
                   swap.w     d2

	; Adjust or set period
                   asr.w      #7,d0
                   add.w      d0,d2
                   add.b      d0,d0
                   bvc.b      .slide
                   move.w     c_PeriodTable(a6,d0.w),d2
.slide:            swap.w     d2
                   bra.b      .write

.trigger:
	; Set volume
                   rol.w      #7,d0
                   move.w     d0,d2
                   and.w      #63,d2
                   swap.w     d2

	; Look up note
                   lsr.w      #7,d0
                   move.l     a2,a5
                   moveq.l    #-8,d3
                   moveq.l    #0,d4
.noteloop:         move.b     (a5)+,d2
                   move.b     (a5)+,d4
                   move.w     (a5)+,d5
                   bne.b      .sameinst
                   addq.w     #8,d3
.sameinst:         sub.w      d4,d0
                   bge.b      .noteloop
                   add.w      d4,d0
                   add.b      d2,d0
                   add.b      d0,d0
                   move.w     c_PeriodTable(a6,d0.w),d2
                   swap.w     d2

	; Set instrument
                   lea        c_Instruments(a6),a5

                   if         SYNC_FX=1
                   cmp.w      #3*8,d3
                   bne        .skipkick
                   move.w     #SYNC_COL_COUNT-2,Variables+SyncKick
.skipkick
                   cmp.w      #4*8,d3
                   bne        .skipsnare
                   move.w     #SYNC_COL_COUNT-2,Variables+SyncSnare
.skipsnare
                   endif
				   
                   add.w      d3,a5

	; Read sample address, length and repeat
                   moveq.l    #1,d6
                   move.w     (a5)+,d3
                   move.w     (a5)+,d0
                   move.l     (a5),a4
                   beq.b      .norepeat
                   move.w     d0,d6
                   sub.w      d3,d0
                   sub.w      d0,a4
                   sub.w      d0,a4
.norepeat:
	; Save restart position and length
                   movem.l    d6/a4,-8(a0)
	; Add offset to sample address
                   move.l     (a5),a4
                   sub.w      d5,d3
                   add.w      d5,d5
                   add.l      d5,a4
.write:
	; Save period and volume
                   move.l     d2,(a0)+

	; Write to audio registers
                   subq.l     #6,a3
                   move.l     d2,-(a3)                                               ; Period|Volume	ch2 0dff0c6
                   move.w     d3,-(a3)                                               ; Length
                   move.l     a4,-(a3)                                               ; Pointer
                   dbf        d7,.channelloop

                   ifeq       CINTER_MANUAL_DMA
	; Wait for old DMA to stop, then start new DMA
                   move.w     (a0)+,d0
                   beq.b      .nodma
                   or.w       #$8000,d0
                   move.w     (a0)+,d1
                   add.w      #$0780,d1
                   lea.l      $dff000,a3
.dmawait:          cmp.w      $006(a3),d1
                   bgt.b      .dmawait
                   move.w     d0,$096(a3)
.nodma:
                   endc
                   rts

	; a0 = sinus will be lea'd
	; a1 = ok
	; a2 = "music data" will be read from a5
	; a3 = ok
	; a4 = "instrument space" will be read from a5
	; a5 = instruments (in c.w.m.)	= c_Instruments + (8*instrunum)
	; a6 = cinter working memory	= CinterSpace
Cinter_Samplecalc_start:
                   lea        c_Sinus(a6),a0
	;lea	c_Instruments(a6),a5
	;lsl.l	#3,d0
	;add.l	d0,a5

	;move.l	(a2)+,(a5)+


	; Read length
	;move.l	(a5),a2
	;clr.l	d5
	;move.w	(a2),d5
                   move.l     (a2)+,(a5)+                                            ; pituus ja repeatti(?)
                   move.l     a4,(a5)+
	;move.l	(a5)+,a4	; kohdeosoite
	;add.l	d5,d5		; pituus tuplataan

	; Init state
                   move.l     a6,a1                                                  ; working memory
                   rept       3
                   move.w     (a2)+,(a1)+
                   clr.w      (a1)+
                   endr
                   move.w     (a2)+,(a1)+                                            ; $d8f0-$fff5
                   clr.w      (a1)+

                   clr.w      (a4)+                                                  ; samplen alkuun tyhjää
                   subq.l     #2,d5
                   moveq.l    #0,d6                                                  ; Index

Cinter_Sampleloop:

	; Distortion parameters
;	move.l	a2,a3
;	move.w	(a3)+,d4

	; Modulation wave
                   move.l     a6,a1
                   move.w     d6,d2
                   move.l     (a1)+,d0
                   lsr.l      #2,d0
                   LONGMUL
Cinter_mdist:
;	lsr.w	#2,d0
;	add.w	d0,d0
;	move.w	(a0,d0.w),d0	; sinus sieltä
;	sub.w	#$1000,d4
;	bcc.b	.mdist
;	lsl.w	#4,d4		; $16-$ffff

	; Modulation strength
                   move.w     d0,d2
                   add.w      #$8000,d2
                   move.l     (a1)+,d3                                               ; TOKA $10000-$640000
                   move.l     d3,d0
                   lsr.l      #3,d3                                                  ; $2000-$c8000
	;move.l	(a1)+,d0	; häh? sama arvo? $10000-$640000
                   lsr.l      #2,d0                                                  ; $4000-$190000
                   LONGMUL
	;swap	d0
	;mulu	d2,d0
                   sub.l      d0,d3

	; Base wave
                   move.w     d6,d2                                                  ; indeksi
                   move.l     (a1)+,d0                                               ; KOLMAS $3900000 - $be000000
                   lsr.l      #2,d0
                   LONGMUL
	;swap	d0
	;mulu	d2,d0
                   sub.l      d3,d0                                                  ; Modulation
Cinter_bdist:
;	lsr.w	#2,d0
;	add.w	d0,d0
;	move.w	(a0,d0.w),d0
;	sub.w	#$1000,d4
;	bcc.b	.bdist
;	lsl.w	#4,d4

;	; Amplitude
;	move.w	(a1)+,d1
;.vpower:
;	muls.w	0(a1),d0	; Dummy offset for better compression
;	add.l	d0,d0
;	swap.w	d0
;	sub.w	#$1000,d4
;	bcc.b	.vpower
;	lsl.w	#4,d4

	; Final distortion
;	bra.b	.fdist_in
;.fdist:	lsr.w	#2,d0
;	add.w	d0,d0
;	move.w	(a0,d0.w),d0
;.fdist_in:
;	sub.w	#$1000,d4
;	bcc.b	.fdist

	; Write sample
                   add.w      d0,d0
                   bvc.b      .notover
                   subq.w     #1,d0
.notover:
                   move.w     d0,$dff180
                   asr.w      #8,d0
                   move.b     d0,(a4)+

	; Attack-Decay
	;move.w	(a3)+,d2
                   sub.w      d1,(a1)
Cinter_attackdecay:
;	bvc.b	.nottop
;	move.w	#32767,(a1)
;	;move.w	(a3),-(a1)
;	move.w	#$0,-(a1)
;.nottop:
;	bpl.b	.notzero
;	clr.w	(a1)
;.notzero:
;	addq	#2,a3
;	; Pitch and mod decays
;	move.l	a6,a1
;	rept	3
;	move.l	(a1),d0
;	move.w	(a3)+,d2
;	;beq.b	*+22	; Optimization, can be omitted
;	LONGMUL
;	;swap	d0
;	;mulu	d2,d0
;	tst.w	d2
;	bmi.b	*+4
;	add.l	(a1),d0
;	move.l	d0,(a1)+
;	endr

;	addq.l	#1,d6
;	cmp.l	d5,d6
;	blt.w	.sampleloop

;	;move.l	a3,a2
;	rts




; a2 = music area
; a3 = jitcode-area
CinterGenerateJITCode:

	;move	a0,$dff180

                   movem.l    d7/a0/a3/a4/a5,-(sp)

                   move.l     a3,a0

	; store/retrieve a2,a4,a5,d5

                   move       #$45f9,(a0)+
                   move.l     a2,(a0)+
                   move       #$49f9,(a0)+                                           ;	49f9 00df f000	LEA.L $00dff000,A4
                   move.l     a4,(a0)+
                   move       #$4bf9,(a0)+                                           ;	4bf9 00df f000	LEA.L $00dff000,A5
                   move.l     a5,(a0)+
                   move       #$2a3c,(a0)+                                           ;	2a3c 0000 0000	MOVE.L #$00000000,D5
                   move.l     d5,(a0)+

                   lea        Cinter_Samplecalc_start(pc),a1
                   move       #(Cinter_Sampleloop-Cinter_Samplecalc_start)/2-1,d7
.copystart:
                   move       (a1)+,(a0)+
                   dbf        d7,.copystart

                   lea        $c(a2),a3
                   move.w     (a3)+,d4

                   move.l     a0,a4                                                  ; a4 = sampleloop

                   move       #(Cinter_mdist-Cinter_Sampleloop)/2-1,d7
.copycode1:
                   move       (a1)+,(a0)+
                   dbf        d7,.copycode1

.mdist:
				;	e448	LSR.W #$00000002,D0
				;	d040	ADD.W D0,D0
                   move.l     #$e448d040,(a0)+
                   move.l     #$30300000,(a0)+                                       ;	3030 0000	MOVE.W (A0, D0.W*1, $00) == $00c23ecf,D0
                   sub        #$1000,d4                                              ;	987c 1000	SUB.W #$1000,D4
                   bcc.b      .mdist                                                 ;	64f2	BCC.B #$fffffff2 == $00c085de (T)
                   lsl        #4,d4                                                  ;	e94c	LSL.W #$00000004,D4

                   move       #(Cinter_bdist-Cinter_mdist)/2-1,d7
.copycode2:
                   move       (a1)+,(a0)+
                   dbf        d7,.copycode2

.bdist:
				;	e448	LSR.W #$00000002,D0
				;	d040	ADD.W D0,D0
                   move.l     #$e448d040,(a0)+
			;	3030 0000	MOVE.W (A0, D0.W*1, $00) == $00c23ecf,D0
                   move.l     #$30300000,(a0)+
                   sub        #$1000,d4
                   bcc.b      .bdist
                   lsl        #4,d4                                                  ;	e94c	LSL.W #$00000004,D4
                   move       #$3219,(a0)+                                           ;	3219	MOVE.W (A1)+,D1

.vpower:
			;	c1e9 0000	MULS.W (A1, $0000) == $00c1fd76,D0
                   move.l     #$c1e90000,(a0)+
				;	d080	ADD.L D0,D0
                   move.l     #$d0804840,(a0)+                                       ;	4840	SWAP.W D0
                   sub        #$1000,d4                                              ;	987c 1000	SUB.W #$1000,D4
                   bcc.b      .vpower                                                ;	64f2	BCC.B #$fffffff2 == $00c08634 (T)
                   lsl        #4,d4                                                  ;	e94c	LSL.W #$00000004,D4
                   bra.s      .fdist_in                                              ;	6008	BT .B #$00000008 == $00c0864e (T)

.fdist:
				;	e448	LSR.W #$00000002,D0
				;	d040	ADD.W D0,D0
                   move.l     #$e448d040,(a0)+
                   move.l     #$30300000,(a0)+                                       ;	3030 0000	MOVE.W (A0, D0.W*1, $00) == $00c23ecf,D0
.fdist_in:
                   sub        #$1000,d4                                              ;	987c 1000	SUB.W #$1000,D4
                   bcc.b      .fdist                                                 ;	64f2	BCC.B #$fffffff2 == $00c08646 (T)

                   move       #(Cinter_attackdecay-Cinter_bdist)/2-1,d7
.copycode3:
                   move       (a1)+,(a0)+
                   dbf        d7,.copycode3

                   move       #$6808,(a0)+                                           ;	6808	BVC.B #$00000008 == $00c08526 (T)
                   move.l     #$32bc7fff,(a0)+                                       ;	32bc 7fff	MOVE.W #$7fff,(A1)
                   move       #$333c,(a0)+                                           ;	333c 0000	MOVE.W #$0000,-(A1)

                   move       (a3)+,(a0)+
				;	6a02	BPL.B #$00000002 == $00c0866c (T)
				;	4251	CLR.W (A1)
                   move.l     #$6a024251,(a0)+
                   move       #$224e,(a0)+                                           ;	224e	MOVEA.L A6,A1

                   moveq      #2,d7
.muluopt:
                   move       (a3)+,d2
                   bne.s      .notmulu0

                   move       #$5849,(a0)+                                           ; 	5849	ADDA.W #$00000004,A1
                   dbf        d7,.muluopt
                   bra        .muludone
.notmulu0:
                   cmp        #1,d2
                   bne.s      .notmulu1
				;	2011	MOVE.L (A1),D0
                   move       #$2011,(a0)+
				;	4240	CLR.W D0
				;	4840	SWAP.W D0
                   move.l     #$42404840,(a0)+
                   move       #$d199,(a0)+                                           ;	d199	ADD.L D0,(A1)+

                   dbf        d7,.muluopt
                   bra.s      .muludone
.notmulu1:
                   cmp        #-1,d2
                   bne.s      .notmuluneg1

				;	2011	MOVE.L (A1),D0
				;	2800	MOVE.L D0,D4
                   move.l     #$20112800,(a0)+
				;	4240	CLR.W D0
				;	2200	MOVE.L D0,D1
                   move.l     #$42402200,(a0)+
				;	4841	SWAP.W D1
				;	9081	SUB.L D1,D0
                   move.l     #$48419081,(a0)+
				;	3204	MOVE.W D4,D1
				;	4844	SWAP.W D4
                   move.l     #$32044844,(a0)+
				;	4244	CLR.W D4
				;	9881	SUB.L D1,D4
                   move.l     #$42449881,(a0)+
				;	4244	CLR.W D4
				;	4844	SWAP.W D4
                   move.l     #$42444844,(a0)+
				;	d084	ADD.L D4,D0
				;	22c0	MOVE.L D0,(A1)+
                   move.l     #$d08422c0,(a0)+
                   dbf        d7,.muluopt
                   bra.s      .muludone

.notmuluneg1:

	; worst case scenario: the original mulu macro
                   move       #$2011,(a0)+                                           ;	2011		MOVE.L (A1),D0
                   move       #$343c,(a0)+                                           ;	343c 0000	MOVE.W #$0000,D2
                   move       d2,(a0)+
				;	3200	MOVE.W D0,D1
				;	4840	SWAP.W D0
                   move.l     #$32004840,(a0)+
				;	c0c2	MULU.W D2,D0
				;	c2c2	MULU.W D2,D1
                   move.l     #$c0c2c2c2,(a0)+
				;	4241	CLR.W D1
				;	4841	SWAP.W D1
                   move.l     #$42414841,(a0)+
                   move       #$d081,(a0)+                                           ;	d081	ADD.L D1,D0
                   tst.w      d2                                                     ;	4a42	TST.W D2

                   bmi.b      .neg                                                   ;	6b02	BMI.B #$00000002 == $00c08688 (F)
                   move       #$d199,(a0)+                                           ;	d199	ADD.L D0,(A1)+
                   dbf        d7,.muluopt
                   bra.s      .muludone
.neg:              move       #$22c0,(a0)+                                           ;	22c0	MOVE.L D0,(A1)+
                   dbf        d7,.muluopt
.muludone:

				;	5286	ADD.L #$00000001,D6
				;	bc85	CMP.L D5,D6
                   move.l     #$5286bc85,(a0)+

                   move       #$6d00,(a0)+                                           ;	6d00 ff00 BLT.W #$ff00
                   move.l     a4,d0
                   sub.l      a0,d0
                   move       d0,(a0)+

                   move       #$4e75,(a0)+                                           ;	4e75	RTS
                   movem.l    (sp)+,d7/a0/a3/a4/a5
                   rts
