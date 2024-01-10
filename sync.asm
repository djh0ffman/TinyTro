
Sync:
    lea       SyncPal(pc),a0
    move.w    SyncKick(a5),d0
    move.w    SyncSnare(a5),d1
    move.w    (a0,d0.w),cpKickColor+2
    move.w    (a0,d1.w),cpSnareColor+2

    tst.w     SyncKick(a5)
    beq       .skipkick
    subq.w    #2,SyncKick(a5)
.skipkick
    tst.w     SyncSnare(a5)
    beq       .skipsnare
    subq.w    #2,SyncSnare(a5)
.skipsnare
    rts

SYNC_COL_COUNT = SyncPalEnd-SyncPal

SyncPal:
    dc.w      $a22,$b22,$c33,$c44,$e55,$e66,$f88,$faa
SyncPalEnd
