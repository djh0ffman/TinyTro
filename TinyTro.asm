; -------------------------------------------------------
; tiny tro
; -------------------------------------------------------

    INCDIR        "include"
    INCLUDE       "hw.i"
    INCLUDE       "funcdef.i"
    INCLUDE       "exec/exec_lib.i"
    INCLUDE       "graphics/graphics_lib.i"
    INCLUDE       "hardware/cia.i"
    include       "graphics/text.i"
    include       "macros.asm"
    include       "variables.asm"
;---------- Const ----------

    section       tinytro,code_c
CIAA              = $00bfe001

DMACONSET         = %1000001110000000

DISABLE_MUSIC     = 0             
SYSTEM_NICE       = 1

    IF            SYSTEM_NICE=0
    org           $40000
    ENDIF

Main:
                     ;movem.l    d0-a6,-(sp)
    PUSHALL

    lea           CUSTOM,a6
    lea           Variables(pc),a5

    IF            SYSTEM_NICE=1
    bsr           system_disable
    ELSE
    move.w        #$7fff,d0
    move.w        d0,$9A(a6)                           ; Disable Interrupts
    move.w        d0,$96(a6)                           ; Clear all DMA channels
    move.w        d0,$9C(a6)                           ; Clear all INT requests
    ENDIF
    bsr           KeyboardInit

    bsr           Init

.mainloop
    tst.w         FrameReq(a5)
    beq           .noreq

    move.w        #1,FrameActive(a5)
    clr.w         FrameReq(a5)
    bsr           HoffBannerLogic
    clr.w         FrameActive(a5)
.noreq

    cmp.w         #5,TitleStatus(a5)
    bcc           .noleft
    tst.b         KeyEnter(a5)
    bne           .yesenter

    btst          #6,$bfe001
    bne           .noleft
.yesenter
    move.w        #5,TitleStatus(a5)
.noleft
    tst.w         Exit(a5)
    beq           .mainloop

    IF            SYSTEM_NICE=1
    bsr           system_enable
    bsr           KeyboardRemove
    POPALL
    moveq         #0,d0
    rts
    ELSE

    nop                                                ; this is where you're hacky bootloader lives
    
    endif


Init:
    bsr           CinterInitMine

    move.l        #$BABEFEED,RandomSeed(a5)

    bsr           PrepRand

    move.l        #ScreenMem,d1
    lea           cpBannerPlanes(pc),a2
    move.w        d1,6(a2)
    swap          d1
    move.w        d1,2(a2)
    swap          d1
    move.l        #ScreenOffset,d1
    move.w        d1,8+6(a2)
    swap          d1
    move.w        d1,8+2(a2)
    swap          d1

    lea           cpBanner(pc),a4
    move.l        a4,cop1lc(a6)
    move.w        #DMACONSET,dmacon(a6)

    move.l        sys_vectorbase(a5),a0
    lea           VBlankTick(pc),a1
    move.l        a1,$6c(a0)

    move.w        #INTENASET!$C000,$9A(a6)             ; set Interrupts+ BIT 14/15

    IF            SYSTEM_NICE=0
    move.l        $4,a6
    lea           Variables(pc),a5
    lea           graphics_name(pc),a1
    moveq         #0,d0
    jsr           -552(a6)                             ; OpenLibrary()

    move.l        d0,a6
                   
    lea           FontDef(PC),a0
    lea           FontName(PC),a1
    move.l        a1,(a0)                              ;PC-relative, ya know!
    jsr           -72(a6)                              ;openFont(topaz.font)
    move.l        d0,a1
    move.l        tf_CharData(a1),TopazPtr(a5)         ;fontaddr
    move.w        tf_Modulo(a1),TopazMod(a5)           ; font mod
    ENDIF

    bsr           NurdleFont

    rts

FONT_CHAR_COUNT   = 224

NurdleFont:
    move.l        TopazPtr(a5),a0
    lea           FontTopaz,a1
    moveq         #0,d0
    move.w        TopazMod(a5),d0

    move.w        #FONT_CHAR_COUNT-1,d7
.charloop
    move.l        a0,a2
    moveq         #8-1,d6
.pixloop
    move.b        (a2),(a1)+
    add.l         d0,a2
    dbra          d6,.pixloop

    addq.l        #1,a0
    dbra          d7,.charloop
    rts


RAND_MAX          = 80+32

PrepRand:
    lea           RandList(a5),a0
    move.w        #RAND_MAX-1,d7
.loop
    RANDOMWORD
    and.w         #31<<3,d0
    move.w        d0,(a0)+
    dbra          d7,.loop
    rts


CinterInitMine:
    IF            DISABLE_MUSIC=1
    rts
    ENDIF
    PUSHALL
	; A2 = Music data
	; A4 = Instrument space
	; A6 = Cinter working memory 
    lea           TuneData,a2
    lea           InstrumentSpace,a4
    lea           Work,a6
    bsr.w         CinterInit    
    POPALL
    rts

CinterPlayMine:
    IF            DISABLE_MUSIC=1
    rts
    ENDIF

    PUSHALL
    lea           TuneData(pc),a2
    lea           Work,a6
	; A6 = Cinter working memory
    bsr.w         CinterPlay1

    lea           TuneData(pc),a2
    move.l        a2,a6
    lea           Work,a6
	; A6 = Cinter working memory
    bsr.w         CinterPlay2
    POPALL
    rts
     
