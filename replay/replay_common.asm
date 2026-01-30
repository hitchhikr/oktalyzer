; ===========================================================================
; Oktalyzer replay routine common code
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled and improved by Franck 'hitchhikr' Charlet.
; ===========================================================================

; ===========================================================================
_LVOSupervisor	    equ	    -30
CIATALO             equ     $400
CIATAHI             equ     $500
CIAICR              equ     $D00
CIACRA              equ     $E00
SMPS_NUMBER         equ     36
		            rsreset
SMP_NAME:           rs.b    20
SMP_LEN:            rs.l    1           ; 20
SMP_REP_START:      rs.w    1           ; 24
SMP_REP_LEN:        rs.w    1           ; 26
SMP_VOL:            rs.w    1           ; 28
SMP_TYPE:           rs.w    1           ; 30
SMP_INFOS_LEN:      rs.b    0           ; 32
		            rsreset
CHAN_TYPE:          rs.b    1           ; 0
                    rs.b    1           ; 1 (pad)
CHAN_SMP_REP_START: rs.l    1           ; 2
CHAN_SMP_REP_LEN_D: rs.b    0           ; 6 (long word)
CHAN_SMP_REP_LEN_S: rs.w    1           ; 6
CHAN_NOTE_S:        rs.w    1           ; 8
CHAN_PERIOD_S:      rs.b    0           ; 10
CHAN_NOTE_D:        rs.w    1           ; 10
CHAN_BASE_NOTE_D:   rs.w    1           ; 12
CHAN_SMP_PROC_D:    rs.l    1           ; 14
CHAN_SMP_PROC_LEN_D:rs.l    1           ; 18
CHAN_LEN:           rs.b    0           ; 22

; ===========================================================================
OKT_init:
                    movem.l d1-a6,-(a7)
                    lea     (OKT_vars,pc),a6
                    cmp.l   #'OKTA',(a0)+
                    bne     .OKT_error
                    cmp.l   #'SONG',(a0)+
                    bne     .OKT_error
                    move.l  a0,(OKT_search_hunk_ptr-OKT_vars,a6)
                    move.l  #'CMOD',d0
                    bsr     .OKT_search_hunk
                    lea     (OKT_channels_modes-OKT_vars,a6),a1
                    move.l  (a0)+,(a1)+
                    move.l  (a0)+,(a1)+
                    move.l  #'SAMP',d0
                    bsr     .OKT_search_hunk
                    lea     (OKT_samples-OKT_vars,a6),a1
                    move.w  #(SMPS_NUMBER*SMP_INFOS_LEN)-1,d0
.OKT_get_samples_infos:
                    move.b  (a0)+,(a1)+
                    dbra    d0,.OKT_get_samples_infos
                    move.l  #'SPEE',d0
                    bsr     .OKT_search_hunk
                    move.w  (a0)+,(OKT_speed-OKT_vars,a6)
                    move.l  #'SLEN',d0
                    bsr     .OKT_search_hunk
                    move.w  (a0)+,(OKT_patterns_number-OKT_vars,a6)
                    move.l  #'PLEN',d0
                    bsr     .OKT_search_hunk
                    move.w  (a0)+,(OKT_song_length-OKT_vars,a6)
                    move.l  #'PATT',d0
                    bsr     .OKT_search_hunk
                    lea     (OKT_patterns-OKT_vars,a6),a1
                    moveq   #128-1,d0
.OKT_get_positions:
                    move.b  (a0)+,(a1)+
                    dbra    d0,.OKT_get_positions
                    lea     (OKT_patterns_list-OKT_vars,a6),a1
                    moveq   #0,d7
.OKT_get_patterns:
                    move.l  #'PBOD',d0
                    bsr     .OKT_search_hunk
                    ; address
                    move.l  a0,(a1)+
                    addq.w  #1,d7
                    cmp.w   (OKT_patterns_number-OKT_vars,a6),d7
                    bne     .OKT_get_patterns
                    lea     (OKT_samples+SMP_LEN-OKT_vars,a6),a5
                    lea     (OKT_samples_table-OKT_vars,a6),a1
                    moveq   #0,d7
.OKT_get_samples_ptrs:
                    tst.l   (a5)
                    beq     .OKT_empty_sample
                    move.l  #'SBOD',d0
                    bsr     .OKT_search_hunk
                    ; address
                    move.l  a0,(a1)
.OKT_empty_sample:
                    addq.l  #4,a1
                    lea     (SMP_INFOS_LEN,a5),a5
                    addq.w  #1,d7
                    cmp.w   #SMPS_NUMBER,d7
                    bne     .OKT_get_samples_ptrs
                    bsr     OKT_init_variables
                    bsr     OKT_custom_init
                    movem.l (a7)+,d1-a6
                    moveq   #1,d0
                    rts
.OKT_error:
                    movem.l (a7)+,d1-a6
                    moveq   #0,d0
                    rts

; ===========================================================================
.OKT_search_hunk:
                    movem.l d2/d3,-(a7)
                    move.l  (OKT_search_hunk_ptr-OKT_vars,a6),a0
.OKT_loop:
                    movem.l (a0)+,d2/d3
                    cmp.l   d2,d0
                    beq     .OKT_found
                    add.l   d3,a0
                    bra     .OKT_loop
