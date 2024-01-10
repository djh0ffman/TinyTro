
*****************************************
** keyboard system
*****************************************

INTB_SETCLR  EQU (15)                                                                 ;Set/Clear control bit. Determines if bits
			   ;written with a 1 get set or cleared. Bits
			   ;written with a zero are allways unchanged.
INTB_INTEN   EQU (14)                                                                 ;Master interrupt (enable only )
INTB_EXTER   EQU (13)                                                                 ;External interrupt
INTB_DSKSYNC EQU (12)                                                                 ;Disk re-SYNChronized
INTB_RBF     EQU (11)                                                                 ;serial port Receive Buffer Full
INTB_AUD3    EQU (10)                                                                 ;Audio channel 3 block finished
INTB_AUD2    EQU (9)                                                                  ;Audio channel 2 block finished
INTB_AUD1    EQU (8)                                                                  ;Audio channel 1 block finished
INTB_AUD0    EQU (7)                                                                  ;Audio channel 0 block finished
INTB_BLIT    EQU (6)                                                                  ;Blitter finished
INTB_VERTB   EQU (5)                                                                  ;start of Vertical Blank
INTB_COPER   EQU (4)                                                                  ;Coprocessor
INTB_PORTS   EQU (3)                                                                  ;I/O Ports and timers
INTB_SOFTINT EQU (2)                                                                  ;software interrupt request
INTB_DSKBLK  EQU (1)                                                                  ;Disk Block done
INTB_TBE     EQU (0)                                                                  ;serial port Transmit Buffer Empty



INTF_SETCLR  EQU (1<<15)
INTF_INTEN   EQU (1<<14)
INTF_EXTER   EQU (1<<13)
INTF_DSKSYNC EQU (1<<12)
INTF_RBF     EQU (1<<11)
INTF_AUD3    EQU (1<<10)
INTF_AUD2    EQU (1<<9)
INTF_AUD1    EQU (1<<8)
INTF_AUD0    EQU (1<<7)
INTF_BLIT    EQU (1<<6)
INTF_VERTB   EQU (1<<5)
INTF_COPER   EQU (1<<4)
INTF_PORTS   EQU (1<<3)
INTF_SOFTINT EQU (1<<2)
INTF_DSKBLK  EQU (1<<1)
INTF_TBE     EQU (1<<0)

KEY_CHECK         MACRO
                  cmp.w        #\1,d0                                                 ; up
                  bne          .\@skip
                  tst.b        \2(a5)
                  bne          .\@skip
                  move.b       #1,\2(a5)
.\@skip                  
                  ENDM

KeyboardInit:       
                  movem.l      d0-a6,-(a7)
                  move.l       sys_vectorbase(a5),a0
                  move.l       $68(a0),StoreKeyboard
                  move.b       #CIAICRF_SETCLR|CIAICRF_SP,(ciaicr+$bfe001)            ;clear all ciaa-interrupts
                  tst.b        (ciaicr+$bfe001)
                  and.b        #~(CIACRAF_SPMODE),(ciacra+$bfe001)                    ;set input mode
                  move.w       #INTF_PORTS,(intreq+$dff000)                           ;clear ports interrupt
                  move.l       #KeyboardInterrupt,$68(a0)                             ;allow ports interrupt
                  move.w       #INTF_SETCLR|INTF_INTEN|INTF_PORTS,(intena+$dff000)
                  movem.l      (a7)+,d0-a6
                  rts

KeyboardRemove:        
                  movem.l      d0-a6,-(a7)
                  move.l       sys_vectorbase(a5),a0
                  move.w       #INTF_SETCLR|INTF_PORTS,(intena+$dff000)
                  move.l       StoreKeyboard,$68(a0)
                  movem.l      (a7)+,d0-a6
                  rts	

KeyboardInterrupt:        
                  PUSHALL
                  lea          Variables,a5

                  lea          $dff000,a0
                  move.w       intreqr(a0),d0
                  btst         #INTB_PORTS,d0
                  beq          .end
		
                  lea          $bfe001,a1
                  btst         #CIAICRB_SP,ciaicr(a1)
                  beq          .end

                  move.b       ciasdr(a1),d0                                          ;read key and store him
                  or.b         #CIACRAF_SPMODE,ciacra(a1)
                  not.b        d0
                  ror.b        #1,d0
                  spl          d1
                  and.w        #$7f,d0

                  tst.b        d1
                  beq          .nope
                  
                  KEY_CHECK    $4c,KeyUp
                  KEY_CHECK    $4d,KeyDown
                  KEY_CHECK    $44,KeyEnter

.nope
                  moveq        #3-1,d1                                                ;handshake
.wait1            move.b       vhposr(a0),d0
.wait2            cmp.b        vhposr(a0),d0
                  beq          .wait2
                  dbf          d1,.wait1

         	
                  and.b        #~(CIACRAF_SPMODE),ciacra(a1)                          ;set input mode

.end              move.w       #INTF_PORTS,intreq(a0)
                  tst.w        intreqr(a0)
KeyboardPatchPtr:
                  nop
                  nop
                  nop

                  POPALL
                  rte

Keys:             dcb.b        $80,0

StoreKeyboard:    dc.l         0
