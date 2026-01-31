; ===========================================================================
; Oktalyzer Amiga replay routine test
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled and improved by Franck 'hitchhikr' Charlet.
; ===========================================================================

; ===========================================================================
                    section start,code
start:
                    ; only necessary if using more than 4 channels
                    bsr     OKT_init_buffers
                    beq     .error_mem
                    move.w  $dff01c,-(a7)
                    move.w  $dff002,-(a7)
                    move.w  #$7fff,$dff096
                    move.w  #$7fff,$dff09a
                    lea	    music,a0
                    bsr	    OKT_init
                    beq     .error
.loop:
                    btst    #6,$bfe001
                    bne     .loop
                    bsr	    OKT_stop
.error:
                    move.w  #$7fff,$dff096
                    move.w  #$7fff,$dff09a
                    move.w  (a7)+,d0
                    or.w    #$8000,d0
                    move.w  d0,$dff096
                    move.w  (a7)+,d0
                    or.w    #$C000,d0
                    move.w  d0,$dff09a
                    ; only necessary if using more than 4 channels
                    bsr     OKT_release_buffers
.error_mem:
                    moveq   #0,d0
                    rts

; ===========================================================================
                    include "replay_amiga.asm"

; ===========================================================================
                    section music,data_c

music:              ;incbin  "../songs/lame d-mo.okta"
                    incbin  "future melody.okta"
                    ;incbin  "storm angel.okta"
                    ;incbin  "../songs/future melody.okta"
                    ;incbin  "OKT.headwar"

                    end