.OKT_found:
                    add.l   d3,a0
                    move.l  a0,(OKT_search_hunk_ptr-OKT_vars,a6)
                    sub.l   d3,a0
                    move.l  d3,d0
                    movem.l (a7)+,d2/d3
                    rts

; ===========================================================================
OKT_init_variables:
                    lea     (OKT_channels_data-OKT_vars,a6),a0
                    move.w  #(CHAN_LEN*8)-1,d0
.OKT_clear_channels_data:
                    sf      (a0)+
                    dbra    d0,.OKT_clear_channels_data
                    lea     (OKT_channels_modes-OKT_vars,a6),a0
                    lea     (OKT_channels_data-OKT_vars,a6),a1
                    moveq   #4-1,d0
                    moveq   #0,d1
                    move.w  #%10000000,d2
                    moveq   #%1,d3
                    clr.w   (OKT_audio_int_bit-OKT_vars,a6)
                    clr.w   (OKT_audio_int_single_bit-OKT_vars,a6)
                    clr.w   (OKT_double_channels-OKT_vars,a6)
.OKT_get_channels_size:
                    tst.w   (a0)
                    sne     CHAN_TYPE(a1)
                    sne     CHAN_TYPE+CHAN_LEN(a1)
                    beq     .OKT_not_doubled
                    or.w    d3,(OKT_double_channels-OKT_vars,a6)
                    tst.w   (OKT_audio_int_single_bit-OKT_vars,a6)
                    bne     .OKT_only_one_int_bit
                    or.w    d2,(OKT_audio_int_single_bit-OKT_vars,a6)
.OKT_only_one_int_bit:
                    or.w    d2,(OKT_audio_int_bit-OKT_vars,a6)
.OKT_not_doubled:
                    add.w   (a0)+,d1
                    lea     (CHAN_LEN*2,a1),a1
                    add.w   d2,d2
                    add.w   d3,d3
                    dbra    d0,.OKT_get_channels_size
                    addq.w  #4,d1
                    add.w   d1,d1
                    add.w   d1,d1
                    move.w  d1,(OKT_rows_size-OKT_vars,a6)
                    lea     (OKT_channels_indexes-OKT_vars,a6),a0
                    ; indexes
                    move.l  #$07060504,(a0)+
                    move.l  #$03020100,(a0)+
                    ; volumes at max
                    move.l  #$40404040,d0
                    move.l  d0,(a0)+
                    move.l  d0,(a0)
                    clr.w   (OKT_song_pos-OKT_vars,a6)
                    bsr     OKT_set_current_pattern
                    move.w  #-1,(OKT_next_song_pos-OKT_vars,a6)
                    move.w  (OKT_speed-OKT_vars,a6),(OKT_current_speed-OKT_vars,a6)
                    clr.w   (OKT_action_cycle-OKT_vars,a6)
                    sf      (OKT_filter_status-OKT_vars,a6)
                    clr.w   (OKT_dmacon-OKT_vars,a6)
                    rts

; ===========================================================================
OKT_replay_handler:
                    lea     (OKT_vars,pc),a6
                    bsr     OKT_set_hw_regs
                    addq.w  #1,(OKT_action_cycle-OKT_vars,a6)
                    move.w  (OKT_current_speed-OKT_vars,a6),d0
                    cmp.w   (OKT_action_cycle-OKT_vars,a6),d0
                    bgt     .OKT_no_new_row
                    bra     OKT_new_row
.OKT_no_new_row:
                    rts

; ===========================================================================
OKT_new_row:
                    clr.w   (OKT_action_cycle-OKT_vars,a6)
                    ; next row
                    move.l  (OKT_current_pattern-OKT_vars,a6),a1
                    add.w   (OKT_rows_size-OKT_vars,a6),a1
                    move.l  a1,(OKT_current_pattern-OKT_vars,a6)
                    addq.w  #1,(OKT_pattern_row-OKT_vars,a6)
                    bsr     OKT_get_current_pattern
                    tst.w   (OKT_next_song_pos-OKT_vars,a6)
                    bpl     .OKT_pattern_end
                    cmp.w   (OKT_pattern_row-OKT_vars,a6),d0
                    bgt     .OKT_no_new_pattern
.OKT_pattern_end:
                    clr.w   (OKT_pattern_row-OKT_vars,a6)
                    tst.w   (OKT_next_song_pos-OKT_vars,a6)
                    bmi     .OKT_no_pos_jump
                    move.w  (OKT_next_song_pos-OKT_vars,a6),(OKT_song_pos-OKT_vars,a6)
                    bra     .OKT_next_pos
.OKT_no_pos_jump:
                    addq.w  #1,(OKT_song_pos-OKT_vars,a6)
.OKT_next_pos:
                    move.w  (OKT_song_pos-OKT_vars,a6),d0
                    cmp.w   (OKT_song_length-OKT_vars,a6),d0
                    bne     .OKT_no_song_end
                    clr.w   (OKT_song_pos-OKT_vars,a6)
                    move.w  (OKT_speed-OKT_vars,a6),(OKT_current_speed-OKT_vars,a6)
.OKT_no_song_end:
                    bsr     OKT_set_current_pattern
.OKT_no_new_pattern:
                    move.w  #-1,(OKT_next_song_pos-OKT_vars,a6)
                    rts

