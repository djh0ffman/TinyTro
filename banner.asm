
;----------------------------------------------------------------------------
;
; h0ff banner
;
; ascii awesome!
;
;----------------------------------------------------------------------------

HoffBannerLogic:
    move.w        TitleStatus(a5),d0
    JMPINDEX      d0

.i
    dc.w          HoffBannerInit-.i
    dc.w          HoffBannerReveal-.i
    dc.w          HoffBannerShow1a-.i
    dc.w          HoffBannerShow2-.i
    dc.w          HoffBannerShow2a-.i
    dc.w          HoffBannerBye-.i
    dc.w          HoffBannerBye2-.i
    dc.w          HoffBannerInit-.i
    dc.w          HoffBannerReveal-.i
    dc.w          HoffBannerMenuWait-.i
    dc.w          HoffBannerMenu-.i
    dc.w          HoffBannerBye-.i
    dc.w          HoffBannerByeExit-.i


HoffBannerInit:
    bsr           HoffBannerCycleProg
    bsr           HoffBannerSetStarts
    bsr           HoffBannerSetItems
    bsr           HoffBannerPrep
    clr.w         HoffBannerTitlePos(a5)
    move.w        #2*FPS,TitleTimer(a5)
    addq.w        #1,TitleStatus(a5)
    rts

HoffBannerCycleProg:
    move.l        TextProgPtr(a5),a0
    tst.l         (a0)
    bne           .noloop
    lea           TextProg,a0
.noloop                     
    move.l        (a0)+,HoffBannerTextPtr(a5)
    move.l        (a0)+,TextSpacing(a5)
    move.w        (a0)+,Center(a5)
    move.w        (a0)+,WaitTime(a5)
    move.l        a0,TextProgPtr(a5)                     
    clr.w         HoffBannerRow(a5)
    rts

HoffBannerSetStarts:
    moveq         #0,d5                                   ; line count
    lea           HoffBannerLineOffests(a5),a1
    lea           HoffBannerLineLengths(a5),a3
    lea           HOFFBANNER_ROW*2(a1),a2
    move.l        HoffBannerTextPtr(a5),a0
.lineloop
    moveq         #-1,d1                                  ; counter
    moveq         #0,d0
.charloop
    addq.w        #1,d1
    move.b        (a0)+,d0
    cmp.b         #$20,d0
    beq           .charloop

    move.w        d1,(a1)+
    moveq         #-1,d1

.eol
    addq.w        #1,d1
    tst.b         d0
    beq           .exit
    cmp.b         #$a,d0
    beq           .linelen
    move.b        (a0)+,d0
    bra           .eol
.linelen
    move.w        d1,(a3)+
    addq.w        #1,d5                                   ;line count
    bra           .lineloop

.exit
    move.w        d5,LineCount(a5)
    rts

HoffBannerSetItems:
    move.w        #HOFFBANNER_ROW-1,d7
    lea           HoffBanItems(a5),a0
    lea           HoffBannerLineOffests(a5),a1
    lea           HoffBannerLineLengths(a5),a2
    moveq         #0,d5                                   ; screen offset
    moveq         #0,d4                                   ; matrix offset
.loop   
    moveq         #0,d0
    move.w        (a1)+,d0                                ; offset
    move.l        #ScreenMem,d1
    add.l         d0,d1
    add.l         d5,d1
    move.l        d1,BanScreen(a0)

    add.w         d0,d0                                   ; *2 for matrix

    lea           HoffBannerMatrix(a5),a3
    lea           HoffBannerMatrixRender(a5),a4

    add.l         d4,d0
    add.l         d0,a3
    add.l         d0,a4
    move.l        a3,BanMaxtrix(a0)                    
    move.l        a4,BanMaxtrixRender(a0)                    

    move.w        (a2)+,d3
    move.w        d3,BanCharCount(a0)

    moveq         #0,d0
    tst.w         Center(a5)
    beq           .nocenter
    lsr.w         #1,d3
    move.w        #HOFFBANNER_COL/2,d0
    sub.w         d3,d0
    add.l         d0,BanScreen(a0)
.nocenter

    add.l         TextSpacing(a5),d5
    add.l         #HOFFBANNER_COL*2,d4

    lea           Ban_Sizeof(a0),a0
    dbra          d7,.loop

    rts

HoffBannerPrep:
    move.w        #0,HoffBannerPos(a5)
    move.w        #HOFFBANNER_COL-1,HoffBannerPos2(a5)

    lea           HoffBannerMatrix(a5),a1
    lea           HoffBannerMatrixRender(a5),a2
    move.w        #HOFFBANNER_MATRIX_SIZE-1,d7
.clear
    clr.w         (a1)+
    move.w        #-1,(a2)+
    dbra          d7,.clear

    move.l        HoffBannerTextPtr(a5),a0
    lea           HoffBannerMatrix(a5),a1

.lineloop
    move.l        a1,a2
.charloop
    moveq         #0,d0
    move.b        (a0)+,d0
    beq           .done
    cmp.b         #$a,d0
    beq           .nextline
    sub.w         #$20,d0                                 ; remove first 32 characters
    lsl.w         #3,d0
    move.w        d0,(a2)+
    bra           .charloop
