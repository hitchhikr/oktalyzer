; ===========================================================================
; Oktalyzer v2.0 - Amiga replay routine
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled and improved by Franck 'hitchhikr' Charlet.
; ===========================================================================

; ===========================================================================
		            rsreset
OKT_SCALING_CODE:   rs.b    64000
OKT_LENGTHS:        rs.l    36*2
OKT_CODE_LENGTH:    rs.b    0

OKT_SCALING_LINES   equ     40000
OKT_BUFFERS_LENGTH  equ     313

_CUSTOM             equ     $DFF000
INTENAR             equ     $1C
INTREQR             equ     $1E
DMACON              equ     $96
INTENA              equ     $9A
INTREQ              equ     $9C
ADKCON              equ     $9E
COLOR00             equ     $180
OKT_AUDIO_BASE      equ     $A0
OKT_AUDIO_DMA       equ     DMACON
OKT_AUDIO_ADR       equ     0
OKT_AUDIO_LEN       equ     4
OKT_AUDIO_PER       equ     6
OKT_AUDIO_VOL       equ     8
OKT_AUDIO_SIZE      equ     $10
OKT_AUDIO_HW_CHANS  equ     4

OKT_SONG_ID         equ     'SNG2'

MEMF_ANY            equ     0
MEMF_CHIP           equ     2
MEMF_CLEAR          equ     $10000
_LVOAllocMem        equ     -198
_LVOFreeMem         equ     -210
_LVOCacheClearU     equ     -636
_LVOCacheClearE     equ     -642
CACRF_ClearI        equ     8

; ===========================================================================
OKT_SET_AUDIO_LEN   MACRO
                    move.w  \1,(OKT_AUDIO_LEN,\2)
                    ENDM

OKT_SET_AUDIO_CTRL  MACRO
                    ENDM

; ===========================================================================
OKT_init_buffers:
                    movem.l d1-a6,-(a7)
                    move.l  4.w,a0
                    move.b  297(a0),d0
                    move.b  d0,(OKT_processor)
                    move.l  #OKT_CODE_LENGTH,d0
                    moveq   #MEMF_ANY,d1
                    move.l  4.w,a6
                    jsr     (_LVOAllocMem,a6)
                    tst.l   d0
                    beq     .OKT_error
                    lea     (OKT_scaling_code_buffer,pc),a0
                    move.l  d0,(a0)
                    move.l  #OKT_SCALING_LINES,d0
                    moveq   #MEMF_ANY,d1
                    move.l  4.w,a6
                    jsr     (_LVOAllocMem,a6)
                    tst.l   d0
                    beq     .OKT_error
                    lea     (OKT_scaling_code_lines,pc),a0
                    move.l  d0,(a0)
                    move.l  #512,d0
                    move.l  #MEMF_CLEAR|MEMF_ANY,d1
                    move.l  4.w,a6
                    jsr     (_LVOAllocMem,a6)
                    tst.l   d0
                    beq     .OKT_error
                    lea     (OKT_channels_notes_buffers,pc),a0
                    move.l  d0,(a0)
                    move.l  #256*65,d0
                    btst    #1,(OKT_processor,pc)
                    beq     .OKT_alloc_table_020_l
                    move.l  #256*65*4,d0
.OKT_alloc_table_020_l:
                    moveq   #MEMF_ANY,d1
                    move.l  4.w,a6
                    jsr     (_LVOAllocMem,a6)
                    tst.l   d0
                    beq     .OKT_error
                    lea     (OKT_volumes_scaling_table,pc),a0
                    move.l  d0,(a0)
                    move.l  #512*8,d0
                    move.l  #MEMF_CLEAR|MEMF_CHIP,d1
                    move.l  4.w,a6
                    jsr     (_LVOAllocMem,a6)
                    tst.l   d0
                    beq     .OKT_error
                    lea     (OKT_vars,pc),a6
                    lea     (OKT_final_mixing_buffers-OKT_vars,a6),a0
                    move.l  d0,(a0)
                    move.l  (OKT_volumes_scaling_table-OKT_vars,a6),a0
                    moveq   #65-1,d6
                    move.l  #256,d2
.OKT_make_volumes_table_outer:
                    move.w  #256-1,d7
                    moveq   #1,d3
.OKT_make_volumes_table_inner:
                    move.l  d3,d0
                    cmp.w   #128,d0
                    bls     .OKT_wrap
                    sub.w   #256,d0
.OKT_wrap:
                    muls.w  d2,d0
                    neg.l   d0
                    asr.l   #8,d0
                    asr.l   #1,d0
                    move.b  d0,(a0)+
                    btst    #1,(OKT_processor-OKT_vars,a6)
                    beq     .OKT_sel_020_table
                    move.b  d0,(a0)+
                    move.b  d0,(a0)+
                    move.b  d0,(a0)+
.OKT_sel_020_table:
                    addq.l  #1,d3
                    dbf     d7,.OKT_make_volumes_table_inner
                    subq.l  #4,d2
                    dbf     d6,.OKT_make_volumes_table_outer
                    move.l  (OKT_scaling_code_buffer-OKT_vars,a6),a0
                    move.l  a0,a1
                    add.l   #OKT_LENGTHS,a1
                    move.l  a1,(OKT_lengths_ptr-OKT_vars,a6)
                    bsr     OKT_generate_scaling_code
                    movem.l (a7)+,d1-a6
                    moveq   #1,d0
                    rts
