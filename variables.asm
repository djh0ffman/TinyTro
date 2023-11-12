
FPS                    = 50
HOFFBANNER_COL         = 80
HOFFBANNER_ROW         = 32
HOFFBANNER_PLANE_SIZE  = HOFFBANNER_ROW*HOFFBANNER_COL*8
HOFFBANNER_MATRIX_SIZE = HOFFBANNER_ROW*HOFFBANNER_COL

INTENASET              = %1100000000100000
;		   ab-------cdefg--
;	a: SET/CLR Bit
;	b: Master Bit
;	c: Blitter Int
;	d: Vert Blank Int
;	e: Copper Int
;	f: IO Ports/Timers
;	g: Software Int

                           RSRESET
BanScreen:                 rs.l       1
BanMaxtrix:                rs.l       1
BanMaxtrixRender:          rs.l       1
BanCharCount:              rs.w       1
BanActive:                 rs.w       1
Ban_Sizeof                 rs.w       0


                           RSRESET
sys_gfxbase                rs.l       1
sys_oldview                rs.l       1
sys_copper1                rs.l       1
sys_copper2                rs.l       1
sys_vectorbase             rs.l       1
sys_vblank                 rs.l       1
sys_adk                    rs.w       1
sys_intena                 rs.w       1
sys_dma                    rs.w       1
sys_deadflag               rs.w       1
vblank_pointer             rs.l       1

TopazPtr:                  rs.l       1
TopazMod:                  rs.w       1

FrameReq:                  rs.w       1
FrameActive:               rs.w       1

TitleTimer:                rs.w       1
TitleStatus:               rs.w       1
HoffBannerTitlePos:        rs.l       1
HoffBannerPos:             rs.l       1
HoffBannerPos2:            rs.l       1
HoffBannerTextPtr:         rs.l       1
HoffBannerRow:             rs.w       1
PlanePos:                  rs.l       1
TextProgPtr:               rs.l       1
LineCount:                 rs.w       1
WaitTime:                  rs.w       1
Exit:                      rs.w       1

Options:                   rs.l       1
OptionId:                  rs.w       1

TextSpacing:               rs.l       1
Center:                    rs.w       1

KeyUp:                     rs.b       1
KeyDown:                   rs.b       1
KeyEnter:                  rs.b       1
KeySpare:                  rs.b       1

HoffBanItems:              rs.b       Ban_Sizeof*HOFFBANNER_ROW

HoffBannerLineOffests:     rs.w       HOFFBANNER_ROW+2
HoffBannerLineLengths:     rs.w       HOFFBANNER_ROW+2
RandList:                  rs.w       RAND_MAX
RandomSeed:                rs.l       1
TickCounter:               rs.w       1
HoffBannerMatrix:          rs.w       HOFFBANNER_MATRIX_SIZE
HoffBannerMatrixRender:    rs.w       HOFFBANNER_MATRIX_SIZE
Vars_sizeof:               rs.w       1
