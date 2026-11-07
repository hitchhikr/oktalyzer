; ===========================================================================
; Oktalyzer v2.0 - Vampire replay routine test
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled and improved by Franck 'hitchhikr' Charlet.
; ===========================================================================
                IFD __VASM
                    opt     o+
                    opt     a+
                    mc68060
                ENDC

; just for testing
SHOW_RASTERS        equ     1

; ===========================================================================
                    section start,code
start:
                    move.w  $dff01c,-(a7)
                    move.w  $dff002,-(a7)
                    move.w  #$7fff,$dff096
                    move.w  #$7fff,$dff09a
                    lea	    music,a0
                    bsr	    OKT_init
                    beq     .error_init
.loop:
                    btst    #6,$bfe001
                    bne     .loop
                    bsr	    OKT_stop
.error_init:
                    move.w  #$7fff,$dff096
                    move.w  #$7fff,$dff09a
                    move.w  (a7)+,d0
                    or.w    #$8000,d0
                    move.w  d0,$dff096
                    move.w  (a7)+,d0
                    or.w    #$C000,d0
                    move.w  d0,$dff09a
                    moveq   #0,d0
                    rts

; ===========================================================================
                    include "replay_vampire.asm"

; ===========================================================================
                    section music,data_c

music:              incbin  "storm_v.okta"

                    end