.OKT_error:
                    movem.l (a7)+,d1-a6
                    moveq   #0,d0
                    rts

; ===========================================================================
OKT_release_buffers:
                    movem.l d0-a6,-(a7)
                    move.l  4.w,a6
                    move.l  (OKT_final_mixing_buffers,pc),d0
                    beq     .OKT_empty_1
                    move.l  d0,a1
                    move.l  #512*8,d0
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_1:
                    move.l  (OKT_volumes_scaling_table,pc),d0
                    beq     .OKT_empty_2
                    move.l  d0,a1
                    move.l  #256*65,d0
                    btst    #1,(OKT_processor,pc)
                    beq     .OKT_free_table_l
                    move.l  #256*65*4,d0
.OKT_free_table_l:
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_2:
                    move.l  (OKT_channels_notes_buffers,pc),d0
                    beq     .OKT_empty_3
                    move.l  d0,a1
                    move.l  #512,d0
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_3:
                    move.l  (OKT_scaling_code_lines,pc),d0
                    beq     .OKT_empty_4
                    move.l  d0,a1
                    move.l  #OKT_SCALING_LINES,d0
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_4:
                    move.l  (OKT_scaling_code_buffer,pc),d0
                    beq     .OKT_empty_5
                    move.l  d0,a1
                    move.l  #OKT_CODE_LENGTH,d0
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_5:
                    movem.l (a7)+,d0-a6
                    rts

; ===========================================================================
OKT_custom_init:
                    bsr     OKT_get_vbr
                    add.l   #$70,d0
                    move.l  d0,(OKT_vbr-OKT_vars,a6)
                    sf      (OKT_buffer_flip-OKT_vars,a6)
                    move.l  (OKT_channels_notes_buffers-OKT_vars,a6),a0
                    moveq   #0,d1
                    move.w  #512-1,d0
.OKT_clear_notes_buffers:
                    move.b  d1,(a0)+
                    dbra    d0,.OKT_clear_notes_buffers
                    move.l  (OKT_final_mixing_buffers-OKT_vars,a6),a0
                    move.w  #512-1,d0
.OKT_clear_mix_buffers:
                    ; clear 8 bytes
                    move.l  d1,(a0)+
                    move.l  d1,(a0)+
                    dbra    d0,.OKT_clear_mix_buffers
                    lea     (_CUSTOM|OKT_AUDIO_BASE),a1
                    move.w  #$7FFF,(INTREQ-OKT_AUDIO_BASE,a1)
                    move.w  #$4780,(INTENA-OKT_AUDIO_BASE,a1)
                    move.w  #$F,(DMACON-OKT_AUDIO_BASE,a1)
                    move.w  #$FF,(ADKCON-OKT_AUDIO_BASE,a1)
                    move.l  (OKT_final_mixing_buffers-OKT_vars,a6),a0
                    move.l  a0,(OKT_AUDIO_BASE-OKT_AUDIO_BASE,a1)
                    lea     (512*2,a0),a0
                    move.l  a0,($B0-OKT_AUDIO_BASE,a1)
                    lea     (512*2,a0),a0
                    move.l  a0,($C0-OKT_AUDIO_BASE,a1)
                    lea     (512*2,a0),a0
                    move.l  a0,($D0-OKT_AUDIO_BASE,a1)
                    move.w  #OKT_BUFFERS_LENGTH/2,d0
                    move.w  d0,($A4-OKT_AUDIO_BASE,a1)
                    move.w  d0,($B4-OKT_AUDIO_BASE,a1)
                    move.w  d0,($C4-OKT_AUDIO_BASE,a1)
                    move.w  d0,($D4-OKT_AUDIO_BASE,a1)
                    move.w  #227,d0
                    move.w  d0,($A6-OKT_AUDIO_BASE,a1)
                    move.w  d0,($B6-OKT_AUDIO_BASE,a1)
                    move.w  d0,($C6-OKT_AUDIO_BASE,a1)
                    move.w  d0,($D6-OKT_AUDIO_BASE,a1)
                    clr.l   OKT_patched_addr
                    bset    #1,$BFE001
                    move.l  (OKT_vbr-OKT_vars,a6),a0
                    ; we use a level 6 interrupt if there are
                    ; no doubled channels in song
                    tst.w   (OKT_audio_int_single_bit-OKT_vars,a6)
                    bne     .OKT_no_double_channels
                    ; $78
                    addq.l  #8,a0
                    move.l  a0,(OKT_vbr-OKT_vars,a6)
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
                    move.w  #$E000,(INTENA-OKT_AUDIO_BASE,a1)
                    move.w  #$8200,(DMACON-OKT_AUDIO_BASE,a1)
                    rts