; ===========================================================================
OKT_get_current_pattern:
                    lea     (OKT_patterns-OKT_vars,a6),a0
                    move.w  (OKT_song_pos-OKT_vars,a6),d0
                    move.b  (a0,d0.w),d0
                    bra     OKT_get_pattern_address_and_length

; ===========================================================================
OKT_set_current_pattern:
                    lea     (OKT_patterns-OKT_vars,a6),a0
                    move.w  (OKT_song_pos-OKT_vars,a6),d0
                    move.b  (a0,d0.w),d0
                    bsr     OKT_get_pattern_address_and_length
                    move.l  a0,(OKT_current_pattern-OKT_vars,a6)
                    clr.w   (OKT_pattern_row-OKT_vars,a6)
                    rts

; ===========================================================================
OKT_get_pattern_address_and_length:
                    lea     (OKT_patterns_list-OKT_vars,a6),a0
                    add.w   d0,d0
                    add.w   d0,d0
                    move.l  (a0,d0.w),a0
                    move.w  (a0)+,d0
                    rts

; ===========================================================================
OKT_set_hw_regs:
                    bsr     OKT_turn_dma_on
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    bne     .OKT_no_new_row
                    moveq   #0,d4
                    moveq   #1,d5
                    bsr     OKT_fill_double_channels
                    bsr     OKT_fill_single_channels
                    or.w    d4,(OKT_dmacon-OKT_vars,a6)
.OKT_no_new_row:
                    bsr     OKT_handle_effects_double_channels
                    bsr     OKT_handle_effects_single_channels
                IFEQ OKT_AUDIO_ALL_HW
                    move.b  (OKT_filter_status-OKT_vars,a6),d0
                    beq     .OKT_blink
                    bclr    #1,($BFE001)
                    bra     .OKT_set_hw_volumes
.OKT_blink:
                    bset    #1,($BFE001)
.OKT_set_hw_volumes:
                ENDC
                    ; set hw volumes
                    move.w  (OKT_global_volume-OKT_vars,a6),d2
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    lea     (OKT_channels_data-OKT_vars,a6),a3
                    lea     (OKT_AUDIO_BASE),a1
                    moveq   #8-1,d7
.OKT_loop:
                    tst.b   CHAN_TYPE(a3)
                    bne     .OKT_skip_double_channel
                    moveq   #0,d0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    move.b  (a0,d0.w),d0
                    mulu.w  d2,d0
                    lsr.w   #6,d0
                    OKT_SET_AUDIO_VOL d0,a1
                    lea     (CHAN_LEN*2,a3),a3
                    lea     (OKT_AUDIO_SIZE,a1),a1
                    subq.w  #1,d7
                    dbra    d7,.OKT_loop
                    rts
.OKT_skip_double_channel:
                IFEQ OKT_AUDIO_ALL_HW
                    ; software channels are hw vol. max
                    moveq   #64,d0
                    mulu.w  d2,d0
                    lsr.w   #6,d0
                    OKT_SET_AUDIO_VOL d0,a1
                    lea     (CHAN_LEN*2,a3),a3
                    lea     (OKT_AUDIO_SIZE,a1),a1
                    subq.w  #1,d7
                    dbra    d7,.OKT_loop
                    rts
                ELSE
                    moveq   #0,d0
                    move.b  (-8,a0,d7.w),d0
                    move.b  (a0,d0.w),d0
                    mulu.w  d2,d0
                    lsr.w   #6,d0
                    OKT_SET_AUDIO_VOL d0,a1
                    lea     (CHAN_LEN,a3),a3
                    lea     (OKT_AUDIO_SIZE,a1),a1
                    subq.w  #1,d7
                    moveq   #0,d0
                    move.b  (-8,a0,d7.w),d0
                    move.b  (a0,d0.w),d0
                    mulu.w  d2,d0
                    lsr.w   #6,d0
                    OKT_SET_AUDIO_VOL d0,a1
                    lea     (CHAN_LEN,a3),a3
                    lea     (OKT_AUDIO_SIZE,a1),a1
                    dbra    d7,.OKT_loop
                    rts
                ENDC

; ===========================================================================
OKT_turn_dma_on:
                    lea     (OKT_dmacon-OKT_vars,a6),a0
                    move.w  (a0),d0
                    beq     .OKT_no_channels
                    clr.w   (a0)
                    ori.w   #$8000,d0
                    OKT_SET_AUDIO_DMA d0
                    ; dma wait
                    lea     ($DFF006),a0
                    move.b  (a0),d1
.OKT_next_line:
                    cmp.b   (a0),d1
                    beq     .OKT_next_line
                    move.b  (a0),d1
.OKT_wait_line:
                    cmp.b   (a0),d1
                    beq     .OKT_wait_line
                    lea     (OKT_AUDIO_BASE),a4
                    lea     (OKT_channels_data+CHAN_SMP_REP_START-OKT_vars,a6),a1
                    moveq   #OKT_AUDIO_HW_CHANS-1,d7
                    moveq   #0,d1
.OKT_set_channels_repeat_data:
                    btst    d1,d0
                    beq     .OKT_set_channel
                    OKT_SET_AUDIO_ADR CHAN_SMP_REP_START-CHAN_SMP_REP_START(a1),a4
                    OKT_SET_AUDIO_LEN CHAN_SMP_REP_LEN_S-CHAN_SMP_REP_START(a1),a4
