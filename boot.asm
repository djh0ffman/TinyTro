; -------------------------------------------------------
;
; BOOT!
;
; when SYSTEM_FRIENDLY = 1 the intro exits into this code
; so you can pull up your cracks boot loader
;
;  move.w    OptionId(a5),d0                   ; this value is the selected item from the list
;  move.l    Options(a5),d0                    ; bit flags from options menu
; 
; -------------------------------------------------------  
  
    move.w    #$7fff,$dff096
    move.w    #$7fff,$dff09a
    move.w    #0,$dff180
NOPE
    bra       NOPE