.OKT_no_double_channels:
                    move.l  (a0),(OKT_old_irq-OKT_vars,a6)
                    lea     (OKT_audio_int-OKT_vars,a6),a2
                    move.l	a2,(a0)
                    move.w  (OKT_audio_int_single_bit-OKT_vars,a6),d0
                    move.w	d0,(INTREQ-OKT_AUDIO_BASE,a1)
                    or.W    #$C000,d0
                    move.w	d0,(INTENA-OKT_AUDIO_BASE,a1)
                    move.w  #$8200,d0
                    ; only switch double channels on
                    or.w    (OKT_double_channels-OKT_vars,a6),d0
                    move.w  d0,(DMACON-OKT_AUDIO_BASE,a1)
                    rts

; ===========================================================================
OKT_stop:
                    movem.l d0/a0/a1/a2/a6,-(a7)
                    lea     (OKT_vars,pc),a6
                    lea     (_CUSTOM|OKT_AUDIO_DMA),a2
                    move.w  #$7FFF,(INTREQ-OKT_AUDIO_DMA,a2)
                    move.w  #$6780,(INTENA-OKT_AUDIO_DMA,a2)
                    move.w  #%1111,(a2)
                    moveq   #0,d0
                    move.w  d0,($A8-OKT_AUDIO_DMA,a2)
                    move.w  d0,($B8-OKT_AUDIO_DMA,a2)
                    move.w  d0,($C8-OKT_AUDIO_DMA,a2)
                    move.w  d0,($D8-OKT_AUDIO_DMA,a2)
                    tst.w   (OKT_audio_int_single_bit-OKT_vars,a6)
                    bne     .OKT_no_double_channels
                    lea     $BFD000|CIATBLO,a0
                    lea     (OKT_old_cia_timer-OKT_vars,a6),a1
                    move.b  (a1)+,CIAICR-CIATBLO(a0)
                    move.b  (a1)+,CIACRB-CIATBLO(a0)
                    move.b  (a1)+,CIATBLO-CIATBLO(a0)
                    move.b  (a1),CIATBHI-CIATBLO(a0)
.OKT_no_double_channels:
                    move.l  (OKT_vbr-OKT_vars,a6),a0
                    move.l  (OKT_old_irq-OKT_vars,a6),(a0)
                    move.w	#$C000,(INTENA-OKT_AUDIO_DMA,a2)
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
                    ; movec vbr,d0
                    dc.w    $4E7A,$0801
                    rte
.OKT_no_processor:
                    moveq   #0,d0
                    rte

; ===========================================================================
OKT_audio_int:
                    movem.l	d0-a6,-(a7)
                    lea	    _CUSTOM|INTENAR,a1
                    move.w	(a1)+,d0
                    and.w	(a1),d0
                    move.w  d0,-(a7)
                    and.w   (OKT_audio_int_single_bit,pc),d0
                    beq     .OKT_no_int
                IFD SHOW_RASTERS
                    move.w  #$77,(_CUSTOM|COLOR00)
                ENDC
                    bsr     OKT_main
                    lea     (_CUSTOM|OKT_AUDIO_BASE),a1
                    move.l  (OKT_final_mixing_buffers,pc),a0
                    tst.b   (OKT_buffer_flip)
                    beq     .OKT_buffer_2
                    lea     (512,a0),a0
.OKT_buffer_2:
                    move.w  (OKT_double_channels,pc),d1
                    btst    #0,d1
                    beq     .OKT_channel_1
                    move.l  a0,(a1)
.OKT_channel_1:
                    lea     (512*2,a0),a0
                    btst    #1,d1
                    beq     .OKT_channel_2
                    move.l  a0,($10,a1)
.OKT_channel_2:
                    lea     (512*2,a0),a0
                    btst    #2,d1
                    beq     .OKT_channel_3
                    move.l  a0,($20,a1)
.OKT_channel_3:
                    btst    #3,d1
                    beq     .OKT_no_int
                    lea     (512*2,a0),a0
                    move.l  a0,($30,a1)
.OKT_no_int:
                IFD SHOW_RASTERS
                    move.w  #0,(_CUSTOM|COLOR00)
                ENDC
                    move.w	(a7)+,_CUSTOM|INTREQ
                    movem.l	(a7)+,d0-a6
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
OKT_main:
                    bsr     OKT_replay_handler
                    move.l  (OKT_final_mixing_buffers-OKT_vars,a6),a5
                    lea     (512,a5),a5
                    not.b   (OKT_buffer_flip-OKT_vars,a6)
                    bne     .OKT_mix_buffers
                    move.l  (OKT_final_mixing_buffers-OKT_vars,a6),a5
.OKT_mix_buffers:
                    lea     (OKT_channels_data-OKT_vars,a6),a2
                    moveq   #8-1,d7
.OKT_mix_channels_buffers:
                    tst.b   (a2)
                    beq     .OKT_only_double_channels
                    clr.w   (OKT_mixing_routines_index-OKT_vars,a6)
                    btst    #1,(OKT_processor-OKT_vars,a6)
                    beq     .OKT_sel_020_code
                    move.w  #12,(OKT_mixing_routines_index-OKT_vars,a6)
.OKT_sel_020_code:
                    movem.l d7/a5,-(a7)
                    lea     (a2),a3
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    moveq   #0,d0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    move.b  (a0,d0.w),d0
                    moveq   #64,d1
                    sub.b   d0,d1
                    lsl.l   #8,d1
                    btst    #1,(OKT_processor-OKT_vars,a6)
                    beq     .OKT_020_table_l
                    lsl.l   #2,d1