.OKT_set_channel:
                IFEQ OKT_AUDIO_ALL_HW
                    lea     ((CHAN_LEN*2),a1),a1
                ELSE
                    lea     (CHAN_LEN,a1),a1
                ENDC
                    lea     (OKT_AUDIO_SIZE,a4),a4
                    addq.l  #1,d1
                    dbf     d7,.OKT_set_channels_repeat_data
.OKT_no_channels:
                    rts

; ===========================================================================
OKT_fill_double_channels:
                    lea     (OKT_samples_table-OKT_vars,a6),a0
                    lea     (OKT_samples-OKT_vars,a6),a1
                    move.l  (OKT_current_pattern-OKT_vars,a6),a2
                    lea     (OKT_channels_data-OKT_vars,a6),a3
                IFNE OKT_AUDIO_ALL_HW
                    lea     (OKT_AUDIO_BASE),a4
                ENDC
                    moveq   #8-1,d7
.OKT_loop:
                    tst.b   CHAN_TYPE(a3)
                    bne     .OKT_fill_data
                    addq.w  #4,a2
                    lea     (CHAN_LEN*2,a3),a3
                IFNE OKT_AUDIO_ALL_HW
                    lea     (OKT_AUDIO_SIZE,a4),a4
                ENDC
                    subq.w  #1,d7
                    dbra    d7,.OKT_loop
                    rts
.OKT_fill_data:
                IFEQ OKT_AUDIO_ALL_HW
                    bsr     OKT_fill_double_channel_data
                    subq.w  #1,d7
                    bsr     OKT_fill_double_channel_data
                ELSE
                    bsr     OKT_fill_single_channel_data
                    add.w   d5,d5
                    addq.w  #4,a2
                    lea     (CHAN_LEN,a3),a3
                    lea     (OKT_AUDIO_SIZE,a4),a4
                    subq.w  #1,d7
                    bsr     OKT_fill_single_channel_data
                    add.w   d5,d5
                    addq.w  #4,a2
                    lea     (CHAN_LEN,a3),a3
                    lea     (OKT_AUDIO_SIZE,a4),a4
                ENDC
                    dbra    d7,.OKT_loop
                    rts

; ===========================================================================
                IFEQ OKT_AUDIO_ALL_HW
OKT_fill_double_channel_data:
                    moveq   #0,d3
                    move.b  (a2),d3
                    beq     .OKT_no_data
                    subq.w  #1,d3
                    moveq   #0,d0
                    move.b  (1,a2),d0
                    add.w   d0,d0
                    add.w   d0,d0
                    move.l  (a0,d0.w),d2
                    beq     .OKT_no_data
                    ; *32
                    lsl.w   #3,d0
                    ; starting address
                    move.l  d2,(CHAN_SMP_PROC_D,a3)
                    ; starting length
                    move.l  (SMP_LEN,a1,d0.w),d0
                    ; that was a bug
                    bclr    #0,d0
                    move.l  d0,(CHAN_SMP_PROC_LEN_D,a3)
                    moveq   #0,d0
                    moveq   #0,d1
                    move.w  (SMP_REP_LEN,a1),d0
                    add.l   d0,d0
                    ; repeat length
                    move.l  d0,(CHAN_SMP_REP_LEN_D,a3)
                    move.w  (SMP_REP_START,a1),d1
                    add.l   d1,d1
                    add.l   d2,d1
                    ; repeat start address
                    move.l  d1,(CHAN_SMP_REP_START,a3)
                    move.l  a0,-(a7)
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    moveq   #0,d0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    ; default sample volume
                    move.b  (SMP_VOL+1,a1),(a0,d0.w)
                    move.l  (a7)+,a0
                    ; note index
                    move.w  d3,(CHAN_NOTE_D,a3)
                    move.w  d3,(CHAN_BASE_NOTE_D,a3)
.OKT_no_data:
                    addq.w  #4,a2
                    lea     (CHAN_LEN,a3),a3
                    rts
                ENDC

; ===========================================================================
OKT_fill_single_channels:
                    lea     (OKT_samples_table-OKT_vars,a6),a0
                    move.l  (OKT_current_pattern-OKT_vars,a6),a2
                    lea     (OKT_channels_data-OKT_vars,a6),a3
                    lea     (OKT_AUDIO_BASE),a4
                    lea     (OKT_periods_table-OKT_vars,a6),a5
                    moveq   #8-1,d7
.OKT_loop:
                    tst.b   CHAN_TYPE(a3)
                    bne     .OKT_skip_double_channel
                    bsr     OKT_fill_single_channel_data
                    addq.w  #4,a2
                    lea     (CHAN_LEN*2,a3),a3
                    lea     (OKT_AUDIO_SIZE,a4),a4
                    add.w   d5,d5
                    subq.w  #1,d7
                    dbra    d7,.OKT_loop
                    rts
.OKT_skip_double_channel:
                    addq.w  #8,a2
                    lea     (CHAN_LEN*2,a3),a3
                    lea     (OKT_AUDIO_SIZE,a4),a4
                    add.w   d5,d5
                    subq.w  #1,d7
                    dbra    d7,.OKT_loop
                    rts

