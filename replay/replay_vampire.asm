; ===========================================================================
; Oktalyzer Vampire replay routine
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled and improved by Franck 'hitchhikr' Charlet.
; ===========================================================================

; ===========================================================================
                IFD __VASM__
                    mc68020
                ENDC

; ===========================================================================
		            rsreset
OKT_AUDIO_BASE      equ     $DFF400
OKT_AUDIO_DMA       equ     $DFF296
OKT_AUDIO_ADR       equ     0
OKT_AUDIO_LEN       equ     4
OKT_AUDIO_VOL       equ     8
OKT_AUDIO_CTRL      equ     $A
OKT_AUDIO_PER       equ     $C
OKT_AUDIO_SIZE      equ     $10
OKT_AUDIO_HW_CHANS  equ     8
OKT_AUDIO_ALL_HW    equ     1

; ===========================================================================
OKT_SET_AUDIO_VOL   macro
                    ; set panning
                    move.w  d0,d1
                    mulu    (a4,d3.w),d0
                    lsr.w   #7,d0
                    lsl.w   #8,d0
                    mulu    (a4,d3.w),d1
                    lsr.w   #7,d1
                    or.w    d1,d0
                    move.w  \1,(OKT_AUDIO_VOL,\2)
                    endm

; ===========================================================================
OKT_custom_init:
                    bsr     OKT_get_vbr
                    add.l   #$78,d0
                    move.l  d0,(OKT_vbr-OKT_vars,a6)
                    lea     ($DFF0A0),a1
                    move.w  #$4000,($9A-$A0,a1)
                    move.w  #%11111111,($296-$A0,a1)
                    move.w  #$FF,($9E-$A0,a1)
                    move.l  (OKT_vbr-OKT_vars,a6),a0
                    move.l  (a0),(OKT_old_irq-OKT_vars,a6)
                    lea     (OKT_cia_int-OKT_vars,a6),a2
                    move.l	a2,(a0)
                    lea     $BFD000+CIATALO,a3
                    lea     (OKT_old_cia_timer-OKT_vars,a6),a2
                    move.b  #$7F,CIAICR-CIATALO(a3)
                    move.b  (a3),(a2)+
                    move.b  CIATAHI-CIATALO(a3),(a2)
                    move.l	#1773447,d0
; NTSC
;                    move.l  #1789773,d0
                    divu    #125,d0
                    move.b  d0,(a3)
                    lsr.w   #8,d0
                    move.b  d0,CIATAHI-CIATALO(a3)
                    move.b  #%10000001,CIAICR-CIATALO(a3)
                    move.b  #%10001,CIACRA-CIATALO(a3)
                    move.w  #$E000,($9A-$A0,a1)
                    move.w  #$8200,($96-$A0,a1)
                    moveq   #1,d0
                    rts

; ===========================================================================
OKT_stop:
                    movem.l d0/d1/a0/a1/a2/a6,-(a7)
                    lea     (OKT_vars,pc),a6
                    lea     ($DFF296),a2
                    move.w  #$7FFF,($9C-$96,a2)
                    move.w  #$4000,($9A-$96,a2)
                    move.w  #%11111111,(a2)
                    moveq   #0,d0
                    move.w  d0,($408-$96,a2)
                    move.w  d0,($418-$96,a2)
                    move.w  d0,($428-$96,a2)
                    move.w  d0,($438-$96,a2)
                    move.w  d0,($448-$96,a2)
                    move.w  d0,($458-$96,a2)
                    move.w  d0,($468-$96,a2)
                    move.w  d0,($478-$96,a2)
                    lea     $BFD000+CIATALO,a0
                    lea     (OKT_old_cia_timer-OKT_vars,a6),a1
                    move.b  (a1)+,(a0)
                    move.b  (a1),CIATAHI-CIATALO(a0)
                    move.b  #%10000,CIACRA-CIATALO(a0)
                    move.l  (OKT_vbr-OKT_vars,a6),a0
                    move.l  (OKT_old_irq-OKT_vars,a6),(a0)
                    move.w	#$C000,($9A-$96,a2)
                    movem.l (a7)+,d0/d1/a0/a1/a2/a6
                    rts

; ===========================================================================
OKT_get_vbr:
                    move.l  a6,-(a7)
                    move.l  4.w,a6
                    lea     .OKT_get_it(pc),a5
                    jsr     _LVOSupervisor(a6)
                    move.l  (a7)+,a6
                    rts
.OKT_get_it:
                    move.b  297(a6),d0
                    lea     OKT_processor(pc),a1
                    move.b  d0,(a1)
                    btst    #0,d0
                    beq.b   .OKT_no_processor
                    ; turn vampire extras on
                    move    sr,d1
                    or.w    #$800,d1
                    move    d1,sr
                    move.w  #%10000,$dff1fc
                    dc.w    $4E7A,$0801
                    rte
.OKT_no_processor:
                    moveq   #0,d0
                    rte

; ===========================================================================
OKT_cia_int:
                    tst.b   $BFDD00
                    movem.l d0-a6,-(a7)
                    lea     $DFF09C,a0
                    move.w  #$2000,(a0)
                    move.w  #$2000,(a0)
                    move.w  #$f0,$dff180
                    bsr     OKT_replay_handler
                    move.w  #$0,$dff180
                    movem.l (a7)+,d0-a6
                    rte

; ===========================================================================
OKT_main:
                    lea     (OKT_vars,pc),a6
                    bra     OKT_replay_handler

; ===========================================================================
                    include "replay_common.asm"