.OKT_020_table_l:
                    lea     (OKT_BUFFERS_LENGTH,a5),a1
                    move.l  (OKT_volumes_scaling_table-OKT_vars,a6),a5
                    add.l   d1,a5
                    pea     (a2)
                    move.l  4.w,a6
                    lea     (_LVOCacheClearU,a6),a6
                    bsr     OKT_create_channel_waveform_data
                    lea     (OKT_vars,pc),a6
                    move.l  (a7)+,a2
                    add.w   d0,(OKT_mixing_routines_index-OKT_vars,a6)
                    move.l  (a7),d7
                    subq.w  #1,d7
                    ; mix buffer
                    move.l  4(a7),a1
                    tst.b   d0
                    bne     .OKT_second_buffer
                    ; first buffer has data: use the second buffer
                    move.l  (OKT_channels_notes_buffers-OKT_vars,a6),a1
.OKT_second_buffer:
                    ; next channel
                    lea     (CHAN_LEN,a2),a3
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    moveq   #0,d0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    move.b  (a0,d0.w),d0
                    moveq   #64,d1
                    sub.b   d0,d1
                    lsl.l   #8,d1
                    btst    #1,(OKT_processor-OKT_vars,a6)
                    beq     .OKT_020_table_r
                    lsl.l   #2,d1
.OKT_020_table_r:
                    lea     (OKT_BUFFERS_LENGTH,a1),a1
                    move.l  (OKT_volumes_scaling_table-OKT_vars,a6),a5
                    add.l   d1,a5
                    pea     (a2)
                    move.l  4.w,a6
                    lea     (_LVOCacheClearU,a6),a6
                    bsr     OKT_create_channel_waveform_data
                    lea     (OKT_vars,pc),a6
                    move.l  (a7)+,a2
                    movem.l (a7)+,d7/a5
                    add.w   d0,(OKT_mixing_routines_index-OKT_vars,a6)
                    move.w  (OKT_mixing_routines_index-OKT_vars,a6),d0
                    move.l  (OKT_mixing_routines_table,pc,d0.w),a3
                    jsr     (a3)
                    lea     (CHAN_LEN*2,a2),a2
                    lea     (512*2,a5),a5
                    subq.w  #1,d7
                    dbra    d7,.OKT_mix_channels_buffers
                    rts
.OKT_only_double_channels:
                    lea     (CHAN_LEN*2,a2),a2
                    lea     (512*2,a5),a5
                    subq.w  #1,d7
                    dbra    d7,.OKT_mix_channels_buffers
OKT_no_mix:
                    rts
OKT_mixing_routines_table:
                    dc.l    OKT_mix_000,OKT_no_mix,OKT_mix_000_empty
                    dc.l    OKT_mix_020,OKT_no_mix,OKT_mix_020_empty
OKT_mixing_routines_index:
                    dc.w    0

; ===========================================================================
; in:
; a1: dest buffer
; a3: channel
; a5: waveform volumes buffer
; out:
; d0: 0 = processed / 4 = not processed
OKT_create_channel_waveform_data:
                    lea     (OKT_patched_addr,pc),a2
                    tst.l   (CHAN_SMP_PROC_D,a3)
                    beq     .OKT_no_mix
                    tst.w   (CHAN_NOTE_D,a3)
                    bpl     .OKT_min
                    clr.w   (CHAN_NOTE_D,a3)
.OKT_min:
                    cmp.w   #36-1,(CHAN_NOTE_D,a3)
                    ble     .OKT_max
                    move.w  #36-1,(CHAN_NOTE_D,a3)
.OKT_max:
                    ; mixing buffer
                    move.l  a1,-(a7)
                    ; check if the sample has been processed
                    move.l  (CHAN_SMP_PROC_LEN_D,a3),d2
                    bgt     .OKT_process_samples
                    ; is there a repeat ?
                    tst.l   (CHAN_SMP_REP_LEN_D,a3)
                    beq     .OKT_no_repeat
                    ; yes: set restart
                    move.l  (CHAN_SMP_REP_START,a3),(CHAN_SMP_PROC_D,a3)
                    ; new length to process
                    move.l  (CHAN_SMP_REP_LEN_D,a3),(CHAN_SMP_PROC_LEN_D,a3)
                    bra     .OKT_process_samples
.OKT_no_repeat:
                    ; no: discard
                    clr.l   (CHAN_SMP_PROC_D,a3)
                    clr.l   (CHAN_SMP_PROC_LEN_D,a3)
                    addq.l  #4,a7
                    bra     .OKT_no_mix
.OKT_process_samples:
                    moveq   #0,d3
.OKT_continue_process_samples:
                    ; length still to process in source
                    move.l  (CHAN_SMP_PROC_LEN_D,a3),d4
                    ; we want to number of sample to read for this note
                    move.l  (OKT_lengths_ptr,pc),a0
                    moveq   #0,d0
                    move.w  (CHAN_NOTE_D,a3),d0
                    lsl.w   #3,d0
                    ; length of source bytes read for this note
                    move.l  4(a0,d0.w),d1
                    ; check if there's enough samples available to fill a complete mixbuffer
                    cmp.l   d4,d1
                    bge     .OKT_enough_samples
                    ; set maximum to mixbuffer reading
                    move.l  d1,d4
