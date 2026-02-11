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
_CUSTOM             equ     $DFF000
OKT_AUDIO_BASE      equ     $400
OKT_AUDIO_DMA       equ     $296
OKT_AUDIO_ADR       equ     0
OKT_AUDIO_LEN       equ     4
OKT_AUDIO_VOL       equ     8
OKT_AUDIO_CTRL      equ     $A
OKT_AUDIO_PER       equ     $C
OKT_AUDIO_SIZE      equ     $10
OKT_AUDIO_HW_CHANS  equ     8
OKT_AUDIO_VAMPIRE   equ     1

OKT_SONG_ID         equ     'SNG3'

; ===========================================================================
OKT_SET_AUDIO_PAN   MACRO
                    ; set panning
                    move.w  d0,d1
                    mulu    (a4,d3.w*4),d0
                    lsr.w   #7,d0
                    lsl.w   #8,d0
                    mulu    2(a4,d3.w*4),d1
                    lsr.w   #7,d1
                    or.w    d1,d0
                    ENDM

; ===========================================================================
OKT_custom_init:
                    bsr     OKT_get_vbr
                    add.l   #$78,d0
                    move.l  d0,(OKT_vbr-OKT_vars,a6)
                    move.w  #$4000,($DFF09A)
                    move.w  #%11111111,(_CUSTOM|OKT_AUDIO_DMA)
                    move.w  #$FF,($DFF09E)
                    move.l  (OKT_vbr-OKT_vars,a6),a0
                    move.l  (a0),(OKT_old_irq-OKT_vars,a6)
                    lea     (OKT_cia_int-OKT_vars,a6),a2
                    move.l	a2,(a0)
                    lea     $BFD000+CIATBLO,a3
                    lea     (OKT_old_cia_timer-OKT_vars,a6),a2
                    move.b  #$7F,CIAICR-CIATBLO(a3)
                    move.b  (a3),(a2)+
                    move.b  CIATBHI-CIATBLO(a3),(a2)
                    move.l	#1773447,d0
; NTSC
;                    move.l  #1789773,d0
                    divu    #125,d0
                    move.b  d0,(a3)
                    lsr.w   #8,d0
                    move.b  d0,CIATBHI-CIATBLO(a3)
                    move.b  #%10000010,CIAICR-CIATBLO(a3)
                    move.b  #%10001,CIACRB-CIATBLO(a3)
                    move.w  #$E000,($DFF09A)
                    move.w  #$8200,($DFF096)
                    rts

; ===========================================================================
OKT_stop:
                    movem.l d0/a0/a1/a2/a6,-(a7)
                    lea     (OKT_vars,pc),a6
                    lea     (_CUSTOM|OKT_AUDIO_BASE),a2
                    move.w  #$7FFF,($DFF09C)
                    move.w  #$4000,($DFF09A)
                    move.w  #%11111111,(a2)
                    moveq   #0,d0
                    move.w  d0,($408-$400,a2)
                    move.w  d0,($418-$400,a2)
                    move.w  d0,($428-$400,a2)
                    move.w  d0,($438-$400,a2)
                    move.w  d0,($448-$400,a2)
                    move.w  d0,($458-$400,a2)
                    move.w  d0,($468-$400,a2)
                    move.w  d0,($478-$400,a2)
                    lea     $BFD000+CIATBLO,a0
                    lea     (OKT_old_cia_timer-OKT_vars,a6),a1
                    move.b  (a1)+,(a0)
                    move.b  (a1),CIATBHI-CIATBLO(a0)
                    move.b  #%10000,CIACRB-CIATBLO(a0)
                    move.l  (OKT_vbr-OKT_vars,a6),a0
                    move.l  (OKT_old_irq-OKT_vars,a6),(a0)
                    move.w	#$C000,($DFF09A)
                    movem.l (a7)+,d0/a0/a1/a2/a6
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
                    bsr     OKT_replay_handler
                    movem.l (a7)+,d0-a6
                    rte

; ===========================================================================
                    include "replay_common.asm"