; ===========================================================================
OKT_fill_single_channel_data:
                    moveq   #0,d3
                    move.b  (a2),d3
                    beq     .OKT_no_set
                    subq.w  #1,d3
                    moveq   #0,d0
                    move.b  (1,a2),d0
                    add.w   d0,d0
                    add.w   d0,d0
                    move.l  (a0,d0.w),d2
                    beq     .OKT_no_set
                    lsl.w   #3,d0
                    lea     (OKT_samples-OKT_vars,a6),a1
                    add.w   d0,a1
                    ; length
                    move.l  (SMP_LEN,a1),d1
                    lsr.l   #1,d1
                    tst.w   d1
                    beq     .OKT_no_set
                    OKT_SET_AUDIO_DMA d5
                    or.w    d5,d4
                    ; start sample address
                    OKT_SET_AUDIO_ADR d2,a4
                    ; note index
                    move.w  d3,(CHAN_NOTE_S,a3)
                    add.w   d3,d3
                    move.w  (a5,d3.w),d0
                    ; period
                    move.w  d0,(CHAN_PERIOD_S,a3)
                    OKT_SET_AUDIO_PER d0,a4
                    move.l  a0,-(a7)
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    moveq   #0,d0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    ; default sample volume
                    move.b  (SMP_VOL+1,a1),(a0,d0.w)
                    move.l  (a7)+,a0
                    moveq   #0,d0
                    ; repeat length
                    move.w  (SMP_REP_LEN,a1),d0
                    bne     .OKT_real_repeat
                    ; length before repeat
                    OKT_SET_AUDIO_LEN d1,a4
                    move.l  #OKT_empty_waveform,(CHAN_SMP_REP_START,a3)
                    move.w  #2/2,(CHAN_SMP_REP_LEN_S,a3)
.OKT_no_set:
                    rts
.OKT_real_repeat:
                    move.w  d0,(CHAN_SMP_REP_LEN_S,a3)
                    moveq   #0,d1
                    move.w  (SMP_REP_START,a1),d1
                    add.w   d1,d0
                    ; length
                    OKT_SET_AUDIO_LEN d0,a4
                    add.l   d1,d1
                    add.l   d2,d1
                    move.l  d1,(CHAN_SMP_REP_START,a3)
                    rts

; ===========================================================================
OKT_handle_effects_double_channels:
                    move.l  (OKT_current_pattern-OKT_vars,a6),a2
                    addq.w  #2,a2
                    lea     (OKT_channels_data-OKT_vars,a6),a3
                IFNE OKT_AUDIO_ALL_HW
                    lea     (OKT_periods_table-OKT_vars,a6),a5
                    lea     (OKT_AUDIO_BASE),a4
                ENDC
                    moveq   #8-1,d7
.OKT_loop:
                    tst.b   CHAN_TYPE(a3)
                    bne     .OKT_process_effect
                    addq.w  #4,a2
                    lea     (CHAN_LEN*2,a3),a3
                IFNE OKT_AUDIO_ALL_HW
                    lea     (OKT_AUDIO_SIZE,a4),a4
                ENDC
                    subq.w  #1,d7
                    dbra    d7,.OKT_loop
                    rts

; ===========================================================================
.OKT_process_effect:
                    moveq   #0,d0
                    move.b  (a2),d0
                    add.w   d0,d0
                IFEQ OKT_AUDIO_ALL_HW
                    lea     (OKT_effects_table_d-OKT_vars,a6),a1
                ELSE
                    lea     (OKT_effects_table_s-OKT_vars,a6),a1
                ENDC
                    move.w  (a1,d0.w),d0
                    beq     .OKT_no_effect_l
                    moveq   #0,d1
                    move.b  (1,a2),d1
                    jsr     (a1,d0.w)
.OKT_no_effect_l:
                    addq.w  #4,a2
                    lea     (CHAN_LEN,a3),a3
                IFNE OKT_AUDIO_ALL_HW
                    lea     (OKT_AUDIO_SIZE,a4),a4
                ENDC
                    subq.w  #1,d7
                    moveq   #0,d0
                    move.b  (a2),d0
                    add.w   d0,d0
                    move.w  (a1,d0.w),d0
                    beq     .OKT_no_effect_r
                    moveq   #0,d1
                    move.b  (1,a2),d1
                    jsr     (a1,d0.w)
.OKT_no_effect_r:
                    addq.w  #4,a2
                    lea     (CHAN_LEN,a3),a3
                IFNE OKT_AUDIO_ALL_HW
                    lea     (OKT_AUDIO_SIZE,a4),a4
                ENDC
                    dbra    d7,.OKT_loop
                    rts
                IFEQ OKT_AUDIO_ALL_HW
OKT_effects_table_d:
                    dc.w    0,                                      0,                                  0
                    dc.w    0,                                      0,                                  0
                    dc.w    0,                                      0,                                  0
                    dc.w    0,                                      OKT_arp_d-OKT_effects_table_d,      OKT_arp2_d-OKT_effects_table_d
                    dc.w    OKT_arp3_d-OKT_effects_table_d,         OKT_slide_d_d-OKT_effects_table_d,  0
                    dc.w    OKT_filter-OKT_effects_table_d,         0,                                  OKT_slide_u_tick_d-OKT_effects_table_d
                    dc.w    0,                                      0,                                  0
                    dc.w    OKT_slide_d_tick_d-OKT_effects_table_d, 0,                                  0
                    dc.w    0,                                      OKT_pos_jump-OKT_effects_table_d,   0
                    dc.w    0,                                      OKT_set_speed-OKT_effects_table_d,  0
                    dc.w    OKT_slide_u_d-OKT_effects_table_d,      OKT_set_volume-OKT_effects_table_d, 0
                    dc.W    0,                                      0,                                  0
                ENDC

