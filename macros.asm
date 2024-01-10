** push and pops

PUSH          MACRO
              move.l     \1,-(sp)
              ENDM

POP           MACRO
              move.l     (sp)+,\1
              ENDM

PUSHM         MACRO
              movem.l    \1,-(sp)
              ENDM

POPM          MACRO
              movem.l    (sp)+,\1
              ENDM

PUSHMOST      MACRO
              movem.l    d0-a4,-(sp)
              ENDM

POPMOST       MACRO
              movem.l    (sp)+,d0-a4
              ENDM

PUSHALL       MACRO
              movem.l    d0-a6,-(sp)
              ENDM

POPALL        MACRO
              movem.l    (sp)+,d0-a6
              ENDM



** jump index
** 1 = index

JMPINDEX      MACRO
              add.w      \1,\1
              move.w     .\@jmplist(pc,\1.w),\1
              jmp        .\@jmplist(pc,\1.w)
.\@jmplist
              ENDM



RANDOMWORD    MACRO
              move.l     d1,-(sp)
              move.l     RandomSeed(a5),d0
              move.l     d0,d1
              swap.w     d0
              mulu.w     #$9D3D,d1
              add.l      d1,d0
              move.l     d0,RandomSeed(a5)
              clr.w      d0
              swap.w     d0
              move.l     (sp)+,d1
              ENDM



** jump index
** 1 = index

JMPINDEX      MACRO
              add.w      \1,\1
              move.w     .\@jmplist(pc,\1.w),\1
              jmp        .\@jmplist(pc,\1.w)
.\@jmplist
              ENDM
