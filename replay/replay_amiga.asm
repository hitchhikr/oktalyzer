; ===========================================================================
; Oktalyzer Amiga replay routine
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled and improved by Franck 'hitchhikr' Charlet.
; ===========================================================================

; ===========================================================================
		            rsreset
OKT_SCALING_CODE:   rs.b    70800
OKT_CODE_POINTERS:  rs.l    36
OKT_LENGTHS:        rs.w    36*2
OKT_CODE_LENGTH:    rs.b    0
OKT_SCALING_MINES   equ     19552
OKT_BUFFERS_LENGTH  equ     312
OKT_AUDIO_BASE      equ     $DFF0A0
OKT_AUDIO_DMA       equ     $DFF096
OKT_AUDIO_ADR       equ     0
OKT_AUDIO_LEN       equ     4
OKT_AUDIO_PER       equ     6
OKT_AUDIO_VOL       equ     8
OKT_AUDIO_SIZE      equ     $10
OKT_AUDIO_HW_CHANS  equ     4
OKT_IN_TRACKER      equ     0
MEMF_ANY            equ     0
MEMF_CHIP           equ     2
MEMF_CLEAR          equ     $10000
_LVOAllocMem        equ     -198
_LVOFreeMem         equ     -210
_LVOCacheClearU     equ     -636
_LVOCacheClearE     equ     -642
CACRF_ClearI        equ     8

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

                    move.l  #OKT_SCALING_MINES,d0
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
                    btst    #1,(OKT_processor)
                    beq     .OKT_alloc_table_020_l
                    move.l  #256*65*4,d0
.OKT_alloc_table_020_l:
                    moveq   #MEMF_ANY,d1
                    move.l  4.w,a6
                    jsr     (_LVOAllocMem,a6)
                    tst.l   d0
                    beq     .OKT_error
                    lea     (OKT_volumes_scaling_table_l,pc),a0
                    move.l  d0,(a0)

                    move.l  #256*65,d0
                    btst    #1,(OKT_processor)
                    beq     .OKT_alloc_table_020_r
                    move.l  #256*65*4,d0
.OKT_alloc_table_020_r:
                    moveq   #MEMF_ANY,d1
                    move.l  4.w,a6
                    jsr     (_LVOAllocMem,a6)
                    tst.l   d0
                    beq     .OKT_error
                    lea     (OKT_volumes_scaling_table_r,pc),a0
                    move.l  d0,(a0)

                    move.l  #512*8,d0
                    move.l  #MEMF_CLEAR|MEMF_CHIP,d1
                    move.l  4.w,a6
                    jsr     (_LVOAllocMem,a6)
                    tst.l   d0
                    beq     .OKT_error
                    lea     (OKT_final_mixing_buffers,pc),a0
                    move.l  d0,(a0)

                    lea     (OKT_vars,pc),a6
                    move.l  (OKT_volumes_scaling_table_l-OKT_vars,a6),a0
                    ; interleaved table
                    move.l  (OKT_volumes_scaling_table_r-OKT_vars,a6),a1
                    moveq   #65-1,d6
                    move.l  #256,d2
.OKT_make_volumes_table_outer:
                    move.w  #256-1,d7
                    moveq   #1,d3
.OKT_make_volumes_table_inner:
                    move.l  d3,d0
                    cmp.w   #127,d0
                    bls     .OKT_wrap
                    sub.w   #256,d0
.OKT_wrap:
                    muls.w  d2,d0
                    asr.l   #8,d0
                    neg.w   d0
                    move.w  d0,d1
                    asr.b   #1,d0
                    muls.w  #65,d1
                    divs.w  #128,d1
                    move.b  d0,(a0)+
                    move.b  d1,(a1)+
                    btst    #1,(OKT_processor-OKT_vars,a6)
                    beq     .OKT_sel_020_code
                    move.b  d0,(a0)+
                    move.b  d0,(a0)+
                    move.b  d0,(a0)+
                    move.b  d1,(a1)+
                    move.b  d1,(a1)+
                    move.b  d1,(a1)+
