
; Amiga system shutdown and restore code
; based on original code by Stringray

DMASET       = %1000001000000000
;		     a----bcdefghi--j
;	a: SET/CLR Bit
;	b: Blitter Priority
;	c: Enable DMA
;	d: Bit Plane DMA
;	e: Copper DMA
;	f: Blitter DMA
;	g: Sprite DMA
;	h: Disk DMA
;	i..j: Audio Channel 0-3




; os startup



system_disable:     
                   move.l     $4,a6
                   lea        Variables,a5
                   lea        graphics_name(pc),a1
                   moveq      #0,d0
                   jsr        -552(a6)                        ; OpenLibrary()
                   move.l     d0,sys_gfxbase(a5)
                   bne.b      .gfxok
                   moveq      #-1,d0                          ; return failure
                   rts

.gfxok             move.l     d0,a6
                   
                   lea        FontDef(PC),a0
                   lea        FontName(PC),a1
                   move.l     a1,(a0)                         ;PC-relative, ya know!
                   jsr        -72(a6)                         ;openFont(topaz.font)
                   move.l     d0,a1
                   move.l     tf_CharData(a1),TopazPtr(a5)    ;fontaddr
                   move.w     tf_Modulo(a1),TopazMod(a5)      ; font mod

                   move.l     34(a6),sys_oldview(a5)
                   sub.l      a1,a1
                   bsr.w      doview
                   move.l     $26(a6),sys_copper1(a5)         ; Store old CL 1
                   move.l     $32(a6),sys_copper2(a5)         ; Store old CL 2
                   bsr        get_vectorbase
                   move.l     d0,sys_vectorbase(a5)
                   move.l     d0,a0

	***	Store Custom Regs	***

                   lea        $dff000,a6                      ; base address
                   move.w     $10(a6),sys_adk(a5)             ; Store old ADKCON
                   move.w     $1C(a6),sys_intena(a5)          ; Store old INTENA
                   move.w     $02(a6),sys_dma(a5)             ; Store old DMA
                   move.w     #$7FFF,d0
                   bsr        wait_raster
                   move.w     d0,$9A(a6)                      ; Disable Interrupts
                   move.w     d0,$96(a6)                      ; Clear all DMA channels
                   move.w     d0,$9C(a6)                      ; Clear all INT requests

                    
                   move.l     $6c(a0),sys_vblank(a5)
                   ;lea        vblank_server(pc),a1
                   ;move.l     a1,$6c(a0)


                   ;move.w     #INTENASET!$C000,$9A(a6)        ; set Interrupts+ BIT 14/15
                   ;move.w     #DMASET!$8200,$96(a6)       ; set DMA	+ BIT 09/15
                   moveq      #0,d0                           ; return success
                   
                   move.l     d0,SPR0DATA(a6)
                   rts

system_enable:     lea        Variables,a5
                   lea        $dff000,a6
                   clr.l      vblank_pointer(a5)

                   move.w     #$8000,d0
                   or.w       d0,sys_intena(a5)               ; SET/CLR-Bit to 1
                   or.w       d0,sys_dma(a5)                  ; SET/CLR-Bit to 1
                   or.w       d0,sys_adk(a5)                  ; SET/CLR-Bit to 1
                   subq.w     #1,d0
                   bsr        wait_raster
                   move.w     d0,$9A(a6)                      ; Clear all INT bits
                   move.w     d0,$96(a6)                      ; Clear all DMA channels
                   move.w     d0,$9C(a6)                      ; Clear all INT requests

                   move.l     sys_vectorbase(a5),a0
                   move.l     sys_vblank(a5),$6c(a0)

                   move.l     sys_copper1(a5),$80(a6)         ; Restore old CL 1
                   move.l     sys_copper2(a5),$84(a6)         ; Restore old CL 2
                   move.w     d0,$88(a6)                      ; start copper1
                   move.w     sys_intena(a5),$9A(a6)          ; Restore INTENA
                   move.w     sys_dma(a5),$96(a6)             ; Restore DMAcon
                   move.w     sys_adk(a5),$9E(a6)             ; Restore ADKcon
   
                   move.l     sys_gfxbase(a5),a6
                   move.l     sys_oldview(a5),a1              ; restore old viewport
                   bsr        doview

                   move.l     a6,a1
                   move.l     $4.w,a6
                   jsr        -414(a6)                        ; Closelibrary()
                   rts

doview:            jsr        -222(a6)                        ; LoadView()
                   jsr        -270(a6)                        ; WaitTOF()
                   jmp        -270(a6)


*******************************************
*** Get Address of the VBR		***
*******************************************

get_vectorbase:    move.l     a5,-(a7)
                   moveq      #0,d0                           ; default at $0
                   move.l     $4.w,a6
                   btst       #0,296+1(a6)                    ; 68010+?
                   beq.b      .is68k                          ; nope.
                   lea        .getit(pc),a5
                   jsr        -30(a6)                         ; SuperVisor()
.is68k             move.l     (a7)+,a5
                   rts

.getit             dc.l       $4E7A0801                       ;      vbr,d0
                   rte                                        ; back to user state code
	

wait_raster:       move.l     d0,-(a7)
.loop              move.l     $dff004,d0
                   and.l      #$1ff00,d0
                   cmp.l      #$30<<8,d0
                   bne.b      .loop
                   move.l     (a7)+,d0
                   rts


vblank_server:     movem.l    d0-a6,-(a7)

                   lea        CUSTOM,a6                   
                   lea        Variables,a5

                   lea        $dff09c,a6
                   moveq      #$20,d0
                   move.w     d0,(a6)
                   move.w     d0,(a6)                         ; twice to avoid a4k hw bug

                   move.l     vblank_pointer(a5),d0
                   beq.b      .noVBI
                   move.l     d0,a0
                   jsr        (a0)

.noVBI             movem.l    (a7)+,d0-a6
                   rte

VECTOR_SIZE  = $c0
VECTOR_COUNT = VECTOR_SIZE/4

graphics_name:     dc.b       'graphics.library',0
                   even