.nextline
    lea           HOFFBANNER_COL*2(a1),a1
    bra           .lineloop

.done
    ;lea           HoffBannerMatrixEnd,a3
    rts

HoffBannerReveal:
    move.w        TickCounter(a5),d0
    and.w         #1,d0
    beq           .doit
    bra           .printit
.doit
    RANDOMWORD
    and.w         #31,d0
    add.w         d0,d0
    lea           RandList(a5),a4
    lea           (a4,d0.w),a4

    moveq         #0,d0
    move.w        HoffBannerRow(a5),d0
    cmp.w         LineCount(a5),d0
    beq           .done

    mulu          #Ban_Sizeof,d0
    lea           HoffBanItems(a5),a3
    lea           (a3,d0.w),a3

    move.w        BanCharCount(a3),d7
    subq.w        #1,d7
    bmi           .nope

    move.l        BanMaxtrix(a3),a0
    move.l        BanMaxtrixRender(a3),a1
    move.w        #1,BanActive(a3)

.charloop
    move.w        (a0)+,d1
    add.w         (a4)+,d1
    move.w        d1,(a1)+
    dbra          d7,.charloop
.nope
    addq.w        #1,HoffBannerRow(a5)
.printit
    bsr           HoffBannerPrint
    rts

.done
    clr.w         HoffBannerPos(a5)
    move.w        WaitTime(a5),TitleTimer(a5)
    addq.w        #1,TitleStatus(a5)
    clr.w         HoffBannerTitlePos(a5)
    rts


HoffBannerPrint:
    PUSHALL
    lea           FontTopaz,a1
    lea           HoffBanItems(a5),a6
    move.w        #HOFFBANNER_ROW-1,d6
.lineloop
    tst.w         BanActive(a6)
    bne           .lineactive
    lea           Ban_Sizeof(a6),a6
    bra           .lineerror

.lineactive
    moveq         #0,d5                                   ; not active?
    move.l        (a6)+,a3                                ; screen
    move.l        (a6)+,a2
    move.l        (a6)+,a0           
    move.w        (a6)+,d7
                     
    subq.w        #1,d7
    bmi           .lineerror

;    move.w        #HOFFBANNER_COL-1,d7
.charloop
    move.w        (a2)+,d1
    move.w        (a0)+,d0
    bmi           .skipchar

    ; do sub
    cmp.w         d0,d1
    bne           .loadchar
    move.w        #-1,-2(a0)                              ; kill
.loadchar   
    subq.w        #8,-2(a0)
    moveq         #1,d5                                   ; active
    lea           (a1,d0.w),a4
    move.b        (a4)+,HOFFBANNER_COL*0(a3)
    move.b        (a4)+,HOFFBANNER_COL*1(a3)
    move.b        (a4)+,HOFFBANNER_COL*2(a3)
    move.b        (a4)+,HOFFBANNER_COL*3(a3)
    move.b        (a4)+,HOFFBANNER_COL*4(a3)
    move.b        (a4)+,HOFFBANNER_COL*5(a3)
    move.b        (a4)+,HOFFBANNER_COL*6(a3)
    move.b        (a4)+,HOFFBANNER_COL*7(a3)

.skipchar
    addq.l        #1,a3
    dbra          d7,.charloop

    move.w        d5,(a6)+
.lineerror
    dbra          d6,.lineloop
    POPALL
    rts




HoffBannerShow1a:
    bsr           HoffBannerPrint
    subq.w        #1,TitleTimer(a5)
    bne           .notyet

    clr.w         HoffBannerPos(a5)
    move.w        #3*FPS,TitleTimer(a5)
    addq.w        #1,TitleStatus(a5)
    clr.w         HoffBannerTitlePos(a5)
.notyet
    rts

HoffBannerClearInit:
    move.w        TickCounter(a5),d0
    and.w         #3,d0
    bne           .waitout

    moveq         #0,d0
    move.w        HoffBannerPos(a5),d0
    move.w        LineCount(a5),d1
    btst          #0,d1
    beq           .even
    addq.w        #1,d1
.even
    lsr.w         #1,d1
    cmp.w         d1,d0
    beq           .exit

    bsr           .dokill

    moveq         #0,d0
    move.w        LineCount(a5),d0
    subq.w        #1,d0
    sub.w         HoffBannerPos(a5),d0
    bsr           .dokill

    addq.w        #1,HoffBannerPos(a5)
.waitout
    rts
.exit
    addq.w        #1,TitleStatus(a5)
    rts

.dokill
    lea           HoffBanItems(a5),a4
    mulu          #Ban_Sizeof,d0
    lea           (a4,d0.w),a4

    move.w        BanCharCount(a4),d7
    beq           .lineerror
    subq.w        #1,d7

    move.w        #1,BanActive(a4)

    RANDOMWORD
    and.w         #31,d0
    add.w         d0,d0
    lea           RandList(a5),a3
    lea           (a3,d0.w),a3

    move.l        BanMaxtrix(a4),a1
    move.l        BanMaxtrixRender(a4),a2