.OKT_sel_020_code:
                    addq.l  #1,d3
                    dbf     d7,.OKT_make_volumes_table_inner
                    subq.l  #4,d2
                    dbf     d6,.OKT_make_volumes_table_outer
                    move.l  (OKT_scaling_code_buffer-OKT_vars,a6),a0
                    move.l  a0,a1
                    add.l   #OKT_CODE_POINTERS,a1
                    move.l  a1,(OKT_code_ptr-OKT_vars,a6)
                    add.l   #OKT_LENGTHS-OKT_CODE_POINTERS,a1
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
                    move.l  (OKT_volumes_scaling_table_r,pc),d0
                    beq     .OKT_empty_2
                    move.l  d0,a1
                    move.l  #256*65,d0
                    btst    #1,(OKT_processor)
                    beq     .OKT_free_table_r
                    move.l  #256*65*4,d0
.OKT_free_table_r:
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_2:
                    move.l  (OKT_volumes_scaling_table_l,pc),d0
                    beq     .OKT_empty_3
                    move.l  d0,a1
                    move.l  #256*65,d0
                    btst    #1,(OKT_processor)
                    beq     .OKT_free_table_l
                    move.l  #256*65*4,d0
.OKT_free_table_l:
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_3:
                    move.l  (OKT_channels_notes_buffers,pc),d0
                    beq     .OKT_empty_4
                    move.l  d0,a1
                    move.l  #512,d0
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_4:
                    move.l  (OKT_scaling_code_lines,pc),d0
                    beq     .OKT_empty_5
                    move.l  d0,a1
                    move.l  #OKT_SCALING_MINES,d0
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_5:
                    move.l  (OKT_scaling_code_buffer,pc),d0
                    beq     .OKT_empty_6
                    move.l  d0,a1
                    move.l  #OKT_CODE_LENGTH,d0
                    jsr     (_LVOFreeMem,a6)
.OKT_empty_6:
                    movem.l (a7)+,d0-a6
                    rts

; ===========================================================================
OKT_custom_init:
                    bsr     OKT_get_vbr
                    add.l   #$70,d0
                    move.l  d0,(OKT_vbr-OKT_vars,a6)
                    sf      (OKT_buffer_flip-OKT_vars,a6)
                    lea     ($DFF0A0),a1
                    move.w  #$4780,($9A-$A0,a1)
                    move.w  #$F,($96-$A0,a1)
                    move.w  #$FF,($9E-$A0,a1)
                    move.l  (OKT_final_mixing_buffers-OKT_vars,a6),a0
                    move.l  a0,($A0-$A0,a1)
                    lea     (512*2,a0),a0
                    move.l  a0,($B0-$A0,a1)
                    lea     (512*2,a0),a0
                    move.l  a0,($C0-$A0,a1)
                    lea     (512*2,a0),a0
                    move.l  a0,($D0-$A0,a1)
                    move.w  #OKT_BUFFERS_LENGTH/2,d0
                    move.w  d0,($A4-$A0,a1)
                    move.w  d0,($B4-$A0,a1)
                    move.w  d0,($C4-$A0,a1)
                    move.w  d0,($D4-$A0,a1)
                    move.w  #227,d0
                    move.w  d0,($A6-$A0,a1)
                    move.w  d0,($B6-$A0,a1)
                    move.w  d0,($C6-$A0,a1)
                    move.w  d0,($D6-$A0,a1)
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
.OKT_no_double_channels:
                    move.l  (a0),(OKT_old_irq-OKT_vars,a6)
                    lea     (OKT_audio_int-OKT_vars,a6),a2
                    move.l	a2,(a0)
                    move.w  (OKT_audio_int_single_bit-OKT_vars,a6),d0
                    move.w	d0,($9C-$A0,a1)
                    or.W    #$C000,d0
                    move.w	d0,($9A-$A0,a1)
                    move.w  (OKT_audio_int_single_bit-OKT_vars,a6),d0
                    lsr.w   #7,d0
                    or.w    #$820F,d0
                    move.w  d0,($96-$A0,a1)
                    rts

