; ===========================================================================
; Oktalyzer v2.0 - Vampire replay routine
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled and improved by Franck 'hitchhikr' Charlet.
; ===========================================================================

; ===========================================================================
                IFD __VASM
                    mc68020
                ENDC

; ===========================================================================
_CUSTOM             equ     $DFF000
DMACON              equ     $96
INTENA              equ     $9A
INTREQ              equ     $9C
ADKCON              equ     $9E
COLOR00             equ     $180
FMODE               equ     $1FC
INTREQ2             equ     $29C
OKT_AUDIO_BASE      equ     $440
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
OKT_SET_AUDIO_LEN   MACRO
                    move.l  \1,(OKT_AUDIO_LEN,\2)
                    ENDM

OKT_SET_AUDIO_CTRL  MACRO
                    move.w  \1,(OKT_AUDIO_CTRL,\2)
                    ENDM

; ===========================================================================
OKT_custom_init:
                    bsr     OKT_get_vbr
                    add.l   #$78,d0
                    move.l  d0,(OKT_vbr-OKT_vars,a6)
                    lea     (_CUSTOM),a1
                    move.w  #$4000,(INTENA,a1)
                    move.w  #%1111,(DMACON,a1)
                    move.w  #%111111111111,(OKT_AUDIO_DMA,a1)
                    move.w  #$FF,(ADKCON,a1)
                    bset    #1,$BFE001
                    move.l  d0,a0
                    move.l  (a0),(OKT_old_irq-OKT_vars,a6)
                    lea     (OKT_cia_int-OKT_vars,a6),a2
                    move.l	a2,(a0)
                    lea     $BFD000|CIATBLO,a3
                    lea     (OKT_old_cia_timer-OKT_vars,a6),a2
                    move.b  CIAICR-CIATBLO(a3),(a2)+
                    move.b  CIACRB-CIATBLO(a3),(a2)+
                    move.b  CIATBLO-CIATBLO(a3),(a2)+
                    move.b  CIATBHI-CIATBLO(a3),(a2)
                    move.b  #%01111111,CIAICR-CIATBLO(a3)
                    move.l	#1773447,d0
; NTSC
;                    move.l  #1789773,d0
                    divu    #125,d0
                    move.b  d0,CIATBLO-CIATBLO(a3)
                    lsr.w   #8,d0
                    move.b  d0,CIATBHI-CIATBLO(a3)
                    move.b  #%10000010,CIAICR-CIATBLO(a3)
                    move.b  #%00010001,CIACRB-CIATBLO(a3)
                    move.w  #$E000,(INTENA,a1)
                    move.w  #$8200,(DMACON,a1)
                    rts

; ===========================================================================
OKT_stop:
                    movem.l d0/d1/a0/a1/a2/a6,-(a7)
                    lea     (OKT_vars,pc),a6
                    lea     (_CUSTOM),a2
                    move.w  #$7FFF,(INTREQ,a2)
                    move.w  #%111111111111,(INTREQ2,a2)
                    move.w  #$4000,(INTENA,a2)
                    move.w  #%1111,(DMACON,a2)
                    move.w  #%111111111111,(OKT_AUDIO_DMA,a2)
                    lea     (_CUSTOM|OKT_AUDIO_BASE),a2
                    moveq   #0,d0
                    moveq   #OKT_AUDIO_HW_CHANS-1,d1
.OKT_clear_all_vols:
                    move.w  d0,(OKT_AUDIO_VOL,a2)
                    lea     (OKT_AUDIO_SIZE,a2),a2
                    dbf     d1,.OKT_clear_all_vols
                    lea     $BFD000|CIATBLO,a0
                    lea     (OKT_old_cia_timer-OKT_vars,a6),a1
                    move.b  (a1)+,CIAICR-CIATBLO(a0)
                    move.b  (a1)+,CIACRB-CIATBLO(a0)
                    move.b  (a1)+,CIATBLO-CIATBLO(a0)
                    move.b  (a1),CIATBHI-CIATBLO(a0)
                    move.l  (OKT_vbr-OKT_vars,a6),a0
                    move.l  (OKT_old_irq-OKT_vars,a6),(a0)
                    move.w	#$C000,(INTENA-OKT_AUDIO_BASE,a2)
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
                    btst    #0,d0
                    beq.b   .OKT_no_processor
                    ; turn vampire extras on
                    move    sr,d0
                    or.w    #$800,d0
                    move    d0,sr
                    ; movec vbr,d0
                    dc.w    $4E7A,$0801
                    rte
.OKT_no_processor:
                    moveq   #0,d0
                    rte

; ===========================================================================
OKT_cia_int:
                    tst.b   $BFD000|CIAICR
                    movem.l d0-a6,-(a7)
                    lea     _CUSTOM|INTREQ,a0
                    move.w  #$2000,(a0)
                    move.w  #$2000,(a0)
                IFD SHOW_RASTERS
                    move.w  #$770,_CUSTOM|COLOR00
                ENDC
                    bsr     OKT_replay_handler
                IFD SHOW_RASTERS
                    move.w  #0,_CUSTOM|COLOR00
                ENDC
                    movem.l (a7)+,d0-a6
                    rte

; ===========================================================================
                    include "replay_common.asm"