.clear
    move.w        (a3)+,(a2)+
    clr.w         (a1)+
    dbra          d7,.clear

.lineerror
    rts

HoffBannerShow2:
    bsr           HoffBannerClearInit
    bsr           HoffBannerPrint
    rts


HoffBannerShow2a:
    bsr           HoffBannerPrint
    bsr           HoffBannerTest
    bne           .notyet
    clr.w         TitleStatus(a5)
.notyet
    rts

HoffBannerBye:
    bsr           HoffBannerClearInit
    bsr           HoffBannerPrint
    rts

HoffBannerBye2:
    bsr           HoffBannerPrint
    bsr           HoffBannerTest
    bne           .notyet
    addq.w        #1,TitleStatus(a5)
    move.l        #MenuProg,TextProgPtr(a5)
    bsr           HoffBannerInit
.notyet
    rts


HoffBannerByeExit:
    bsr           HoffBannerPrint
    bsr           HoffBannerTest
    bne           .notyet
    move.w        #1,Exit(a5)
.notyet
    rts

HoffBannerMenuWait:
    bsr           HoffBannerPrint
    bsr           HoffBannerTest
    bne           .notyet
    addq.w        #1,TitleStatus(a5)
    clr.b         KeyUp(a5)
    clr.b         KeyDown(a5)
    clr.b         KeyEnter(a5)
    move.w        #MENU_COUNT-1,OptionId(a5)
.notyet
    rts

HoffBannerMenu:
    bsr           HoffBannerPrint
    move.w        OptionId(a5),d0
    moveq         #-1,d1

    tst.b         KeyUp(a5)
    beq           .skipup
    clr.b         KeyUp(a5)
    subq.w        #1,d0
    bpl           .setoption
    bra           .testenter
.skipup
    tst.b         KeyDown(a5)
    beq           .skipdown
    clr.b         KeyDown(a5)
    addq.w        #1,d0
    cmp.w         #MENU_COUNT,d0
    bcs           .setoption
    bra           .testenter
.skipdown
.setoption
    move.w        d0,OptionId(a5)

.testenter
    tst.b         KeyEnter(a5)
    beq           .skipenter
    clr.b         KeyEnter(a5)

    move.w        OptionId(a5),d0
    cmp.w         #MENU_COUNT-1,d0
    bne           .noexit
    addq.w        #1,TitleStatus(a5)
    move.w        #BKG_COLOR,cpSelect+6
    bra           .byebye
.noexit
    moveq         #1,d1
    lsl.l         d0,d1
    eor.l         d1,Options(a5)
    bsr           HoffBannerPrintOption

.skipenter
    bsr           HoffBannerShowSelected
.byebye
    rts


HoffBannerPrintOption:
    lea           RandList(a5),a4
    move.w        OptionId(a5),d0
    move.w        d0,d6
    add.w         d0,d0
    add.w         #MENU_LINE,d0
    mulu          #Ban_Sizeof,d0
    lea           HoffBanItems(a5),a0
    lea           (a0,d0.w),a0
    move.l        BanMaxtrix(a0),a1
    move.l        BanMaxtrixRender(a0),a2
    move.w        BanCharCount(a0),d1
    sub.w         #5,d1
    add.w         d1,d1
    lea           (a1,d1.w),a1
    lea           (a2,d1.w),a2

    lea           OptionOn(pc),a3
    moveq         #1,d0
    lsl.w         d6,d0
    and.l         Options(a5),d0
    bne           .ison
    lea           OptionOff(pc),a3
.ison

    REPT          3
    move.w        (a3)+,d0
    move.w        d0,(a1)+
    add.w         (a4)+,d0
    move.w        d0,(a2)+
    ENDR

    move.w        #1,BanActive(a0)

    rts

OptionOn:
    dc.w          0
    dc.w          ("O"-$20)<<3
    dc.w          ("N"-$20)<<3

OptionOff:
    dc.w          ("O"-$20)<<3
    dc.w          ("F"-$20)<<3
    dc.w          ("F"-$20)<<3



HoffBannerShowSelected:
    move.w        OptionId(a5),d0
    add.w         d0,d0
    add.w         #MENU_LINE,d0
    mulu          #Ban_Sizeof,d0
    lea           HoffBanItems(a5),a0
    lea           (a0,d0.w),a0
    move.l        BanScreen(a0),d0
    sub.l         #ScreenMem,d0
    divu          #HOFFBANNER_COL,d0
    add.w         #$2b,d0
    lea           cpSelect,a0
    move.b        d0,(a0)
    addq.w        #8,d0
    move.b        d0,8(a0)
    move.w        #0,6(a0)
    rts

HoffBannerTest:
    lea           HoffBanItems(a5),a0
    move.w        #HOFFBANNER_ROW-1,d7
    moveq         #0,d0
.loop
    add.w         BanActive(a0),d0
    lea           Ban_Sizeof(a0),a0
    dbra          d7,.loop
    tst.w         d0
    rts