; ===========================================================================
OKT_stop:
                    movem.l d0/d1/a0/a1/a2/a6,-(a7)
                    lea     (OKT_vars,pc),a6
                    lea     ($DFF096),a2
                    move.w  #$7FFF,($9C-$96,a2)
                    move.w  #$6780,($9A-$96,a2)
                    move.w  #%1111,(a2)
                    moveq   #0,d0
                    move.w  d0,($A8-$96,a2)
                    move.w  d0,($B8-$96,a2)
                    move.w  d0,($C8-$96,a2)
                    move.w  d0,($D8-$96,a2)
                    tst.w   (OKT_audio_int_single_bit-OKT_vars,a6)
                    bne     .OKT_no_double_channels
                    lea     $BFD000+CIATALO,a0
                    lea     (OKT_old_cia_timer-OKT_vars,a6),a1
                    move.b  (a1)+,(a0)
                    move.b  (a1),CIATAHI-CIATALO(a0)
                    move.b  #%10000,CIACRA-CIATALO(a0)
.OKT_no_double_channels:
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
                    dc.w    $4E7A,$0801
                    rte
.OKT_no_processor:
                    moveq   #0,d0
                    rte

; ===========================================================================
OKT_audio_int:
                    movem.l	d0-a6,-(a7)
                    lea	    $DFF01C,a1
                    move.w	(a1)+,d0
                    and.w	(a1),d0
                    and.w   (OKT_audio_int_single_bit,pc),d0
                    beq     .OKT_no_int
                    move.w	d0,$9C-$1E(a1)
                    move.w  #$f00,$dff180
                    bsr     OKT_main
                    move.w  #0,$dff180
                    lea	    $DFF0A0,a1
                    move.l  (OKT_final_mixing_buffers-OKT_vars,a6),a0
                    tst.b   (OKT_buffer_flip-OKT_vars,a6)
                    beq     .OKT_buffer_2
                    lea     (512,a0),a0
.OKT_buffer_2:
                    move.w  (OKT_double_channels-OKT_vars,a6),d1
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
                    movem.l	(a7)+,d0-a6
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
                    bsr     OKT_replay_handler
                    move.l  (OKT_final_mixing_buffers-OKT_vars,a6),a5
                    lea     (512,a5),a5
                    not.b   (OKT_buffer_flip-OKT_vars,a6)
                    bne     OKT_mix_buffers
                    move.l  (OKT_final_mixing_buffers-OKT_vars,a6),a5
                    bra     OKT_mix_buffers

; ===========================================================================
OKT_mix_buffers:
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
                    lea     (a5),a1
                    move.l  a2,a3
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    moveq   #0,d0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    move.b  (a0,d0.w),d0
                    moveq   #64,d1
                    sub.b   d0,d1
                    lsl.w   #8,d1
                    move.l  (OKT_volumes_scaling_table_r,pc),a5
                    add.l   d1,a5
                    bsr     OKT_create_channel_waveform_data
                    add.w   d0,(OKT_mixing_routines_index-OKT_vars,a6)
                    move.l  (a7),d7
                    subq.w  #1,d7
                    move.l  4(a7),a1
                    move.l  (OKT_volumes_scaling_table_l,pc),a5
                    tst.b   d0
                    bne     .OKT_no_buffer
                    ; wasn't processed
                    move.l  (OKT_channels_notes_buffers,pc),a1
                    move.l  (OKT_volumes_scaling_table_r,pc),a5
.OKT_no_buffer:
                    lea     (CHAN_LEN,a2),a3
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    moveq   #0,d0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    move.b  (a0,d0.w),d0
                    moveq   #64,d1
                    sub.b   d0,d1
                    lsl.w   #8,d1
                    add.l   d1,a5
                    bsr     OKT_create_channel_waveform_data
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
                    rts
OKT_no_mix:
                    rts
OKT_mixing_routines_table:
                    dc.l    OKT_mix_000_lr,OKT_no_mix,OKT_mix_000_empty
                    dc.l    OKT_mix_020_lr,OKT_no_mix,OKT_mix_020_empty
OKT_mixing_routines_index:
                    dc.w    0

; ===========================================================================
OKT_create_channel_waveform_data:
                    tst.l   (CHAN_SMP_PROC_D,a3)
                    beq     .OKT_no_mix
                    tst.w   (CHAN_NOTE_D,a3)
                    bpl     .OKT_min
                    clr.w   (CHAN_NOTE_D,a3)
.OKT_min:
                    cmpi.w  #36-1,(CHAN_NOTE_D,a3)
                    ble     .OKT_max
                    move.w  #36-1,(CHAN_NOTE_D,a3)