; ===========================================================================
OKT_handle_effects_single_channels:
                    move.l  (OKT_current_pattern-OKT_vars,a6),a2
                    addq.w  #2,a2
                    lea     (OKT_channels_data-OKT_vars,a6),a3
                    lea     (OKT_periods_table-OKT_vars,a6),a5
                    lea     (OKT_AUDIO_BASE),a4
                    moveq   #8-1,d7
.OKT_loop:
                    tst.b   CHAN_TYPE(a3)
                    beq     .OKT_process_effect
                    addq.w  #8,a2
                    lea     (CHAN_LEN*2,a3),a3
                    lea     (OKT_AUDIO_SIZE,a4),a4
                    subq.w  #1,d7
                    dbra    d7,.OKT_loop
                    rts
.OKT_process_effect:
                    moveq   #0,d0
                    ; effect number
                    move.b  (a2),d0
                    add.w   d0,d0
                    move.w  (OKT_effects_table_s,pc,d0.w),d0
                    beq     .OKT_no_effect
                    moveq   #0,d1
                    ; effect data
                    move.b  (1,a2),d1
                    jsr     (OKT_effects_table_s,pc,d0.w)
.OKT_no_effect:
                    addq.w  #4,a2
                    lea     (CHAN_LEN*2,a3),a3
                    lea     (OKT_AUDIO_SIZE,a4),a4
                    subq.w  #1,d7
                    dbra    d7,.OKT_loop
                    rts
OKT_effects_table_s:
                    dc.w    0,                                      OKT_port_d-OKT_effects_table_s,     OKT_port_u-OKT_effects_table_s
                    dc.w    0,                                      0,                                  0
                    dc.w    0,                                      0,                                  0
                    dc.w    0,                                      OKT_arp_s-OKT_effects_table_s,      OKT_arp2_s-OKT_effects_table_s
                    dc.w    OKT_arp3_s-OKT_effects_table_s,         OKT_slide_d_s-OKT_effects_table_s,  0
                    dc.w    OKT_filter-OKT_effects_table_s,         0,                                  OKT_slide_u_tick_s-OKT_effects_table_s
                    dc.w    0,                                      0,                                  0
                    dc.w    OKT_slide_d_tick_s-OKT_effects_table_s, 0,                                  0
                    dc.w    OKT_release-OKT_effects_table_s,        OKT_pos_jump-OKT_effects_table_s,   0
                    dc.w    0,                                      OKT_set_speed-OKT_effects_table_s,  0
                    dc.w    OKT_slide_u_s-OKT_effects_table_s,      OKT_set_volume-OKT_effects_table_s, 0
                    dc.w    0,                                      0,                                  0

; ===========================================================================
OKT_port_u:
                    add.w   d1,(CHAN_PERIOD_S,a3)
                    cmp.w   #$358,(CHAN_PERIOD_S,a3)
                    ble     .OKT_max
                    move.w  #$358,(CHAN_PERIOD_S,a3)
.OKT_max:
                    OKT_SET_AUDIO_PER CHAN_PERIOD_S(a3),a4
                    rts

; ===========================================================================
OKT_port_d:
                    sub.w   d1,(CHAN_PERIOD_S,a3)
                    cmp.w   #$71,(CHAN_PERIOD_S,a3)
                    bge     .OKT_min
                    move.w  #$71,(CHAN_PERIOD_S,a3)
.OKT_min:
                    OKT_SET_AUDIO_PER CHAN_PERIOD_S(a3),a4
                    rts

; ===========================================================================
OKT_arp_s:
                    move.w  (CHAN_NOTE_S,a3),d2
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    move.b  (OKT_div_table_s,pc,d0.w),d0
                    bne     .OKT_step_2
                    ; step 1: add the first value
                    and.w   #$F0,d1
                    lsr.w   #4,d1
                    sub.w   d1,d2
                    bra     OKT_set_arp_s
.OKT_step_2:
                    subq.b  #1,d0
                    bne     .OKT_step_3
                    ; step 2: play the note
                    bra     OKT_set_arp_s
.OKT_step_3:
                    ; step 3: add the second value
                    and.w   #$F,d1
                    add.w   d1,d2
                    bra     OKT_set_arp_s
OKT_div_table_s:
                    dc.b    0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0

; ===========================================================================
OKT_arp2_s:
                    move.w  (CHAN_NOTE_S,a3),d2
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    and.w   #3,d0
                    bne     .OKT_step_2
                    ; step 1: play the note
                    bra     OKT_set_arp_s
.OKT_step_2:
                    subq.b  #1,d0
                    bne     .OKT_step_3
                    ; step 2: add the second value
                    and.w   #$F,d1
                    add.w   d1,d2
                    bra     OKT_set_arp_s
