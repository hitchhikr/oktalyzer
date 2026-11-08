; ===========================================================================
; Oktalyzer v2.0 - Amiga replay routine test
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled and improved by Franck 'hitchhikr' Charlet.
; ===========================================================================
                IFD __VASM
                    opt     o+
                    opt     a+
                    mc68000
                ENDC

; just for testing
SHOW_RASTERS        equ     1

_LVOLoadView        equ     -222
_LVOWaitTOF         equ     -270

; ===========================================================================
                    section start,code
start:
                    ; only necessary if using more than 4 channels
                    bsr     OKT_init_buffers
                    beq     .error_mem

                    move.l  4.w,a6
                    ; gfxbase
                    move.l  156(a6),a6
                    ; current view
                    move.l  34(a6),-(a7)
                    jsr     _LVOWaitTOF(a6)
                    sub.l   a1,a1
                    jsr     _LVOLoadView(a6)
                    jsr     _LVOWaitTOF(a6)
                    jsr     _LVOWaitTOF(a6)

                    move.w  $DFF01C,-(a7)
                    move.w  $DFF002,-(a7)
                    move.w  #$7FFF,$DFF096
                    move.w  #$7FFF,$DFF09A
                    lea	    music,a0
                    bsr	    OKT_init
                    beq     .error_init
.loop:
                    btst    #6,$BFE001
                    bne     .loop
                    bsr	    OKT_stop
.error_init:
                    move.w  #$7FFF,$DFF096
                    move.w  #$7FFF,$DFF09A
                    move.w  (a7)+,d0
                    or.w    #$8000,d0
                    move.w  d0,$DFF096
                    move.w  (a7)+,d0
                    or.w    #$C000,d0
                    move.w  d0,$DFF09A

                    ; restore view
                    move.l  (a7)+,a1
                    jsr     _LVOLoadView(a6)
                    jsr     _LVOWaitTOF(a6)
                    jsr     _LVOWaitTOF(a6)

                    ; only necessary if using more than 4 channels
                    bsr     OKT_release_buffers
.error_mem:

                    moveq   #0,d0
                    rts

; ===========================================================================
                    include "replay_amiga.asm"

; ===========================================================================
                    section music,data_c

music:              incbin  "lame d-mo_a.okta"
                    
                    end