.OKT_max:
                    move.l  a1,-(a7)
                    ; check if the sample has been processed
                    move.l  (CHAN_SMP_PROC_LEN_D,a3),d2
                    bgt     .OKT_sample_end
                    ; is there a repeat ?
                    tst.l   (CHAN_SMP_REP_LEN_D,a3)
                    beq     .OKT_no_repeat
.OKT_rearm:
                    ; yes: rearm
                    move.l  (CHAN_SMP_REP_START,a3),(CHAN_SMP_PROC_D,a3)
                    move.l  (CHAN_SMP_REP_LEN_D,a3),d2
                    move.l  d2,(CHAN_SMP_PROC_LEN_D,a3)
                    bra     .OKT_sample_end
.OKT_no_repeat:
                    ; no: discard
                    clr.l   (CHAN_SMP_PROC_D,a3)
                    clr.l   (CHAN_SMP_PROC_LEN_D,a3)
                    addq.l  #4,a7
                    bra     .OKT_no_mix
.OKT_sample_end:
                    move.l  (OKT_lengths_ptr,pc),a0
                    move.w  (CHAN_NOTE_D,a3),d0
                    add.w   d0,d0
                    add.w   d0,d0
                    move.w  (a0,d0.w),d3
                    ext.l   d3
                    ; length left to process
                    cmp.l   d3,d2
                    bgt     .OKT_no_cut_code
                    ; less left than processed in the generated code
                    ; can process on this note
                    add.w   d2,d2
                    ; get byte loading offset
                    move.l  (OKT_scaling_code_lines,pc),a4
                    ; base
                    add.w   2(a0,d0.w),d2
                    move.w  (a4,d2.w),d0
                    ; get code address
                    move.w  (CHAN_NOTE_D,a3),d3
                    add.w   d3,d3
                    add.w   d3,d3
                    move.l  (OKT_code_ptr,pc),a4
                    move.l  (a4,d3.w),a4
                    ; offset
                    add.w   d0,a4
                    ; patch it
                    move.l  a4,(OKT_patched_addr-OKT_vars,a6)
                    move.w  (a4),(OKT_patched_instr-OKT_vars,a6)
                    move.w  #$4e75,(a4)
                    btst    #1,(OKT_processor-OKT_vars,a6)
                    beq     .OKT_no_cut_code
                    movem.l a0/a1/a2/a3/a6,-(a7)
                    move.l  4.w,a6
                    jsr     (_LVOCacheClearU,a6)
                    movem.l (a7)+,a0/a1/a2/a3/a6
.OKT_no_cut_code:
                    ; source waveform
                    move.l  (CHAN_SMP_PROC_D,a3),a0
                    move.l  (OKT_code_ptr-OKT_vars,a6),a4
                    moveq   #0,d0
                    moveq   #0,d1
                    move.w  (CHAN_NOTE_D,a3),d3
                    add.w   d3,d3
                    add.w   d3,d3
                    move.l  (a4,d3.w),a4
                    jsr     (a4)
                    ; restore the patch code if any
                    tst.l   OKT_patched_addr
                    beq     .OKT_no_patch
                    move.l  (OKT_patched_addr-OKT_vars,a6),a4
                    move.w  (OKT_patched_instr-OKT_vars,a6),(a4)
                    clr.l   (OKT_patched_addr)
                    btst    #1,(OKT_processor-OKT_vars,a6)
                    beq     .OKT_no_patch
                    movem.l a0/a1/a2/a3/a6,-(a7)
                    move.l  4.w,a6
                    jsr     (_LVOCacheClearU,a6)
                    movem.l (a7)+,a0/a1/a2/a3/a6
.OKT_no_patch:
                    ; new source pos
                    move.l  (CHAN_SMP_PROC_D,a3),d0
                    move.l  a0,(CHAN_SMP_PROC_D,a3)
                    ; length processed
                    sub.l   d0,a0
                    move.l  (CHAN_SMP_PROC_LEN_D,a3),d2
                    ; length remaining to process
                    sub.l   a0,d2
                    move.l  d2,(CHAN_SMP_PROC_LEN_D,a3)
                    ; check if the mix buffer was entirely processed
                    lea     (a1),a4
                    sub.l   (a7)+,a4
                    cmp.l   #OKT_BUFFERS_LENGTH,a4
                    bge     .OKT_processed
                    ; restart it to continue the filling
                    tst.l   (CHAN_SMP_REP_LEN_D,a3)
                    bne     .OKT_rearm
                    ; fill the rest of the buffer
                    move.l  #OKT_BUFFERS_LENGTH,d1
                    sub.l   a4,d1
                    btst    #0,d1
                    beq     .OKT_odd
                    sf      (a1)+
                    subq.l  #1,d1