.OKT_step_3:
                    ; step 4: play the note
                    subq.b  #1,d0
                    beq     OKT_set_arp_s
                    ; step 3: add the first value
                    and.w   #$F0,d1
                    lsr.w   #4,d1
                    sub.w   d1,d2
                    bra     OKT_set_arp_s

; ===========================================================================
OKT_arp3_s:
                    move.w  (CHAN_NOTE_S,a3),d2
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    move.b  (OKT_div_table_3_s,pc,d0.w),d0
                    bne     .OKT_step_1
                    ; step 1: don't change anything
                    rts
.OKT_step_1:
                    subq.b  #1,d0
                    bne     .OKT_step_2
                    ; step 2: play the first value
                    and.w   #$F0,d1
                    lsr.w   #4,d1
                    add.w   d1,d2
                    bra     OKT_set_arp_s
.OKT_step_2:
                    subq.b  #1,d0
                    bne     .OKT_step_3
                    ; step 3: play the second value
                    and.w   #$F,d1
                    add.w   d1,d2
.OKT_step_3:
                    ; step 4: play the note
                    bra     OKT_set_arp_s
OKT_div_table_3_s:
                    dc.b    0,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3

; ===========================================================================
OKT_slide_u_tick_s:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    beq     OKT_slide_u_s
                    rts

; ===========================================================================
OKT_slide_u_s:
                    move.w  (CHAN_NOTE_S,a3),d2
                    add.w   d1,d2
                    move.w  d2,(CHAN_NOTE_S,a3)
                    bra     OKT_set_arp_s

; ===========================================================================
OKT_slide_d_tick_s:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    beq     OKT_slide_d_s
                    rts

; ===========================================================================
OKT_slide_d_s:
                    move.w  (CHAN_NOTE_S,a3),d2
                    sub.w   d1,d2
                    move.w  d2,(CHAN_NOTE_S,a3)

; ===========================================================================
OKT_set_arp_s:
                    tst.w   d2
                    bpl     .OKT_min
                    moveq   #0,d2
.OKT_min:
                    cmp.w   #36-1,d2
                    ble     .OKT_max
                    moveq   #36-1,d2
.OKT_max:
                    add.w   d2,d2
                    move.w  (a5,d2.w),d0
                    OKT_SET_AUDIO_PER d0,a4
                    move.w  d0,(CHAN_PERIOD_S,a3)
                    rts

; ===========================================================================
                IFEQ OKT_AUDIO_ALL_HW
OKT_arp_d:
                    move.w  (CHAN_BASE_NOTE_D,a3),d2
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    move.b  (OKT_div_table_d,pc,d0.w),d0
                    bne     .OKT_step_1
                    and.w   #$F0,d1
                    lsr.w   #4,d1
                    sub.w   d1,d2
                    move.w  d2,(CHAN_NOTE_D,a3)
                    rts
.OKT_step_1:
                    subq.b  #1,d0
                    bne     .OKT_step_2
                    move.w  d2,(CHAN_NOTE_D,a3)
                    rts
.OKT_step_2:
                    and.w   #$F,d1
                    add.w   d1,d2
                    move.w  d2,(CHAN_NOTE_D,a3)
                    rts
OKT_div_table_d:
                    dc.b    0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0

; ===========================================================================
OKT_arp2_d:
                    move.w  (CHAN_BASE_NOTE_D,a3),d2
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    and.w   #3,d0
                    bne     .OKT_step_1
.OKT_step_0:
                    move.w  d2,(CHAN_NOTE_D,a3)
                    rts
.OKT_step_1:
                    subq.b  #1,d0
                    bne     .OKT_step_2
                    and.w   #$F,d1
                    add.w   d1,d2
                    move.w  d2,(CHAN_NOTE_D,a3)
                    rts
.OKT_step_2:
                    subq.b  #1,d0
                    beq     .OKT_step_0
                    and.w   #$F0,d1
                    lsr.w   #4,d1
                    sub.w   d1,d2
                    move.w  d2,(CHAN_NOTE_D,a3)
                    rts

; ===========================================================================
OKT_arp3_d:
                    move.w  (CHAN_BASE_NOTE_D,a3),d2
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    move.b  (OKT_div_table_3_d,pc,d0.w),d0
                    bne     .OKT_step_1
                    rts
.OKT_step_1:
                    subq.b  #1,d0
                    bne     .OKT_step_2
                    and.w   #$F0,d1
                    lsr.w   #4,d1
                    add.w   d1,d2
                    move.w  d2,(CHAN_NOTE_D,a3)
                    rts
.OKT_step_2:
                    subq.b  #1,d0
                    bne     .OKT_step_3
                    and.w   #$F,d1
                    add.w   d1,d2
.OKT_step_3:
                    move.w  d2,(CHAN_NOTE_D,a3)
                    rts
OKT_div_table_3_d:
                    dc.b    0,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3

; ===========================================================================
OKT_slide_u_tick_d:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    beq     OKT_slide_u_d
                    rts
OKT_slide_u_d:
                    add.w   d1,(CHAN_BASE_NOTE_D,a3)
                    add.w   d1,(CHAN_NOTE_D,a3)
                    rts

; ===========================================================================
OKT_slide_d_tick_d:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    beq     OKT_slide_d_d
                    rts
OKT_slide_d_d:
                    sub.w   d1,(CHAN_BASE_NOTE_D,a3)
                    sub.w   d1,(CHAN_NOTE_D,a3)
                    rts
                ENDC