.OKT_enough_samples:
                    ; global amount of reading processed in d3
                    add.l   d4,d3
                    cmp.l   d3,d1
                    bge     .OKT_max_reading
                    move.l  d3,d6
                    sub.l   d1,d6
                    sub.l   d6,d4
                    ; max. to read
                    move.l  d1,d3
.OKT_max_reading:
                    move.l  d3,d2
                    ; table is 2 words
                    lsl.l   #2,d2
                    ; start of code chunk + offset in it
                    add.l   (a0,d0.w),d2
                    move.l  d2,a4
                    move.l  (a4),a4
                    ; source + length to process
                    move.l  (CHAN_SMP_PROC_D,a3),a0
                    add.l   d4,a0
                    moveq   #0,d0
                    ; execute the code
                    jsr     (a4)
                    ; de-patch the older one
                    tst.l   (OKT_patched_addr-OKT_patched_addr,a2)
                    beq     .OKT_no_depatch
                    move.l  (OKT_patched_addr,pc),a0
                    move.w  (OKT_patched_instruction,pc),(a0)
                    clr.l   (OKT_patched_addr-OKT_patched_addr,a2)
.OKT_no_depatch:
                    ; new patch for the next batch
                    move.l  a4,(OKT_patched_addr-OKT_patched_addr,a2)
                    move.w  (a4),(OKT_patched_instruction-OKT_patched_addr,a2)
                    ; rts (replaces a move.b -(a0),d0 or a subq.w  #1,a0)
                    move.w  #$4e75,(a4)
                    btst    #1,(OKT_processor,pc)
                    beq     .OKT_no_cut_code
                    movem.l a1/a3/a5,-(a7)
                    jsr     (a6)
                    movem.l (a7)+,a1/a3/a5
.OKT_no_cut_code:
                    ; check if the mix buffer was entirely processed
                    move.l  (a7),d0
                    ; (subtract start of the buffer)
                    sub.l   a1,d0
                    ; add the amount of samples processed
                    add.l   d4,(CHAN_SMP_PROC_D,a3)
                    ; remove the amount of samples processed
                    ; (either the complete sample length or the mixbuffer length)
                    sub.l   d4,(CHAN_SMP_PROC_LEN_D,a3)
                    move.l  #OKT_BUFFERS_LENGTH,d1
                    cmp.l   d1,d0
                    ; mixbuffer is full
                    bge     .OKT_processed
                    ; mixbuffer isn't full yet
                    move.l  (CHAN_SMP_PROC_LEN_D,a3),d2
                    bgt     .OKT_still_samples
                    ; check if there's a sample loop
                    tst.l   (CHAN_SMP_REP_LEN_D,a3)
                    beq     .OKT_max_fill
                    move.l  (CHAN_SMP_REP_START,a3),(CHAN_SMP_PROC_D,a3)
                    move.l  (CHAN_SMP_REP_LEN_D,a3),(CHAN_SMP_PROC_LEN_D,a3)
.OKT_still_samples:
                    bra     .OKT_continue_process_samples
.OKT_max_fill:
                    sub.l   d0,d1
                    ; fill the rest of the buffer with 0s
                    btst    #0,d1
                    beq     .OKT_odd
                    sf      -(a1)
                    subq.l  #1,d1
.OKT_odd:
                    lsr.l   #1,d1
                    add.l   d1,d1
                    beq     .OKT_processed
                    lea     (.OKT_processed,pc),a4
                    sub.l   d1,a4
                    moveq   #0,d0
                    jmp     (a4)
                REPT OKT_BUFFERS_LENGTH/2
                    move.w  d0,-(a1)
                ENDR
.OKT_processed:
                    tst.l   (OKT_patched_addr-OKT_patched_addr,a2)
                    beq     .OKT_exit_depatch
                    move.l  (OKT_patched_addr,pc),a0
                    move.w  (OKT_patched_instruction,pc),(a0)
                    clr.l   (OKT_patched_addr-OKT_patched_addr,a2)
                    btst    #1,(OKT_processor,pc)
                    beq     .OKT_exit_depatch
                    movem.l a1/a3/a5,-(a7)
                    jsr     (a6)
                    movem.l (a7)+,a1/a3/a5
.OKT_exit_depatch:
                    addq.l  #4,a7
                    moveq   #0,d0
                    rts
.OKT_no_mix:
                    moveq   #4,d0
                    rts

; ===========================================================================
OKT_mix_000:
                    move.l  (OKT_channels_notes_buffers,pc),a1
                    lea     (a5),a4
                    movem.l d7/a2/a5/a6,-(a7)
                REPT 6
                    movem.l (a4),d0-d7/a0/a2/a3/a5/a6
                    add.l   (a1)+,d0
                    add.l   (a1)+,d1
                    add.l   (a1)+,d2
                    add.l   (a1)+,d3
                    add.l   (a1)+,d4
                    add.l   (a1)+,d5
                    add.l   (a1)+,d6
                    add.l   (a1)+,d7
                    add.l   (a1)+,a0
                    add.l   (a1)+,a2
                    add.l   (a1)+,a3
                    add.l   (a1)+,a5
                    add.l   (a1)+,a6
                    movem.l d0-d7/a0/a2/a3/a5/a6,(a4)
                    lea     (52,a4),a4
                ENDR
                    movem.l (a7)+,d7/a2/a5/a6
                    rts

; ===========================================================================
OKT_mix_000_empty:
                    lea     (a5),a4
                    movem.l d7/a2/a5/a6,-(a7)
                    moveq   #0,d0
                    moveq   #0,d1
                    moveq   #0,d2
                    moveq   #0,d3
                    moveq   #0,d4
                    moveq   #0,d5
                    moveq   #0,d6
                    moveq   #0,d7
                    move.l  d0,a1
                    move.l  d0,a2
                    move.l  d0,a3
                    move.l  d0,a5
                    move.l  d0,a6
                    lea     (52*6,a4),a4
                REPT 6
                    movem.l d0-d7/a1/a2/a3/a5/a6,-(a4)
                ENDR
                    movem.l (a7)+,d7/a2/a5/a6
                    rts

; ===========================================================================
OKT_mix_020:
                    move.l  (OKT_channels_notes_buffers,pc),a1
                    lea     (a5),a4
                    movem.l d7/a2/a5/a6,-(a7)
                    moveq   #6-1,d7
.OKT_loop:
                    movem.l (a4),d0-d6/a0/a2/a3/a5/a6
                    add.l   (a1)+,d0
                    add.l   (a1)+,d1
                    add.l   (a1)+,d2
                    add.l   (a1)+,d3
                    add.l   (a1)+,d4
                    add.l   (a1)+,d5
                    add.l   (a1)+,d6
                    add.l   (a1)+,a0
                    add.l   (a1)+,a2
                    add.l   (a1)+,a3
                    add.l   (a1)+,a5
                    add.l   (a1)+,a6
                    movem.l d0-d6/a0/a2/a3/a5/a6,(a4)
                    lea     (48,a4),a4
                    dbf     d7,.OKT_loop
                    movem.l (a4),d0-d5
                    add.l   (a1)+,d0
                    add.l   (a1)+,d1
                    add.l   (a1)+,d2
                    add.l   (a1)+,d3
                    add.l   (a1)+,d4
                    add.l   (a1),d5
                    movem.l d0-d5,(a4)
                    movem.l (a7)+,d7/a2/a5/a6
                    rts

; ===========================================================================
OKT_mix_020_empty:
                    lea     (a5),a4
                    movem.l d7/a2/a5/a6,-(a7)
                    moveq   #3-1,d7
                    moveq   #0,d0
                    moveq   #0,d1
                    moveq   #0,d2
                    moveq   #0,d3
                    moveq   #0,d4
                    moveq   #0,d5
                    moveq   #0,d6
                    move.l  d0,a0
                    move.l  d0,a1
                    move.l  d0,a2
                    move.l  d0,a3
                    move.l  d0,a5
                    move.l  d0,a6
                    lea     (52*6,a4),a4
.OKT_loop:
                    movem.l d0-d6/a0/a1/a2/a3/a5/a6,-(a4)
                    movem.l d0-d6/a0/a1/a2/a3/a5/a6,-(a4)
                    dbf     d7,.OKT_loop
                    movem.l (a7)+,d7/a2/a5/a6
                    rts

; ===========================================================================
; generate the scaling frequencies code
OKT_generate_scaling_code:
                    move.l  (OKT_scaling_code_buffer,pc),a0
                    add.l   #OKT_LENGTHS,a0
                    lea     (OKT_scaling_freqs_table,pc),a5
                    move.l  (OKT_lengths_ptr,pc),a3
                    lea     (OKT_store_bytes_table,pc),a4
                    btst    #1,(OKT_processor,pc)
                    beq     .OKT_sel_020_code
                    addq.w  #2,a4
.OKT_sel_020_code:
                    move.l  (OKT_scaling_code_lines,pc),a6
                    moveq   #36-1,d7
.OKT_loop_freqs:
                    swap    d7
                    ; start offset of this lines chunk/freq
                    move.l  a6,(a3)+
                    subq.l  #2,a0
                    move.l  a0,(a6)+
                    move.w  (OKT_opcode_rts,pc),(a0)
                    moveq   #0,d2
                    moveq   #0,d3
                    ; source buffer position
                    moveq   #0,d5
                    moveq   #-1,d4
                    ; dest buffer position
                    moveq   #0,d6
.OKT_loop_freq:
                    move.w  (a4),d0
                    lea     (a4,d0.w),a1
                    cmp.w   d4,d3
                    beq.w   .OKT_wait_freq_nibble
                    move.w  d3,d0
                    sub.w   d4,d0
                    cmpi.w  #1,d0
                    beq     .OKT_no_load_store_skip
                    cmpi.w  #2,d0
                    beq     .OKT_no_skip_load_store
                    move.w  d6,d7
                    addq.w  #1,d7
                    ; will it be too big ? we're done
                    cmp.w   #OKT_BUFFERS_LENGTH,d7
                    bgt     .OKT_done_freq
                    ; position of the read
                    ; number of bytes written
                    subq.l  #2,a0
                    move.l  a0,(a6)+
                    move.w  (OKT_opcode_skip,pc),(a0)
                    subq.l  #6,a0
                    move.l  a0,(a6)+
                    move.l  (a1)+,(a0)
                    move.w  (a1),(4,a0)
                    addq.w  #2,d5
                    addq.w  #1,d6
                    bra     .OKT_freq_nibble
.OKT_no_skip_load_store:
                    move.w  d6,d7
                    addq.w  #1,d7
                    ; will it be too big ? we're done
                    cmp.w   #OKT_BUFFERS_LENGTH,d7
                    bgt     .OKT_done_freq
                    subq.l  #6,a0
                    move.l  a0,(a6)+
                    move.l  (a1)+,(a0)
                    move.w  (a1),(4,a0)
                    subq.l  #2,a0
                    move.l  a0,(a6)+
                    move.w  (OKT_opcode_skip,pc),(a0)
                    addq.w  #2,d5
                    addq.w  #1,d6
                    bra     .OKT_freq_nibble
.OKT_no_load_store_skip:
                    tst.w   d2
                    beq     .OKT_store_1_byte
                    subq.w  #1,d2
                    beq     .OKT_store_2_bytes
                    subq.w  #1,d2
                    beq     .OKT_store_3_bytes
                    subq.w  #1,d2
                    ; store 4 bytes
                    move.w  (12,a4),d0
                    lea     (a4,d0.w),a1
                    ; bytes in dest buffer
                    move.w  d6,d7
                    add.w   (2,a1),d7
                    ; will it be too big ? try less
                    cmp.w   #OKT_BUFFERS_LENGTH,d7
                    bgt     .OKT_store_3_bytes
                    add.w   (2,a1),d6
                    ; length to copy
                    moveq   #0,d0
                    move.w  (a1),d0
                    sub.l   d0,a0
                    move.l  a0,(a6)+
                    sub.l   d0,a1
                    lsr.w   #1,d0
                    subq.w  #1,d0
                    pea     (a0)
.OKT_copy_4_bytes:
                    move.w  (a1)+,(a0)+
                    dbra    d0,.OKT_copy_4_bytes
                    move.l  (a7)+,a0
                    addq.w  #1,d5
                    bra     .OKT_freq_nibble
.OKT_store_3_bytes:
                    move.w  (8,a4),d0
                    lea     (a4,d0.w),a1
                    ; bytes in dest buffer
                    move.w  d6,d7
                    add.w   (2,a1),d7
                    ; will it be too big ? try less
                    cmp.w   #OKT_BUFFERS_LENGTH,d7
                    bgt     .OKT_store_2_bytes
                    add.w   (2,a1),d6
                    ; length to copy
                    moveq   #0,d0
                    move.w  (a1),d0
                    sub.l   d0,a0
                    move.l  a0,(a6)+
                    sub.l   d0,a1
                    lsr.w   #1,d0
                    subq.w  #1,d0
                    pea     (a0)
.OKT_copy_3_bytes:
                    move.w  (a1)+,(a0)+
                    dbra    d0,.OKT_copy_3_bytes
                    move.l  (a7)+,a0
                    addq.w  #1,d5
                    bra     .OKT_freq_nibble
.OKT_store_2_bytes:
                    move.w  (4,a4),d0
                    lea     (a4,d0.w),a1
                    ; bytes in dest buffer
                    move.w  d6,d7
                    add.w   (2,a1),d7
                    ; will it be too big ? try less
                    cmp.w   #OKT_BUFFERS_LENGTH,d7
                    bgt     .OKT_store_1_byte
                    add.w   (2,a1),d6
                    ; length to copy
                    moveq   #0,d0
                    move.w  (a1),d0
                    sub.l   d0,a0
                    move.l  a0,(a6)+
                    sub.l   d0,a1
                    lsr.w   #1,d0
                    subq.w  #1,d0
                    pea     (a0)
.OKT_copy_2_bytes:
                    move.w  (a1)+,(a0)+
                    dbra    d0,.OKT_copy_2_bytes
                    move.l  (a7)+,a0
                    addq.w  #1,d5
                    bra     .OKT_freq_nibble
.OKT_store_1_byte:
                    move.w  (a4),d0
                    lea     (a4,d0.w),a1
                    move.w  d6,d7
                    addq.w  #1,d7
                    ; will it be too big ? we're done
                    cmp.w   #OKT_BUFFERS_LENGTH,d7
                    bgt     .OKT_done_freq
                    subq.l  #6,a0
                    move.l  a0,(a6)+
                    move.l  (a1)+,(a0)
                    move.w  (a1),(4,a0)
                    addq.w  #1,d5
                    addq.w  #1,d6
                    bra     .OKT_freq_nibble
.OKT_wait_freq_nibble:
                    addq.w  #1,d2
.OKT_freq_nibble:
                    cmp.w   #OKT_BUFFERS_LENGTH,d6
                    bgt     .OKT_done_freq
                    move.w  d3,d4
                    swap    d3
                    add.l   (a5),d3
                    swap    d3
                    bra     .OKT_loop_freq
.OKT_done_freq:
                    ; bytes processed in source for this chunk/freq
                    move.l  d5,(a3)+
                    addq.l  #4,a5
                    swap    d7
                    dbra    d7,.OKT_loop_freqs
                    rts

; ===========================================================================
OKT_store_bytes_table:
                    dc.w    OKT_opcodes_store_1_byte_000-OKT_store_bytes_table,OKT_opcodes_store_1_byte_020-OKT_store_bytes_table-2
                    dc.w    OKT_opcodes_store_2_bytes_000-OKT_store_bytes_table,OKT_opcodes_store_2_bytes_020-OKT_store_bytes_table-2
                    dc.w    OKT_opcodes_store_3_bytes_000-OKT_store_bytes_table,OKT_opcodes_store_3_bytes_020-OKT_store_bytes_table-2
                    dc.w    OKT_opcodes_store_4_bytes_000-OKT_store_bytes_table,OKT_opcodes_store_4_bytes_020-OKT_store_bytes_table-2
; ==================
; 2 bytes
OKT_opcode_skip:
                    subq.w  #1,a0
; ==================
; 2 bytes
OKT_opcode_rts:
                    rts
; ==================
; 6 bytes
OKT_opcodes_store_1_byte_000:
                    move.b  -(a0),d0
                    move.b  (a5,d0.w),-(a1)
; ===
OKT_opcodes_store_2_bytes_000_e:
                    move.b  -(a0),d0
                    move.b  (a5,d0.w),d0
                    move.b  d0,-(a1)
                    move.b  d0,-(a1)
OKT_opcodes_store_2_bytes_000:
                    dc.w    OKT_opcodes_store_2_bytes_000-OKT_opcodes_store_2_bytes_000_e,2
; ===
OKT_opcodes_store_3_bytes_000_e:
                    move.b  -(a0),d0
                    move.b  (a5,d0.w),d0
                    move.b  d0,-(a1)
                    move.b  d0,-(a1)
                    move.b  d0,-(a1)
OKT_opcodes_store_3_bytes_000:
                    dc.w    OKT_opcodes_store_3_bytes_000-OKT_opcodes_store_3_bytes_000_e,3
; ===
OKT_opcodes_store_4_bytes_000_e:
                    move.b  -(a0),d0
                    move.b  (a5,d0.w),d0
                    move.b  d0,-(a1)
                    move.b  d0,-(a1)
                    move.b  d0,-(a1)
                    move.b  d0,-(a1)
OKT_opcodes_store_4_bytes_000:
                    dc.w    OKT_opcodes_store_4_bytes_000-OKT_opcodes_store_4_bytes_000_e,4
                IFD __VASM
                    mc68020
                ENDC
; ==================
; 6 bytes
OKT_opcodes_store_1_byte_020:
                    move.b  -(a0),d0
                    move.b  (a5,d0.w*4),-(a1)
; ===
OKT_opcodes_store_2_bytes_020_e:
                    move.b  -(a0),d0
                    move.w  (a5,d0.w*4),-(a1)
OKT_opcodes_store_2_bytes_020:
                    dc.w    OKT_opcodes_store_2_bytes_020-OKT_opcodes_store_2_bytes_020_e,2
; ===
OKT_opcodes_store_3_bytes_020_e:
                    move.b  -(a0),d0
                    move.l  (a5,d0.w*4),-(a1)
                    addq.l  #1,a1
OKT_opcodes_store_3_bytes_020:
                    dc.w    OKT_opcodes_store_3_bytes_020-OKT_opcodes_store_3_bytes_020_e,3
; ===
OKT_opcodes_store_4_bytes_020_e:
                    move.b  -(a0),d0
                    move.l  (a5,d0.w*4),-(a1)
OKT_opcodes_store_4_bytes_020:
                    dc.w    OKT_opcodes_store_4_bytes_020-OKT_opcodes_store_4_bytes_020_e,4
            IFD __VASM
                IFD OKT_AUDIO_VAMPIRE
                    mc68020
                ELSE
                    mc68000
                ENDC
            ENDC

; ===========================================================================
OKT_scaling_freqs_table:
                    dc.l    $4409,$4814,$4C6E,$50E3,$55E6,$5B00,$606C,$662C,$6C40,$72A5,$7955
                    dc.l    $8090,$8813,$9028,$98DC,$A1C7,$ABCC,$B600,$C0D9,$CC59,$D881,$E54A
                    dc.l    $F2AA,$101B2,$11026,$12051,$13286,$1438E,$15696,$16C00,$181B2,$19745
                    dc.l    $1AF68,$1CA95,$1E555,$20365
OKT_lengths_ptr:
                    dc.l    0
OKT_buffer_flip:
                    dc.b    0
OKT_processor:
                    dc.b    0
OKT_patched_addr:
                    dc.l    0
OKT_patched_instruction:
                    dc.w    0
OKT_scaling_code_buffer:
                    dc.l    0
OKT_scaling_code_lines:
                    dc.l    0
OKT_channels_notes_buffers:
                    dc.l    0
OKT_volumes_scaling_table:
                    dc.l    0
OKT_final_mixing_buffers:
                    dc.l    0

; ===========================================================================
                    include "replay_common.asm"