.OKT_odd:
                    lsr.l   #1,d1
                    add.l   d1,d1
                    beq     .OKT_processed
                    lea     (.OK_clear_buffer,pc),a4
                    sub.l   d1,a4
                    moveq   #0,d0
                    jmp     (a4)
                REPT OKT_BUFFERS_LENGTH/2
                    move.w  d0,(a1)+
                ENDR
.OK_clear_buffer:
.OKT_processed:
                    moveq   #0,d0
                    rts
.OKT_no_mix:
                    moveq   #4,d0
                    rts

; ===========================================================================
OKT_mix_000_lr:
                    move.l  (OKT_channels_notes_buffers,pc),a1
                    lea     (a5),a4
                    movem.l d7/a2/a5/a6,-(a7)
                REPT 6
                    movem.l (a4),d0-d7/a2/a3/a5/a6
                    add.l   (a1)+,d0
                    add.l   (a1)+,d1
                    add.l   (a1)+,d2
                    add.l   (a1)+,d3
                    add.l   (a1)+,d4
                    add.l   (a1)+,d5
                    add.l   (a1)+,d6
                    add.l   (a1)+,d7
                    add.l   (a1)+,a2
                    add.l   (a1)+,a3
                    add.l   (a1)+,a5
                    add.l   (a1)+,a6
                    movem.l d0-d7/a2/a3/a5/a6,(a4)
                    lea     (48,a4),a4
                ENDR
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
OKT_mix_020_lr:
                    move.l  (OKT_channels_notes_buffers,pc),a1
                    lea     (a5),a4
                    movem.l d7/a2/a5/a6,-(a7)
                    moveq   #7-1,d7
.OKT_loop:
                    movem.l (a4),d0-d6/a2/a3/a5/a6
                    add.l   (a1)+,d0
                    add.l   (a1)+,d1
                    add.l   (a1)+,d2
                    add.l   (a1)+,d3
                    add.l   (a1)+,d4
                    add.l   (a1)+,d5
                    add.l   (a1)+,d6
                    add.l   (a1)+,a2
                    add.l   (a1)+,a3
                    add.l   (a1)+,a5
                    add.l   (a1)+,a6
                    movem.l d0-d6/a2/a3/a5/a6,(a4)
                    lea     (44,a4),a4
                    dbf     d7,.OKT_loop
                    move.l  (a4),d0
                    add.l   (a1),d0
                    move.l  d0,(a4)
                    movem.l (a7)+,d7/a2/a5/a6
                    rts

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
                    move.l  (OKT_code_ptr-OKT_vars,a6),a2
                    move.l  (OKT_scaling_code_buffer-OKT_vars,a6),a0
                    lea     (OKT_scaling_freqs_table,pc),a5
                    move.l  (OKT_lengths_ptr-OKT_vars,a6),a3
                    lea     (OKT_store_bytes_table-OKT_vars,a6),a4
                    btst    #1,(OKT_processor-OKT_vars,a6)
                    beq     .OKT_sel_020_code
                    addq.w  #2,a4
.OKT_sel_020_code:
                    move.l  (OKT_scaling_code_lines,pc),a6
                    moveq   #36-1,d7
                    ; line 0
                    clr.w   (a6)+
.OKT_loop_freqs:
                    ; code pointers
                    move.l  a0,(a2)+
                    move.l  a6,d1
                    moveq   #0,d2
                    moveq   #0,d3
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
                    move.l  a0,d0
                    sub.l   (-4,a2),d0
                    move.w  d0,(a6)+
                    move.w  (OKT_opcode_add,pc),(a0)+
                    move.l  a0,d0
                    sub.l   (-4,a2),d0
                    move.w  d0,(a6)+
                    move.l  (a1)+,(a0)+
                    move.w  (a1),(a0)+
                    addq.w  #1,d6
                    cmp.w   #OKT_BUFFERS_LENGTH,d6
                    bge     .OKT_done_freq
                    bra     .OKT_freq_nibble