; ===========================================================================
OKT_pos_jump:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    bne     .OKT_no_change
                    move.w  d1,d0
                    and.w   #$F,d0
                    lsr.w   #4,d1
                    mulu.w  #10,d1
                    add.w   d1,d0
                    cmp.w   (OKT_song_length-OKT_vars,a6),d0
                    bcc     .OKT_no_change
                    move.w  d0,(OKT_next_song_pos-OKT_vars,a6)
.OKT_no_change:
                    rts

; ===========================================================================
OKT_set_speed:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    bne     .OKT_no_change
                    and.w   #$F,d1
                    beq     .OKT_no_change
                    move.w  d1,(OKT_current_speed-OKT_vars,a6)
.OKT_no_change:
                    rts

; ===========================================================================
OKT_filter:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    bne     .OKT_no_change
                    tst.b   d1
                    sne     (OKT_filter_status-OKT_vars,a6)
.OKT_no_change:
                    rts

; ===========================================================================
OKT_set_volume:
                    moveq   #0,d0
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    add.w   d0,a0
                    cmp.w   #$40,d1
                    bgt     OKT_volume_fade
                    move.b  d1,(a0)
OKT_volume_fade_done:
                    rts
OKT_volume_fade:
                    subi.b  #$40,d1
                    ;$40 >= $4f
                    cmp.b   #$10,d1
                    blt     .OKT_fade_volume_out
                    ;$50 >= $5f
                    subi.b  #$10,d1
                    cmp.b   #$10,d1
                    blt     .OKT_fade_volume_in
                    ;$60 >= $6f
                    subi.b  #$10,d1
                    cmp.b   #$10,d1
                    blt     .OKT_fade_volume_out_tick
                    ;$70 >= $7f
                    subi.b  #$10,d1
                    cmp.b   #$10,d1
                    blt     .OKT_fade_volume_in_tick
                    rts
.OKT_fade_volume_out_tick:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    bne     OKT_volume_fade_done
.OKT_fade_volume_out:
                    sub.b   d1,(a0)
                    bpl     OKT_volume_fade_done
                    sf      (a0)
                    rts
.OKT_fade_volume_in_tick:
                    move.w  (OKT_action_cycle-OKT_vars,a6),d0
                    bne     OKT_volume_fade_done
.OKT_fade_volume_in:
                    add.b   d1,(a0)
                    cmp.b   #64,(a0)
                    bls     OKT_volume_fade_done
                    move.b  #64,(a0)
                    bra     OKT_volume_fade_done

; ===========================================================================
OKT_release:
                    moveq   #0,d0
                    lea     (OKT_channels_volumes-OKT_vars,a6),a0
                    move.b  (OKT_channels_indexes-OKT_channels_volumes,a0,d7.w),d0
                    add.w   d7,a0
                    cmp.b   #$40,d1
                    bhi     OKT_volume_fade
                    rts

; ===========================================================================
; set global volume
OKT_set_global_volume:
                    cmp.w   #64,d0
                    bls     .OKT_max
                    moveq   #64,d0
.OKT_max:
                    move.w  d0,(OKT_global_volume-OKT_vars,a6)
                    rts

; ===========================================================================
OKT_vars:
OKT_periods_table:
                    dc.w    $358,$328,$2FA,$2D0,$2A6,$280,$25C,$23A,$21A,$1FC,$1E0,$1C5,$1AC,$194
                    dc.w    $17D,$168,$153,$140,$12E,$11D,$10D,$FE,$F0,$E2,$D6,$CA,$BE,$B4,$AA
                    dc.w    $A0,$97,$8F,$87,$7F,$78,$71,0
OKT_old_cia_timer:
                    dcb.b   2,0
OKT_global_volume:
                    dc.w    64
OKT_vbr:
                    dc.l    0
OKT_old_irq:
                    dc.l    0
OKT_action_cycle:
                    dc.w    0
OKT_current_pattern:
                    dc.l    0
OKT_rows_size:
                    dc.w    0
OKT_audio_int_bit:
                    dc.w    0
OKT_audio_int_single_bit:
                    dc.w    0
OKT_double_channels:
                    dc.w    0
OKT_pattern_row:
                    dc.w    0
OKT_current_speed:
                    dc.w    0
OKT_next_song_pos:
                    dc.w    0
OKT_song_pos:
                    dc.w    0
; ===
OKT_channels_indexes:
                    dcb.b   8,0
OKT_channels_volumes:
                    dcb.b   8,0
; ===
OKT_filter_status:
                    dc.b    0
OKT_processor:
                    dc.b    0
OKT_dmacon:
                    dc.w    0
OKT_patterns_number:
                    dc.w    0
OKT_search_hunk_ptr:
                    dc.l    0
OKT_channels_modes:
                    dcb.b   8,0
OKT_speed:
                    dc.w    0
OKT_song_length:
                    dc.w    0
OKT_channels_data:
                    ds.b    CHAN_LEN*8
OKT_samples:
                    ds.b    SMPS_NUMBER*SMP_INFOS_LEN
OKT_patterns:
                    ds.l    32
OKT_patterns_list:
                    ds.l    64
OKT_samples_table:
                    ds.l    SMPS_NUMBER