VBlankTick:
    PUSHALL

    lea           CUSTOM,a6                   
    lea           Variables(pc),a5

    moveq         #$20,d0
    move.w        d0,$9c(a6)
    move.w        d0,$9c(a6)                           ; twice to avoid a4k hw bug

    ;move.w        #$040,$dff180
    addq.w        #1,TickCounter(a5)
    bsr           CinterPlayMine
    tst.w         FrameActive(a5)
    bne           .norun

    move.w        #1,FrameReq(a5)
.norun
    ;move.w        #$000,$dff180
    POPALL
    rte


    include       "banner.asm"
    include       "keyboard.asm"
    include       "cinter.asm"

    IF            SYSTEM_NICE=1
    include       "os_kill.asm"
    ENDIF


BKG_COLOR         = $113

cpBanner:
    dc.w          DIWSTRT,$2c81                        ; window start stop
    dc.w          DIWSTOP,$2cc1                        ; 192 + 8

    dc.w          DDFSTRT,$3c                          ; datafetch start stop 
    dc.w          DDFSTOP,$d4

    dc.w          BPLCON0,$a200                        ; set as 1 bp display
    dc.w          BPLCON1,$0040                        ; set scroll 0
    dc.w          BPLCON2,$0000    
    dc.w          BPL1MOD,0
    dc.w          BPL2MOD,0

    dc.w          COLOR00,$000
    dc.w          COLOR01,$ccc
    dc.w          COLOR02,$000
    dc.w          COLOR03,$ccc
cpBannerPlanes:
    dc.w          BPL1PTH,$0
    dc.w          BPL1PTL,$0    
    dc.w          BPL2PTH,$0
    dc.w          BPL2PTL,$0    

    ; top lines
    dc.w          $27ff,$fffe
    dc.w          COLOR00,$a22
    dc.w          $28ff,$fffe
    dc.w          COLOR00,$000
    dc.w          $29ff,$fffe
    dc.w          COLOR00,BKG_COLOR

cpSelect:
    ; select lines
    dc.w          $50ff,$fffe
    dc.w          COLOR00,BKG_COLOR
    dc.w          $58ff,$fffe
    dc.w          COLOR00,BKG_COLOR

    ; end lines
    dc.w          $ffdf,$fffe

    dc.w          $2eff,$fffe
    dc.w          COLOR00,$000
    dc.w          $2fff,$fffe
    dc.w          COLOR00,$a22
    dc.w          $30ff,$fffe
    dc.w          COLOR00,$000

                ;dc.w       $90df,$fffe            ;  end of loading thingy
                ;dc.w       BPLCON0,$0000   
    dc.l          COPPER_HALT
    dc.l          COPPER_HALT

FontDef:
    dc.l          0
    dc.w          8,0

TextProg:
    dc.l          LogoText
    dc.l          SCREEN_WIDTH_BYTE*8
    dc.w          0                                    ; no centring
    dc.w          6*FPS                                ; wait time

    dc.l          IntroText
    dc.l          SCREEN_WIDTH_BYTE*10
    dc.w          1                                    ; centring
    dc.w          15*FPS                               ; wait time

    dc.l          BBSText
    dc.l          SCREEN_WIDTH_BYTE*8
    dc.w          0                                    ; no centring
    dc.w          6*FPS                                ; wait time

    dc.l          IntroText
    dc.l          SCREEN_WIDTH_BYTE*10
    dc.w          1                                    ; centring
    dc.w          15*FPS                               ; wait time

    dc.l          0                                    ; repeat

MenuProg:
    dc.l          MenuText
    dc.l          SCREEN_WIDTH_BYTE*10
    dc.w          1                                    ; centring
    dc.w          15*FPS                               ; wait time
    dc.l          0
    
    IF            SYSTEM_NICE=0
graphics_name:   
    dc.b          'graphics.library',0
    even
    ENDIF

; 224*8
FontName:
    dc.b          "topaz.font",0
GfxLib:	
    dc.b          "graphics.library",0                 ;MUST BE ODD!
    even

LogoText:
    incbin        "ne7-tte.txt"
    dc.b          0
    even

BBSText:
    incbin        "r32_bbs_ad2.txt"
    dc.b          0

IntroText:
    incbin        "intro-text.txt"
    dc.b          0
    even

MENU_LINE         = 11
MENU_COUNT        = 2

MenuText:
    incbin        "menu.txt"
    dc.b          0
    even

TuneData:
    incbin        "C:\code\cinter\convert\tune.dat"

; ram area

SCREEN_WIDTH      = 640
SCREEN_WIDTH_BYTE = SCREEN_WIDTH/8
SCREEN_HEIGHT     = 256
SCREEN_SIZE       = SCREEN_WIDTH_BYTE*SCREEN_HEIGHT

Variables:
    dcb.b         Vars_sizeof


FontTopaz:
    dcb.b         FONT_CHAR_COUNT*8

ScreenOffset:
    dcb.b         SCREEN_WIDTH_BYTE*4
ScreenMem:
    dcb.b         HOFFBANNER_PLANE_SIZE,0

InstrumentSpace:
    dcb.b         44604
Work:
    dcb.b         $8000

    dc.b          "END!"