.OKT_no_skip_load_store:
                    move.l  a0,d0
                    sub.l   (-4,a2),d0
                    move.w  d0,(a6)+
                    move.l  (a1)+,(a0)+
                    move.w  (a1),(a0)+
                    move.l  a0,d0
                    sub.l   (-4,a2),d0
                    move.w  d0,(a6)+
                    move.w  (OKT_opcode_add,pc),(a0)+
                    addq.w  #1,d6
                    cmp.w   #OKT_BUFFERS_LENGTH,d6
                    bge     .OKT_done_freq
                    bra     .OKT_freq_nibble
.OKT_no_load_store_skip:
                    tst.w   d2
                    beq     .OKT_store_1_byte
                    subq.w  #1,d2
                    beq     .OKT_store_2_bytes
                    subq.w  #1,d2
                    beq     .OKT_store_3_bytes
                    subq.w  #1,d2
                    move.w  (12,a4),d0
                    bra     .OKT_do_store
.OKT_store_3_bytes:
                    move.w  (8,a4),d0
                    bra     .OKT_do_store
.OKT_store_2_bytes:
                    move.w  (4,a4),d0
.OKT_do_store:
                    lea     (a4,d0.w),a1
                    move.l  a0,d0
                    sub.l   (-4,a2),d0
                    move.w  d0,(a6)+
                    ; length to copy
                    move.w  (a1),d0
                    ; bytes in dest buffer
                    add.w   (2,a1),d6
                    suba.w  d0,a1
                    lsr.w   #1,d0
                    subq.w  #1,d0
.OKT_copy_code:
                    move.w  (a1)+,(a0)+
                    dbra    d0,.OKT_copy_code
                    cmp.w   #OKT_BUFFERS_LENGTH,d6
                    bge     .OKT_done_freq
                    bra     .OKT_freq_nibble
.OKT_store_1_byte:
                    move.l  a0,d0
                    sub.l   (-4,a2),d0
                    move.w  d0,(a6)+
                    move.l  (a1)+,(a0)+
                    move.w  (a1),(a0)+
                    addq.w  #1,d6
                    cmp.w   #OKT_BUFFERS_LENGTH,d6
                    bge     .OKT_done_freq
                    bra     .OKT_freq_nibble
.OKT_wait_freq_nibble:
                    addq.w  #1,d2
.OKT_freq_nibble:
                    move.w  d3,d4
                    swap    d3
                    add.l   (a5),d3
                    swap    d3
                    bra     .OKT_loop_freq
.OKT_done_freq:
                    ; small overrun correction
                    sub.w   #OKT_BUFFERS_LENGTH,d6
                    beq     .OKT_step_back
                    ; subq.l #1,a0
                    move.w  #$5388,(a0)+
.OKT_step_back:
                    move.w  (OKT_opcode_rts,pc),(a0)+
                    ; length
                    move.w  d3,(a3)+
                    ; offset in code lines
                    move.l  d1,d0
                    sub.l   (OKT_scaling_code_lines,pc),d0
                    move.w  d0,(a3)+
                    move.l  a6,d1
                    addq.l  #4,a5
                    dbra    d7,.OKT_loop_freqs
                    lea     (OKT_vars,pc),a6
                    rts

; ===========================================================================
OKT_store_bytes_table:
                    dc.w    OKT_opcodes_store_1_byte_000-OKT_store_bytes_table,OKT_opcodes_store_1_byte_020-OKT_store_bytes_table-2
                    dc.w    OKT_opcodes_store_2_bytes_000-OKT_store_bytes_table,OKT_opcodes_store_2_bytes_020-OKT_store_bytes_table-2
                    dc.w    OKT_opcodes_store_3_bytes_000-OKT_store_bytes_table,OKT_opcodes_store_3_bytes_020-OKT_store_bytes_table-2
                    dc.w    OKT_opcodes_store_4_bytes_000-OKT_store_bytes_table,OKT_opcodes_store_4_bytes_020-OKT_store_bytes_table-2
; ==================
; 2 bytes
OKT_opcode_add:
                    addq.w  #1,a0
; ==================
; 2 bytes
OKT_opcode_rts:
                    rts
; ==================
; 6 bytes
OKT_opcodes_store_1_byte_000:
                    move.b  (a0)+,d0
                    move.b  (a5,d0.w),(a1)+
; ===
OKT_opcodes_store_2_bytes_000_e:
                    move.b  (a0)+,d0
                    move.b  (a5,d0.w),d0
                    move.b  d0,(a1)+
                    move.b  d0,(a1)+
OKT_opcodes_store_2_bytes_000:
                    dc.w    OKT_opcodes_store_2_bytes_000-OKT_opcodes_store_2_bytes_000_e,2
; ===
OKT_opcodes_store_3_bytes_000_e:
                    move.b  (a0)+,d0
                    move.b  (a5,d0.w),d0
                    move.b  d0,(a1)+
                    move.b  d0,(a1)+
                    move.b  d0,(a1)+
OKT_opcodes_store_3_bytes_000:
                    dc.w    OKT_opcodes_store_3_bytes_000-OKT_opcodes_store_3_bytes_000_e,3
; ===
OKT_opcodes_store_4_bytes_000_e:
                    move.b  (a0)+,d0
                    move.b  (a5,d0.w),d0
                    move.b  d0,(a1)+
                    move.b  d0,(a1)+
                    move.b  d0,(a1)+
                    move.b  d0,(a1)+
OKT_opcodes_store_4_bytes_000:
                    dc.w    OKT_opcodes_store_4_bytes_000-OKT_opcodes_store_4_bytes_000_e,4
                IFD __VASM__
                    mc68020
                ENDC
; ==================
; 6 bytes
OKT_opcodes_store_1_byte_020:
                    move.b  (a0)+,d0
                    move.b  (a5,d0.w*4),(a1)+
; ===
OKT_opcodes_store_2_bytes_020_e:
                    move.b  (a0)+,d0
                    move.w  (a5,d0.w*4),(a1)+
OKT_opcodes_store_2_bytes_020:
                    dc.w    OKT_opcodes_store_2_bytes_020-OKT_opcodes_store_2_bytes_020_e,2
; ===
OKT_opcodes_store_3_bytes_020_e:
                    move.b  (a0)+,d0
                    move.l  (a5,d0.w*4),(a1)+
                    subq.l  #1,a1
OKT_opcodes_store_3_bytes_020:
                    dc.w    OKT_opcodes_store_3_bytes_020-OKT_opcodes_store_3_bytes_020_e,3
; ===
OKT_opcodes_store_4_bytes_020_e:
                    move.b  (a0)+,d0
                    move.l  (a5,d0.w*4),(a1)+
OKT_opcodes_store_4_bytes_020:
                    dc.w    OKT_opcodes_store_4_bytes_020-OKT_opcodes_store_4_bytes_020_e,4
                IFD __VASM__
                    mc68000
                ENDC

; ===========================================================================
OKT_scaling_freqs_table:
                    dc.l    $4409,$4814,$4C6E,$50E3,$55E6,$5B00,$606C,$662C,$6C40,$72A5,$7955
                    dc.l    $8090,$8813,$9028,$98DC,$A1C7,$ABCC,$B600,$C0D9,$CC59,$D881,$E54A
                    dc.l    $F2AA,$101B2,$11026,$12051,$13286,$1438E,$15696,$16C00,$181B2,$19745
                    dc.l    $1AF68,$1CA95,$1E555,$20365
OKT_code_ptr:
                    dc.l    0
OKT_lengths_ptr:
                    dc.l    0
OKT_buffer_flip:
                    dc.b    0
                    even
OKT_patched_addr:
                    dc.l    0
OKT_patched_instr:
                    dc.w    0
OKT_scaling_code_buffer:
                    dc.l    0
OKT_scaling_code_lines:
                    dc.l    0
OKT_channels_notes_buffers:
                    dc.l    0
OKT_volumes_scaling_table_l:
                    dc.l    0
OKT_volumes_scaling_table_r:
                    dc.l    0
OKT_final_mixing_buffers:
                    dc.l    0

; ===========================================================================
                    include "replay_common.asm"
