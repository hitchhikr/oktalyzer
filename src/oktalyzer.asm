; ===========================================================================
; Oktalyzer v1.57
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled by Franck 'hitchhikr' Charlet.
; ===========================================================================

; ===========================================================================
                    mc68000
                    opt      all+

; ===========================================================================
                    include  "exec/execbase.i"
                    include  "dos/dos.i"
                    include  "dos/dosextens.i"
                    include  "graphics/gfxbase.i"
                    include  "graphics/view.i"
                    include  "intuition/screens.i"
                    include  "resources/disk.i"
                    include  "workbench/startup.i"
                    include  "devices/trackdisk.i"
                    include  "devices/bootblock.i"
                    include  "lvo/exec_lib.i"
                    include  "lvo/dos_lib.i"
                    include  "lvo/graphics_lib.i"
                    include  "lvo/intuition_lib.i"
                    include  "lvo/disk_lib.i"
                    include  "hardware/custom.i"
                    include  "hardware/dmabits.i"
                    include  "hardware/intbits.i"
                    include  "hardware/cia.i"

; ===========================================================================
SCREEN_WIDTH        equ      640
SCREEN_BYTES        equ      (SCREEN_WIDTH/8)

PREFS_FILE_LEN      equ      2102
TRACK_LEN           equ      (22*512)

OK                  equ      0
ERROR               equ      -1

DIR_SONGS           equ      0
DIR_SAMPLES         equ      1
DIR_PREFS           equ      2
DIR_EFFECTS         equ      3

MIX_BUFFERS_1       equ      4
MIX_BUFFERS_LEN_1   equ      626

MIX_BUFFERS_2       equ      2
MIX_BUFFERS_LEN_2   equ      2240

MIDI_OFF            equ      0
MIDI_IN             equ      1
MIDI_OUT            equ      2

CMD_END             equ      0
CMD_TEXT            equ      2
CMD_CLEAR_MAIN_MENU equ      3
CMD_SUB_COMMAND     equ      6
CMD_TEXT_PTR        equ      8
CMD_CLEAR_CHARS     equ      10
CMD_SET_SUB_SCREEN  equ      11
CMD_SET_MAIN_SCREEN equ      12
CMD_MOVE_TO_LINE    equ      13

ERROR_NO_MEM        equ      0
ERROR_WHAT_BLOCK    equ      ERROR_NO_MEM+1
ERROR_WHAT_POS      equ      ERROR_WHAT_BLOCK+1
ERROR_SMP_TOO_LONG  equ      ERROR_WHAT_POS+1
ERROR_WHAT_SMP      equ      ERROR_SMP_TOO_LONG+1
ERROR_SMP_CLEARED   equ      ERROR_WHAT_SMP+1
ERROR_NO_MORE_PATT  equ      ERROR_SMP_CLEARED+1
ERROR_NO_MORE_POS   equ      ERROR_NO_MORE_PATT+1
ERROR_PATT_IN_USE   equ      ERROR_NO_MORE_POS+1
ERROR_COPY_BUF_FREE equ      ERROR_PATT_IN_USE+1
ERROR_NO_MORE_SMP   equ      ERROR_COPY_BUF_FREE+1
ERROR_ONLY_4B_MODE  equ      ERROR_NO_MORE_SMP+1
ERROR_LEFT_ONE_BIT  equ      ERROR_ONLY_4B_MODE+1
ERROR_BLOCK_COPIED  equ      ERROR_LEFT_ONE_BIT+1
ERROR_SMP_CLIPPED   equ      ERROR_BLOCK_COPIED+1
ERROR_SMP_TOO_SHORT equ      ERROR_SMP_CLIPPED+1
ERROR_IFF_ERROR     equ      ERROR_SMP_TOO_SHORT+1
ERROR_SAME_SMP      equ      ERROR_IFF_ERROR+1
ERROR_DIFF_MODES    equ      ERROR_SAME_SMP+1
ERROR_Z_NOT_FOUND   equ      ERROR_DIFF_MODES+1
ERROR_CANT_INST     equ      ERROR_Z_NOT_FOUND+1
ERROR_ALREADY_INST  equ      ERROR_CANT_INST+1
ERROR_NO_OKDIR      equ      ERROR_ALREADY_INST+1
ERROR_OPEN_DEVICE   equ      ERROR_NO_OKDIR+1
ERROR_VERIFY        equ      ERROR_OPEN_DEVICE+1
ERROR_WHAT_SMPS     equ      ERROR_VERIFY+1
ERROR_CANT_CONVERT  equ      ERROR_WHAT_SMPS+1
ERROR_OK_STRUCT     equ      ERROR_CANT_CONVERT+1
ERROR_ST_STRUCT     equ      ERROR_OK_STRUCT+1
ERROR_WHAT_FILE     equ      ERROR_ST_STRUCT+1
ERROR_NOT_DIR       equ      ERROR_WHAT_FILE+1
ERROR_ENDOF_ENTRIES equ      ERROR_NOT_DIR+1
ERROR_NOTHING_SEL   equ      ERROR_ENDOF_ENTRIES+1
ERROR_MULTI_SEL     equ      ERROR_NOTHING_SEL+1
ERROR_COPYBUF_EMPTY equ      ERROR_MULTI_SEL+1
ERROR_NO_ENTRIES    equ      ERROR_COPYBUF_EMPTY+1
ERROR_EF_STRUCT     equ      ERROR_NO_ENTRIES+1
ERROR_ONLY_IN_PAL   equ      ERROR_EF_STRUCT+1

; ===========================================================================
EXEC                MACRO
                    move.l   a6,-(sp)
                    move.l   (4).w,a6
                    jsr      (_LVO\1,a6)
                    move.l   (sp)+,a6
                    ENDM

DOS                 MACRO
                    move.l   a6,-(sp)
                    move.l   DOSBase,a6
                    jsr      (_LVO\1,a6)
                    move.l   (sp)+,a6
                    ENDM

INT                 MACRO
                    move.l   a6,-(sp)
                    move.l   IntBase,a6
                    jsr      (_LVO\1,a6)
                    move.l   (sp)+,a6
                    ENDM

GFX                 MACRO
                    move.l   a6,-(sp)
                    move.l   GFXBase,a6
                    jsr      (_LVO\1,a6)
                    move.l   (sp)+,a6
                    ENDM

DISK                MACRO
                    move.l   a6,-(sp)
                    move.l   DiskBase,a6
                    jsr      (_LVO\1,a6)
                    move.l   (sp)+,a6
                    ENDM

; ===========================================================================
                    section  prog,code
start:
                    sub.l    a5,a5
                    sub.l    a1,a1
                    EXEC     FindTask
                    move.l   d0,a4
                    lea      (dos_name),a1
                    EXEC     OldOpenLibrary
                    move.l   d0,a6
                    move.l   d0,(DOSBase)
                    tst.l    (pr_CLI,a4)
                    seq      (started_from_CLI)
                    bne.b    .from_CLI
                    lea      (pr_MsgPort,a4),a0
                    EXEC     WaitPort
                    lea      (pr_MsgPort,a4),a0
                    EXEC     GetMsg
                    move.l   d0,workbench_message
                    move.l   d0,a0
                    move.l   (sm_ArgList,a0),a0
                    move.l   (a0),d1
                    bra.b    .from_WB
.from_CLI:
                    moveq    #0,d1
                    DOS      CurrentDir
                    move.l   d0,-(a7)
                    move.l   d0,d1
                    DOS      CurrentDir
                    move.l   (a7)+,d1
.from_WB:
                    DOS      DupLock
                    move.l   d0,(current_dir_lock)
                    move.l   #oktalyzer_name,d1
                    moveq    #0,d2
                    lea      (start-4,pc),a0
                    move.l   (a0),d3
                    clr.l    (a0)
                    move.l   #8*1024,d4
                    DOS      CreateProc
                    move.l   (DOSBase),a1
                    EXEC     CloseLibrary
                    move.l   (workbench_message),d0
                    beq.b    .no_message
                    EXEC     Forbid
                    move.l   (workbench_message),a1
                    EXEC     ReplyMsg
.no_message:
                    moveq    #0,d0
                    rts
                    dc.b     0,'$VER: version 1.150',0
                    even
workbench_message:
                    dc.l     0
started_from_CLI:
                    dc.b     0
                    even

; ===========================================================================
                    section  main,code
begin:
                    move.l   sp,(save_stack)
                    bsr.b    init_all
                    jsr      (auto_load_prefs)
                    bsr      main_loop
                    bsr      free_resources
                    moveq    #0,d0
                    rts

; ===========================================================================
exit:
                    move.l   (save_stack),sp
                    bsr      free_resources
                    moveq    #100,d0
                    rts

; ===========================================================================
init_all:
                    sub.l    a1,a1
                    EXEC     FindTask
                    move.l   d0,(our_task)
                    tst.b    (started_from_CLI)
                    beq.b    .set_wb_cli_msg_ptr
                    move.l   #WB_MSG,(wb_cli_text_ptr)
.set_wb_cli_msg_ptr:
                    bsr      open_libraries
                    move.l   (current_dir_lock),d1
                    DOS      CurrentDir
                    jsr      (close_workbench)
                    bsr      set_copper_bitplanes
                    bsr      set_pal_ntsc_vars
                    bsr      set_chipset_aga
                    bsr      install_vbi_int
                    bsr      patch_sys_requesters_function
                    bset     #1,(CIAB)
                    bsr      construct_mult_table
                    jsr      (get_screen_metrics)
                    lea      (our_window_struct),a0
                    ; set the right position according to the width
                    ; of the screen and our window
                    sub.w    (4,a0),d1
                    move.w   d1,(a0)
                    ; add to the height
                    add.w    d0,(6,a0)
                    lea      (our_gadget_struct),a0
                    ; add to the y pos
                    add.w    d0,(6,a0)
                    bsr      install_our_copperlist
                    bra      construct_main_copperlist
our_task:
                    dc.l     0
current_dir_lock:
                    dc.l     0

; ===========================================================================
set_pal_ntsc_vars:
                    move.l   (4).w,a0
                    cmpi.b   #60,(VBlankFrequency,a0)
                    bne      .pal_machine
                    move.b   #$EB,(copper_pal_line)
                    move.b   #$EC,(copper_credits_line)
                    move.b   #$F4,(copper_end_line)
                    move.w   #17,(number_of_rows_on_screen)
                    move.w   #7,(lbW026954)
                    move.w   #392-1,(max_mouse_pointer_y)
                    st       (ntsc_flag)
                    move.w   #17,(max_lines)
.pal_machine:
                    lea      (lbL028096),a0
                    move.w   (max_lines),d0
                    bra      lbC0208DA
ntsc_flag:
                    dc.b     0
                    even

; ===========================================================================
set_chipset_aga:
                    move.w   _CUSTOM+DENISEID,d0
                    moveq    #31-1,d2
                    and.w    #$FF,d0
.check_chipset_loop:
                    move.w   _CUSTOM+DENISEID,d1
                    and.w    #$FF,d1
                    cmp.b    d0,d1
                    bne      .not_aga
                    dbf      d2,.check_chipset_loop
                    or.b     #$F0,d0
                    cmp.b    #$F8,d0
                    beq      .machine_is_aga
.not_aga:
                    rts
.machine_is_aga:
                    move.w   #$2C,copper_ddfstrt+2
                    move.w   #$B4,copper_ddfstop+2
                    rts

; ===========================================================================
free_resources:
                    bsr      stop_audio_channels
                    jsr      (lbC028914)
                    jsr      (lbC02B732)
                    bsr      free_all_samples
                    bsr      restore_sys_requesters_function
                    bsr      lbC01E476
                    jsr      (open_workbench)
                    jsr      restore_screen
                    bra      close_libraries

; ===========================================================================
main_loop:
                    lea      (main_menu_text),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
.loop:
                    lea      (lbW017396),a0
                    bsr      process_commands_sequence
                    bsr      lbC01FBF2
                    bsr      lbC0202A8
                    bsr      display_pattern_caret
                    lea      (lbW01737C),a0
                    bsr      lbC020626
                    bsr      erase_pattern_caret
                    move.l   (current_cmd_ptr),d0
                    beq.b    .no_command
                    move.l   d0,a0
                    jsr      (a0)
                    bra.b    .loop
.no_command:
                    tst.b    (quit_flag)
                    beq.b    .loop
                    rts

; ===========================================================================
lbC01E03E:
                    move.l   #lbC01E04A,(current_cmd_ptr)
                    rts
lbC01E04A:
                    lea      (patterns_ed_help_text_1),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    bsr      lbC0246B8
                    lea      (patterns_ed_help_text_2),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    bra      lbC0246B8
lbC01E074:
                    move.l   #lbC01E080,(current_cmd_ptr)
                    rts
lbC01E080:
                    lea      (effects_help_text),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    bra      lbC0246B8
lbC01E096:
                    jmp      (lbC028904)
lbC01E09E:
                    move.l   #lbC02800C,(current_cmd_ptr)
                    rts
lbC01E0AA:
                    move.l   #lbC02A772,(current_cmd_ptr)
                    rts
lbC01E0B6:
                    move.l   #lbC02B6CC,(current_cmd_ptr)
                    rts
lbC01E0C2:
                    jsr      (wait_drive_ready)
                    jsr      (own_blitter)
                    EXEC     Disable
                    bsr      stop_audio_channels
                    move.w   (_CUSTOM|JOY0DAT),(save_joy0dat)
                    move.w   (lbW01B70E),(lbW01B70C)
                    jmp      (lbC02576C)
lbC01E0FA:
                    jsr      (lbC02576C)
                    move.w   (save_joy0dat),(_CUSTOM|JOYTEST)
                    st       (lbB020540)
                    EXEC     Enable
                    jsr      (disown_blitter)
                    jmp      (release_drive)
save_joy0dat:
                    dc.w     0

; ===========================================================================
install_vbi_int:
                    moveq    #-1,d0
                    EXEC     AllocSignal
                    move.b   d0,(lbB01E1D2)
                    moveq    #0,d1
                    bset     d0,d1
                    move.l   d1,(lbL01E1D4)
                    lea      (lbW018516),a0
                    jsr      (lbC02D022)
                    EXEC     Disable
                    clr.w    (lbW01E376)
                    clr.w    (lbW01E378)
                    clr.w    (lbB01E37A)
                    lea      (vbi_int_struct,pc),a1
                    moveq    #INTB_VERTB,d0
                    EXEC     AddIntServer
                    EXEC     Enable
                    bra      install_midi_ints

; ===========================================================================
remove_vbi_int:
                    lea      (vbi_int_struct,pc),a1
                    moveq    #INTB_VERTB,d0
                    EXEC     RemIntServer
                    lea      (lbW018516),a0
                    jsr      (lbC02D046)
                    moveq    #0,d0
                    move.b   (lbB01E1D2,pc),d0
                    EXEC     FreeSignal
                    rts
lbB01E1D2:
                    dc.b     0
                    even
lbL01E1D4:
                    dc.l     0
vbi_int_struct:
                    dc.l     0,0
                    dc.b     2,127
                    dc.l     vbi_int_name
                    dc.l     0,vbi_int_code
vbi_int_name:
                    dc.b     'Oktalyzer VBI Interrupt',0

; ===========================================================================
install_copper_int:
                    EXEC     Disable
                    lea      (copper_int_struct,pc),a1
                    move.l   a0,(IS_CODE,a1)
                    cmpi.b   #MIDI_IN,(midi_mode)
                    seq      (used_int_flag)
                    beq.b    .use_copper_int
                    moveq    #INTB_EXTER,d0
                    EXEC     AddIntServer
                    move.l   #(INTREQ<<16)|(INTF_EXTER|INTF_SETCLR),d1
                    bra.b    .use_external_int
.use_copper_int:
                    moveq    #INTB_COPER,d0
                    EXEC     AddIntServer
                    move.l   #(INTREQ<<16)|(INTF_SETCLR|INTF_COPER),d1
.use_external_int:
                    move.l   d1,(copper_int)
                    st       (copper_int_installed_flag)
                    EXEC     Enable
                    rts
used_int_flag:
                    dc.b     0
                    even

; ===========================================================================
remove_copper_int:
                    EXEC     Disable
                    move.l   #(BPLCON0<<16)|$9200,(copper_int)
                    lea      (copper_int_struct,pc),a1
                    moveq    #INTB_EXTER,d0
                    tst.b    (used_int_flag)
                    beq.b    .use_external_int
                    moveq    #INTB_COPER,d0
.use_external_int:
                    EXEC     RemIntServer
                    sf       (copper_int_installed_flag)
                    EXEC     Enable
                    rts
copper_int_installed_flag:
                    dc.b     0
                    even
copper_int_struct:
                    dc.l     0,0
                    dc.b     2,127
                    dc.l     copper_int_name
                    dc.l     0,0
copper_int_name:
                    dc.b     'Oktalyzer Copper/External Interrupt',0

; ===========================================================================
vbi_int_code:
                    tst.w    (lbW01E5E8)
                    bne.b    lbC01E326
                    movem.l  d0-d3/a0/a1,-(sp)
                    moveq    #10,d0
                    moveq    #0,d1
                    moveq    #0,d2
                    moveq    #0,d3
                    bsr      lbC0205C4
                    lea      (lbW01E376,pc),a0
                    moveq    #6,d0
                    bsr      lbC01E32A
                    lea      (lbW01E378,pc),a0
                    moveq    #9,d0
                    bsr      lbC01E32A
                    ; must be 0 as some flag is tested right after that
                    moveq    #0,d0
                    movem.l  (sp)+,d0-d3/a0/a1
                    rts
lbC01E326:
                    moveq    #0,d0
                    rts
lbC01E32A:
                    EXEC     Disable
                    tst.w    (a0)
                    beq.b    lbC01E368
                    subq.w   #1,(a0)
                    bne.b    lbC01E368
                    move.w   (mouse_repeat_speed),(a0)
                    EXEC     Enable
                    movem.w  (mouse_pointer_coords,pc),d1/d2
                    lsr.w    #1,d2
                    moveq    #0,d3
                    bra      lbC0205C4
lbC01E368:
                    EXEC     Enable
                    rts
lbW01E376:
                    dc.w     0
lbW01E378:
                    dc.w     0
lbB01E37A:
                    dc.b     0
lbB01E37B:
                    dc.b     0

; ===========================================================================
lbC01E37C:
                    tst.w    (lbW01E5E8)
                    bne.b    lbC01E3A4
                    move.b   (4,a0),d0
                    cmpi.b   #1,d0
                    beq.b    lbC01E3A8
                    cmpi.b   #2,d0
                    beq.b    lbC01E3B8
                    cmpi.b   #15,d0
                    beq.b    lbC01E3D6
                    cmpi.b   #16,d0
                    beq.b    lbC01E3D6
                    moveq    #0,d0
                    rts
lbC01E3A4:
                    move.l   a0,d0
                    rts
lbC01E3A8:
                    move.w   (6,a0),d0
                    move.w   (8,a0),d1
                    bsr      lbC02048C
                    moveq    #0,d0
                    rts
lbC01E3B8:
                    movem.w  (10,a0),d0/d1
                    move.w   (6,a0),-(sp)
                    move.w   (8,a0),-(sp)
                    bsr      lbC0206F2
                    move.w   (sp)+,d1
                    move.w   (sp)+,d0
                    bsr      lbC01E3EE
                    moveq    #0,d0
                    rts
lbC01E3D6:
                    movem.l  d2/d3,-(sp)
                    moveq    #13,d0
                    moveq    #0,d1
                    moveq    #0,d2
                    moveq    #0,d3
                    bsr      lbC0205C4
                    movem.l  (sp)+,d2/d3
                    moveq    #0,d0
                    rts
lbC01E3EE:
                    movem.l  d2/d3,-(sp)
                    move.w   d1,d3
                    movem.w  (mouse_pointer_coords),d1/d2
                    lsr.w    #1,d2
                    cmpi.w   #104,d0
                    bne.b    lbC01E41C
                    st       (lbB01E37B)
                    moveq    #4,d0
                    bsr      lbC0205C4
                    move.w   (mouse_repeat_delay),(lbW01E376)
                    bra.b    lbC01E46C
lbC01E41C:
                    cmpi.w   #232,d0
                    bne.b    lbC01E436
                    clr.w    (lbW01E376)
                    sf       (lbB01E37B)
                    moveq    #5,d0
                    bsr      lbC0205C4
                    bra.b    lbC01E46C
lbC01E436:
                    cmpi.w   #105,d0
                    bne.b    lbC01E454
                    st       (lbB01E37A)
                    moveq    #7,d0
                    bsr      lbC0205C4
                    move.w   (mouse_repeat_delay),(lbW01E378)
                    bra.b    lbC01E46C
lbC01E454:
                    cmpi.w   #233,d0
                    bne.b    lbC01E470
                    clr.w    (lbW01E378)
                    sf       (lbB01E37A)
                    moveq    #8,d0
                    bsr      lbC0205C4
lbC01E46C:
                    bsr      install_mouse_pointer
lbC01E470:
                    movem.l  (sp)+,d2/d3
                    rts
lbC01E476:
                    bsr      remove_midi_ints
                    bra      remove_vbi_int

; ===========================================================================
reinstall_midi_ints:
                    EXEC     Disable
                    bsr      install_midi_ints
                    clr.w    (lbW01E376)
                    clr.w    (lbW01E378)
                    clr.w    (lbB01E37A)
                    EXEC     Enable
                    rts

; ===========================================================================
patch_sys_requesters_function:
                    EXEC     Disable
                    lea      (lbW01E5E8,pc),a0
                    tst.w    (a0)
                    beq.b    lbC01E4CC
                    subq.w   #1,(a0)
lbC01E4CC:
                    move.l   (IntBase),a1
                    move.w   #_LVOAutoRequest,a0
                    cmpi.w   #36,(LIB_VERSION,a1)
                    bcs.b    .old_intuition
                    move.w   #_LVOEasyRequestArgs,a0
.old_intuition:
                    move.l   #our_sys_requesters_function,d0
                    EXEC     SetFunction
                    move.l   d0,(old_sys_requesters_function)
                    EXEC     Enable
                    rts

; ===========================================================================
restore_sys_requesters_function:
                    move.l   d2,-(sp)
                    EXEC     Disable
                    addq.w   #1,(lbW01E5E8)
                    move.l   (IntBase),a1
                    move.w   #_LVOAutoRequest,a0
                    cmpi.w   #36,(LIB_VERSION,a1)
                    bcs.b    .old_intuition
                    move.w   #_LVOEasyRequestArgs,a0
.old_intuition:
                    move.l   (old_sys_requesters_function,pc),d0
                    EXEC     SetFunction
                    EXEC     Enable
                    move.l   (sp)+,d2
                    rts
old_sys_requesters_function:
                    dc.l     0
our_sys_requesters_function:
                    tst.b    (copper_int_installed_flag)
                    bne.b    .installed
                    tst.b    (workbench_opened_flag)
                    bne.b    lbC01E56A
.installed:
                    moveq    #0,d0
                    rts
lbC01E56A:
                    movem.l  d0-d7/a0-a6,-(sp)
                    EXEC     Disable
                    lea      (lbW01E5E8,pc),a0
                    addq.w   #1,(a0)
                    cmpi.w   #1,(a0)
                    bne.b    lbC01E58E
                    jsr      (remove_midi_ints)
                    jsr      (restore_screen)
lbC01E58E:
                    EXEC     Enable
                    movem.l  (sp)+,d0-d7/a0-a6
                    pea      (lbC01E5A8,pc)
                    move.l   (old_sys_requesters_function,pc),-(sp)
                    rts
lbC01E5A8:
                    movem.l  d0-d7/a0-a6,-(sp)
                    EXEC     Disable
                    subq.w   #1,(lbW01E5E8)
                    bne.b    lbC01E5D6
                    bsr      reinstall_midi_ints
                    EXEC     Enable
                    bsr      install_our_copperlist
                    bra.b    lbC01E5E2
lbC01E5D6:
                    EXEC     Enable
lbC01E5E2:
                    movem.l  (sp)+,d0-d7/a0-a6
                    rts
lbW01E5E8:
                    dc.w     0

; ===========================================================================
construct_mult_table:
                    lea      (emult_table),a0
                    move.w   #(15*SCREEN_BYTES),d0
                    moveq    #16-1,d1
.outer_copy_1:
                    moveq    #8-1,d2
.inner_copy_1:
                    move.w   d0,-(a0)
                    dbra     d2,.inner_copy_1
                    subi.w   #SCREEN_BYTES,d0
                    dbra     d1,.outer_copy_1
                    move.w   #(31*SCREEN_BYTES),d0
                    moveq    #16-1,d1
.outer_copy_2:
                    moveq    #8-1,d2
.inner_copy_2:
                    move.w   d0,-(a0)
                    dbra     d2,.inner_copy_2
                    subi.w   #SCREEN_BYTES,d0
                    dbra     d1,.outer_copy_2
                    rts

; ===========================================================================
stop_audio_channels:
                    movem.l  d0/a0,-(sp)
                    lea      (_CUSTOM),a0
                    moveq    #0,d0
                    move.w   d0,(AUD0VOL,a0)
                    move.w   d0,(AUD1VOL,a0)
                    move.w   d0,(AUD2VOL,a0)
                    move.w   d0,(AUD3VOL,a0)
                    move.w   #DMAF_AUDIO,(DMACON,a0)
                    jsr      (lbC029E48)
                    movem.l  (sp)+,d0/a0
                    rts

; ===========================================================================
open_libraries:
                    lea      (intuition_name,pc),a1
                    EXEC     OldOpenLibrary
                    move.l   d0,(IntBase)
                    lea      (graphics_name,pc),a1
                    EXEC     OldOpenLibrary
                    move.l   d0,(GFXBase)
                    lea      (disk_name,pc),a1
                    moveq    #0,d0
                    EXEC     OpenResource
                    move.l   d0,(DiskBase)
                    rts

; ===========================================================================
close_libraries:
                    move.l   (IntBase,pc),a1
                    EXEC     CloseLibrary
                    move.l   (GFXBase,pc),a1
                    EXEC     CloseLibrary
                    rts
dos_name:
                    DOSNAME
intuition_name:
                    INTNAME
graphics_name:
                    GRAPHICSNAME
disk_name:
                    DISKNAME
                    even
DOSBase:
                    dc.l     0
IntBase:
                    dc.l     0
GFXBase:
                    dc.l     0
DiskBase:
                    dc.l     0

; ===========================================================================
set_copper_bitplanes:
                    move.l   #dummy_sprite,d0
                    lea      (sprites_bps+2),a0
                    moveq    #8-1,d7
.set_sprites_bps:
                    move.w   d0,(4,a0)
                    swap     d0
                    move.w   d0,(a0)
                    swap     d0
                    addq.w   #8,a0
                    dbra     d7,.set_sprites_bps
                    lea      (main_menu_bp+2),a0
                    move.l   #main_screen,d0
                    move.w   d0,(4,a0)
                    swap     d0
                    move.w   d0,(a0)
                    lea      (credits_bp+2),a0
                    move.l   #bottom_credits_picture,d0
                    move.w   d0,(4,a0)
                    swap     d0
                    move.w   d0,(a0)
                    rts

; ===========================================================================
set_full_screen_copperlist_ntsc:
                    EXEC     Disable
                    move.w   #DMAF_COPPER,(_CUSTOM|DMACON)
                    addq.b   #1,(dma_copper_spinlock)
                    tst.b    (ntsc_flag)
                    beq      .no_ntsc
                    lea      (full_screen_copperlist_flag,pc),a0
                    tst.b    (a0)
                    beq      .no_ntsc
                    sf       (a0)
                    bsr      construct_full_screen_copperlist_ntsc
                    move.w   #11,(lbW026954)
                    move.w   #56,(lbW01E8E8)
.no_ntsc:
                    subq.b   #1,(dma_copper_spinlock)
                    bgt.b    lbC01E7E8
                    move.w   #DMAF_SETCLR|DMAF_COPPER,(_CUSTOM|DMACON)
lbC01E7E8:
                    EXEC     Enable
                    rts

; ===========================================================================
construct_full_screen_copperlist_ntsc:
                    EXEC     Disable
                    move.w   #DMAF_COPPER,(_CUSTOM|DMACON)
                    addq.b   #1,(dma_copper_spinlock)
                    move.b   #$2C,(copper_start_line)
                    lea      (fullscreen_copperlist_ntsc_struct),a0
                    bsr      construct_copperlist
                    subq.b   #1,(dma_copper_spinlock)
                    bgt.b    lbC01E832
                    move.w   #DMAF_SETCLR|DMAF_COPPER,(_CUSTOM|DMACON)
lbC01E832:
                    EXEC     Enable
                    rts

; ===========================================================================
restore_full_screen_copperlist_ntsc:
                    EXEC     Disable
                    move.w   #DMAF_COPPER,(_CUSTOM|DMACON)
                    addq.b   #1,(dma_copper_spinlock)
                    tst.b    (ntsc_flag)
                    beq.b    .no_ntsc
                    lea      (full_screen_copperlist_flag,pc),a0
                    tst.b    (a0)
                    bne.b    .no_ntsc
                    st       (a0)
                    bsr      construct_main_copperlist
                    move.w   #7,(lbW026954)
                    clr.w    (lbW01E8E8)
.no_ntsc:
                    subq.b   #1,(dma_copper_spinlock)
                    bgt.b    lbC01E88E
                    move.w   #DMAF_SETCLR|DMAF_COPPER,(_CUSTOM|DMACON)
lbC01E88E:
                    EXEC     Enable
                    rts

; ===========================================================================
construct_main_copperlist:
                    EXEC     Disable
                    move.w   #DMAF_COPPER,(_CUSTOM|DMACON)
                    addq.b   #1,(dma_copper_spinlock)
                    move.b   #$64,(copper_start_line)
                    lea      (main_copperlist_struct),a0
                    bsr      construct_copperlist
                    subq.b   #1,(dma_copper_spinlock)
                    bgt.b    lbC01E8D8
                    move.w   #DMAF_SETCLR|DMAF_COPPER,(_CUSTOM|DMACON)
lbC01E8D8:
                    EXEC     Enable
                    rts
full_screen_copperlist_flag:
                    dc.b     -1
                    even
lbW01E8E8:
                    dc.w     0

; ===========================================================================
construct_copperlist:
                    movem.l  a2/a3,-(sp)
                    move.l   a0,a2
                    EXEC     Disable
                    move.w   #DMAF_COPPER,(_CUSTOM|DMACON)
                    addq.b   #1,(dma_copper_spinlock)
                    ; first copperlist
                    move.l   (a2)+,a3
.loop:
                    move.l   (a2),d0
                    beq.b    .done
                    moveq    #-1,d1
                    cmp.l    d1,d0
                    beq.b    .skip
                    ; copper jump address
                    move.l   (4,a2),a0
                    ; dest block
                    move.l   d0,a1
                    bsr      set_copperlist_jump
                    move.l   (a2),a0
                    ; copper back jump address
                    lea      (12,a0),a0
                    ; dest block
                    move.l   (8,a2),a1
                    bsr      set_copperlist_jump
                    ; next entry
                    lea      (12,a2),a2
                    bra.b    .loop
.skip:
                    ; write dummy values to dest block
                    move.l   (4,a2),a0
                    move.l   #(COLOR31<<16)|$0000,d0
                    move.l   d0,(a0)+
                    move.l   d0,(a0)+
                    move.l   d0,(a0)+
                    addq.w   #8,a2
                    bra.b    .loop
.done:
                    move.l   a3,a0
                    move.l   a0,(_CUSTOM|COP1LCH)
                    subq.b   #1,(dma_copper_spinlock)
                    bgt.b    lbC01E976
                    move.w   #DMAF_SETCLR|DMAF_COPPER,(_CUSTOM|DMACON)
lbC01E976:
                    EXEC     Enable
                    movem.l  (sp)+,a2/a3
                    rts

; ===========================================================================
set_copperlist_jump:
                    move.l   a0,d0
                    move.w   #COP2LCH,(a1)
                    move.w   #COP2LCL,(4,a1)
                    move.w   d0,(6,a1)
                    swap     d0
                    move.w   d0,(2,a1)
                    move.l   #(COPJMP2<<16)+$0000,(8,a1)
                    rts

; ===========================================================================
install_our_copperlist:
                    movem.l  d0/d1/a0/a1,-(sp)
                    lea      (copperlist),a0
                    jsr      (setup_screen)
                    move.l   d0,(screen_mem_block)
                    movem.l  (sp)+,d0/d1/a0/a1
                    rts
dma_copper_spinlock:
                    dc.b     0
                    even

; ===========================================================================
lbC01E9DC:
                    move.w   d1,d2
                    move.w   d0,d1
                    movem.l  d2/d3,-(sp)
                    move.w   d1,d3
                    lsr.w    #3,d2
                    subq.w   #7,d2
                    bmi.b    lbC01EA2C
                    add.w    (pattern_bitplane_top_pos),d2
                    move.w   d2,(viewed_pattern_row)
                    move.w   d2,d0
                    bsr      lbC01F200
                    bsr      lbC01F1D8
                    lsr.w    #3,d3
                    lea      (caret_current_positions+1),a0
                    moveq    #-1,d0
lbC01EA0C:
                    addq.w   #1,d0
                    move.b   (a0)+,d1
                    beq.b    lbC01EA1E
                    cmp.b    d3,d1
                    ble.b    lbC01EA0C
                    move.w   d0,(caret_pos_x)
                    bra.b    lbC01EA28
lbC01EA1E:
                    move.w   (lbW01B294),(caret_pos_x)
lbC01EA28:
                    bsr      display_pattern_caret
lbC01EA2C:
                    movem.l  (sp)+,d2/d3
                    rts
lbC01EA32:
                    move.w   d1,d0
                    sf       d1
                    bsr      lbC01EA70
                    moveq    #ERROR,d0
                    rts
lbC01EA3E:
                    cmpi.b   #MIDI_IN,(midi_mode)
                    bne.b    lbC01EA6C
                    move.w   d1,d0
                    subi.w   #$30,d0
                    bmi.b    lbC01EA56
                    cmpi.w   #$24,d0
                    blt.b    lbC01EA58
lbC01EA56:
                    moveq    #-1,d0
lbC01EA58:
                    addq.w   #1,d0
                    tst.w    d2
                    bne.b    lbC01EA66
                    jsr      (lbC029E50)
                    bra.b    lbC01EA6C
lbC01EA66:
                    st       d1
                    bsr      lbC01EA70
lbC01EA6C:
                    moveq    #ERROR,d0
                    rts
lbC01EA70:
                    movem.l  d2/d5/d6/a5,-(sp)
                    move.b   d1,(lbW01EC46)
                    move.w   d0,-(sp)
                    bsr      get_current_pattern_rows
                    move.l   a0,a5
                    move.w   d0,(lbW01EC42)
                    move.w   (sp)+,d0
                    move.w   (viewed_pattern_row,pc),d6
                    move.w   d6,d1
                    mulu.w   (lbW02A75A),d1
                    adda.l   d1,a5
                    move.w   (lbW01EC42),(lbW01EC44)
                    sub.w    d6,(lbW01EC44)
                    addq.w   #7,d6
                    moveq    #0,d1
                    move.w   (caret_pos_x,pc),d1
                    divu.w   #5,d1
                    lea      (caret_current_positions),a0
                    move.w   (caret_pos_x,pc),d2
                    adda.w   d2,a0
                    moveq    #0,d5
                    move.b   (a0),d5
                    move.w   d5,d2
                    cmpi.w   #45,d2
                    blt.b    lbC01EACE
                    subq.w   #3,d2
lbC01EACE:
                    subq.w   #6,d2
                    ext.l    d2
                    divu.w   #18,d2
                    move.w   d2,(lbW01EC40)
                    add.w    d1,d1
                    add.w    d1,d1
                    adda.w   d1,a5
                    swap     d1
                    lsl.w    #2,d1
                    tst.b    (lbB01B2A6)
                    bne.b    lbC01EB00
                    lea      (lbL01EC04,pc),a0
                    tst.b    (lbW01EC46)
                    beq.b    lbC01EB10
                    lea      (lbL01EC2C,pc),a0
                    bra.b    lbC01EB10
lbC01EB00:
                    lea      (lbL01EBF0,pc),a0
                    tst.b    (lbW01EC46)
                    beq.b    lbC01EB10
                    lea      (lbL01EC18,pc),a0
lbC01EB10:
                    move.l   (a0,d1.w),d2
                    beq      lbC01EBEA
                    move.l   d2,a0
                    tst.w    d1
                    bne.b    lbC01EB50
                    tst.b    (lbW01EC46)
                    bne.b    lbC01EB50
                    move.w   d0,d2
                    bclr     #$F,d2
                    cmpi.w   #1,d2
                    beq.b    lbC01EB60
                    cmpi.w   #4,d2
                    beq.b    lbC01EB70
                    cmpi.w   #$106,d2
                    beq.b    lbC01EB68
                    cmpi.w   #$206,d2
                    beq.b    lbC01EB7C
                    cmpi.w   #$406,d2
                    beq.b    lbC01EBA2
                    cmpi.w   #$1006,d2
                    beq.b    lbC01EBC6
lbC01EB50:
                    move.w   d0,d2
                    andi.w   #$7F00,d2
                    bne      lbC01EBEA
                    jsr      (a0)
                    bra      lbC01EBEA
lbC01EB60:
                    bsr      lbC01EEB0
                    bra      lbC01EBEA
lbC01EB68:
                    bsr      lbC01EE44
                    bra      lbC01EBEA
lbC01EB70:
                    bsr      lbC01EE44
                    bsr      next_pattern_row
                    bra      lbC01EBEA
lbC01EB7C:
                    clr.l    (a5)
                    bsr      erase_pattern_caret
                    lea      (ascii_MSG1,pc),a0
                    move.w   d5,d0
                    move.w   d6,d1
                    jsr      (draw_text)
                    bsr      next_pattern_row
                    bra      lbC01EBEA
ascii_MSG1:
                    dc.b     '--- 0000',0
                    even
lbC01EBA2:
                    clr.w    (2,a5)
                    bsr      erase_pattern_caret
                    lea      (ascii_MSG2,pc),a0
                    move.w   d5,d0
                    addq.w   #5,d0
                    move.w   d6,d1
                    jsr      (draw_text)
                    bsr      next_pattern_row
                    bra      lbC01EBEA
ascii_MSG2:
                    dc.b     '000',0
lbC01EBC6:
                    clr.w    (a5)
                    bsr      erase_pattern_caret
                    lea      (ascii_MSG3,pc),a0
                    move.w   d5,d0
                    move.w   d6,d1
                    jsr      (draw_text)
                    bsr      lbC01FA98
                    bsr      lbC01FBE2
                    bra.b    lbC01EBEA
ascii_MSG3:
                    dc.b     '--- 0',0
lbC01EBEA:
                    movem.l  (sp)+,d2/d5/d6/a5
                    rts
lbL01EBF0:
                    dc.l     lbC01EC48
                    dc.l     lbC01ED64
                    dc.l     lbC01ED9C
                    dc.l     lbC01EDD4
                    dc.l     lbC01EE0E
lbL01EC04:
                    dc.l     lbC01ED12,0,0,0,0
lbL01EC18:
                    dc.l     lbC01EC74,0,0,0,0
lbL01EC2C:
                    dc.l     lbC01ED3A,0,0,0,0
lbW01EC40:
                    dc.w     0
lbW01EC42:
                    dc.w     0
lbW01EC44:
                    dc.w     0
lbW01EC46:
                    dc.w     0
lbC01EC48:
                    movem.l  d2,-(sp)
                    btst     #15,d0
                    seq      d2
                    bsr      lbC01F06E
                    bmi      lbC01EC6E
                    move.l   (lbL01F2D0),a1
                    move.b   (a1,d0.w),d0
                    bmi      lbC01EC6E
                    move.b   d2,d1
                    bsr      lbC01EC7A
lbC01EC6E:
                    movem.l  (sp)+,d2
                    rts
lbC01EC74:
                    st       d1
lbC01EC7A:
                    movem.l  d2,-(sp)
                    lea      (lbL01A13A),a0
                    move.b   d5,(a0)
                    move.b   d6,(1,a0)
                    sf       (1,a5)
                    move.b   d0,(a5)
                    beq.b    lbC01ECBC
                    move.b   (lbB021E53,pc),(1,a5)
                    tst.b    d1
                    beq.b    lbC01ECBC
                    move.w   d0,d1
                    movem.l  d0/a0,-(sp)
                    move.w   (lbW01EC40,pc),d0
                    movem.w  d0/d1,-(sp)
                    jsr      (lbC029E3E)
                    movem.w  (sp)+,d0/d1
                    bsr      lbC01EF1E
                    movem.l  (sp)+,d0/a0
lbC01ECBC:
                    movem.l  d0/a0,-(sp)
                    bsr      erase_pattern_caret
                    movem.l  (sp)+,d0/a0
                    add.w    d0,d0
                    add.w    d0,d0
                    lea      (C1C1D1D1E1F1F_MSG),a1
                    move.l   (a1,d0.w),(2,a0)
                    sf       (6,a0)
                    jsr      (draw_text_with_coords_struct)
                    move.w   d5,d0
                    addq.w   #4,d0
                    move.w   d6,d1
                    move.w   (current_sample,pc),d2
                    tst.b    (a5)
                    bne.b    lbC01ED00
                    moveq    #0,d2
                    sf       (1,a5)
                    bsr      draw_one_char_alpha_numeric
                    bsr      next_pattern_row
                    bra.b    lbC01ED0C
lbC01ED00:
                    bsr      draw_one_char_alpha_numeric
                    bsr      lbC01FA98
                    bsr      lbC01FBE2
lbC01ED0C:
                    movem.l  (sp)+,d2
                    rts
lbC01ED12:
                    movem.l  d2,-(sp)
                    btst     #15,d0
                    seq      d2
                    bsr      lbC01F06E
                    bmi.b    lbC01ED34
                    move.l   (lbL01F2D0),a0
                    move.b   (a0,d0.w),d0
                    ble.b    lbC01ED34
                    move.b   d2,d1
                    bsr      lbC01ED46
lbC01ED34:
                    movem.l  (sp)+,d2
                    rts
lbC01ED3A:
                    tst.b    d0
                    beq.b    lbC01ED44
                    st       d1
                    bra      lbC01ED46
lbC01ED44:
                    rts
lbC01ED46:
                    tst.b    d1
                    beq.b    lbC01ED62
                    move.w   d0,d1
                    move.w   (lbW01EC40,pc),d0
                    movem.w  d0/d1,-(sp)
                    jsr      (lbC029E3E)
                    movem.w  (sp)+,d0/d1
                    bra      lbC01EF1E
lbC01ED62:
                    rts
lbC01ED64:
                    movem.l  d2,-(sp)
                    bsr      lbC01F094
                    bmi.b    lbC01ED96
                    move.b   d0,(1,a5)
                    lea      (alpha_numeric_table),a0
                    move.b   (a0,d0.w),d2
                    move.w   d5,d0
                    move.w   d6,d1
                    movem.l  d0/d1,-(sp)
                    bsr      erase_pattern_caret
                    movem.l  (sp)+,d0/d1
                    jsr      (draw_one_char)
                    bsr      next_pattern_row
lbC01ED96:
                    movem.l  (sp)+,d2
                    rts
lbC01ED9C:
                    movem.l  d2,-(sp)
                    bsr      lbC01F094
                    bmi.b    lbC01EDCE
                    move.b   d0,(2,a5)
                    lea      (alpha_numeric_table),a0
                    move.b   (a0,d0.w),d2
                    move.w   d5,d0
                    move.w   d6,d1
                    movem.w  d0/d1,-(sp)
                    bsr      erase_pattern_caret
                    movem.w  (sp)+,d0/d1
                    jsr      (draw_one_char)
                    bsr      next_pattern_row
lbC01EDCE:
                    movem.l  (sp)+,d2
                    rts
lbC01EDD4:
                    movem.l  d2,-(sp)
                    bsr      lbC01F0C6
                    bmi.b    lbC01EE08
                    andi.b   #$F,(3,a5)
                    lsl.b    #4,d0
                    or.b     d0,(3,a5)
                    lea      (alpha_numeric_table),a0
                    lsr.b    #4,d0
                    move.b   (a0,d0.w),d2
                    move.w   d5,d0
                    move.w   d6,d1
                    bsr      erase_pattern_caret
                    jsr      (draw_one_char)
                    bsr      next_pattern_row
lbC01EE08:
                    movem.l  (sp)+,d2
                    rts
lbC01EE0E:
                    movem.l  d2,-(sp)
                    bsr      lbC01F0C6
                    bmi.b    lbC01EE3E
                    andi.b   #$F0,(3,a5)
                    or.b     d0,(3,a5)
                    lea      (alpha_numeric_table),a0
                    move.b   (a0,d0.w),d2
                    move.w   d5,d0
                    move.w   d6,d1
                    bsr      erase_pattern_caret
                    jsr      (draw_one_char)
                    bsr      next_pattern_row
lbC01EE3E:
                    movem.l  (sp)+,d2
                    rts
lbC01EE44:
                    movem.l  d2,-(sp)
                    move.l   a5,a0
                    move.w   (lbW01EC44,pc),d0
                    subq.w   #2,d0
                    move.w   (lbW02A75A),d1
                    mulu.w   d1,d0
                    adda.l   d0,a0
                    move.w   (lbW01EC44,pc),d0
                    subq.w   #1,d0
                    bmi.b    lbC01EE6E
                    bra.b    lbC01EE6A
lbC01EE64:
                    move.l   (a0),(a0,d1.w)
                    suba.w   d1,a0
lbC01EE6A:
                    dbra     d0,lbC01EE64
lbC01EE6E:
                    move.l   a5,a0
                    clr.l    (a0)
                    bsr      erase_pattern_caret
                    bsr      lbC01F508
                    move.w   d5,d0
                    move.w   (viewed_pattern_row,pc),d1
                    move.w   (lbW01EC44,pc),d2
                    jsr      (lbC0269F2)
                    lea      (ascii_MSG5,pc),a0
                    move.w   d5,d0
                    move.w   d6,d1
                    jsr      (draw_text)
                    bsr      lbC01F440
                    bsr      display_pattern_caret
                    movem.l  (sp)+,d2
                    rts
ascii_MSG5:
                    dc.b     '--- 0000',0
                    even
lbC01EEB0:
                    movem.l  d2,-(sp)
                    move.w   (viewed_pattern_row,pc),d1
                    subq.w   #1,d1
                    bmi.b    lbC01EF0E
                    move.l   a5,a0
                    move.w   (lbW02A75A),d0
                    suba.w   d0,a0
                    move.w   (lbW01EC44,pc),d1
                    bra.b    lbC01EED2
lbC01EECC:
                    move.l   (a0,d0.w),(a0)
                    adda.w   d0,a0
lbC01EED2:
                    dbra     d1,lbC01EECC
                    clr.l    (a0)
                    bsr      erase_pattern_caret
                    bsr      lbC01F508
                    move.w   d5,d0
                    move.w   (viewed_pattern_row,pc),d1
                    subq.w   #1,d1
                    move.w   (lbW01EC44,pc),d2
                    addq.w   #1,d2
                    jsr      (lbC026994)
                    lea      (ascii_MSG55,pc),a0
                    move.w   d5,d0
                    move.w   (lbW01EC42,pc),d1
                    addq.w   #6,d1
                    jsr      (draw_text)
                    bsr      lbC01F440
                    bsr      previous_pattern_row
lbC01EF0E:
                    movem.l  (sp)+,d2
                    rts
ascii_MSG55:
                    dc.b     '--- 0000',0
                    even
lbC01EF1E:
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    bne.b    lbC01EF5A
                    movem.l  d2/a2,-(sp)
                    lea      (OK_Samples),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    tst.w    (30,a0)
                    bne.b    lbC01EF46
                    move.w   #64,d2
                    bra.b    lbC01EF4A
lbC01EF46:
                    move.w   (28,a0),d2
lbC01EF4A:
                    move.w   (current_sample,pc),d0
                    jsr      (lbC0229C4)
                    movem.l  (sp)+,d2/a2
                    rts
lbC01EF5A:
                    tst.l    (lbL01A130)
                    beq      lbC01EFE4
                    tst.l    (lbL01A134)
                    beq.b    lbC01EFE4
                    movem.l  d2-d4/a2,-(sp)
                    move.w   d0,-(sp)
                    move.w   d1,-(sp)
                    jsr      (lbC028E96)
                    move.w   (sp)+,d1
                    lea      (OK_Samples),a2
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a2
                    lea      (lbW02513C),a0
                    add.w    d1,d1
                    move.w   (a0,d1.w),d2
                    move.l   (lbL01A130),a0
                    move.l   (lbL01A134),d0
                    lsr.l    #1,d0
                    tst.w    (30,a2)
                    bne.b    lbC01EFB6
                    moveq    #64,d3
                    lea      (OK_EmptyWaveForm),a1
                    moveq    #1,d1
                    bra.b    lbC01EFDA
lbC01EFB6:
                    move.w   (28,a2),d3
                    move.w   (26,a2),d1
                    bne.b    lbC01EFCA
                    lea      (OK_EmptyWaveForm),a1
                    moveq    #1,d1
                    bra.b    lbC01EFDA
lbC01EFCA:
                    move.l   a0,a1
                    moveq    #0,d4
                    move.w   (24,a2),d4
                    move.w   d1,d0
                    add.w    d4,d0
                    add.l    d4,d4
                    adda.l   d4,a1
lbC01EFDA:
                    move.w   (sp)+,d4
                    bsr      lbC01EFE8
                    movem.l  (sp)+,d2-d4/a2
lbC01EFE4:
                    rts
lbC01EFE8:
                    movem.l  d5/a2,-(sp)
                    lea      (_CUSTOM|AUD0LCH),a2
                    moveq    #DMAB_AUD0,d5
                    bset     d4,d5
                    move.w   d5,(DMACON-AUD0LCH,a2)
                    lsl.w    #4,d4
                    adda.w   d4,a2
                    move.l   a0,(a2)+
                    move.w   d0,(a2)+
                    move.w   #113,(a2)
                    bsr      wait_raster
                    move.w   d2,(a2)+
                    move.w   d3,(a2)+
                    ori.w    #DMAF_SETCLR,d5
                    move.w   d5,(_CUSTOM|DMACON)
                    bsr      wait_raster
                    move.l   a1,(-10,a2)
                    move.w   d1,(-6,a2)
                    movem.l  (sp)+,d5/a2
                    rts

; ===========================================================================
wait_raster:
                    movem.l  d0/d1,-(sp)
                    moveq    #5-1,d1
.loop:
                    move.b   (_CUSTOM|VHPOSR),d0
.wait:
                    cmp.b    (_CUSTOM|VHPOSR),d0
                    beq.b    .wait
                    dbra     d1,.loop
                    movem.l  (sp)+,d0/d1
                    rts

; ===========================================================================
lbC01F06E:
                    movem.l  d2,-(sp)
                    lea      (zsxdcvgbhnjml_MSG),a0
                    moveq    #-1,d2
lbC01F07A:
                    addq.w   #1,d2
                    move.b   (a0)+,d1
                    beq.b    lbC01F08C
                    cmp.b    d1,d0
                    bne.b    lbC01F07A
                    move.w   d2,d0
                    movem.l  (sp)+,d2
                    rts
lbC01F08C:
                    moveq    #ERROR,d0
                    movem.l  (sp)+,d2
                    rts
lbC01F094:
                    movem.l  d2,-(sp)
                    cmp.b    #'a',d0
                    blt.b    lbC01F0A8
                    cmp.b    #'z',d0
                    bgt.b    lbC01F0A8
                    sub.b    #' ',d0
lbC01F0A8:
                    lea      (alpha_numeric_table),a0
                    moveq    #-1,d2
lbC01F0B0:
                    addq.w   #1,d2
                    move.b   (a0)+,d1
                    beq.b    lbC01F0BE
                    cmp.b    d0,d1
                    bne.b    lbC01F0B0
                    move.w   d2,d0
                    bra.b    lbC01F0C0
lbC01F0BE:
                    moveq    #ERROR,d0
lbC01F0C0:
                    movem.l  (sp)+,d2
                    rts
lbC01F0C6:
                    movem.l  d2,-(sp)
                    cmp.b    #'a',d0
                    blt.b    lbC01F0DA
                    cmp.b    #'z',d0
                    bgt.b    lbC01F0DA
                    sub.b    #' ',d0
lbC01F0DA:
                    lea      (ABCDEF_MSG),a0
                    moveq    #-1,d2
lbC01F0E2:
                    addq.w   #1,d2
                    move.b   (a0)+,d1
                    beq.b    lbC01F0F0
                    cmp.b    d0,d1
                    bne.b    lbC01F0E2
                    move.w   d2,d0
                    bra.b    lbC01F0F2
lbC01F0F0:
                    moveq    #ERROR,d0
lbC01F0F2:
                    movem.l  (sp)+,d2
                    rts
ABCDEF_MSG:
                    dc.b     '0123456789ABCDEF',0
                    even
lbC01F10A:
                    subq.w   #1,(caret_pos_x)
                    bpl      display_pattern_caret
                    move.w   (lbW01B294),(caret_pos_x)
                    bra      display_pattern_caret
lbC01F122:
                    subq.w   #5,(caret_pos_x)
                    bpl      display_pattern_caret
                    move.w   (caret_pos_x,pc),d0
                    add.w    (lbW01B294),d0
                    addq.w   #1,d0
                    move.w   d0,(caret_pos_x)
                    bra      display_pattern_caret
lbC01F142:
                    addq.w   #1,(caret_pos_x)
                    move.w   (lbW01B294),d0
                    cmp.w    (caret_pos_x,pc),d0
                    bge      display_pattern_caret
                    clr.w    (caret_pos_x)
                    bra      display_pattern_caret
lbC01F160:
                    addq.w   #5,(caret_pos_x)
                    move.w   (lbW01B294),d0
                    cmp.w    (caret_pos_x,pc),d0
                    bge      display_pattern_caret
                    move.w   (caret_pos_x,pc),d0
                    sub.w    (lbW01B294),d0
                    subq.w   #1,d0
                    move.w   d0,(caret_pos_x)
                    bra      display_pattern_caret

; ===========================================================================
previous_pattern_row:
                    subq.w   #1,(viewed_pattern_row)
                    bra.b    lbC01F1D8

; ===========================================================================
next_pattern_row:
                    addq.w   #1,(viewed_pattern_row)
                    bra.b    lbC01F1D8
lbC01F19A:
                    move.w   (f6_key_line_jump_value),(viewed_pattern_row)
                    bra.b    lbC01F1D4
lbC01F1A6:
                    move.w   (f7_key_line_jump_value),(viewed_pattern_row)
                    bra.b    lbC01F1D4
lbC01F1B2:
                    move.w   (f8_key_line_jump_value),(viewed_pattern_row)
                    bra.b    lbC01F1D4
lbC01F1BE:
                    move.w   (f9_key_line_jump_value),(viewed_pattern_row)
                    bra.b    lbC01F1D4
lbC01F1CA:
                    move.w   (f10_key_line_jump_value),(viewed_pattern_row)
lbC01F1D4:
                    bsr      lbC01F200
lbC01F1D8:
                    bsr      get_current_pattern_rows
                    move.w   d0,d1
                    move.w   (viewed_pattern_row,pc),d0
lbC01F1E2:
                    tst.w    d0
                    bpl.b    lbC01F1EA
                    add.w    d1,d0
                    bra.b    lbC01F1E2
lbC01F1EA:
                    cmp.w    d1,d0
                    blt.b    lbC01F1F2
                    sub.w    d1,d0
                    bra.b    lbC01F1EA
lbC01F1F2:
                    move.w   d0,(viewed_pattern_row)
                    bsr      set_pattern_bitplane
                    bra      display_pattern_caret
lbC01F200:
                    bsr      get_current_pattern_rows
                    move.w   d0,d1
                    move.w   (viewed_pattern_row,pc),d0
                    subq.w   #1,d1
                    cmp.w    d1,d0
                    ble.b    lbC01F218
                    move.w   d1,d0
                    move.w   d0,(viewed_pattern_row)
lbC01F218:
                    rts
lbC01F21A:
                    lea      (ascii_MSG6,pc),a1
                    move.b   d0,(a1)
                    lea      (GotoPattern_MSG,pc),a0
                    jsr      (lbC0248CC)
                    bmi.b    lbC01F24E
                    cmp.w    (lbW01BC6E),d0
                    bcs.b    lbC01F23C
                    move.w   (lbW01BC6E),d0
                    subq.w   #1,d0
lbC01F23C:
                    cmp.w    (current_viewed_pattern),d0
                    beq.b    lbC01F24E
                    move.w   d0,(current_viewed_pattern)
                    bra      lbC0202A8
lbC01F24E:
                    rts
GotoPattern_MSG:
                    dc.b     'Go to Pattern:',0
ascii_MSG6:
                    dc.b     0
                    dc.b     0
                    dc.b     0
lbC01F262:
                    tst.w    (current_viewed_pattern)
                    beq.b    lbC01F274
                    subq.w   #1,(current_viewed_pattern)
                    bra      lbC0202A8
lbC01F274:
                    rts
lbC01F276:
                    move.w   (current_viewed_pattern),d0
                    addq.w   #1,d0
                    cmp.w    (lbW01BC6E),d0
                    bne.b    lbC01F28E
                    bsr      lbC020112
                    beq.b    lbC01F28E
                    rts
lbC01F28E:
                    addq.w   #1,(current_viewed_pattern)
                    bra      lbC0202A8
lbC01F298:
                    bsr      stop_audio_channels
lbC01F29C:
                    move.l   #C1C1D1D1E1F1F_MSG0,(lbL01F2CC)
                    move.l   #lbB02526B,(lbL01F2D0)
                    rts
lbC01F2B2:
                    bsr      stop_audio_channels
lbC01F2B6:
                    move.l   #C2C2D2D2E2F2F_MSG,(lbL01F2CC)
                    move.l   #lbB02532E,(lbL01F2D0)
                    rts
lbL01F2CC:
                    dc.l     C1C1D1D1E1F1F_MSG0
lbL01F2D0:
                    dc.l     lbB02526B
lbC01F2D4:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F2FA
                    move.w   (lbW01B294),d0
                    cmp.w    (lbW01F504),d0
                    beq.b    lbC01F2FA
                    addq.w   #5,(lbW01F500)
                    addq.w   #5,(lbW01F504)
                    bra      lbC01F46E
lbC01F2FA:
                    rts
lbC01F2FC:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F31C
                    tst.w    (lbW01F500)
                    beq.b    lbC01F31C
                    subq.w   #5,(lbW01F500)
                    subq.w   #5,(lbW01F504)
                    bra      lbC01F46E
lbC01F31C:
                    rts
lbC01F31E:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F342
                    bsr      get_current_pattern_rows
                    subq.w   #1,d0
                    cmp.w    (lbW01F506,pc),d0
                    beq.b    lbC01F342
                    addq.w   #1,(lbW01F502)
                    addq.w   #1,(lbW01F506)
                    bra      lbC01F46E
lbC01F342:
                    rts
lbC01F344:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F364
                    tst.w    (lbW01F502)
                    beq.b    lbC01F364
                    subq.w   #1,(lbW01F502)
                    subq.w   #1,(lbW01F506)
                    bra      lbC01F46E
lbC01F364:
                    rts
lbC01F366:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F3B2
                    addq.w   #5,(lbW01F504)
                    bra      lbC01F46E
lbC01F378:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F38A
                    subq.w   #5,(lbW01F504)
                    bra      lbC01F46E
lbC01F38A:
                    rts
lbC01F38C:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F3B2
                    addq.w   #1,(lbW01F506)
                    bra      lbC01F46E
lbC01F39E:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F3B0
                    subq.w   #1,(lbW01F506)
                    bra      lbC01F46E
lbC01F3B0:
                    rts
lbC01F3B2:
                    moveq    #0,d0
                    move.w   (caret_pos_x,pc),d0
                    divu.w   #5,d0
                    mulu.w   #5,d0
                    move.w   (viewed_pattern_row,pc),d1
                    movem.w  d0/d1,(lbW01F500)
                    addq.w   #4,d0
                    movem.w  d0/d1,(lbW01F504)
                    bra      lbC01F472
lbC01F3DA:
                    bsr.b    lbC01F42C
                    moveq    #0,d0
                    move.w   (caret_pos_x,pc),d0
                    divu.w   #5,d0
                    mulu.w   #5,d0
                    moveq    #0,d1
                    movem.w  d0/d1,(lbW01F500)
                    addq.w   #4,d0
                    move.w   d0,-(sp)
                    bsr      get_current_pattern_rows
                    move.w   d0,d1
                    subq.w   #1,d1
                    move.w   (sp)+,d0
                    movem.w  d0/d1,(lbW01F504)
                    bra.b    lbC01F472
lbC01F40C:
                    bsr.b    lbC01F42C
                    clr.l    (lbW01F500)
                    move.w   (lbW01B294),(lbW01F504)
                    bsr      get_current_pattern_rows
                    subq.w   #1,d0
                    move.w   d0,(lbW01F506)
                    bra.b    lbC01F472
lbC01F42C:
                    bsr      lbC01F508
lbC01F430:
                    moveq    #-1,d0
                    move.l   d0,(lbW01F500)
                    move.l   d0,(lbW01F46A)
                    rts
lbC01F440:
                    moveq    #-1,d0
                    cmp.l    (lbW01F46A,pc),d0
                    beq      lbC01F472
                    move.w   (lbW01F46A,pc),(lbW01F502)
                    move.w   (lbW01F46C,pc),(lbW01F506)
                    move.l   (lbW01F46A,pc),-(sp)
                    bsr      lbC01F472
                    move.l   (sp)+,(lbW01F46A)
                    rts
lbW01F46A:
                    dc.w     -1
lbW01F46C:
                    dc.w     -1
lbC01F46E:
                    bsr      lbC01F508
lbC01F472:
                    moveq    #-1,d0
                    move.l   d0,(lbW01F46A)
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F4FE
                    bsr      get_current_pattern_rows
                    move.w   d0,d4
                    subq.w   #1,d4
                    movem.w  (lbW01F500,pc),d0/d1
                    movem.w  (lbW01F504,pc),d2/d3
                    cmp.w    (lbW01B294),d2
                    ble.b    lbC01F4A2
                    move.w   (lbW01B294),d2
lbC01F4A2:
                    cmp.w    d0,d2
                    bgt.b    lbC01F4AE
                    move.w   d0,d2
                    addq.w   #4,d2
                    cmp.w    d1,d3
                    beq.b    lbC01F430
lbC01F4AE:
                    cmp.w    d4,d1
                    ble.b    lbC01F4B4
                    move.w   d4,d1
lbC01F4B4:
                    cmp.w    d4,d3
                    ble.b    lbC01F4BA
                    move.w   d4,d3
lbC01F4BA:
                    cmp.w    d1,d3
                    bge.b    lbC01F4CA
                    move.w   d1,d3
                    move.w   d0,d4
                    addq.w   #4,d4
                    cmp.w    d4,d2
                    beq      lbC01F430
lbC01F4CA:
                    movem.w  d0/d1,(lbW01F500)
                    movem.w  d2/d3,(lbW01F504)
                    move.w   d1,(lbW01F46A)
                    move.w   d3,(lbW01F46C)
                    lea      (caret_current_positions),a0
                    move.b   (a0,d0.w),d0
                    move.b   (a0,d2.w),d2
                    movem.w  d0-d3,(lbB01B29E)
                    bra.b    lbC01F508
lbC01F4FE:
                    rts
lbW01F500:
                    dc.w     -1
lbW01F502:
                    dc.w     -1
lbW01F504:
                    dc.w     0
lbW01F506:
                    dc.w     0
lbC01F508:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq.b    lbC01F51A
                    lea      (lbB01B29E),a0
                    bra      lbC020C9A
lbC01F51A:
                    rts
lbC01F51C:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    bne.b    lbC01F52A
                    bra      error_what_block
lbC01F52A:
                    bsr.b    lbC01F54E
                    bra      error_block_copied
lbC01F532:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    bne.b    lbC01F540
                    bra      error_what_block
lbC01F540:
                    bsr.b    lbC01F54E
                    lea      (lbC01F54A,pc),a0
                    bra      lbC01F694
lbC01F54A:
                    clr.l    (a0)
                    rts
lbC01F54E:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq      error_what_block
                    bsr      get_current_pattern_rows
                    move.l   a0,a5
                    lea      (lbL01A146),a3
                    move.w   (lbW01F502,pc),d5
                    mulu.w   (lbW02A75A),d5
                    move.w   (lbW01F504,pc),d6
                    ext.l    d6
                    divu.w   #5,d6
                    add.w    d6,d6
                    add.w    d6,d6
                    move.w   (lbW01F506,pc),d7
                    mulu.w   (lbW02A75A),d7
                    move.w   (lbW01F500,pc),d3
                    ext.l    d3
                    divu.w   #5,d3
                    add.w    d3,d3
                    add.w    d3,d3
                    move.w   d6,d0
                    sub.w    d3,d0
                    move.w   d0,(lbW01F5C4)
                    move.w   d7,d0
                    sub.w    d5,d0
                    move.w   d0,(lbW01F5C6)
lbC01F5A8:
                    move.w   d3,d4
lbC01F5AA:
                    lea      (a5,d4.w),a0
                    adda.w   d5,a0
                    move.l   (a0),(a3)+
                    addq.w   #4,d4
                    cmp.w    d4,d6
                    bge.b    lbC01F5AA
                    add.w    (lbW02A75A),d5
                    cmp.w    d5,d7
                    bge.b    lbC01F5A8
                    rts
lbW01F5C4:
                    dc.w     -1
lbW01F5C6:
                    dc.w     -1
lbC01F5C8:
                    lea      (lbC01F5CE,pc),a0
                    bra.b    lbC01F5E4
lbC01F5CE:
                    move.l   (a3)+,(a0)
                    rts
lbC01F5D2:
                    lea      (lbC01F5D8,pc),a0
                    bra.b    lbC01F5E4
lbC01F5D8:
                    move.l   (a3)+,d0
                    tst.b    (-4,a3)
                    beq.b    lbC01F5E2
                    move.l   d0,(a0)
lbC01F5E2:
                    rts
lbC01F5E4:
                    moveq    #-1,d0
                    cmp.l    (lbW01F5C4,pc),d0
                    beq      error_what_block
                    move.l   a0,a4
                    bsr      get_current_pattern_rows
                    move.w   d0,d3
                    subq.w   #1,d3
                    mulu.w   (lbW02A75A),d3
                    move.l   a0,a5
                    lea      (lbL01A146),a3
                    tst.b    (lbB01FA0E)
                    beq.b    lbC01F622
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq      error_what_block
                    move.w   (lbW01F500,pc),d4
                    move.w   (lbW01F502,pc),d5
                    bra.b    lbC01F62A
lbC01F622:
                    move.w   (caret_pos_x,pc),d4
                    move.w   (viewed_pattern_row,pc),d5
lbC01F62A:
                    ext.l    d4
                    divu.w   #5,d4
                    add.w    d4,d4
                    add.w    d4,d4
                    mulu.w   (lbW02A75A),d5
                    move.w   d4,d6
                    add.w    (lbW01F5C4,pc),d6
                    moveq    #0,d2
                    move.w   (lbW01B294),d0
                    ext.l    d0
                    divu.w   #5,d0
                    add.w    d0,d0
                    add.w    d0,d0
                    cmp.w    d6,d0
                    bge.b    lbC01F65C
                    move.w   d6,d2
                    sub.w    d0,d2
                    move.w   d0,d6
lbC01F65C:
                    move.w   d5,d7
                    add.w    (lbW01F5C6,pc),d7
                    cmp.w    d7,d3
                    bge.b    lbC01F668
                    move.w   d3,d7
lbC01F668:
                    move.w   d2,d3
                    move.w   d4,(lbW01F692)
lbC01F670:
                    move.w   (lbW01F692,pc),d4
lbC01F674:
                    lea      (a5,d4.w),a0
                    adda.w   d5,a0
                    jsr      (a4)
                    addq.w   #4,d4
                    cmp.w    d4,d6
                    bge.b    lbC01F674
                    adda.w   d3,a3
                    add.w    (lbW02A75A),d5
                    cmp.w    d5,d7
                    bge.b    lbC01F670
                    bra      lbC0202A8
lbW01F692:
                    dc.w     0
lbC01F694:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq      error_what_block
                    move.l   a0,a3
                    bsr      get_current_pattern_rows
                    move.l   a0,a5
                    move.w   (lbW01F502,pc),d5
                    mulu.w   (lbW02A75A),d5
                    move.w   (lbW01F504,pc),d6
                    ext.l    d6
                    divu.w   #5,d6
                    add.w    d6,d6
                    add.w    d6,d6
                    move.w   (lbW01F506,pc),d7
                    mulu.w   (lbW02A75A),d7
lbC01F6C8:
                    move.w   (lbW01F500,pc),d4
                    ext.l    d4
                    divu.w   #5,d4
                    add.w    d4,d4
                    add.w    d4,d4
lbC01F6D6:
                    lea      (a5,d4.w),a0
                    adda.w   d5,a0
                    jsr      (a3)
                    addq.w   #4,d4
                    cmp.w    d4,d6
                    bge.b    lbC01F6D6
                    add.w    (lbW02A75A),d5
                    cmp.w    d5,d7
                    bge.b    lbC01F6C8
                    bra      lbC0202A8
lbC01F6F2:
                    lea      (lbC01F6FA,pc),a0
                    bra      lbC01F702
lbC01F6FA:
                    move.l   (a0),d0
                    move.l   (a1),(a0)
                    move.l   d0,(a1)
                    rts
lbC01F702:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq      error_what_block
                    move.l   a0,a3
                    bsr      get_current_pattern_rows
                    move.l   a0,a5
                    move.w   (lbW01F504,pc),d6
                    ext.l    d6
                    divu.w   #5,d6
                    add.w    d6,d6
                    add.w    d6,d6
                    move.w   (lbW01F502,pc),d5
                    mulu.w   (lbW02A75A),d5
                    move.w   (lbW01F506,pc),d7
                    sub.w    (lbW01F502,pc),d7
                    addq.w   #1,d7
                    asr.w    #1,d7
                    subq.w   #1,d7
                    bmi.b    lbC01F786
                    mulu.w   (lbW02A75A),d7
                    add.w    d5,d7
                    move.l   a5,a4
                    move.w   (lbW01F506,pc),d0
                    mulu.w   (lbW02A75A),d0
                    adda.w   d0,a4
lbC01F752:
                    move.w   (lbW01F500,pc),d4
                    ext.l    d4
                    divu.w   #5,d4
                    add.w    d4,d4
                    add.w    d4,d4
lbC01F760:
                    lea      (a5,d4.w),a0
                    adda.w   d5,a0
                    lea      (a4,d4.w),a1
                    jsr      (a3)
                    addq.w   #4,d4
                    cmp.w    d4,d6
                    bge.b    lbC01F760
                    suba.w   (lbW02A75A),a4
                    add.w    (lbW02A75A),d5
                    cmp.w    d5,d7
                    bge.b    lbC01F752
                    bra      lbC0202A8
lbC01F786:
                    rts
lbC01F788:
                    lea      (lbC01F798,pc),a0
                    bra      lbC01F694
lbC01F790:
                    lea      (lbC01F7A2,pc),a0
                    bra      lbC01F694
lbC01F798:
                    move.b   (1,a0),d0
                    cmp.b    (lbB021E53,pc),d0
                    bne.b    lbC01F7B0
lbC01F7A2:
                    move.b   (a0),d0
                    beq.b    lbC01F7B0
                    cmpi.b   #$24,d0
                    beq.b    lbC01F7B0
                    addq.b   #1,d0
                    move.b   d0,(a0)
lbC01F7B0:
                    rts
lbC01F7B2:
                    lea      (lbC01F7C2,pc),a0
                    bra      lbC01F694
lbC01F7BA:
                    lea      (lbC01F7CC,pc),a0
                    bra      lbC01F694
lbC01F7C2:
                    move.b   (1,a0),d0
                    cmp.b    (lbB021E53,pc),d0
                    bne.b    lbC01F7D4
lbC01F7CC:
                    move.b   (a0),d0
                    subq.b   #1,d0
                    ble.b    lbC01F7D4
                    move.b   d0,(a0)
lbC01F7D4:
                    rts
lbC01F7D6:
                    lea      (lbC01F7E6,pc),a0
                    bra      lbC01F694
lbC01F7DE:
                    lea      (lbC01F7F0,pc),a0
                    bra      lbC01F694
lbC01F7E6:
                    move.b   (1,a0),d0
                    cmp.b    (lbB021E53,pc),d0
                    bne.b    lbC01F800
lbC01F7F0:
                    move.b   (a0),d0
                    beq.b    lbC01F800
                    cmpi.b   #$18,d0
                    bgt.b    lbC01F800
                    addi.b   #$C,d0
                    move.b   d0,(a0)
lbC01F800:
                    rts
lbC01F802:
                    lea      (lbC01F812,pc),a0
                    bra      lbC01F694
lbC01F80A:
                    lea      (lbC01F81C,pc),a0
                    bra      lbC01F694
lbC01F812:
                    move.b   (1,a0),d0
                    cmp.b    (lbB021E53,pc),d0
                    bne.b    lbC01F82A
lbC01F81C:
                    move.b   (a0),d0
                    cmpi.b   #$C,d0
                    ble.b    lbC01F82A
                    subi.b   #$C,d0
                    move.b   d0,(a0)
lbC01F82A:
                    rts
lbC01F82C:
                    lea      (lbC01F834,pc),a0
                    bra      lbC01F694
lbC01F834:
                    tst.b    (a0)
                    beq.b    lbC01F844
                    move.b   (1,a0),d0
                    cmp.b    (lbB021E53,pc),d0
                    bne.b    lbC01F844
                    clr.l    (a0)
lbC01F844:
                    rts
lbC01F846:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq      error_what_block
                    lea      (DeleteSample_MSG,pc),a0
                    bsr      lbC024876
                    bmi.b    lbC01F868
                    move.b   d0,(lbB01F87C)
                    lea      (lbC01F86A,pc),a0
                    bra      lbC01F694
lbC01F868:
                    rts
lbC01F86A:
                    tst.b    (a0)
                    beq.b    lbC01F87A
                    move.b   (lbB01F87C,pc),d0
                    cmp.b    (1,a0),d0
                    bne.b    lbC01F87A
                    clr.l    (a0)
lbC01F87A:
                    rts
lbB01F87C:
                    dc.b     0
DeleteSample_MSG:
                    dc.b     'Delete Sample..:',0
lbC01F88E:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    beq      error_what_block
                    lea      (OldInstrument_MSG,pc),a0
                    lea      (NewInstrument_MSG,pc),a1
                    bsr      lbC0247B8
                    bmi.b    lbC01F8AE
                    lea      (lbC01F8B0,pc),a0
                    bra      lbC01F694
lbC01F8AE:
                    rts
lbC01F8B0:
                    tst.b    (a0)+
                    beq.b    lbC01F8C4
                    move.b   (lbW01B7DA),d0
                    cmp.b    (a0),d0
                    bne.b    lbC01F8C4
                    move.b   (lbW01B7DC),(a0)
lbC01F8C4:
                    rts
OldInstrument_MSG:
                    dc.b     ' Old Instrument:',0
NewInstrument_MSG:
                    dc.b     ' New Instrument:',0
lbC01F8E8:
                    moveq    #-1,d0
                    cmp.l    (lbW01F500,pc),d0
                    bne.b    lbC01F8F6
                    jmp      (error_what_block)
lbC01F8F6:
                    lea      (OldEffect_MSG,pc),a0
                    lea      (NewEffect_MSG,pc),a1
                    bsr      lbC0247B8
                    bmi.b    lbC01F90C
                    lea      (lbC01F90E,pc),a0
                    bra      lbC01F694
lbC01F90C:
                    rts
lbC01F90E:
                    move.b   (2,a0),d0
                    cmp.b    (lbW01B7DA),d0
                    bne.b    lbC01F922
                    move.b   (lbW01B7DC),(2,a0)
lbC01F922:
                    rts
OldEffect_MSG:
                    dc.b     ' Old Effect....:',0
NewEffect_MSG:
                    dc.b     ' New Effect....:',0
lbC01F946:
                    lea      (On_MSG1,pc),a0
                    tst.b    (lbB01B2A6)
                    bne      lbC01F958
                    lea      (Off_MSG2,pc),a0
lbC01F958:
                    jmp      (draw_text_with_coords_struct)
On_MSG1:
                    dc.b     22,3,' On',0
Off_MSG2:
                    dc.b     22,3,'Off',0
lbC01F96C:
                    not.b    (lbB01B2A6)
                    bra.b    lbC01F946
lbC01F974:
                    move.b   (midi_mode),d0
                    lea      (lbB01F9AA,pc),a0
                    cmp.b    #MIDI_IN,d0
                    beq.b    lbC01F99C
                    lea      (lbB01F9B0,pc),a0
                    cmp.b    #MIDI_OUT,d0
                    beq.b    lbC01F99C
                    lea      (lbB01F9A4,pc),a0
                    cmp.b    #MIDI_OFF,d0
                    beq.b    lbC01F99C
                    lea      (lbB01F9B6,pc),a0
lbC01F99C:
                    jmp      (draw_text_with_coords_struct)
lbB01F9A4:
                    dc.b     36,1,'Off',0
lbB01F9AA:
                    dc.b     36,1,'In ',0
lbB01F9B0:
                    dc.b     36,1,'Out',0
lbB01F9B6:
                    dc.b     36,1,'---',0
lbC01F9BC:
                    bsr      stop_audio_channels
lbC01F9C0:
                    move.b   (midi_mode),d0
                    moveq    #MIDI_IN,d1
                    cmp.b    #MIDI_OFF,d0
                    beq.b    .cycle_mode
                    moveq    #MIDI_OUT,d1
                    cmp.b    #MIDI_IN,d0
                    beq.b    .cycle_mode
                    moveq    #MIDI_OFF,d1
.cycle_mode:
                    move.b   d1,(midi_mode)
                    bra.b    lbC01F974
lbC01F9E0:
                    lea      (Blck_MSG,pc),a0
                    tst.b    (lbB01FA0E)
                    bne.b    lbC01F9F0
                    lea      (Curs_MSG,pc),a0
lbC01F9F0:
                    moveq    #35,d0
                    moveq    #2,d1
                    jmp      (draw_text)
Blck_MSG:
                    dc.b     'Blck',0
Curs_MSG:
                    dc.b     'Curs',0
lbC01FA06:
                    not.b    (lbB01FA0E)
                    bra.b    lbC01F9E0
lbB01FA0E:
                    dc.b     0
                    even
lbC01FA10:
                    tst.w    (lbW01B296)
                    bne.b    lbC01FA24
                    lea      (Off_MSG1,pc),a0
                    jmp      (draw_text_with_coords_struct)
lbC01FA24:
                    lea      (ascii_MSG56,pc),a0
                    jsr      (draw_text_with_coords_struct)
                    moveq    #24,d0
                    moveq    #4,d1
                    move.w   (lbW01B296),d2
                    addq.w   #1,d2
                    bra      draw_one_char_alpha_numeric
ascii_MSG56:
                    dc.b     22,4,'  ',0
Off_MSG1:
                    dc.b     22,4,'Off',0
                    even
lbC01FA4A:
                    moveq    #1,d0
                    bra.b    lbC01FA50
lbC01FA4E:
                    moveq    #-1,d0
lbC01FA50:
                    move.w   (lbW01B296),d1
                    add.w    d0,d1
                    bpl.b    lbC01FA5C
                    moveq    #0,d1
lbC01FA5C:
                    cmpi.w   #7,d1
                    ble.b    lbC01FA64
                    moveq    #7,d1
lbC01FA64:
                    move.w   d1,(lbW01B296)
                    bra.b    lbC01FA10
lbC01FA6C:
                    clr.w    (lbW01B298)
                    move.b   (polyphony),d0
                    ext.w    d0
                    mulu.w   #5,d0
                    cmp.w    (lbW01B294),d0
                    ble.b    lbC01FA8E
                    move.w   (lbW01B294),d0
                    subq.w   #4,d0
lbC01FA8E:
                    move.w   d0,(caret_pos_x)
                    bra      display_pattern_caret
lbC01FA98:
                    move.w   (lbW01B296),d1
                    beq.b    lbC01FAFC
                    addq.w   #1,d1
                    move.w   (caret_pos_x,pc),d0
                    divu.w   #5,d0
                    lea      (polyphony),a0
                    adda.w   (lbW01B298),a0
                    cmp.b    (a0),d0
                    bne.b    lbC01FAFC
                    addq.w   #1,(lbW01B298)
                    cmp.w    (lbW01B298),d1
                    bgt.b    lbC01FACE
                    clr.w    (lbW01B298)
lbC01FACE:
                    lea      (polyphony),a0
                    adda.w   (lbW01B298),a0
                    moveq    #0,d0
                    move.b   (a0),d0
                    mulu.w   #5,d0
                    cmp.w    (lbW01B294),d0
                    ble.b    lbC01FAF2
                    move.w   (lbW01B294),d0
                    subq.w   #4,d0
lbC01FAF2:
                    move.w   d0,(caret_pos_x)
                    bra      display_pattern_caret
lbC01FAFC:
                    rts
lbC01FAFE:
                    clr.w    (lbW01B298)
                    move.b   (polyphony),d0
                    ext.w    d0
                    move.w   (lbW02A75A),d1
                    lsr.w    #2,d1
                    cmp.w    d1,d0
                    blt.b    lbC01FB1C
                    move.w   d1,d0
                    subq.w   #1,d0
lbC01FB1C:
                    move.w   d0,(lbW01B2BA)
                    rts
lbC01FB24:
                    move.w   (lbW01B296),d1
                    beq.b    lbC01FB7E
                    addq.w   #1,d1
                    move.w   (lbW01B2BA),d0
                    lea      (polyphony),a0
                    adda.w   (lbW01B298),a0
                    cmp.b    (a0),d0
                    bne.b    lbC01FB7E
                    addq.w   #1,(lbW01B298)
                    cmp.w    (lbW01B298),d1
                    bgt.b    lbC01FB58
                    clr.w    (lbW01B298)
lbC01FB58:
                    lea      (polyphony),a0
                    adda.w   (lbW01B298),a0
                    moveq    #0,d0
                    move.b   (a0),d0
                    move.w   (lbW02A75A),d1
                    lsr.w    #2,d1
                    cmp.w    d1,d0
                    blt.b    lbC01FB78
                    subq.w   #1,d1
                    move.w   d1,d0
lbC01FB78:
                    move.w   d0,(lbW01B2BA)
lbC01FB7E:
                    rts
lbC01FB80:
                    tst.w    (lbW01FBF0)
                    bne.b    lbC01FB94
                    lea      (Off_MSG3,pc),a0
                    jmp      (draw_text_with_coords_struct)
lbC01FB94:
                    lea      (ascii_MSG57,pc),a0
                    jsr      (draw_text_with_coords_struct)
                    moveq    #$17,d0
                    moveq    #5,d1
                    move.w   (lbW01FBF0,pc),d2
                    jmp      (lbC025E20)
ascii_MSG57:
                    dc.b     22,5,' ',0
Off_MSG3:
                    dc.b     22,5,'Off',0
lbC01FBB8:
                    moveq    #-1,d0
                    bra.b    lbC01FBBE
lbC01FBBC:
                    moveq    #1,d0
lbC01FBBE:
                    move.w   (lbW01FBF0),d1
                    add.w    d0,d1
                    bpl.b    lbC01FBCA
                    moveq    #0,d1
lbC01FBCA:
                    cmpi.w   #$20,d1
                    ble.b    lbC01FBD2
                    moveq    #$20,d1
lbC01FBD2:
                    move.w   d1,(lbW01FBF0)
                    bra.b    lbC01FB80
lbC01FBDA:
                    move.w   d0,(lbW01FBF0)
                    bra.b    lbC01FB80
lbC01FBE2:
                    move.w   (lbW01FBF0,pc),d0
                    add.w    d0,(viewed_pattern_row)
                    bra      lbC01F1D8
lbW01FBF0:
                    dc.w     1
lbC01FBF2:
                    move.w   (current_song_position),d2
                    moveq    #12,d0
                    moveq    #1,d1
                    jsr      (lbC025E0C)
                    lea      (OK_Patterns),a0
                    move.w   (current_song_position),d2
                    move.b   (a0,d2.w),d2
                    moveq    #13,d0
                    moveq    #2,d1
                    jsr      (lbC025E20)
                    move.w   (OK_PLen),d2
                    moveq    #12,d0
                    moveq    #3,d1
                    jsr      (lbC025E0C)
                    move.w   (OK_Speed),d0
                    bsr      lbC01FCD6
                    move.w   (lbW01BC6E),d2
                    moveq    #13,d0
                    moveq    #6,d1
                    jsr      (lbC025E20)
                    bsr      get_current_pattern_rows
                    move.w   d0,d2
                    moveq    #23,d0
                    moveq    #6,d1
                    jsr      (draw_2_digits_hex_number)
                    bsr      lbC01F946
                    bsr      lbC01FA10
                    bsr      lbC01FB80
                    bsr      lbC01F974
                    bsr      lbC01F9E0
                    bsr.b    lbC01FCE0
                    bsr      draw_replay_type
                    bsr      lbC01FEE2
draw_channels_muted_status:
                    ; x pos
                    moveq    #72,d5
                    move.b   (channels_mute_flags),d6
                    lea      (OK_ChannelsModes),a4
                    moveq    #8-1,d7
.loop:
                    tst.w    (a4)+
                    beq.b    .single
                    ; doubled channel
                    bsr.b    draw_channel_muted_status
                    subq.w   #1,d7
                    bsr.b    draw_channel_muted_status
                    bra.b    .done
.single:
                    ; single channel
                    bsr.b    draw_channel_muted_status
                    bsr.b    draw_channel_inactive_status
                    subq.w   #1,d7
.done:
                    dbra     d7,.loop
                    lea      (channels_number_text),a0
                    moveq    #72,d0
                    moveq    #6,d1
                    jmp      (draw_text)

; ===========================================================================
draw_channel_muted_status:
                    moveq    #'*',d2
                    btst     d7,d6
                    bne.b    .muted
                    moveq    #'-',d2
.muted:
                    move.w   d5,d0
                    addq.w   #1,d5
                    moveq    #5,d1
                    jmp      (draw_one_char)

; ===========================================================================
draw_channel_inactive_status:
                    moveq    #' ',d2
                    move.w   d5,d0
                    addq.w   #1,d5
                    moveq    #5,d1
                    jmp      (draw_one_char)

; ===========================================================================
lbC01FCD6:
                    move.w   d0,d2
                    moveq    #14,d0
                    moveq    #5,d1
                    bra      draw_one_char_alpha_numeric
lbC01FCE0:
                    lea      (ascii_MSG58,pc),a0
                    jsr      (draw_text_with_coords_struct)
                    move.w   (current_sample,pc),d2
                    moveq    #56,d0
                    moveq    #0,d1
                    bsr      draw_one_char_alpha_numeric
                    lea      (OK_Samples),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    move.l   a0,-(sp)
                    moveq    #46,d0
                    moveq    #1,d1
                    jsr      (draw_text)
                    move.l   (sp),a0
                    move.l   ($14,a0),d2
                    moveq    #$2E,d0
                    moveq    #2,d1
                    jsr      (lbC025DF0)
                    move.l   (sp),a0
                    tst.w    ($1E,a0)
                    beq.b    lbC01FD80
                    lea      (ascii_MSG7,pc),a0
                    moveq    #40,d0
                    moveq    #3,d1
                    jsr      (process_command)
                    jsr      (lbC028EB2)
                    move.l   (sp),a0
                    moveq    #0,d2
                    move.w   ($18,a0),d2
                    add.l    d2,d2
                    moveq    #$2E,d0
                    moveq    #3,d1
                    jsr      (lbC025DF0)
                    move.l   (sp),a0
                    moveq    #0,d2
                    move.w   ($1A,a0),d2
                    add.l    d2,d2
                    moveq    #$2E,d0
                    moveq    #4,d1
                    jsr      (lbC025DF0)
                    move.l   (sp),a0
                    move.w   ($1C,a0),d2
                    moveq    #$2E,d0
                    moveq    #5,d1
                    jsr      (lbC025E20)
                    lea      (lbB0177D4),a0
                    bsr      lbC020C8A
                    bra.b    lbC01FD98
lbC01FD80:
                    lea      (ascii_MSG59,pc),a0
                    moveq    #40,d0
                    moveq    #3,d1
                    jsr      (process_command)
                    lea      (lbB0177D4),a0
                    bsr      lbC020C92
lbC01FD98:
                    move.l   (sp)+,a0
                    move.w   (30,a0),d0
                    lea      (lbB01FE14,pc),a0
                    move.b   (a0,d0.w),d2
                    moveq    #46,d0
                    moveq    #6,d1
                    jmp      (draw_one_char)
ascii_MSG58:
                    dc.b     46,1,'--------------------',0
ascii_MSG7:
                    dc.b     CMD_TEXT,0,0,'RStr:',0
                    dc.b     CMD_TEXT,0,1,'RLen:',0
                    dc.b     CMD_TEXT,0,2,'Vol.:',0
                    dc.b     CMD_END
ascii_MSG59:
                    dc.b     CMD_TEXT,0,0,'            ',0
                    dc.b     CMD_TEXT,0,1,'            ',0
                    dc.b     CMD_TEXT,0,2,'        ',0
                    dc.b     CMD_END
                    even
lbB01FE14:
                    dc.b     '84B'
                    even

; ===========================================================================
draw_replay_type:
                    moveq    #68,d0
                    moveq    #5,d1
                    move.w   (replay_type,pc),d2
                    addq.w   #1,d2
                    bra      draw_one_char_alpha_numeric

; ===========================================================================
lbC01FE26:
                    lea      (lbL01FE56,pc),a0
                    move.l   (a0),d0
                    eori.l   #$20000,d0
                    move.l   d0,(a0)
                    beq.b    lbC01FE3C
                    lea      (CCMax_MSG,pc),a0
                    bra.b    lbC01FE40
lbC01FE3C:
                    lea      (CChip_MSG,pc),a0
lbC01FE40:
                    move.l   a0,(lbL01FE5A)
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    bra      lbC01FEE2
lbL01FE56:
                    dc.l     0
lbL01FE5A:
                    dc.l     CChip_MSG
CChip_MSG:
                    dc.b     CMD_TEXT,67,1,'Chip:',0
                    dc.b     CMD_TEXT,67,2,'Fast:',0
                    dc.b     CMD_END
CCMax_MSG:
                    dc.b     CMD_TEXT,67,1,'CMax:',0
                    dc.b     CMD_TEXT,67,2,'FMax:',0
                    dc.b     CMD_END
                    even
lbC01FE86:
                    lea      (lbW01FEBE,pc),a0
                    addq.w   #1,(a0)
                    cmpi.w   #3,(a0)
                    bcs.b    lbC01FE94
                    clr.w    (a0)
lbC01FE94:
                    move.w   (a0),d0
                    lsl.w    #2,d0
                    move.l   (lbL01FEB2,pc,d0.w),a0
                    move.l   a0,(lbL01FEC0)
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    bra      lbC01FEE2
lbL01FEB2:
                    dc.l     CSong_MSG
                    dc.l     CPtts_MSG
                    dc.l     CSmps_MSG
lbW01FEBE:
                    dc.w     0
lbL01FEC0:
                    dc.l     CSong_MSG
CSong_MSG:
                    dc.b     CMD_TEXT,67,3,'Song:',0
                    dc.b     CMD_END
CPtts_MSG:
                    dc.b     CMD_TEXT,67,3,'Ptts:',0
                    dc.b     CMD_END
CSmps_MSG:
                    dc.b     CMD_TEXT,67,3,'Smps:',0
                    dc.b     CMD_END
lbC01FEE2:
                    moveq    #2,d1
                    or.l     (lbL01FE56,pc),d1
                    EXEC     AvailMem
                    move.l   d0,d2
                    moveq    #73,d0
                    moveq    #1,d1
                    jsr      (lbC025DD6)
                    moveq    #4,d1
                    or.l     (lbL01FE56,pc),d1
                    EXEC     AvailMem
                    move.l   d0,d2
                    moveq    #73,d0
                    moveq    #2,d1
                    jsr      (lbC025DD6)
                    move.w   (lbW01FEBE,pc),d0
                    bne.b    lbC01FF32
                    bsr      lbC01FF50
                    move.l   d0,d2
                    bsr      lbC01FF74
                    add.l    d2,d0
                    bra.b    lbC01FF42
lbC01FF32:
                    cmpi.w   #1,d0
                    bne.b    lbC01FF3E
                    bsr      lbC01FF50
                    bra.b    lbC01FF42
lbC01FF3E:
                    bsr      lbC01FF74
lbC01FF42:
                    move.l   d0,d2
                    moveq    #$49,d0
                    moveq    #3,d1
                    jmp      (lbC025DD6)
lbC01FF50:
                    move.l   d2,-(sp)
                    lea      (OK_PatternList),a0
                    moveq    #0,d0
                    moveq    #64-1,d1
lbC01FF5C:
                    move.l   (a0)+,d2
                    beq.b    lbC01FF6C
                    move.l   d2,a1
                    move.w   (a1),d2
                    mulu.w   (lbW02A75A),d2
                    add.l    d2,d0
lbC01FF6C:
                    dbra     d1,lbC01FF5C
                    move.l   (sp)+,d2
                    rts
lbC01FF74:
                    lea      (OK_SampleTab),a0
                    moveq    #0,d0
                    moveq    #36-1,d1
lbC01FF7E:
                    tst.l    (a0)+
                    beq.b    lbC01FF84
                    add.l    (a0),d0
lbC01FF84:
                    addq.w   #4,a0
                    dbra     d1,lbC01FF7E
                    rts
lbC01FF8C:
                    bsr      stop_audio_channels
                    move.l   (lbL01A130),d0
                    beq.b    lbC01FFB2
                    move.l   d0,a1
                    move.l   (lbL01A134),d0
                    EXEC     FreeMem
                    clr.l    (lbL01A130)
lbC01FFB2:
                    clr.l    (lbL01A134)
                    clr.l    (lbL029ECE)
                    rts
lbC01FFC0:
                    cmp.l    (lbL01A134),d0
                    beq.b    lbC020018
                    move.l   d0,(lbL01B29A)
                    bsr.b    lbC01FF8C
                    move.l   (lbL01B29A),d0
                    cmpi.l   #131070,d0
                    bgt      error_sample_too_long
                    cmpi.l   #2,d0
                    blt      error_sample_too_short
                    move.l   #$10002,d1
                    EXEC     AllocMem
                    move.l   d0,(lbL01A130)
                    beq      error_no_memory
                    move.l   (lbL01B29A),d0
                    move.l   d0,(lbL01A134)
                    move.l   d0,(lbL029ECE)
lbC020018:
                    moveq    #0,d0
                    rts
lbC02001C:
                    movem.l  d2/a2,-(sp)
                    bsr      lbC01FF8C
                    bsr      lbC02161C
                    move.l   (a0)+,a2
                    move.l   a2,d0
                    beq.b    lbC020072
                    move.l   (a0),d2
                    beq.b    lbC020072
                    move.l   d2,d0
                    moveq    #2,d1
                    EXEC     AllocMem
                    move.l   d0,(lbL01A130)
                    bne.b    lbC020050
                    bsr      error_no_memory
                    bra.b    lbC020074
lbC020050:
                    move.l   d2,(lbL01A134)
                    move.l   d2,(lbL029ECE)
                    move.l   a2,a0
                    move.l   (lbL01A130),a1
                    move.l   d2,d0
                    EXEC     CopyMem
lbC020072:
                    moveq    #0,d0
lbC020074:
                    movem.l  (sp)+,d2/a2
                    rts

; ===========================================================================
set_pattern_bitplane:
                    move.w   (viewed_pattern_row,pc),d0
set_pattern_bitplane_from_given_pos:
                    move.w   (pattern_bitplane_top_pos),d1
                    add.w    (row_pixels_size,pc),d1
                    cmp.w    d1,d0
                    bge.b    .bottom_pos
                    sub.w    d1,d0
                    add.w    d0,(pattern_bitplane_top_pos)
                    bra.b    .top_pos
.bottom_pos:
                    move.w   (pattern_bitplane_top_pos),d1
                    add.w    (number_of_rows_on_screen,pc),d1
                    sub.w    (row_pixels_size,pc),d1
                    subq.w   #1,d1
                    cmp.w    d1,d0
                    blt.b    .top_pos
                    sub.w    d0,d1
                    sub.w    d1,(pattern_bitplane_top_pos)
.top_pos:
                    move.w   (pattern_bitplane_top_pos),d1
                    bsr      get_current_pattern_rows
                    sub.w    (number_of_rows_on_screen,pc),d0
                    cmp.w    d1,d0
                    bge.b    .max
                    move.w   d0,d1
.max:
                    tst.w    d1
                    bpl.b    .min
                    moveq    #0,d1
.min:
                    move.w   d1,(pattern_bitplane_top_pos)
                    mulu.w   #(SCREEN_BYTES*8),d1
                    addi.l   #main_screen+(56*80),d1
                    lea      (main_bp),a1
                    move.l   d1,(pattern_bitplane_offset)
                    move.w   d1,(6,a1)
                    swap     d1
                    move.w   d1,(2,a1)
                    rts
row_pixels_size:
                    dc.w     8
number_of_rows_on_screen:
                    dc.w     24

; ===========================================================================
get_current_pattern_rows:
                    move.w   (current_viewed_pattern),d0
get_given_pattern_rows:
                    lea      (OK_PatternList),a0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.l   (a0,d0.w),a0
                    move.w   (a0)+,d0
                    rts

; ===========================================================================
lbC020112:
                    cmpi.w   #64,(lbW01BC6E)
                    beq      error_no_more_patterns
                    move.l   (lbL02A75C),d0
                    addq.l   #2,d0
                    move.l   #$10000,d1
                    EXEC     AllocMem
                    tst.l    d0
                    beq      lbC020168
                    move.l   d0,a1
                    move.w   (default_pattern_length),(a1)
                    lea      (OK_PatternList),a0
                    move.w   (lbW01BC6E),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.l   a1,(a0,d0.w)
                    addq.w   #1,(lbW01BC6E)
                    bsr      lbC01FBF2
                    moveq    #0,d0
                    rts
lbC020168:
                    bra      error_no_memory
lbC02016E:
                    movem.l  d2/a2,-(sp)
                    move.w   d0,d2
                    mulu.w   (lbW02A75A),d0
                    addq.l   #2,d0
                    move.l   #$10000,d1
                    EXEC     AllocMem
                    tst.l    d0
                    beq.b    lbC0201B6
                    move.l   d0,a2
                    bsr.b    lbC0201C0
                    bsr      lbC020232
                    move.l   a2,a1
                    move.w   d2,(a1)
                    lea      (OK_PatternList),a0
                    move.w   (current_viewed_pattern),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.l   a2,(a0,d0.w)
                    moveq    #0,d0
                    bra.b    lbC0201BA
lbC0201B6:
                    bsr      error_no_memory
lbC0201BA:
                    movem.l  (sp)+,d2/a2
                    rts
lbC0201C0:
                    bsr      get_current_pattern_rows
                    cmp.w    d2,d0
                    ble.b    lbC0201CA
                    move.w   d2,d0
lbC0201CA:
                    mulu.w   (lbW02A75A),d0
                    move.l   a2,a1
                    lea      (2,a1),a1
                    EXEC     CopyMem
                    rts
lbC0201E4:
                    bsr      lbC020266
                    bne.b    lbC0201E4
                    lea      (OK_Patterns),a0
                    moveq    #128-1,d0
lbC0201F2:
                    sf       (a0)+
                    dbra     d0,lbC0201F2
                    move.w   #6,(OK_Speed)
                    move.w   #1,(OK_PLen)
                    st       (channels_mute_flags)
                    clr.w    (current_song_position)
                    clr.w    (current_viewed_pattern)
                    clr.w    (caret_pos_x)
                    clr.w    (viewed_pattern_row)
                    moveq    #-1,d0
                    move.l   d0,(lbW01F5C4)
                    bra      lbC01F430
lbC020232:
                    move.w   (current_viewed_pattern),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    lea      (OK_PatternList),a0
                    move.l   (a0,d0.w),d1
                    beq.b    lbC020264
                    clr.l    (a0,d0.w)
                    move.l   d1,a1
                    move.w   (a1),d0
                    mulu.w   (lbW02A75A),d0
                    addq.l   #2,d0
                    EXEC     FreeMem
lbC020264:
                    rts
lbC020266:
                    tst.w    (lbW01BC6E)
                    beq.b    lbC0202A6
                    move.w   (lbW01BC6E),d0
                    subq.w   #1,d0
                    add.w    d0,d0
                    add.w    d0,d0
                    lea      (OK_PatternList),a0
                    move.l   (a0,d0.w),a1
                    clr.l    (a0,d0.w)
                    moveq    #0,d0
                    move.w   (a1),d0
                    mulu.w   (lbW02A75A),d0
                    addq.l   #2,d0
                    EXEC     FreeMem
                    subq.w   #1,(lbW01BC6E)
lbC0202A6:
                    rts
lbC0202A8:
                    move.w   #$200,(main_bplcon0+2)
                    bsr      set_pattern_bitplane
                    bsr      get_current_pattern_rows
                    move.w   d0,(lbW01B788)
                    bsr      erase_pattern_caret
                    jsr      (clear_1_line_blitter)
                    moveq    #0,d7
                    bsr.b    lbC0202F0
lbC0202CC:
                    bsr.b    lbC02031E
                    addq.w   #1,d7
                    cmp.w    (lbW01B788),d7
                    bne.b    lbC0202CC
                    bsr      lbC01F200
                    bsr      lbC01F1D8
                    bsr      lbC01F440
                    move.w   #$9200,(main_bplcon0+2)
                    bra      lbC01FBF2
lbC0202F0:
                    bsr      get_current_pattern_rows
                    move.l   a0,a4
                    move.w   d7,d0
                    mulu.w   (lbW02A75A),d0
                    adda.l   d0,a4
                    move.w   (current_viewed_pattern),d0
                    ext.l    d0
                    divu.w   #10,d0
                    addi.b   #'0',d0
                    move.b   d0,d4
                    lsl.w    #8,d4
                    swap     d0
                    addi.b   #'0',d0
                    move.b   d0,d4
                    rts
lbC02031E:
                    lea      (alpha_numeric_table),a2
                    lea      (C1C1D1D1E1F1F_MSG),a3
                    lea      (lbW01B736),a5
                    move.w   d4,(a5)+
                    lea      (OK_ChannelsModes),a0
                    moveq    #2-1,d5
lbC02033A:
                    move.b   #' ',(a5)+
                    move.w   d7,d0
                    lsr.w    #4,d0
                    move.b   (a2,d0.w),(a5)+
                    moveq    #$F,d0
                    and.w    d7,d0
                    move.b   (a2,d0.w),(a5)+
                    moveq    #2-1,d6
lbC020350:
                    tst.w    (a0)+
                    beq.b    lbC02035A
                    bsr.b    lbC02038E
                    bsr.b    lbC02038E
                    bra.b    lbC020370
lbC02035A:
                    bsr.b    lbC02038E
                    moveq    #' ',d0
                    move.b   d0,(a5)+
                    move.b   d0,(a5)+
                    move.b   d0,(a5)+
                    move.b   d0,(a5)+
                    move.b   d0,(a5)+
                    move.b   d0,(a5)+
                    move.b   d0,(a5)+
                    move.b   d0,(a5)+
                    move.b   d0,(a5)+
lbC020370:
                    dbra     d6,lbC020350
                    dbra     d5,lbC02033A
                    sf       (a5)
                    lea      (lbW01B736),a0
                    moveq    #0,d0
                    move.w   d7,d1
                    addq.w   #7,d1
                    jmp      (draw_text)
lbC02038E:
                    move.b   #' ',(a5)+
                    moveq    #0,d0
                    move.b   (a4)+,d0
                    add.w    d0,d0
                    add.w    d0,d0
                    lea      (a3,d0.w),a1
                    move.b   (a1)+,(a5)+
                    move.b   (a1)+,(a5)+
                    move.b   (a1)+,(a5)+
                    move.b   #' ',(a5)+
                    move.b   (a4)+,d0
                    move.b   (a2,d0.w),(a5)+
                    move.b   (a4)+,d0
                    move.b   (a2,d0.w),(a5)+
                    move.b   (a4)+,d0
                    moveq    #$F,d1
                    and.w    d0,d1
                    lsr.w    #4,d0
                    move.b   (a2,d0.w),(a5)+
                    move.b   (a2,d1.w),(a5)+
                    rts
lbC0203C6:
                    move.w   d0,-(sp)
                    bsr      lbC01F508
                    move.w   (sp)+,d7
                    bsr      lbC0202F0
                    bsr      lbC02031E
                    bra      lbC01F440
lbC0203DC:
                    move.w   d0,-(sp)
                    bsr      erase_pattern_caret
                    bsr      lbC01F508
                    jsr      (own_blitter)
                    ; clear 1 char line
                    move.l   #$1000000,(BLTCON0,a6)
                    move.w   #0,(BLTDMOD,a6)
                    lea      (main_screen+(56*80)),a0
                    move.w   (sp)+,d0
                    mulu.w   #(SCREEN_BYTES*8),d0
                    adda.l   d0,a0
                    move.l   a0,(BLTDPTH,a6)
                    move.w   #(8*64)+(SCREEN_BYTES/2),(BLTSIZE,a6)
                    jsr      (disown_blitter)
                    bsr      lbC01F440
                    bra      display_pattern_caret

; ===========================================================================
draw_one_char_alpha_numeric:
                    lea      (alpha_numeric_table),a0
                    ext.w    d2
                    move.b   (a0,d2.w),d2
                    jmp      (draw_one_char)

; ===========================================================================
display_pattern_caret:
                    movem.w  (caret_pos_x,pc),d0/d1
                    addq.w   #7,d1
                    lea      (caret_current_positions),a0
                    move.b   (a0,d0.w),d0
                    movem.l  d0/d1,-(sp)
                    bsr.b    erase_pattern_caret
                    movem.l  (sp)+,d0/d1
                    movem.w  d0/d1,(old_caret_pos)
                    jmp      (invert_one_char)
erase_pattern_caret:
                    tst.l    (old_caret_pos)
                    bmi.b    .no_erase
                    movem.l  d0/d1,-(sp)
                    movem.w  (old_caret_pos),d0/d1
                    jsr      (invert_one_char)
                    moveq    #-1,d0
                    move.l   d0,(old_caret_pos)
                    movem.l  (sp)+,d0/d1
.no_erase:
                    rts
old_caret_pos:
                    dc.w     -1,-1

; ===========================================================================
lbC02048C:
                    movem.l  d0-d3/a0,-(sp)
                    tst.b    (lbB020540)
                    beq.b    lbC0204AC
                    btst     #9,d1
                    bne      lbC02053A
                    tst.b    d0
                    bmi      lbC02053A
                    sf       (lbB020540)
lbC0204AC:
                    btst     #9,d1
                    bne.b    lbC0204BA
                    tst.b    d0
                    bmi.b    lbC0204BA
                    bsr      remove_mouse_pointer
lbC0204BA:
                    tst.b    d0
                    smi      d3
                    andi.w   #$7F,d0
                    moveq    #7,d2
                    and.w    d1,d2
                    beq.b    lbC0204CC
                    ori.w    #$100,d0
lbC0204CC:
                    moveq    #$30,d2
                    and.w    d1,d2
                    beq.b    lbC0204D6
                    ori.w    #$200,d0
lbC0204D6:
                    move.w   #$C0,d2
                    and.w    d1,d2
                    beq.b    lbC0204E2
                    ori.w    #$400,d0
lbC0204E2:
                    btst     #8,d1
                    beq.b    lbC0204EC
                    ori.w    #$800,d0
lbC0204EC:
                    btst     #9,d1
                    beq.b    lbC0204F6
                    ori.w    #$8000,d0
lbC0204F6:
                    btst     #3,d1
                    beq.b    lbC020500
                    ori.w    #$1000,d0
lbC020500:
                    cmpi.b   #$40,d0
                    bhi.b    lbC02051E
                    lea      (qwertyuiop123_MSG,pc),a0
                    btst     #8,d0
                    beq.b    lbC020514
                    lea      (_0QWERTYUIOP1_MSG,pc),a0
lbC020514:
                    moveq    #0,d2
                    move.b   d0,d2
                    move.b   (a0,d2.w),d0
                    bra.b    lbC020528
lbC02051E:
                    cmpi.b   #$5F,d0
                    bhi.b    lbC02053A
                    subi.b   #$40,d0
lbC020528:
                    move.w   d0,d1
                    moveq    #1,d0
                    tst.b    d3
                    beq.b    lbC020532
                    moveq    #$E,d0
lbC020532:
                    moveq    #0,d2
                    moveq    #0,d3
                    bsr      lbC0205C4
lbC02053A:
                    movem.l  (sp)+,d0-d3/a0
                    rts
lbB020540:
                    dc.b     0
                    even
qwertyuiop123_MSG:
                    dc.b     '`1234567890-=\ 0qwertyuiop[] 123asdfghjkl;''  456<zxcvbnm,./ .789 '
_0QWERTYUIOP1_MSG:
                    dc.b     '~!@#$%^&*()_+| 0QWERTYUIOP{} 123ASDFGHJKL:"  456>ZXCVBNM<>? .789 '
lbC0205C4:
                    EXEC     Disable
                    movem.l  d4/d5/a0/a1,-(sp)
                    move.w   (lbW01B70C),d4
                    lea      (lbL01B30C),a0
                    move.w   d4,d5
                    lsl.w    #3,d5
                    movem.w  d0-d3,(a0,d5.w)
                    addq.w   #1,d4
                    andi.w   #$7F,d4
                    cmp.w    (lbW01B70E),d4
                    bne.b    lbC0205FA
                    bra.b    lbC020600
lbC0205FA:
                    move.w   d4,(lbW01B70C)
lbC020600:
                    move.l   (our_task,pc),a1
                    move.l   (lbL01E1D4,pc),d0
                    EXEC     Signal
                    movem.l  (sp)+,d4/d5/a0/a1
                    EXEC     Enable
                    rts
lbC020626:
                    bsr      stop_audio_channels
lbC02062A:
                    movem.l  d2-d4/a1/a2,-(sp)
                    move.l   a0,a2
                    bra.b    lbC020642
lbC020632:
                    move.l   (lbL01E1D4,pc),d0
                    EXEC     Wait
lbC020642:
                    move.l   a2,a0
                    EXEC     Disable
                    move.w   (lbW01B70E),d4
                    cmp.w    (lbW01B70C),d4
                    beq.b    lbC0206C2
                    lea      (lbL01B30C),a1
                    move.w   d4,d3
                    lsl.w    #3,d3
                    movem.w  (a1,d3.w),d0-d3
                    addq.w   #1,d4
                    andi.w   #$7F,d4
                    move.w   d4,(lbW01B70E)
                    EXEC     Enable
lbC020686:
                    move.w   (a0)+,d4
                    beq.b    lbC020642
                    cmpi.w   #11,d4
                    beq.b    lbC020694
                    cmp.w    d0,d4
                    bne.b    lbC0206BE
lbC020694:
                    move.l   (a0),a1
                    clr.l    (current_cmd_ptr)
                    sf       (quit_flag)
                    movem.l  d0-d3/a0/a2,-(sp)
                    jsr      (a1)
                    movem.l  (sp)+,d0-d3/a0/a2
                    beq.b    lbC0206D2
                    tst.l    (current_cmd_ptr)
                    bne.b    lbC0206D2
                    tst.b    (quit_flag)
                    bne.b    lbC0206D2
lbC0206BE:
                    addq.w   #4,a0
                    bra.b    lbC020686
lbC0206C2:
                    EXEC     Enable
                    bra      lbC020632
lbC0206D2:
                    move.l   (lbL0208D6),a0
                    bsr      lbC020C14
                    clr.l    (lbL0208D6)
                    bsr      stop_audio_channels
                    movem.l  (sp)+,d2-d4/a1/a2
                    rts
current_cmd_ptr:
                    dc.l     0
quit_flag:
                    dc.b     0
                    even
lbC0206F2:
                    movem.l  d2/d3,-(sp)
                    tst.b    (pointer_visible_flag)
                    bne.b    lbC020774
                    bsr      install_mouse_pointer
                    move.w   d0,d2
                    move.w   d1,d3
                    lea      (mouse_pointer_coords,pc),a0
                    movem.w  (a0),d0/d1
                    ext.w    d2
                    ext.w    d3
                    add.w    d2,d0
                    add.w    d3,d1
                    tst.w    d0
                    bpl.b    lbC02071C
                    moveq    #0,d0
lbC02071C:
                    tst.w    d1
                    bpl.b    lbC020722
                    moveq    #0,d1
lbC020722:
                    cmpi.w   #SCREEN_WIDTH-1,d0
                    blt.b    lbC02072C
                    move.w   #SCREEN_WIDTH-1,d0
lbC02072C:
                    cmp.w    (max_mouse_pointer_y,pc),d1
                    blt.b    lbC020736
                    move.w   (max_mouse_pointer_y,pc),d1
lbC020736:
                    movem.w  d0/d1,(a0)
                    lsr.w    #1,d0
                    lsr.w    #1,d1
                    lea      (mouse_pointer),a0
                    moveq    #9,d2
                    addi.w   #128,d0
                    addi.w   #44,d1
                    add.w    d1,d2
                    move.b   d1,(a0)+
                    moveq    #0,d3
                    ror.w    #1,d0
                    bpl.b    lbC02075A
                    addq.w   #1,d3
lbC02075A:
                    move.b   d0,(a0)+
                    move.b   d2,(a0)+
                    btst     #8,d1
                    beq.b    lbC020766
                    addq.w   #4,d3
lbC020766:
                    btst     #8,d2
                    beq.b    lbC02076E
                    addq.w   #2,d3
lbC02076E:
                    move.b   d3,(a0)+
                    bra.b    lbC02077C
max_mouse_pointer_y:
                    dc.w     496-1
lbC020774:
                    move.w   d1,d2
                    move.w   d0,d1
                    moveq    #12,d0
                    bra.b    lbC020788
lbC02077C:
                    moveq    #3,d0
                    movem.w  (mouse_pointer_coords),d1/d2
                    lsr.w    #1,d2
lbC020788:
                    move.w   (lbB01E37A,pc),d3
                    bsr      lbC0205C4
                    movem.l  (sp)+,d2/d3
                    rts

; ===========================================================================
install_mouse_pointer:
                    EXEC     Disable
                    tst.b    (pointer_visible_flag)
                    bne.b    .no_op
                    tst.b    (mouse_pointer_bp_set_flag)
                    bne.b    .no_op
                    movem.l  d0/a0,-(sp)
                    lea      (mouse_pointer),a0
                    bsr.b    set_mouse_sprite_bp
                    movem.l  (sp)+,d0/a0
.no_op:
                    EXEC     Enable
                    rts

; ===========================================================================
remove_mouse_pointer:
                    EXEC     Disable
                    tst.b    (mouse_pointer_bp_set_flag)
                    beq.b    .no_op
                    movem.l  d0/a0,-(sp)
                    lea      (dummy_sprite),a0
                    bsr      set_mouse_sprite_bp
                    movem.l  (sp)+,d0/a0
.no_op:
                    EXEC     Enable
                    rts

; ===========================================================================
set_mouse_sprite_bp:
                    not.b    (mouse_pointer_bp_set_flag)
                    move.l   a0,d0
                    lea      (sprites_bps+2),a0
                    move.w   d0,(4,a0)
                    swap     d0
                    move.w   d0,(a0)
                    rts
mouse_pointer_coords:
                    dc.w     0,0
mouse_pointer_bp_set_flag:
                    dc.b     0
                    even

; ===========================================================================
hide_mouse_pointer:
                    bsr.b    remove_mouse_pointer
                    st       (pointer_visible_flag)
                    rts
show_mouse_pointer:
                    sf       (pointer_visible_flag)
                    bra      install_mouse_pointer
pointer_visible_flag:
                    dc.b     0
                    even

; ===========================================================================
process_commands_sequence:
                    movem.l  a2/a3,-(sp)
                    sub.l    a1,a1
                    sub.l    a2,a2
                    sub.l    a3,a3
.loop:
                    move.w   (a0)+,d0
                    beq.b    .done
                    cmpi.w   #1,d0
                    beq.b    .sequence_1
                    cmpi.w   #2,d0
                    beq.b    .sequence_2
                    cmpi.w   #3,d0
                    beq.b    .sequence_3
                    ; wrong sequence index
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    .done
.sequence_1:
                    move.l   (a0)+,a1
                    bra.b    .loop
.sequence_2:
                    move.l   (a0)+,a2
                    bra.b    .loop
.sequence_3:
                    move.l   (a0)+,a3
                    bra.b    .loop
.done:
                    ; store at the end of the list
                    movem.l  a1-a3,(a0)
                    move.l   a0,(current_sequence_ptr)
                    clr.l    (lbL0208D6)
                    move.l   (a0),d0
                    beq.b    .no_command
                    move.l   d0,a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
.no_command:
                    movem.l  (sp)+,a2/a3
                    rts
current_sequence_ptr:
                    dc.l     0
lbL0208D6:
                    dc.l     0

; ===========================================================================
lbC0208DA:
                    movem.l  d2/a2/a3,-(sp)
                    move.l   a0,a2
                    move.w   d0,d2
lbC0208E2:
                    move.l   (a2)+,d0
                    beq.b    lbC0208F4
                    move.l   d0,a3
lbC0208E8:
                    add.b    d2,(7,a3)
                    move.l   (a3),d0
                    beq.b    lbC0208E2
                    move.l   d0,a3
                    bra.b    lbC0208E8
lbC0208F4:
                    movem.l  (sp)+,d2/a2/a3
                    rts
lbC0208FA:
                    tst.l    (current_sequence_ptr)
                    beq      lbC020A1C
                    cmpi.w   #1,d0
                    beq.b    lbC020950
                    tst.b    (pointer_visible_flag)
                    bne      lbC0209FC
                    cmpi.w   #3,d0
                    beq.b    lbC02093C
                    cmpi.w   #4,d0
                    beq.b    lbC020974
                    cmpi.w   #6,d0
                    beq      lbC02098E
                    cmpi.w   #7,d0
                    beq      lbC0209A8
                    cmpi.w   #9,d0
                    beq      lbC0209E2
                    bra      lbC020A18
lbC02093C:
                    add.w    (lbW01E8E8,pc),d2
                    move.w   d1,d0
                    move.w   d2,d1
                    bsr      lbC020AF2
                    bsr      lbC020B56
                    bra      lbC020A18
lbC020950:
                    moveq    #0,d0
                    move.l   d0,a0
                    move.w   d1,-(sp)
                    bsr      lbC020B56
                    move.w   (sp)+,d1
                    move.l   (current_sequence_ptr,pc),a0
                    move.l   (4,a0),d0
                    beq      lbC020A18
                    move.l   d0,a0
                    move.w   d1,d0
                    bsr      lbC020B7C
                    bra      lbC020A18
lbC020974:
                    add.w    (lbW01E8E8,pc),d2
                    move.w   d1,d0
                    move.w   d2,d1
                    move.w   d3,d2
                    move.w   #10,a0
                    move.w   #14,a1
                    bsr      lbC020A8C
                    bra      lbC020A18
lbC02098E:
                    add.w    (lbW01E8E8,pc),d2
                    move.w   d1,d0
                    move.w   d2,d1
                    move.w   d3,d2
                    move.w   #10,a0
                    move.w   #14,a1
                    bsr      lbC020A60
                    bra      lbC020A18
lbC0209A8:
                    add.w    (lbW01E8E8,pc),d2
                    move.l   (lbL0208D6,pc),d0
                    beq.b    lbC020A18
                    move.l   d0,a0
                    move.w   (4,a0),d0
                    btst     #11,d0
                    beq.b    lbC0209CC
                    bsr      hide_mouse_pointer
                    clr.w    (lbW020A30)
                    bra      lbC020A18
lbC0209CC:
                    move.w   d1,d0
                    move.w   d2,d1
                    move.w   d3,d2
                    move.w   #14,a0
                    move.w   #10,a1
                    bsr      lbC020A8C
                    bra      lbC020A18
lbC0209E2:
                    add.w    (lbW01E8E8,pc),d2
                    move.w   d1,d0
                    move.w   d2,d1
                    move.w   d3,d2
                    move.w   #14,a0
                    move.w   #10,a1
                    bsr      lbC020A60
                    bra      lbC020A18
lbC0209FC:
                    cmpi.w   #7,d0
                    beq.b    lbC020A10
                    cmpi.w   #12,d0
                    beq.b    lbC020A0A
                    bra.b    lbC020A18
lbC020A0A:
                    bsr      lbC020A34
                    bra.b    lbC020A18
lbC020A10:
                    bsr      show_mouse_pointer
lbC020A18:
                    moveq    #ERROR,d0
                    bra.b    lbC020A2E
lbC020A1C:
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    moveq    #0,d0
lbC020A2E:
                    rts
lbW020A30:
                    dc.w     0
lbW020A32:
                    dc.w     6
lbC020A34:
                    sub.w    d2,(lbW020A30)
                    move.w   (lbW020A30,pc),d0
                    ext.l    d0
                    divs.w   (lbW020A32,pc),d0
                    swap     d0
                    move.w   d0,(lbW020A30)
                    swap     d0
                    tst.w    d0
                    beq.b    lbC020A5E
                    move.w   #14,a0
                    move.w   #10,a1
                    bra      lbC020A8C
lbC020A5E:
                    rts
lbC020A60:
                    movem.l  d0/a0,-(sp)
                    move.l   (lbL0208D6,pc),d0
                    beq.b    lbC020A86
                    move.l   d0,a0
                    move.w   (4,a0),d0
                    btst     #12,d0
                    bne.b    lbC020A86
                    btst     #11,d0
                    bne.b    lbC020A86
                    movem.l  (sp)+,d0/a0
                    bra      lbC020A8C
lbC020A86:
                    movem.l  (sp)+,d0/a0
                    rts
lbC020A8C:
                    movem.l  d3-d7/a2,-(sp)
                    move.w   d0,d5
                    move.w   d1,d6
                    move.w   a0,d3
                    move.w   a1,d4
                    move.l   (lbL0208D6,pc),d0
                    beq.b    lbC020AEC
                    clr.l    (lbL0208D6)
                    move.l   d0,a2
                    move.l   a2,a0
                    bsr      lbC020C14
                    move.w   d5,d0
                    move.w   d6,d1
                    move.l   (a2,d3.w),d7
                    beq.b    lbC020AC4
                    move.l   d7,a0
                    movem.l  d0-d7/a0-a6,-(sp)
                    jsr      (a0)
                    movem.l  (sp)+,d0-d7/a0-a6
                    bra.b    lbC020AE0
lbC020AC4:
                    move.w   (4,a2),d7
                    btst     #11,d7
                    bne.b    lbC020AE0
                    move.l   (a2,d4.w),d7
                    beq.b    lbC020AE0
                    move.l   d7,a0
                    movem.l  d0-d7/a0-a6,-(sp)
                    jsr      (a0)
                    movem.l  (sp)+,d0-d7/a0-a6
lbC020AE0:
                    move.l   a2,a0
                    move.l   a0,(lbL0208D6)
                    bsr      lbC020C14
lbC020AEC:
                    movem.l  (sp)+,d3-d7/a2
                    rts
lbC020AF2:
                    movem.l  d2/d3,-(sp)
                    move.w   d0,d2
                    move.w   d1,d3
                    lsr.w    #3,d2
                    lsr.w    #3,d3
                    move.l   (current_sequence_ptr,pc),d0
                    beq.b    lbC020B3E
                    move.l   d0,a0
                    move.l   (8,a0),d0
                    beq.b    lbC020B3E
lbC020B0C:
                    move.l   d0,a0
                    move.w   (4,a0),d0
                    btst     #14,d0
                    bne.b    lbC020B38
                    move.b   (6,a0),d0
                    cmp.b    d2,d0
                    bhi.b    lbC020B38
                    move.b   (7,a0),d1
                    cmp.b    d3,d1
                    bhi.b    lbC020B38
                    add.b    (8,a0),d0
                    cmp.b    d2,d0
                    bls.b    lbC020B38
                    add.b    (9,a0),d1
                    cmp.b    d3,d1
                    bhi.b    lbC020B50
lbC020B38:
                    move.l   (a0),d0
                    bne.b    lbC020B0C
                    bra.b    lbC020B4E
lbC020B3E:
                    move.w   #$F00,(_CUSTOM|COLOR00)
lbC020B4E:
                    sub.l    a0,a0
lbC020B50:
                    movem.l  (sp)+,d2/d3
                    rts
lbC020B56:
                    movem.l  a2/a3,-(sp)
                    move.l   (lbL0208D6,pc),a2
                    move.l   a0,a3
                    cmpa.l   a2,a3
                    beq.b    lbC020B76
                    move.l   a2,a0
                    bsr      lbC020C14
                    move.l   a3,a0
                    bsr      lbC020C14
                    move.l   a3,(lbL0208D6)
lbC020B76:
                    movem.l  (sp)+,a2/a3
                    rts
lbC020B7C:
                    movem.l  d2-d4,-(sp)
                    bclr     #15,d0
                    sne      d1
                    bsr      lbC020B90
                    movem.l  (sp)+,d2-d4
                    rts
lbC020B90:
                    move.w   (a0)+,d2
                    move.w   (lbW020B9A,pc,d2.w),d2
                    jmp      (lbW020B9A,pc,d2.w)
lbW020B9A:
                    dc.w     lbC020BA6-lbW020B9A,lbC020BA8-lbW020B9A,lbC020BB2-lbW020B9A
                    dc.w     lbC020BC6-lbW020B9A,lbC020BD2-lbW020B9A,lbC020BF6-lbW020B9A
lbC020BA6:
                    rts
lbC020BA8:
                    move.w   (a0)+,d2
                    move.l   (a0)+,a1
                    tst.b    d1
                    bne.b    lbC020B90
                    bra.b    lbC020BB6
lbC020BB2:
                    move.w   (a0)+,d2
                    move.l   (a0)+,a1
lbC020BB6:
                    cmp.b    d2,d0
                    bne.b    lbC020B90
                    movem.l  d0/d1/a0,-(sp)
                    jsr      (a1)
                    movem.l  (sp)+,d0/d1/a0
                    bra.b    lbC020B90
lbC020BC6:
                    movem.w  (a0)+,d2-d4
                    move.l   (a0)+,a1
                    tst.b    d1
                    bne.b    lbC020B90
                    bra.b    lbC020BD8
lbC020BD2:
                    movem.w  (a0)+,d2-d4
                    move.l   (a0)+,a1
lbC020BD8:
                    cmp.b    d2,d0
                    bcs.b    lbC020B90
                    cmp.b    d3,d0
                    bhi.b    lbC020B90
                    moveq    #0,d3
                    move.b   d0,d3
                    sub.b    d2,d3
                    add.w    d4,d3
                    movem.l  d0/d1/a0,-(sp)
                    move.w   d3,d0
                    jsr      (a1)
                    movem.l  (sp)+,d0/d1/a0
                    bra.b    lbC020B90
lbC020BF6:
                    move.w   (a0)+,d2
                    move.l   (a0)+,a1
                    move.w   d0,d3
                    andi.w   #$FF00,d2
                    andi.w   #$FF00,d3
                    cmp.w    d2,d3
                    bne.b    lbC020B90
                    move.l   a0,-(sp)
                    move.l   a1,a0
                    bsr.b    lbC020B90
                    move.l   (sp)+,a0
                    bra      lbC020B90
lbC020C14:
                    movem.l  d2-d6/a2,-(sp)
                    move.l   a0,d0
                    beq.b    lbC020C84
                    move.w   (4,a0),d0
                    btst     #13,d0
                    bne.b    lbC020C84
                    lea      (main_screen),a2
                    moveq    #0,d3
                    moveq    #0,d4
                    move.b   (6,a0),d3
                    move.b   (7,a0),d4
                    move.l   d3,d5
                    move.l   d4,d6
                    add.b    (8,a0),d5
                    add.b    (9,a0),d6
                    lsl.w    #3,d3
                    lsl.w    #3,d4
                    lsl.w    #3,d5
                    lsl.w    #3,d6
                    subq.w   #1,d3
                    subq.w   #1,d4
                    subq.w   #1,d5
                    subq.w   #1,d6
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d5,d1
                    move.w   d4,d2
                    bsr      lbC020D42
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d4,d1
                    move.w   d6,d2
                    bsr      lbC020D84
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d5,d1
                    move.w   d6,d2
                    bsr      lbC020D42
                    move.l   a2,a0
                    move.w   d5,d0
                    move.w   d4,d1
                    move.w   d6,d2
                    bsr      lbC020D84
lbC020C84:
                    movem.l  (sp)+,d2-d6/a2
                    rts
lbC020C8A:
                    andi.w   #$BFFF,(4,a0)
                    rts
lbC020C92:
                    ori.w    #$4000,(4,a0)
                    rts
lbC020C9A:
                    lea      (main_screen+(56*80)),a1
                    bra.b    lbC020CBC
lbC020CA2:
                    tst.w    (a0)
                    bmi.b    lbC020CB4
                    move.l   a0,-(sp)
                    jsr      (lbC020CB6)
                    move.l   (sp)+,a0
                    addq.w   #8,a0
                    bra.b    lbC020CA2
lbC020CB4:
                    rts
lbC020CB6:
                    lea      (main_screen),a1
lbC020CBC:
                    move.l   a0,d0
                    ble      lbC020D34
                    move.l   a1,(lbL020D36)
                    movem.w  (a0),d0-d3
                    lsl.w    #3,d0
                    lsl.w    #3,d1
                    lsl.w    #3,d2
                    lsl.w    #3,d3
                    subq.w   #1,d0
                    subq.w   #1,d1
                    addq.w   #8,d2
                    addq.w   #7,d3
                    movem.w  d0-d3,(lbW020D3A)
                    move.l   (lbL020D36,pc),a0
                    move.w   (lbW020D3A,pc),d0
                    move.w   (lbW020D3E,pc),d1
                    move.w   (lbW020D3C,pc),d2
                    bsr      lbC020D42
                    move.l   (lbL020D36,pc),a0
                    move.w   (lbW020D3A,pc),d0
                    move.w   (lbW020D3C,pc),d1
                    move.w   (lbW020D40,pc),d2
                    bsr      lbC020D84
                    move.l   (lbL020D36,pc),a0
                    move.w   (lbW020D3A,pc),d0
                    move.w   (lbW020D3E,pc),d1
                    move.w   (lbW020D40,pc),d2
                    bsr      lbC020D42
                    move.l   (lbL020D36,pc),a0
                    move.w   (lbW020D3E,pc),d0
                    move.w   (lbW020D3C,pc),d1
                    move.w   (lbW020D40,pc),d2
                    bra      lbC020D84
lbC020D34:
                    rts
lbL020D36:
                    dc.l     0
lbW020D3A:
                    dc.w     0
lbW020D3C:
                    dc.w     0
lbW020D3E:
                    dc.w     0
lbW020D40:
                    dc.w     0
lbC020D42:
                    movem.l  d0-d7/a0-a6,-(sp)
                    tst.w    d2
                    bmi.b    lbC020D7E
                    cmpi.w   #1079,d2
                    bgt.b    lbC020D7E
                    cmp.w    d0,d1
                    bgt.b    lbC020D56
                    exg      d0,d1
lbC020D56:
                    tst.w    d1
                    bmi.b    lbC020D7E
                    cmpi.w   #SCREEN_WIDTH-1,d0
                    bgt.b    lbC020D7E
                    tst.w    d0
                    bpl.b    lbC020D66
                    moveq    #0,d0
lbC020D66:
                    cmpi.w   #SCREEN_WIDTH-1,d1
                    ble.b    lbC020D70
                    move.w   #SCREEN_WIDTH-1,d1
lbC020D70:
                    move.l   a0,a3
                    exg      d1,d2
                    move.w   d1,d3
                    moveq    #$5A,d4
                    jsr      (draw_filled_box_with_minterms)
lbC020D7E:
                    movem.l  (sp)+,d0-d7/a0-a6
                    rts
lbC020D84:
                    movem.l  d0-d7/a0-a6,-(sp)
                    tst.w    d0
                    bmi.b    lbC020DC0
                    cmpi.w   #SCREEN_WIDTH-1,d0
                    bgt.b    lbC020DC0
                    cmp.w    d1,d2
                    bgt.b    lbC020D98
                    exg      d1,d2
lbC020D98:
                    tst.w    d2
                    bmi.b    lbC020DC0
                    cmpi.w   #1079,d1
                    bgt.b    lbC020DC0
                    tst.w    d1
                    bpl.b    lbC020DA8
                    moveq    #0,d1
lbC020DA8:
                    cmpi.w   #1079,d2
                    ble.b    lbC020DB2
                    move.w   #1079,d2
lbC020DB2:
                    move.l   a0,a3
                    move.w   d2,d3
                    move.w   d0,d2
                    moveq    #$5A,d4
                    jsr      (draw_filled_box_with_minterms)
lbC020DC0:
                    movem.l  (sp)+,d0-d7/a0-a6
                    rts

; ===========================================================================
free_all_samples:
                    bsr      do_free_all_samples
                    bra      lbC0201E4

; ===========================================================================
lbC020DCE:
                    bsr      ask_are_you_sure_requester
                    bne.b    lbC020DE4
                    bsr      lbC0201E4
                    bsr      lbC020112
                    bmi      exit
                    bra      lbC0202A8
lbC020DE4:
                    rts

; ===========================================================================
load_song:
                    move.l   #do_load_song,(current_cmd_ptr)
                    rts
do_load_song:
                    lea      (LoadSong_MSG,pc),a0
                    moveq    #DIR_SONGS,d0
                    jsr      (display_file_requester)
                    bgt.b    .confirmed
                    rts
.confirmed:
                    lea      (filename_to_load),a0
                    jsr      (open_file_for_reading)
                    bmi      .error
                    lea      (song_chunk_header_loaded_data),a0
                    moveq    #8,d0
                    jsr      (read_from_file)
                    bmi.b    .error
                    lea      (song_chunk_header_loaded_data),a0
                    cmpi.l   #'OKTA',(a0)+
                    bne      load_st_mod
                    cmpi.l   #'SONG',(a0)+
                    beq.b    .load_okta_mod
                    bsr      error_ok_struct_error
                    bra.b    lbC020E96

; ===========================================================================
.load_okta_mod:
                    jsr      (backup_prefs)
                    bsr      free_all_samples
                    lea      (CMOD_MSG,pc),a0
                    bsr      lbC021342
                    lea      (SAMP_MSG,pc),a0
                    bsr      lbC021342
                    lea      (CMOD_MSG,pc),a0
                    bsr      lbC021364
                    bmi.b    lbC020EA2
                    jsr      (lbC02B354)
                    bsr      lbC0201E4
                    lea      (SAMP_MSG,pc),a0
                    bsr      lbC021364
                    bmi.b    lbC020EA6
                    bsr      lbC0211F6
                    bmi.b    lbC020EA6
                    bsr      lbC0212A2
                    bmi.b    lbC020EA6
                    jsr      (close_file)
                    bsr      lbC02001C
                    bra      lbC01FBF2
.error:
                    bsr      display_dos_error
lbC020E96:
                    jsr      (close_file)
                    bra      lbC02001C
lbC020EA2:
                    bsr      display_dos_error
lbC020EA6:
                    jsr      (close_file)
                    bsr      free_all_samples
                    bsr      lbC020112
                    bmi      exit
                    rts
LoadSong_MSG:
                    dc.b     'Load Song',0

; ===========================================================================
load_st_mod:
                    jsr      (backup_prefs)
                    bsr      free_all_samples
                    lea      (OK_ChannelsModes),a0
                    clr.l    (a0)
                    clr.l    (4,a0)
                    tst.b    (st_load_tracks_mode)
                    beq.b    lbC020EF0
                    move.l   #$10001,(a0)
                    move.l   #$10001,(4,a0)
lbC020EF0:
                    jsr      (lbC02B354)
                    bsr      lbC0201E4
                    bsr.b    lbC020F2C
                    bmi.b    lbC020F18
                    bsr      lbC02103C
                    bmi.b    lbC020F18
                    bsr      lbC0210CE
                    bmi.b    lbC020F18
                    jsr      (close_file)
                    bsr      lbC02001C
                    bra      lbC01FBF2
lbC020F18:
                    jsr      (close_file)
                    bsr      free_all_samples
                    bsr      lbC020112
                    bmi      exit
                    rts
lbC020F2C:
                    moveq    #12,d0
                    jsr      (move_in_file)
                    bmi      lbC02102A
                    lea      (OK_Samples+32),a5
                    moveq    #15-1,d7
                    tst.b    (st_load_tracks_samples)
                    beq.b    lbC020F4A
                    moveq    #31-1,d7
lbC020F4A:
                    move.l   a5,a0
                    moveq    #30,d0
                    jsr      (read_from_file)
                    bmi      lbC02102A
                    andi.l   #$FFFF,(20,a5)
                    beq.b    lbC020F96
                    lsl.w    (22,a5)
                    move.w   (28,a5),d0
                    move.w   (24,a5),(28,a5)
                    cmpi.w   #64,(28,a5)
                    bhi      lbC021024
                    move.w   (26,a5),(24,a5)
                    move.w   d0,(26,a5)
                    moveq    #1,d0
                    tst.b    (st_load_tracks_mode)
                    beq.b    lbC020F90
                    moveq    #0,d0
lbC020F90:
                    move.w   d0,(30,a5)
                    bra.b    lbC020F9C
lbC020F96:
                    move.l   a5,a0
                    bsr      lbC021032
lbC020F9C:
                    lea      (32,a5),a5
                    dbra     d7,lbC020F4A
                    lea      (OK_PLen,pc),a5
                    move.l   a5,a0
                    move.l   #130,d0
                    jsr      (read_from_file)
                    bmi.b    lbC02102A
                    move.w   (a5),d0
                    lsr.w    #8,d0
                    move.w   d0,(a5)+
                    beq.b    lbC021024
                    adda.w   d0,a5
                    move.w   #$80,d1
                    sub.w    d0,d1
                    bmi.b    lbC021024
                    bra.b    lbC020FCE
lbC020FCC:
                    sf       (a5)+
lbC020FCE:
                    dbra     d1,lbC020FCC
                    move.w   #6,(OK_Speed)
                    tst.b    (st_load_tracks_mode)
                    beq.b    lbC020FF2
                    lea      (OK_Patterns,pc),a0
                    moveq    #128-1,d0
lbC020FE8:
                    move.b   (a0),d1
                    lsr.b    #1,d1
                    move.b   d1,(a0)+
                    dbra     d0,lbC020FE8
lbC020FF2:
                    lea      (OK_Patterns,pc),a0
                    moveq    #0,d1
                    moveq    #128-1,d0
lbC020FFA:
                    cmp.b    (a0)+,d1
                    bgt.b    lbC021002
                    move.b   (-1,a0),d1
lbC021002:
                    dbra     d0,lbC020FFA
                    addq.w   #1,d1
                    move.w   d1,(lbW01B730)
                    tst.b    (st_load_tracks_samples)
                    beq.b    lbC021020
                    moveq    #4,d0
                    jsr      (move_in_file)
                    bmi.b    lbC02102A
lbC021020:
                    moveq    #0,d0
                    rts
lbC021024:
                    bsr      error_st_struct_error
                    bra.b    lbC02102E
lbC02102A:
                    bsr      display_dos_error
lbC02102E:
                    moveq    #ERROR,d0
                    rts
lbC021032:
                    moveq    #32-1,d0
lbC021034:
                    sf       (a0)+
                    dbra     d0,lbC021034
                    rts
lbC02103C:
                    move.w   (default_pattern_length),-(sp)
                    move.l   (lbL02A75C),-(sp)
lbC021048:
                    move.w   (lbW01B730),d7
                    cmp.w    (lbW01BC6E),d7
                    beq.b    lbC0210A4
                    move.w   #$40,(default_pattern_length)
                    move.w   (default_pattern_length),d0
                    mulu.w   (lbW02A75A),d0
                    move.l   d0,(lbL02A75C)
                    bsr      lbC020112
                    bmi.b    lbC0210BE
                    move.w   (lbW01BC6E),d0
                    subq.w   #1,d0
                    bsr      get_given_pattern_rows
                    mulu.w   (lbW02A75A),d0
                    move.l   a0,(lbL01B2A8)
                    jsr      (read_from_file)
                    bmi.b    lbC0210BA
                    move.l   (lbL01B2A8),a0
                    bsr      lbC021144
                    bmi.b    lbC0210B4
                    bra.b    lbC021048
lbC0210A4:
                    move.l   (sp)+,(lbL02A75C)
                    move.w   (sp)+,(default_pattern_length)
                    moveq    #0,d0
                    rts
lbC0210B4:
                    bsr      error_st_struct_error
                    bra.b    lbC0210BE
lbC0210BA:
                    bsr      display_dos_error
lbC0210BE:
                    move.l   (sp)+,(lbL02A75C)
                    move.w   (sp)+,(default_pattern_length)
                    moveq    #ERROR,d0
                    rts
lbC0210CE:
                    lea      (OK_Samples),a5
                    moveq    #0,d7
lbC0210D6:
                    move.l   (20,a5),d0
                    beq.b    lbC02111E
                    move.l   d0,(lbL01B732)
                    move.w   d7,(current_sample)
                    bsr      lbC021F9E
                    bmi.b    lbC02113C
                    bsr      lbC02161C
                    move.l   (a0),a0
                    move.l   a0,(lbL021140)
                    move.l   (lbL01B732),d0
                    jsr      (read_from_file)
                    bmi.b    lbC021138
                    cmpi.w   #1,(30,a5)
                    beq.b    lbC02111E
                    move.l   (lbL021140,pc),a0
                    move.l   (lbL01B732),d0
                    bsr      lbC021F62
lbC02111E:
                    lea      (32,a5),a5
                    addq.w   #1,d7
                    cmpi.w   #36,d7
                    bne.b    lbC0210D6
                    clr.w    (current_sample)
                    bsr      lbC01FBF2
                    moveq    #OK,d0
                    rts
lbC021138:
                    bsr      display_dos_error
lbC02113C:
                    moveq    #ERROR,d0
                    rts
lbL021140:
                    dc.l     0
lbC021144:
                    movem.l  d2/d3/a2-a5,-(sp)
                    move.l   a0,a3
                    move.w   #256,d3
                    move.l   a0,a1
                    tst.b    (st_load_tracks_mode)
                    beq.b    lbC021160
                    add.w    d3,d3
                    lea      (lbL01A146),a1
lbC021160:
                    subq.w   #1,d3
lbC021162:
                    bsr      lbC0211B0
                    addq.w   #4,a0
                    addq.w   #4,a1
                    dbra     d3,lbC021162
                    tst.b    (st_load_tracks_mode)
                    beq.b    lbC0211A4
                    lea      (lbL01A146),a0
                    lea      (1024,a0),a5
                    move.l   a3,a1
                    lea      (16,a3),a4
                    moveq    #64-1,d0
lbC021188:
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    move.l   (a5)+,(a4)+
                    move.l   (a5)+,(a4)+
                    move.l   (a5)+,(a4)+
                    move.l   (a5)+,(a4)+
                    lea      (16,a1),a1
                    lea      (16,a4),a4
                    dbra     d0,lbC021188
lbC0211A4:
                    moveq    #OK,d0
                    bra.b    lbC0211AA
lbC0211A8:
                    moveq    #ERROR,d0
lbC0211AA:
                    movem.l  (sp)+,d2/d3/a2-a5
                    rts
lbC0211B0:
                    moveq    #0,d1
                    move.w   (a0),d0
                    move.w   d0,d2
                    lsr.w    #8,d2
                    andi.w   #$10,d2
                    andi.w   #$EFFF,d0
                    beq.b    lbC0211D0
                    lea      (OK_FullPeriodTab,pc),a2
lbC0211C6:
                    addq.w   #1,d1
                    tst.w    (a2)
                    beq.b    lbC0211A8
                    cmp.w    (a2)+,d0
                    bne.b    lbC0211C6
lbC0211D0:
                    move.b   d1,(a1)
                    move.b   (2,a0),d0
                    andi.b   #$F0,d0
                    lsr.b    #4,d0
                    or.b     d2,d0
                    move.b   d0,(1,a1)
                    move.b   (2,a0),d0
                    andi.b   #$F,d0
                    move.b   d0,(2,a1)
                    move.b   (3,a0),(3,a1)
                    rts
lbC0211F6:
                    move.w   (default_pattern_length),-(sp)
                    move.l   (lbL02A75C),-(sp)
lbC021202:
                    move.w   (lbW01B730),d7
                    cmp.w    (lbW01BC6E),d7
                    beq.b    lbC021278
                    lea      (song_chunk_header_loaded_data),a0
                    moveq    #8,d0
                    jsr      (read_from_file)
                    bmi.b    lbC02128E
                    lea      (song_chunk_header_loaded_data),a0
                    cmpi.l   #'PBOD',(a0)
                    bne.b    lbC021288
                    lea      (song_chunk_header_loaded_data),a0
                    moveq    #2,d0
                    jsr      (read_from_file)
                    bmi.b    lbC02128E
                    move.w   (song_chunk_header_loaded_data),d0
                    move.w   d0,(default_pattern_length)
                    mulu.w   (lbW02A75A),d0
                    move.l   d0,(lbL02A75C)
                    bsr      lbC020112
                    bmi.b    lbC021292
                    move.w   (lbW01BC6E),d0
                    subq.w   #1,d0
                    bsr      get_given_pattern_rows
                    mulu.w   (lbW02A75A),d0
                    jsr      (read_from_file)
                    bmi.b    lbC02128E
                    bra.b    lbC021202
lbC021278:
                    move.l   (sp)+,(lbL02A75C)
                    move.w   (sp)+,(default_pattern_length)
                    moveq    #OK,d0
                    rts
lbC021288:
                    bsr      error_ok_struct_error
                    bra.b    lbC021292
lbC02128E:
                    bsr      display_dos_error
lbC021292:
                    move.l   (sp)+,(lbL02A75C)
                    move.w   (sp)+,(default_pattern_length)
                    moveq    #ERROR,d0
                    rts
lbC0212A2:
                    lea      (OK_Samples),a5
                    moveq    #0,d7
lbC0212AA:
                    move.w   d7,(current_sample)
                    movem.l  d7/a5,-(sp)
                    bsr      lbC01FBF2
                    movem.l  (sp)+,d7/a5
                    move.l   (20,a5),d0
                    beq.b    lbC021310
                    move.l   d0,(lbL01B732)
                    bsr      lbC021F9E
                    bmi.b    lbC021334
                    lea      (song_chunk_header_loaded_data),a0
                    moveq    #8,d0
                    jsr      (read_from_file)
                    bmi.b    lbC021330
                    lea      (song_chunk_header_loaded_data),a0
                    cmpi.l   #'SBOD',(a0)+
                    bne.b    lbC02132A
                    move.l   (lbL01B732),d0
                    cmp.l    (a0),d0
                    blt.b    lbC02132A
                    move.l   (a0),(lbL01B732)
                    bsr      lbC02161C
                    move.l   (a0),a0
                    move.l   (lbL01B732),d0
                    jsr      (read_from_file)
                    bmi.b    lbC021330
lbC021310:
                    lea      (32,a5),a5
                    addq.w   #1,d7
                    cmpi.w   #36,d7
                    bne.b    lbC0212AA
                    clr.w    (current_sample)
                    bsr      lbC01FBF2
                    moveq    #OK,d0
                    rts
lbC02132A:
                    bsr      error_ok_struct_error
                    bra.b    lbC021334
lbC021330:
                    bsr      display_dos_error
lbC021334:
                    clr.w    (current_sample)
                    bsr      lbC01FBF2
                    moveq    #ERROR,d0
                    rts
lbC021342:
                    move.l   a0,a5
lbC021344:
                    tst.l    (a5)
                    beq.b    lbC021362
                    move.l   (4,a5),d0
                    move.l   (8,a5),a0
                    move.w   (14,a5),d1
lbC021354:
                    subq.l   #2,d0
                    bmi.b    lbC02135C
                    move.w   d1,(a0)+
                    bra.b    lbC021354
lbC02135C:
                    lea      (16,a5),a5
                    bra.b    lbC021344
lbC021362:
                    rts
lbC021364:
                    move.l   a0,a5
lbC021366:
                    lea      (song_chunk_header_loaded_data),a0
                    moveq    #8,d0
                    jsr      (read_from_file)
                    bmi.b    lbC0213A2
                    movem.l  (song_chunk_header_loaded_data),d0/d1
                    cmp.l    (a5),d0
                    bne.b    lbC0213AA
                    cmp.l    (4,a5),d1
                    bne.b    lbC0213B6
                    move.l   d1,d0
                    move.l   (8,a5),a0
                    jsr      (read_from_file)
                    bmi.b    lbC0213A2
lbC021396:
                    lea      (16,a5),a5
                    tst.l    (a5)
                    bne.b    lbC021366
                    moveq    #OK,d0
                    rts
lbC0213A2:
                    bsr      display_dos_error
                    moveq    #ERROR,d0
                    rts
lbC0213AA:
                    move.l   d1,d0
                    jsr      (move_in_file)
                    bmi.b    lbC0213A2
                    bra.b    lbC021366
lbC0213B6:
                    sub.l    (4,a5),d1
                    bpl.b    lbC0213D0
                    add.l    (4,a5),d1
                    move.l   d1,d0
                    move.l   (8,a5),a0
                    jsr      (read_from_file)
                    bmi.b    lbC0213A2
                    bra.b    lbC021396
lbC0213D0:
                    move.l   d1,(lbL01B2AC)
                    move.l   (4,a5),d0
                    move.l   (8,a5),a0
                    jsr      (read_from_file)
                    bmi.b    lbC0213A2
                    move.l   (lbL01B2AC),d0
                    jsr      (move_in_file)
                    bmi.b    lbC0213A2
                    bra.b    lbC021396
CMOD_MSG:
                    dc.b     'CMOD'
                    dc.l     8
                    dc.l     OK_ChannelsModes
                    dc.l     1
                    dc.l     0
SAMP_MSG:
                    dc.b     'SAMP'
                    dc.l     1152
                    dc.l     OK_Samples
                    dc.l     0
                    dc.b     'SPEE'
                    dc.l     2
                    dc.l     OK_Speed
                    dc.l     6
                    dc.b     'SLEN'
                    dc.l     2
                    dc.l     lbW01B730
                    dc.l     1
                    dc.b     'PLEN'
                    dc.l     2
                    dc.l     OK_PLen
                    dc.l     1
                    dc.b     'PATT'
                    dc.l     128
                    dc.l     OK_Patterns
                    dc.l     0
                    dc.l     0
lbC02145E:
                    move.l   #lbC02146A,(current_cmd_ptr)
                    rts
lbC02146A:
                    lea      (SaveSong_MSG),a0
                    moveq    #DIR_SONGS,d0
                    jsr      (display_file_requester)
                    bmi.b    lbC0214AE
                    lea      (filename_to_load),a0
                    jsr      (open_file_for_writing)
                    bmi.b    lbC0214AA
                    lea      (OKTASONG_MSG,pc),a0
                    moveq    #8,d0
                    jsr      (write_to_file)
                    bmi.b    lbC0214AA
                    lea      (CMOD_MSG0,pc),a0
                    bsr.b    lbC0214C8
                    bmi.b    lbC0214AE
                    bsr      lbC021548
                    bmi.b    lbC0214AE
                    bsr      lbC0215AC
                    bra.b    lbC0214AE
lbC0214AA:
                    bsr      display_dos_error
lbC0214AE:
                    jmp      (close_file)
SaveSong_MSG:
                    dc.b     'Save Song',0
OKTASONG_MSG:
                    dc.b     'OKTASONG'
lbC0214C8:
                    move.l   a0,a5
lbC0214CA:
                    tst.l    (a5)
                    beq.b    lbC0214F8
                    move.l   a5,a0
                    moveq    #8,d0
                    jsr      (write_to_file)
                    bmi.b    lbC0214F0
                    move.l   (4,a5),d0
                    move.l   (8,a5),a0
                    jsr      (write_to_file)
                    bmi.b    lbC0214F0
                    lea      (12,a5),a5
                    bra.b    lbC0214CA
lbC0214F0:
                    bsr      display_dos_error
                    moveq    #ERROR,d0
                    rts
lbC0214F8:
                    moveq    #OK,d0
                    rts
CMOD_MSG0:
                    dc.b     'CMOD'
                    dc.l     8
                    dc.l     OK_ChannelsModes
                    dc.b     'SAMP'
                    dc.l     1152
                    dc.l     OK_Samples
                    dc.b     'SPEE'
                    dc.l     2
                    dc.l     OK_Speed
                    dc.b     'SLEN'
                    dc.l     2
                    dc.l     lbW01BC6E
                    dc.b     'PLEN'
                    dc.l     2
                    dc.l     OK_PLen
                    dc.b     'PATT'
                    dc.l     128
                    dc.l     OK_Patterns
                    dc.l     0
lbC021548:
                    moveq    #0,d7
lbC02154A:
                    cmp.w    (lbW01BC6E),d7
                    beq.b    lbC0215A8
                    move.w   d7,d0
                    bsr      get_given_pattern_rows
                    mulu.w   (lbW02A75A),d0
                    subq.w   #2,a0
                    addq.l   #2,d0
                    move.l   a0,(lbL01B718)
                    move.l   d0,(lbL01B71C)
                    lea      (lbL01B710),a0
                    move.l   #'PBOD',(a0)
                    move.l   d0,(4,a0)
                    moveq    #8,d0
                    jsr      (write_to_file)
                    bmi.b    lbC0215A0
                    move.l   (lbL01B718),a0
                    move.l   (lbL01B71C),d0
                    jsr      (write_to_file)
                    bmi.b    lbC0215A0
                    addq.w   #1,d7
                    bra.b    lbC02154A
lbC0215A0:
                    bsr      display_dos_error
                    moveq    #ERROR,d0
                    rts
lbC0215A8:
                    moveq    #OK,d0
                    rts
lbC0215AC:
                    lea      (OK_Samples),a4
                    lea      (OK_SampleTab),a5
                    moveq    #36-1,d7
lbC0215BA:
                    move.l   (a5),d0
                    beq.b    lbC021606
                    move.l   d0,a0
                    move.l   (20,a4),d0
                    andi.l   #$FFFFFFFE,d0
                    beq.b    lbC021606
                    move.l   a0,(lbL01B720)
                    move.l   d0,(lbL01B724)
                    lea      (lbL01B710),a0
                    move.l   #'SBOD',(a0)
                    move.l   d0,(4,a0)
                    moveq    #8,d0
                    jsr      (write_to_file)
                    bmi.b    lbC021614
                    move.l   (lbL01B720),a0
                    move.l   (lbL01B724),d0
                    jsr      (write_to_file)
                    bmi.b    lbC021614
lbC021606:
                    lea      (32,a4),a4
                    addq.w   #8,a5
                    dbra     d7,lbC0215BA
                    moveq    #OK,d0
                    rts
lbC021614:
                    bsr      display_dos_error
                    moveq    #ERROR,d0
                    rts
lbC02161C:
                    move.l   d0,-(sp)
                    move.w   (current_sample,pc),d0
                    lea      (OK_SampleTab),a0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    move.l   (sp)+,d0
                    rts
lbC021630:
                    lea      (OK_SampleTab),a0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    rts
lbC02163C:
                    bsr      lbC021650
                    beq.b    lbC02164A
                    bsr      ask_are_you_sure_requester
                    beq.b    do_free_all_samples
                    rts
lbC02164A:
                    bra      error_what_samples
lbC021650:
                    lea      (OK_SampleTab),a0
                    moveq    #36-1,d0
lbC021658:
                    tst.l    (a0)+
                    bne.b    lbC021668
                    tst.l    (a0)+
                    bne.b    lbC021668
                    dbra     d0,lbC021658
                    moveq    #OK,d0
                    rts
lbC021668:
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
do_free_all_samples:
                    clr.w    (current_sample)
.loop:
                    bsr.b    do_free_sample
                    addq.w   #1,(current_sample)
                    cmpi.w   #36,(current_sample)
                    bne.b    .loop
                    clr.w    (current_sample)
                    bra      lbC01FBF2

; ===========================================================================
lbC02168E:
                    bsr.b    lbC02161C
                    tst.l    (a0)
                    beq      error_what_sample
                    bsr      ask_are_you_sure_requester
                    beq.b    do_free_sample
                    rts

; ===========================================================================
do_free_sample:
                    bsr.b    lbC0216BE
                    bsr      lbC01FF8C
                    lea      (OK_Samples),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    moveq    #8-1,d0
lbC0216B4:
                    clr.l    (a0)+
                    dbra     d0,lbC0216B4
                    bra      lbC01FBF2
lbC0216BE:
                    bsr      lbC02161C
                    tst.l    (a0)
                    beq.b    lbC0216DA
                    move.l   (a0),a1
                    clr.l    (a0)+
                    move.l   (a0),d0
                    clr.l    (a0)+
                    EXEC     FreeMem
lbC0216DA:
                    rts

; ===========================================================================
lbC0216DC:
                    bsr      lbC02161C
                    move.l   (a0)+,(lbL021778)
                    beq      error_what_sample
                    tst.l    (a0)+
                    beq      error_what_sample
                    lea      (CopyToSample_MSG,pc),a0
                    bsr      lbC024876
                    bmi.b    lbC021762
                    cmp.w    (current_sample,pc),d0
                    beq      error_same_sample
                    move.w   (current_sample,pc),d1
                    move.w   d1,(lbW02177C)
                    move.w   d0,(current_sample)
                    bsr      lbC02161C
                    tst.l    (a0)
                    beq.b    lbC021720
                    bsr      ask_are_you_sure_requester
                    bne.b    lbC02175A
lbC021720:
                    lea      (OK_Samples),a0
                    move.l   a0,a1
                    lsl.w    #5,d1
                    adda.w   d1,a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a1
                    move.l   (20,a0),d0
                    moveq    #8-1,d2
lbC02173A:
                    move.l   (a0)+,(a1)+
                    dbra     d2,lbC02173A
                    bsr      lbC021F9E
                    bmi.b    lbC02175A
                    bsr      lbC02161C
                    move.l   (a0)+,a1
                    move.l   (a0),d0
                    move.l   (lbL021778,pc),a0
lbC021752:
                    subq.l   #1,d0
                    bmi.b    lbC02175A
                    move.b   (a0)+,(a1)+
                    bra.b    lbC021752
lbC02175A:
                    move.w   (lbW02177C,pc),(current_sample)
lbC021762:
                    bra      lbC01FBF2
CopyToSample_MSG:
                    dc.b     ' Copy To Sample:',0
                    even
lbL021778:
                    dc.l     0
lbW02177C:
                    dc.w     0
lbC02177E:
                    lea      (OK_Samples),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    move.w   (30,a0),(lbW01BC68)
                    bsr      lbC02161C
                    move.l   (a0)+,(lbL01BC60)
                    beq      error_what_sample
                    move.l   (a0)+,(lbL01BC64)
                    beq      error_what_sample
                    move.l   (lbL01A130),d0
                    beq      error_what_sample
                    lea      (MixWithSample_MSG,pc),a0
                    bsr      lbC024876
                    bmi      lbC021888
                    cmp.w    (current_sample,pc),d0
                    beq      error_same_sample
                    move.w   (current_sample,pc),(lbW01BC5E)
                    move.w   d0,(current_sample)
                    bsr      lbC02161C
                    tst.l    (a0)+
                    beq      lbC021874
                    tst.l    (a0)+
                    beq      lbC021874
                    lea      (OK_Samples),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    move.w   (30,a0),d0
                    cmp.w    (lbW01BC68),d0
                    bne.b    lbC02187A
                    bsr      ask_are_you_sure_requester
                    bne.b    lbC02187E
                    bsr      lbC02161C
                    move.l   (4,a0),d0
                    cmp.l    (lbL01A134),d0
                    blt.b    lbC02181E
                    bsr      lbC01FFC0
                    bmi.b    lbC02187E
lbC02181E:
                    bsr      lbC02161C
                    move.l   (4,a0),d0
                    move.l   (a0),a0
                    move.l   (lbL01BC60),a1
                    move.l   (lbL01BC64),d1
                    move.l   (lbL01A130),a2
                    move.l   (lbL01A134),d2
lbC021840:
                    subq.l   #1,d2
                    bmi.b    lbC021860
                    moveq    #0,d3
                    subq.l   #1,d0
                    bmi.b    lbC02184E
                    move.b   (a0)+,d3
                    ext.w    d3
lbC02184E:
                    moveq    #0,d4
                    subq.l   #1,d1
                    bmi.b    lbC021858
                    move.b   (a1)+,d4
                    ext.w    d4
lbC021858:
                    add.w    d4,d3
                    asr.w    #1,d3
                    move.b   d3,(a2)+
                    bra.b    lbC021840
lbC021860:
                    move.w   (lbW01BC5E),(current_sample)
                    jsr      (lbC028324)
                    bra      lbC01FBF2
lbC021874:
                    bsr      error_what_sample
                    bra.b    lbC02187E
lbC02187A:
                    bsr      error_different_modes
lbC02187E:
                    move.w   (lbW01BC5E),(current_sample)
lbC021888:
                    rts
MixWithSample_MSG:
                    dc.b     'Mix With Sample:',0
                    even
lbC02189C:
                    lea      (SwapWith_MSG,pc),a0
                    bsr      lbC024876
                    bmi      lbC021908
                    move.w   d0,(lbW02190A)
                    cmp.w    (current_sample,pc),d0
                    beq      error_same_sample
                    move.w   (current_sample,pc),d0
                    bsr      lbC021630
                    move.l   a0,a3
                    move.w   (lbW02190A,pc),d0
                    bsr      lbC021630
                    move.l   a0,a5
                    lea      (OK_Samples),a4
                    move.l   a4,a2
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a4
                    move.w   (lbW02190A,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a2
                    movem.l  (a3),d0/d1
                    movem.l  (a5),d2/d3
                    movem.l  d0/d1,(a5)
                    movem.l  d2/d3,(a3)
                    moveq    #8-1,d2
lbC0218F4:
                    move.l   (a4),d0
                    move.l   (a2),d1
                    move.l   d0,(a2)+
                    move.l   d1,(a4)+
                    dbra     d2,lbC0218F4
                    bsr      lbC02001C
                    bra      lbC01FBF2
lbC021908:
                    rts
lbW02190A:
                    dc.w     0
SwapWith_MSG:
                    dc.b     'Swap With .....:',0
                    even
lbC02191E:
                    lea      (lbC02192A,pc),a0
                    move.l   a0,(current_cmd_ptr)
                    rts
lbC02192A:
                    lea      (LoadSamples_MSG,pc),a0
                    moveq    #DIR_SAMPLES,d0
                    jsr      (lbC026ACC)
                    bgt.b    lbC02193C
                    moveq    #ERROR,d0
                    rts
lbC02193C:
                    clr.w    (lbW0219F8)
                    cmpi.w   #1,d0
                    seq      (lbB021A1E)
                    move.w   d0,(lbW0219FA)
                    move.w   (current_sample,pc),(lbW0219F6)
lbC02195A:
                    move.w   (lbW0219F8,pc),d0
                    jsr      (lbC026CF2)
                    bmi.b    lbC0219E0
                    movem.l  a0/a1,-(sp)
                    jsr      (lbC025C1A)
                    movem.l  (sp)+,a0/a1
                    bmi.b    lbC0219DC
                    tst.b    (lbB021A1E)
                    bne.b    lbC0219B6
lbC02197E:
                    movem.l  d0/a0/a1,-(sp)
                    bsr      lbC02161C
                    tst.l    (a0)
                    movem.l  (sp)+,d0/a0/a1
                    beq.b    lbC0219B6
                    movem.l  d0/a0/a1,-(sp)
                    lea      (Overwrite_MSG,pc),a0
                    bsr      ask_yes_no_requester
                    movem.l  (sp)+,d0/a0/a1
                    beq.b    lbC0219B0
                    movem.l  d0/a0/a1,-(sp)
                    bsr      lbC021E38
                    movem.l  (sp)+,d0/a0/a1
                    bpl.b    lbC02197E
                    bra.b    lbC0219E0
lbC0219B0:
                    st       (lbB021A1E)
lbC0219B6:
                    bsr      lbC021A20
                    bmi.b    lbC0219E0
                    addq.w   #1,(lbW0219F8)
                    move.w   (lbW0219FA,pc),d0
                    cmp.w    (lbW0219F8,pc),d0
                    beq.b    lbC0219D4
                    bsr      lbC021E38
                    bpl.b    lbC02195A
                    bra.b    lbC0219E0
lbC0219D4:
                    bsr      lbC0219E8
                    moveq    #OK,d0
                    rts
lbC0219DC:
                    bsr      display_dos_error
lbC0219E0:
                    bsr      lbC0219E8
                    moveq    #ERROR,d0
                    rts
lbC0219E8:
                    jsr      (lbC026D24)
                    move.w   (lbW0219F6,pc),d0
                    bra      lbC021E2A
lbW0219F6:
                    dc.w     0
lbW0219F8:
                    dc.w     0
lbW0219FA:
                    dc.w     0
LoadSamples_MSG:
                    dc.b     'Load Sample(s)',0
Overwrite_MSG:
                    dc.b     '   Overwrite ??   ',0
lbB021A1E:
                    dc.b     0
                    even
lbC021A20:
                    move.l   a0,(lbL021C16)
                    move.l   a1,(lbL021C1A)
                    sf       (lbB021C04)
                    clr.w    (lbW021C0A)
                    clr.w    (lbW021C0C)
                    cmpi.l   #2,d0
                    bge.b    lbC021A4E
                    bsr      error_sample_too_short
                    bra      lbC021BC2
lbC021A4E:
                    move.l   d0,(lbL021C06)
                    move.l   (lbL021C16,pc),a0
                    jsr      (open_file_for_reading)
                    bmi      lbC021BBA
                    lea      (lbL021BF0,pc),a0
                    moveq    #12,d0
                    jsr      (read_from_file)
                    bmi      lbC021BBA
                    lea      (lbL021BF0,pc),a0
                    cmpi.l   #'FORM',(a0)
                    bne.b    lbC021AE2
                    cmpi.l   #'8SVX',(8,a0)
                    bne      lbC021BAE
                    lea      (VHDR_MSG,pc),a0
                    bsr      lbC021364
                    bmi      lbC021BA6
                    lea      (lbL021BF0,pc),a0
                    cmpi.b   #1,(14,a0)
                    bne      lbC021BAE
                    tst.b    (15,a0)
                    bne      lbC021BAE
                    move.l   (a0)+,d0
                    lsr.l    #1,d0
                    move.w   d0,(lbW021C0A)
                    move.l   (a0)+,d0
                    lsr.l    #1,d0
                    move.w   d0,(lbW021C0C)
                    bne.b    lbC021AC8
                    clr.w    (lbW021C0A)
lbC021AC8:
                    move.l   #'BODY',d0
                    bsr      lbC021C1E
                    bmi      lbC021BA6
                    move.l   d0,(lbL021C06)
                    st       (lbB021C04)
lbC021AE2:
                    move.l   (lbL021C06,pc),d0
                    cmpi.l   #131070,d0
                    bls.b    lbC021AF8
                    bsr      error_sample_clipped
                    move.l   #131070,d0
lbC021AF8:
                    cmpi.l   #2,d0
                    bcc.b    lbC021B08
                    bsr      error_sample_too_short
                    bra      lbC021BA6
lbC021B08:
                    lea      (OK_Samples),a0
                    move.w   (current_sample,pc),d2
                    lsl.w    #5,d2
                    move.w   (samples_load_mode),(30,a0,d2.w)
                    bsr      lbC021F9E
                    bmi      lbC021BA6
                    move.l   d0,(lbL021C0E)
                    move.l   d1,(lbL021C12)
                    move.l   (lbL021C1A,pc),a0
                    lea      (OK_Samples),a1
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a1
                    moveq    #20-1,d0
lbC021B44:
                    move.b   (a0)+,(a1)+
                    dbra     d0,lbC021B44
                    move.l   d1,(a1)+
                    move.w   (lbW021C0A,pc),(a1)+
                    move.w   (lbW021C0C,pc),(a1)+
                    move.w   #64,(a1)+
                    move.w   (samples_load_mode),(a1)+
                    move.b   (lbB021C04,pc),d0
                    beq.b    lbC021B76
                    move.l   (lbL021C0E,pc),a0
                    move.l   (lbL021C12,pc),d0
                    jsr      (read_from_file)
                    bmi.b    lbC021BBA
                    bra.b    lbC021B90
lbC021B76:
                    jsr      (close_file)
                    move.l   (lbL021C16,pc),a0
                    move.l   (lbL021C0E,pc),a1
                    move.l   (lbL021C12,pc),d0
                    jsr      (load_file)
                    bmi.b    lbC021BBA
lbC021B90:
                    cmpi.w   #1,(samples_load_mode)
                    beq.b    lbC021BA6
                    move.l   (lbL021C0E,pc),a0
                    move.l   (lbL021C12,pc),d0
                    bsr      lbC021F62
lbC021BA6:
                    bsr      lbC021BCE
                    moveq    #OK,d0
                    rts
lbC021BAE:
                    jsr      (close_file)
                    bsr      error_iff_struct_error
                    bra.b    lbC021BC2
lbC021BBA:
                    bsr      display_dos_error
lbC021BC2:
                    bsr      do_free_sample
                    bsr      lbC021BCE
                    moveq    #ERROR,d0
                    rts
lbC021BCE:
                    jsr      (close_file)
                    bsr      lbC02001C
                    bra      lbC01FBF2
VHDR_MSG:
                    dc.b     'VHDR'
                    dc.l     20
                    dc.l     lbL021BF0
                    dc.l     0
                    dc.l     0
lbL021BF0:
                    dcb.l    5,0
lbB021C04:
                    dc.b     0
                    even
lbL021C06:
                    dc.l     0
lbW021C0A:
                    dc.w     0
lbW021C0C:
                    dc.w     0
lbL021C0E:
                    dc.l     0
lbL021C12:
                    dc.l     0
lbL021C16:
                    dc.l     0
lbL021C1A:
                    dc.l     0
lbC021C1E:
                    movem.l  d5-d7/a3,-(sp)
                    moveq    #0,d6
                    move.l   d0,d7
                    lea      (lbL021C6A,pc),a3
lbC021C2A:
                    move.l   a3,a0
                    moveq    #8,d0
                    jsr      (read_from_file)
                    bmi.b    lbC021C54
                    addq.l   #8,d6
                    move.l   (a3),d1
                    move.l   (4,a3),d0
                    cmp.l    d7,d1
                    beq.b    lbC021C50
                    move.l   d0,d5
                    jsr      (move_in_file)
                    bmi.b    lbC021C54
                    add.l    d5,d6
                    bra.b    lbC021C2A
lbC021C50:
                    tst.l    d0
                    bra.b    lbC021C64
lbC021C54:
                    bsr      display_dos_error
                    neg.l    d6
                    move.l   d6,d0
                    jsr      (move_in_file)
                    moveq    #ERROR,d0
lbC021C64:
                    movem.l  (sp)+,d5-d7/a3
                    rts
lbL021C6A:
                    dcb.b    8,0
lbC021C72:
                    tst.l    (lbL01A130)
                    beq      error_what_sample
                    tst.l    (lbL01A134)
                    beq      error_what_sample
                    move.l   #lbC021C92,(current_cmd_ptr)
                    rts
lbC021C92:
                    lea      (OK_Samples),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    jsr      (lbC026E36)
                    lea      (SaveSample_MSG,pc),a0
                    moveq    #DIR_SAMPLES,d0
                    jsr      (display_file_requester)
                    bmi      lbC021DA2
                    lea      (OK_Samples+30),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    cmpi.w   #1,(a0,d0.w)
                    beq.b    lbC021CDA
                    move.l   (lbL01A130),a0
                    move.l   (lbL01A134),d0
                    bsr      lbC021F90
lbC021CDA:
                    tst.w    (samples_save_format)
                    bne      lbC021D88
                    lea      (filename_to_load),a0
                    jsr      (open_file_for_writing)
                    bmi      lbC021DB0
                    move.l   (lbL01A134),d0
                    moveq    #-2,d1
                    and.l    d1,d0
                    move.l   d0,(lbL021E1A)
                    addi.l   #96,d0
                    move.l   d0,(ascii_MSG60)
                    lea      (OK_Samples),a0
                    lea      (ascii_MSG62,pc),a1
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    move.l   a0,a2
                    moveq    #19-1,d0
lbC021D26:
                    move.b   (a0)+,(a1)+
                    dbra     d0,lbC021D26
                    sf       (a1)+
                    moveq    #0,d0
                    move.w   (24,a2),d0
                    add.l    d0,d0
                    move.l   d0,(lbL021DCA)
                    moveq    #0,d1
                    move.w   (26,a2),d1
                    add.l    d1,d1
                    move.l   d1,(ascii_MSG61)
                    beq.b    lbC021D54
                    add.l    d1,d0
                    cmp.l    (lbL021E1A,pc),d0
                    ble.b    lbC021D64
lbC021D54:
                    move.l   (lbL021E1A),(lbL021DCA)
                    clr.l    (ascii_MSG61)
lbC021D64:
                    lea      (FORM_MSG,pc),a0
                    moveq    #104,d0
                    jsr      (write_to_file)
                    bmi.b    lbC021DB0
                    move.l   (lbL01A130),a0
                    move.l   (lbL021E1A),d0
                    jsr      (write_to_file)
                    bmi.b    lbC021DB0
                    bra.b    lbC021DA2
lbC021D88:
                    lea      (filename_to_load),a0
                    move.l   (lbL01A130),a1
                    move.l   (lbL01A134),d0
                    jsr      (save_file)
                    bmi.b    lbC021DB0
lbC021DA2:
                    jsr      (close_file)
                    bsr      lbC02001C
                    bra      lbC01FBF2
lbC021DB0:
                    bsr      display_dos_error
                    bra.b    lbC021DA2
FORM_MSG:
                    dc.b     'FORM'
ascii_MSG60:
                    dc.l     0
                    dc.b     '8SVXVHDR'
                    dc.l     20
lbL021DCA:
                    dc.l     0
ascii_MSG61:
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     $20,$20,$AB,1,0,0,1,0,0
                    dc.b     'NAME'
                    dc.l     20
ascii_MSG62:
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     'ANNO'
                    dc.l     20
                    dc.b     'Oktalyzer',0,0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     0
                    dc.b     'BODY'
lbL021E1A:
                    dc.l     0
SaveSample_MSG:
                    dc.b     'Save Sample',0
lbC021E2A:
                    move.w   d0,(current_sample)
                    bsr      lbC02001C
                    bra      lbC01FBF2
lbC021E38:
                    lea      (current_sample,pc),a0
                    cmpi.w   #35,(a0)
                    beq      error_no_more_samples
                    addq.w   #1,(a0)
                    bsr      lbC02001C
                    bsr      lbC01FBF2
                    moveq    #0,d0
                    rts
current_sample:
                    dc.b     0
lbB021E53:
                    dc.b     0
lbC021E54:
                    lea      (current_sample,pc),a0
                    tst.w    (a0)
                    beq      error_no_more_samples
                    subq.w   #1,(a0)
                    bsr      lbC02001C
                    bsr      lbC01FBF2
                    moveq    #0,d0
                    rts
lbC021E6C:
                    lea      (OK_Samples+28),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    cmpi.w   #64,(a0)
                    beq.b    lbC021E86
                    addq.w   #1,(a0)
                    bra      lbC01FBF2
lbC021E86:
                    rts
lbC021E88:
                    lea      (OK_Samples+28),a0
                    move.w   (current_sample,pc),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    tst.w    (a0)
                    beq.b    lbC021EA0
                    subq.w   #1,(a0)
                    bra      lbC01FBF2
lbC021EA0:
                    rts
lbC021EA2:
                    tst.l    (lbL01A130)
                    beq      error_what_sample
                    tst.l    (lbL01A134)
                    beq      error_what_sample
                    lea      (OK_Samples+30),a5
                    move.w   (current_sample,pc),d1
                    lsl.w    #5,d1
                    adda.w   d1,a5
                    move.w   (a5),d0
                    bne      lbC021ED8
                    bsr      lbC021F70
                    addq.w   #1,(a5)
                    bra      lbC021EE6
lbC021ED8:
                    cmp.w    #1,d0
                    bne      lbC021EE6
                    bsr      lbC021F46
                    addq.w   #1,(a5)
lbC021EE6:
                    jsr      (lbC028324)
                    bsr      lbC01FBF2
                    moveq    #0,d0
                    rts
lbC021EF4:
                    tst.l    (lbL01A130)
                    beq      error_what_sample
                    tst.l    (lbL01A134)
                    beq      error_what_sample
                    lea      (OK_Samples+30),a5
                    move.w   (current_sample,pc),d1
                    lsl.w    #5,d1
                    adda.w   d1,a5
                    move.w   (a5),d0
                    cmp.w    #2,d0
                    bne      lbC021F2A
                    bsr      lbC021F70
                    subq.w   #1,(a5)
                    bra      lbC021F38
lbC021F2A:
                    cmp.w    #1,d0
                    bne      lbC021F38
                    bsr      lbC021F46
                    subq.w   #1,(a5)
lbC021F38:
                    jsr      (lbC028324)
                    bsr      lbC01FBF2
                    moveq    #0,d0
                    rts
lbC021F46:
                    bsr      stop_audio_channels
                    move.l   (lbL01A130),a0
                    move.l   (lbL01A134),d0
                    bsr.b    lbC021F62
                    jsr      (lbC028324)
                    bra      lbC01FBF2
lbC021F62:
                    subq.l   #1,d0
                    bmi.b    lbC021F6E
                    move.b   (a0),d1
                    asr.b    #1,d1
                    move.b   d1,(a0)+
                    bra.b    lbC021F62
lbC021F6E:
                    rts
lbC021F70:
                    bsr      stop_audio_channels
                    move.l   (lbL01A130),a0
                    move.l   (lbL01A134),d0
                    bsr.b    lbC021F90
                    jsr      (lbC028324)
                    bsr      lbC01FBF2
                    bra      error_left_one_bit
lbC021F90:
                    subq.l   #1,d0
                    bmi.b    lbC021F9C
                    move.b   (a0),d1
                    add.b    d1,d1
                    move.b   d1,(a0)+
                    bra.b    lbC021F90
lbC021F9C:
                    rts
lbC021F9E:
                    move.l   d0,-(sp)
                    bsr      lbC0216BE
                    move.l   (sp),d0
                    lea      (OK_Samples),a0
                    move.w   (current_sample,pc),d2
                    lsl.w    #5,d2
                    adda.w   d2,a0
                    move.l   a0,(lbL021FFC)
                    moveq    #2,d1
                    tst.w    (30,a0)
                    bne.b    lbC021FC4
                    moveq    #0,d1
lbC021FC4:
                    ori.l    #$10000,d1
                    EXEC     AllocMem
                    move.l   (sp)+,d1
                    tst.l    d0
                    beq.b    lbC021FF0
                    bsr      lbC02161C
                    move.l   d0,(a0)+
                    move.l   d1,(a0)+
                    move.l   (lbL021FFC,pc),a0
                    move.l   d1,(20,a0)
                    tst.l    d0
                    rts
lbC021FF0:
                    bsr      error_no_memory
                    bsr      do_free_sample
                    moveq    #ERROR,d0
                    rts
lbL021FFC:
                    dc.l     0
lbC022000:
                    cmpi.w   #15,(OK_Speed)
                    beq.b    lbC022010
                    addq.w   #1,(OK_Speed)
lbC022010:
                    bra      lbC01FBF2
lbC022014:
                    cmpi.w   #1,(OK_Speed)
                    beq.b    lbC022024
                    subq.w   #1,(OK_Speed)
lbC022024:
                    bra      lbC01FBF2
lbC022028:
                    move.w   (OK_PLen),d0
                    subq.w   #1,d0
                    cmp.w    (current_song_position),d0
                    beq      error_no_more_positions
                    addq.w   #1,(current_song_position)
                    bra      lbC01FBF2
lbC022044:
                    tst.w    (current_song_position)
                    beq      error_no_more_positions
                    subq.w   #1,(current_song_position)
                    bra      lbC01FBF2
lbC022058:
                    lea      (OK_Patterns),a0
                    move.w   (current_song_position),d0
                    move.w   (lbW01BC6E),d1
                    subq.w   #1,d1
                    cmp.b    (a0,d0.w),d1
                    beq      error_no_more_patterns
                    addq.b   #1,(a0,d0.w)
                    bra      lbC01FBF2
lbC02207C:
                    lea      (OK_Patterns),a0
                    move.w   (current_song_position),d0
                    tst.b    (a0,d0.w)
                    beq      error_no_more_patterns
                    subq.b   #1,(a0,d0.w)
                    bra      lbC01FBF2
lbC022098:
                    cmpi.w   #1,(OK_PLen)
                    beq      error_no_more_positions
                    subq.w   #1,(OK_PLen)
                    move.w   (OK_PLen),d0
                    lea      (OK_Patterns),a0
                    sf       (a0,d0.w)
                    cmp.w    (current_song_position),d0
                    bne      lbC01FBF2
                    subq.w   #1,(current_song_position)
                    bra      lbC01FBF2
lbC0220CE:
                    cmpi.w   #128,(OK_PLen)
                    beq      error_no_more_positions
                    addq.w   #1,(OK_PLen)
                    bra      lbC01FBF2
lbC0220E4:
                    cmpi.w   #128,(OK_PLen)
                    beq      error_no_more_positions
                    lea      (OK_Patterns,pc),a0
                    adda.w   (current_song_position),a0
                    lea      (OK_Patterns+127,pc),a1
lbC0220FE:
                    cmpa.l   a0,a1
                    beq.b    lbC022108
                    move.b   -(a1),(1,a1)
                    bra.b    lbC0220FE
lbC022108:
                    sf       (a0)
                    bra.b    lbC0220CE
lbC02210C:
                    cmpi.w   #1,(OK_PLen)
                    beq      error_no_more_positions
                    lea      (OK_Patterns,pc),a0
                    adda.w   (current_song_position),a0
                    lea      (OK_Patterns+127,pc),a1
lbC022126:
                    cmpa.l   a1,a0
                    beq.b    lbC022130
                    move.b   (1,a0),(a0)+
                    bra.b    lbC022126
lbC022130:
                    sf       (a0)
                    bra      lbC022098
lbC022136:
                    move.w   (lbW01BC6E),d0
                    subq.w   #1,d0
                    lea      (OK_Patterns,pc),a0
                    moveq    #128-1,d1
lbC022144:
                    cmp.b    (a0)+,d0
                    dbeq     d1,lbC022144
                    beq      error_pattern_in_use
                    cmp.w    (current_viewed_pattern),d0
                    bne.b    lbC022160
                    subq.w   #1,(current_viewed_pattern)
                    bsr      lbC0202A8
lbC022160:
                    bsr      lbC020266
                    bra      lbC01FBF2
lbC022168:
                    bra      lbC020112
lbC02216C:
                    moveq    #-1,d0
                    bra.b    lbC022172
lbC022170:
                    moveq    #1,d0
lbC022172:
                    move.w   d0,d1
                    bsr      get_current_pattern_rows
                    move.w   d0,(lbW0221DC)
                    add.w    d1,d0
                    cmpi.w   #1,d0
                    bpl.b    lbC022188
                    moveq    #1,d0
lbC022188:
                    cmpi.w   #128,d0
                    ble.b    lbC022192
                    move.w   #128,d0
lbC022192:
                    move.w   d0,-(sp)
                    bsr      lbC02016E
                    movem.w  (sp)+,d0
                    bmi.b    lbC0221DA
                    move.w   d0,d1
                    move.w   (lbW0221DC,pc),d0
lbC0221A4:
                    cmp.w    d0,d1
                    beq.b    lbC0221CA
                    blt.b    lbC0221BA
                    movem.w  d0/d1,-(sp)
                    bsr      lbC0203C6
                    movem.w  (sp)+,d0/d1
                    addq.w   #1,d0
                    bra.b    lbC0221A4
lbC0221BA:
                    subq.w   #1,d0
                    movem.w  d0/d1,-(sp)
                    bsr      lbC0203DC
                    movem.w  (sp)+,d0/d1
                    bra.b    lbC0221A4
lbC0221CA:
                    bsr      lbC01F200
                    bsr      lbC01F1D8
                    bsr      set_pattern_bitplane
                    bra      lbC01FBF2
lbC0221DA:
                    rts
lbW0221DC:
                    dc.w     0

; ===========================================================================
decrease_replay_type:
                    lea      (replay_type,pc),a0
                    subq.w   #1,(a0)
                    bpl.b    .reset
                    move.w   #1,(a0)
.reset:
                    bra      draw_replay_type

; ===========================================================================
increase_replay_type:
                    lea      (replay_type,pc),a0
                    addq.w   #1,(a0)
                    cmpi.w   #2,(a0)
                    bne.b    .reset
                    clr.w    (a0)
.reset:
                    bra      draw_replay_type
replay_type:
                    dc.w     1

; ===========================================================================
lbC022202:
                    st       (channels_mute_flags)
                    bra      lbC01FBF2
lbC02220C:
                    sf       (channels_mute_flags)
                    bra      lbC01FBF2
lbC022216:
                    bchg     d0,(channels_mute_flags)
                    bra      lbC01FBF2
lbC022220:
                    moveq    #7,d0
                    bra.b    lbC022216
lbC022224:
                    moveq    #6,d0
                    bra.b    lbC022216
lbC022228:
                    moveq    #5,d0
                    bra.b    lbC022216
lbC02222C:
                    moveq    #4,d0
                    bra.b    lbC022216
lbC022230:
                    moveq    #3,d0
                    bra.b    lbC022216
lbC022234:
                    moveq    #2,d0
                    bra.b    lbC022216
lbC022238:
                    moveq    #1,d0
                    bra.b    lbC022216
lbC02223C:
                    moveq    #0,d0
                    bra.b    lbC022216

; ===========================================================================
play_song:
                    st       (pattern_play_flag)
                    move.w   (current_song_position),(OK_PtPtr)
                    bra.b    go_play
play_pattern:
                    sf       (pattern_play_flag)
                    move.w   (current_viewed_pattern),(OK_PtPtr)
go_play:
                    tst.w    (replay_type)
                    bne.b    .ok_replay_type
                    tst.b    (ntsc_flag)
                    beq.b    .ok_replay_type
                    bra      error_only_in_pal
.ok_replay_type:
                    bsr      lbC01FF8C
                    move.w   (replay_type,pc),d0
                    add.w    d0,d0
                    lea      (lbW022332,pc),a0
                    move.w   (a0,d0.w),d0
                    jsr      (a0,d0.w)
                    bmi      lbC022310
                    lea      (replay_int,pc),a0
                    bsr      install_copper_int
                    bsr      lbC022A2C
                    lea      (lbW022318,pc),a0
                    bsr      lbC02062A
                    bsr      lbC022A2C
                    bsr      remove_copper_int
                    bsr      stop_audio_channels
                    bsr      clear_vumeters
                    bsr      show_pattern_position_bar
                    move.w   (replay_type,pc),d0
                    add.w    d0,d0
                    move.w   (lbW022336,pc,d0.w),d0
                    jsr      (lbW022336,pc,d0.w)
                    move.w   (OK_ActSpeed),(OK_Speed)
                    tst.b    (pattern_play_flag)
                    beq.b    lbC0222E4
                    move.w   (OK_PtPtr),(current_song_position)
                    bra.b    lbC02230C
lbC0222E4:
                    cmpi.b   #2,(lbB01BC6B)
                    bne.b    lbC02230C
                    move.w   (lbW01B2B6),d0
                    bmi.b    lbC02230C
                    mulu.w   #5,d0
                    move.w   d0,(caret_pos_x)
                    move.w   (OK_PattY,pc),d0
                    bmi.b    lbC02230C
                    move.w   d0,(viewed_pattern_row)
lbC02230C:
                    bsr      lbC01F1D8
lbC022310:
                    bsr      lbC02001C
                    bra      lbC01FBF2
lbW022318:
                    dc.w     1
                    dc.l     lbC0225F6
                    dc.w     2
                    dc.l     lbC02262A
                    dc.w     4
                    dc.l     lbC022612
                    dc.w     7
                    dc.l     lbC02261E
                    dc.w     0
lbW022332:
                    dc.w     lbC02233A-lbW022332,lbC022386-lbW022332
lbW022336:
                    dc.w     lbC02236A-lbW022336,lbC022396-lbW022336
lbC02233A:
                    move.l   #43252,d0
                    moveq    #0,d1
                    EXEC     AllocMem
                    tst.l    d0
                    bne.b    lbC022356
                    bra      error_no_memory
lbC022356:
                    move.l   d0,(lbL022382)
                    move.l   d0,a0
                    bsr      lbC023892
                    moveq    #0,d0
                    rts
lbC02236A:
                    move.l   (lbL022382,pc),a1
                    move.l   #43252,d0
                    EXEC     FreeMem
                    rts
lbL022382:
                    dc.l     0
lbC022386:
                    move.b   (ntsc_flag,pc),d0
                    bsr      lbC023E28
                    moveq    #0,d0
                    rts
lbC022396:
                    rts
lbC022398:
                    move.l   #lbC0223A4,(current_cmd_ptr)
                    rts
lbC0223A4:
                    lea      (play_help_text),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    bra      lbC0246B8
lbC0225F6:
                    btst     #15,d1
                    bne.b    lbC022608
                    cmpi.w   #96,d1
                    beq.b    lbC02261E
                    cmpi.w   #5,d1
                    beq.b    lbC022612
lbC022608:
                    move.w   d1,(lbW022638)
                    moveq    #ERROR,d0
                    rts
lbC022612:
                    move.b   #1,(lbB01BC6B)
                    moveq    #OK,d0
                    rts
lbC02261E:
                    move.b   #2,(lbB01BC6B)
                    moveq    #OK,d0
                    rts
lbC02262A:
                    tst.w    d2
                    beq.b    lbC022634
                    move.b   d1,(lbW02263A)
lbC022634:
                    moveq    #ERROR,d0
                    rts
lbW022638:
                    dc.w     0
lbW02263A:
                    dc.w     0

; ===========================================================================
replay_int:
                    movem.l  d1-d7/a0-a6,-(sp)
                    move.w   (replay_type,pc),d0
                    add.w    d0,d0
                    move.w   (replay_table,pc,d0.w),d0
                    jsr      (replay_table,pc,d0.w)
                    movem.l  (sp)+,d1-d7/a0-a6
                    moveq    #0,d0
                    rts
replay_table:
                    dc.w     OK_Play_1-replay_table,OK_Play_2-replay_table

; ===========================================================================
install_midi_ints:
                    movem.l  d0/d1/a0/a1,-(sp)
                    EXEC     Disable
                    move.w   (_CUSTOM|INTENAR),d0
                    and.w    #INTF_RBF,d0
                    move.w   d0,(old_serial_receive_intena)
                    ; baudrate
                    move.w   #114,(_CUSTOM|SERPER)
                    sf       (lbW0228E2)
                    lea      (midi_in_int_struct,pc),a1
                    moveq    #INTB_RBF,d0
                    EXEC     SetIntVector
                    move.l   d0,(old_midi_in_int)
                    move.w   #INTF_SETCLR|INTF_RBF,(_CUSTOM|INTENA)
                    move.w   #INTF_RBF,(_CUSTOM|INTREQ)
                    move.w   (_CUSTOM|INTENAR),d0
                    and.w    #INTF_TBE,d0
                    move.w   d0,(old_serial_transmit_intena)
                    ; baudrate
                    move.w   #114,(_CUSTOM|SERPER)
                    clr.w    (lbW022A20)
                    clr.w    (lbW022A22)
                    sf       (lbB022A24)
                    lea      (midi_out_int_struct,pc),a1
                    moveq    #0,d0
                    EXEC     SetIntVector
                    move.l   d0,(old_midi_out_int)
                    move.w   #INTF_SETCLR|INTF_TBE,(_CUSTOM|INTENA)
                    move.w   #INTF_TBE,(_CUSTOM|INTREQ)
                    EXEC     Enable
                    movem.l  (sp)+,d0/d1/a0/a1
                    rts

; ===========================================================================
remove_midi_ints:
                    movem.l  d0/d1/a0/a1,-(sp)
                    EXEC     Disable
                    move.w   #INTF_RBF,(_CUSTOM|INTENA)
                    move.l   (old_midi_in_int),a1
                    moveq    #INTB_RBF,d0
                    EXEC     SetIntVector
                    move.w   (old_serial_receive_intena),d0
                    beq.b    .receive_was_not_active
                    or.w     #INTF_SETCLR,d0
                    move.w   d0,(_CUSTOM|INTENA)
                    move.w   #INTF_RBF,(_CUSTOM|INTREQ)
.receive_was_not_active:
                    move.w   #INTF_TBE,(_CUSTOM|INTENA)
                    move.l   (old_midi_out_int),a1
                    moveq    #0,d0
                    EXEC     SetIntVector
                    move.w   (old_serial_transmit_intena),d0
                    beq.b    .transmit_was_not_active
                    or.w     #INTF_SETCLR,d0
                    move.w   d0,(_CUSTOM|INTENA)
                    move.w   #INTF_TBE,(_CUSTOM|INTREQ)
.transmit_was_not_active:
                    EXEC     Enable
                    movem.l  (sp)+,d0/d1/a0/a1
                    rts
old_midi_in_int:
                    dc.l     0
old_serial_receive_intena:
                    dc.w     0
old_midi_out_int:
                    dc.l     0
old_serial_transmit_intena:
                    dc.w     0
midi_in_int_struct:
                    dc.l     0,0
                    dc.b     2,127
                    dc.l     midi_in_name
                    dc.l     0,receive_bytes_from_ser
midi_in_name:
                    dc.b     'Oktalyzer MidiIn Interrupt',0
                    even
midi_out_int_struct:
                    dc.l     0,0
                    dc.b     2,127
                    dc.l     midi_out_name
                    dc.l     0,transmit_byte_to_ser
midi_out_name:
                    dc.b     'Oktalyzer MidiOut Interrupt',0

; ===========================================================================
receive_bytes_from_ser:
                    move.w   (_CUSTOM|SERDATR),d0
                    move.w   d1,(_CUSTOM|INTREQ)
                    cmpi.b   #MIDI_IN,(midi_mode)
                    bne      lbC0228DC
                    movem.l  d0-d3/a0,-(sp)
                    move.w   (_CUSTOM|SERDATR),d0
                    btst     #7,d0
                    bne.b    lbC02289E
                    cmpi.b   #$90,(lbW0228E2)
                    bne.b    lbC02286E
                    lea      (lbB0228DE,pc),a0
                    adda.w   (lbB0228E0,pc),a0
                    move.b   d0,(a0)
                    bchg     #0,(lbB0228E1)
                    beq      lbC0228D8
                    moveq    #2,d0
                    moveq    #0,d1
                    move.b   (lbB0228DE,pc),d1
                    moveq    #0,d2
                    move.b   (lbB0228DF,pc),d2
                    moveq    #0,d3
                    bsr      lbC0205C4
                    bra.b    lbC0228D8
lbC02286E:
                    cmpi.b   #$80,(lbW0228E2)
                    bne.b    lbC0228D8
                    lea      (lbB0228DE,pc),a0
                    adda.w   (lbB0228E0,pc),a0
                    move.b   d0,(a0)
                    bchg     #0,(lbB0228E1)
                    beq.b    lbC0228D8
                    moveq    #2,d0
                    moveq    #0,d1
                    move.b   (lbB0228DE,pc),d1
                    moveq    #0,d2
                    moveq    #0,d3
                    bsr      lbC0205C4
                    bra.b    lbC0228D8
lbC02289E:
                    cmpi.b   #$90,d0
                    bne.b    lbC0228B2
                    move.b   d0,(lbW0228E2)
                    clr.w    (lbB0228E0)
                    bra.b    lbC0228D8
lbC0228B2:
                    cmp.b    #$80,d0
                    bne.b    lbC0228C6
                    move.b   d0,(lbW0228E2)
                    clr.w    (lbB0228E0)
                    bra.b    lbC0228D8
lbC0228C6:
                    cmpi.b   #$F8,d0
                    beq.b    lbC0228D8
                    cmpi.b   #$FE,d0
                    beq.b    lbC0228D8
                    sf       (lbW0228E2)
lbC0228D8:
                    movem.l  (sp)+,d0-d3/a0
lbC0228DC:
                    rts
lbB0228DE:
                    dc.b     0
lbB0228DF:
                    dc.b     0
lbB0228E0:
                    dc.b     0
lbB0228E1:
                    dc.b     0
lbW0228E2:
                    dc.b     0
                    even

; ===========================================================================
transmit_byte_to_ser:
                    EXEC     Disable
                    move.w   #INTF_TBE,(_CUSTOM|INTREQ)
                    move.w   (_CUSTOM|SERDATR),d0
                    btst     #13,d0
                    beq.b    lbC022960
                    move.w   (lbW022A20,pc),d0
                    cmp.w    (lbW022A22,pc),d0
                    beq.b    lbC022960
                    lea      (lbL01BC70),a1
                    move.w   #$100,d1
                    move.b   (a1,d0.w),d1
                    move.w   d1,(_CUSTOM|SERDAT)
                    addq.w   #1,d0
                    and.w    #$FF,d0
                    move.w   d0,(lbW022A20)
lbC022960:
                    EXEC     Enable
                    rts
lbC02296E:
                    move.l   d2,-(sp)
                    EXEC     Disable
                    move.w   (lbW022A22,pc),d1
                    move.w   d1,d2
                    addq.w   #1,d2
                    and.w    #$FF,d2
                    cmp.w    (lbW022A20,pc),d2
                    beq.b    lbC0229A2
                    lea      (lbL01BC70),a0
                    move.b   d0,(a0,d1.w)
                    move.w   d2,(lbW022A22)
                    bsr      transmit_byte_to_ser
lbC0229A2:
                    EXEC     Enable
                    move.l   (sp)+,d2
                    rts
lbC0229B2:
                    cmp.b    (lbB022A24,pc),d0
                    beq.b    lbC0229C2
                    move.b   d0,(lbB022A24)
                    jmp      (lbC02296E,pc)
lbC0229C2:
                    rts
lbC0229C4:
                    tst.b    d2
                    beq.b    lbC0229FC
                    movem.l  d2/d3,-(sp)
                    move.b   d1,d3
                    and.b    #$F,d0
                    or.b     #$90,d0
                    jsr      (lbC0229B2,pc)
                    move.b   d3,d0
                    add.b    #$2F,d0
                    jsr      (lbC02296E,pc)
                    move.b   d2,d0
                    add.b    d0,d0
                    cmp.b    #$80,d0
                    bcs.b    lbC0229F2
                    move.b   #$7F,d0
lbC0229F2:
                    jsr      (lbC02296E,pc)
                    movem.l  (sp)+,d2/d3
                    rts
lbC0229FC:
                    move.l   d2,-(sp)
                    move.b   d1,d2
                    and.b    #$F,d0
                    or.b     #$80,d0
                    jsr      (lbC0229B2,pc)
                    move.b   d2,d0
                    add.b    #$2F,d0
                    jsr      (lbC02296E,pc)
                    moveq    #0,d0
                    jsr      (lbC02296E,pc)
                    move.l   (sp)+,d2
                    rts
lbW022A20:
                    dc.w     0
lbW022A22:
                    dc.w     0
lbB022A24:
                    dc.b     0
                    even
lbC022A2C:
                    lea      (lbL022A76,pc),a0
                    moveq    #8-1,d0
lbC022A32:
                    clr.w    (4,a0)
                    lea      (6,a0),a0
                    dbra     d0,lbC022A32
                    bra      lbC022A44
lbC022A44:
                    movem.l  d2/a2,-(sp)
                    lea      (lbL022A76,pc),a2
                    moveq    #8-1,d2
lbC022A4E:
                    tst.b    (2,a2)
                    beq.b    lbC022A68
                    subq.w   #1,(4,a2)
                    bpl.b    lbC022A68
                    sf       (2,a2)
                    move.b   (a2),d0
                    move.b   (1,a2),d1
                    jsr      (lbC0229FC,pc)
lbC022A68:
                    lea      (6,a2),a2
                    dbra     d2,lbC022A4E
                    movem.l  (sp)+,d2/a2
                    rts
lbL022A76:
                    dcb.l    12,0
lbC022AA6:
                    tst.b    d2
                    beq      lbC022AEE
                    movem.l  d2-d6/a2,-(sp)
                    move.b   d0,d5
                    move.b   d1,d6
                    lea      (lbL022A76,pc),a2
                    ext.w    d4
                    mulu.w   #6,d4
                    adda.l   d4,a2
                    tst.b    (2,a2)
                    beq      lbC022AD2
                    move.b   (a2),d0
                    move.b   (1,a2),d1
                    jsr      (lbC0229FC,pc)
lbC022AD2:
                    move.b   d5,d0
                    move.b   d6,d1
                    jsr      (lbC0229C4,pc)
                    move.b   d5,(a2)
                    move.b   d6,(1,a2)
                    lsr.l    #6,d3
                    move.w   d3,(4,a2)
                    st       (2,a2)
                    movem.l  (sp)+,d2-d6/a2
lbC022AEE:
                    rts
lbC022AF0:
                    tst.w    (lbW01B2B6)
                    bmi.b    lbC022AFE
                    bsr.b    lbC022B00
                    bra      lbC022B60
lbC022AFE:
                    rts
lbC022B00:
                    cmpi.b   #MIDI_IN,(midi_mode)
                    bne.b    lbC022B5E
                    lea      (lbW02263A,pc),a0
                    move.b   (a0),d0
                    beq.b    lbC022B5E
                    sf       (a0)
                    subi.b   #$30,d0
                    bmi.b    lbC022B24
                    cmpi.b   #$24,d0
                    bge.b    lbC022B24
                    addq.w   #1,d0
                    bra.b    lbC022B26
lbC022B24:
                    moveq    #0,d0
lbC022B26:
                    bsr      lbC022C3C
                    lea      (OK_PattLineBuff),a0
                    move.w   (lbW01B2B6),d2
                    add.w    d2,d2
                    add.w    d2,d2
                    adda.w   d2,a0
                    move.b   (lbB021E53,pc),d1
                    move.b   d0,(a0)+
                    bne.b    lbC022B46
                    moveq    #0,d1
lbC022B46:
                    move.b   d1,(a0)+
                    ext.w    d0
                    bsr      lbC022D06
                    bsr      lbC01FB24
                    bsr      OK_GetPatternData
                    bsr      lbC0231DC
                    bra      lbC022C6A
lbC022B5E:
                    rts
lbC022B60:
                    lea      (lbW022638,pc),a0
                    move.w   (a0),d0
                    beq      lbC022C3A
                    clr.w    (a0)
                    btst     #$B,d0
                    beq.b    lbC022B92
                    cmpi.b   #$31,d0
                    beq      lbC01FBB8
                    cmpi.b   #$32,d0
                    beq      lbC01FBBC
                    cmpi.b   #$34,d0
                    beq      lbC01FA4E
                    cmpi.b   #$35,d0
                    beq      lbC01FA4A
lbC022B92:
                    cmpi.b   #$C,d0
                    beq      lbC022C88
                    cmpi.b   #$D,d0
                    beq      lbC022C98
                    btst     #$F,d0
                    bne      lbC022C3A
                    btst     #$B,d0
                    beq.b    lbC022BB8
                    cmpi.b   #$37,d0
                    beq      lbC01F9C0
lbC022BB8:
                    cmpi.b   #$F,d0
                    beq      lbC022CD6
                    cmpi.b   #$E,d0
                    beq      lbC022CEE
                    cmpi.b   #2,d0
                    beq      lbC01F96C
                    cmpi.b   #$10,d0
                    beq      lbC01F29C
                    cmpi.b   #$11,d0
                    beq      lbC01F2B6
                    cmpi.b   #$12,d0
                    blt.b    lbC022BEE
                    cmpi.b   #$19,d0
                    ble      lbC022CAA
lbC022BEE:
                    cmpi.b   #$1F,d0
                    beq      lbC01FAFE
                    bsr      lbC01F06E
                    bmi.b    lbC022C3A
                    move.l   (lbL01F2D0,pc),a0
                    move.b   (a0,d0.w),d0
                    bmi.b    lbC022C3A
                    ext.w    d0
                    bsr.b    lbC022C3C
                    lea      (OK_PattLineBuff),a0
                    move.w   (lbW01B2B6),d2
                    add.w    d2,d2
                    add.w    d2,d2
                    adda.w   d2,a0
                    move.b   d0,(a0)+
                    bne.b    lbC022C24
                    sf       (a0)+
                    bra.b    lbC022C28
lbC022C24:
                    move.b   (lbB021E53,pc),(a0)+
lbC022C28:
                    bsr      lbC022D06
                    bsr      lbC01FB24
                    bsr      OK_GetPatternData
                    bsr      lbC0231DC
                    bra.b    lbC022C6A
lbC022C3A:
                    rts
lbC022C3C:
                    lea      (OK_PattLineBuff),a0
                    lea      (lbL01B7B2),a1
                REPT 8
                    move.l   (a0),(a1)+
                    clr.l    (a0)+
                ENDR
                    rts
lbC022C6A:
                    lea      (lbL01B7B2),a0
                    lea      (OK_PattLineBuff),a1
                REPT 8
                    move.l   (a0)+,(a1)+
                ENDR
                    rts
lbC022C88:
                    lea      (current_sample,pc),a0
                    tst.w    (a0)
                    beq.b    lbC022C96
                    subq.w   #1,(a0)
                    bra      lbC01FCE0
lbC022C96:
                    rts
lbC022C98:
                    lea      (current_sample,pc),a0
                    cmpi.w   #$23,(a0)
                    beq.b    lbC022CA8
                    addq.w   #1,(a0)
                    bra      lbC01FCE0
lbC022CA8:
                    rts
lbC022CAA:
                    subi.b   #18,d0
                    ext.w    d0
                    lea      (lbL02A76A),a0
                    move.b   (a0,d0.w),d0
                    bmi.b    lbC022CCA
                    eori.b   #7,d0
                    bchg     d0,(channels_mute_flags)
                    bra      draw_channels_muted_status
lbC022CCA:
                    rts
lbC022CD6:
                    lea      (lbW01B2BA),a0
                    subq.w   #1,(a0)
                    bpl.b    lbC022CEC
                    move.w   (lbW02A75A),d0
                    lsr.w    #2,d0
                    subq.w   #1,d0
                    move.w   d0,(a0)
lbC022CEC:
                    rts
lbC022CEE:
                    lea      (lbW01B2BA),a0
                    addq.w   #1,(a0)
                    move.w   (lbW02A75A),d0
                    lsr.w    #2,d0
                    cmp.w    (a0),d0
                    bne.b    lbC022D04
                    clr.w    (a0)
lbC022D04:
                    rts
lbC022D06:
                    move.w   d0,(lbB01B2B8)
                    tst.b    (lbB01B2A6)
                    beq      lbC022DE6
                    tst.b    (pattern_play_flag)
                    bne      lbC022DE6
                    move.w   (OK_PattY,pc),d2
                    mulu.w   (OK_ActSpeed),d2
                    add.w    (OK_ActCyc,pc),d2
                    move.w   (lbW01FBF0,pc),d1
                    mulu.w   (OK_ActSpeed),d1
                    tst.w    d1
                    beq.b    lbC022D54
                    divu.w   d1,d2
                    move.w   d1,d3
                    lsr.w    #1,d3
                    swap     d2
                    cmp.w    d3,d2
                    blt.b    lbC022D50
                    swap     d2
                    mulu.w   d1,d2
                    add.w    d1,d2
                    bra.b    lbC022D54
lbC022D50:
                    swap     d2
                    mulu.w   d1,d2
lbC022D54:
                    divu.w   (OK_ActSpeed),d2
                    bsr      OK_GetPPatt
lbC022D5E:
                    cmp.w    d0,d2
                    blt.b    lbC022D66
                    sub.w    d0,d2
                    bra.b    lbC022D5E
lbC022D66:
                    move.w   d2,d3
                    mulu.w   (lbW02A75A),d2
                    adda.l   d2,a0
                    move.w   (lbW01B2B6),d1
                    add.w    d1,d1
                    add.w    d1,d1
                    adda.w   d1,a0
                    move.b   (lbB01B2B9),(a0)+
                    bne.b    lbC022D88
                    sf       (a0)+
                    bra.b    lbC022D8C
lbC022D88:
                    move.b   (lbB021E53,pc),(a0)+
lbC022D8C:
                    lea      (C1C1D1D1E1F1F_MSG),a1
                    lea      (lbW01B2B0),a0
                    move.w   (lbB01B2B8),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.l   (a1,d0.w),(a0)
                    tst.w    (lbB01B2B8)
                    bne.b    lbC022DB6
                    move.b   #'0',(4,a0)
                    bra.b    lbC022DC4
lbC022DB6:
                    lea      (alpha_numeric_table,pc),a1
                    move.w   (current_sample,pc),d0
                    move.b   (a1,d0.w),(4,a0)
lbC022DC4:
                    sf       (5,a0)
                    move.w   (lbW01B2B6),d0
                    mulu.w   #5,d0
                    lea      (caret_current_positions),a1
                    move.b   (a1,d0.w),d0
                    move.w   d3,d1
                    addq.w   #7,d1
                    jmp      (draw_text)
lbC022DE6:
                    rts

; ===========================================================================
show_pattern_position_bar:
                    tst.b    (pattern_play_flag)
                    bne      lbC022EF8
                    move.w   (OK_PattY,pc),d2
                    bmi      lbC022EF8
                    move.w   d2,d0
                    bsr      set_pattern_bitplane_from_given_pos
                    lea      (main_screen+(56*80)),a0
                    move.w   d2,d0
                    mulu.w   #(SCREEN_BYTES*8),d0
                    adda.l   d0,a0
                    move.l   a0,a1
                    lea      (-SCREEN_BYTES,a1),a1
                    lea      ((SCREEN_BYTES*8),a1),a2
                    tst.w    d2
                    beq.b    lbC022E44
                REPT 20
                    not.l    (a1)+
                ENDR
lbC022E44:
                REPT 20
                    not.l    (a2)+
                ENDR
                    move.w   (lbW01B2B6),d0
                    bmi      lbC022EF8
                    lea      (caret_current_positions),a1
                    mulu.w   #5,d0
                    move.b   (a1,d0.w),d1
                    ext.w    d1
                    adda.w   d1,a0
                    lea      (-SCREEN_BYTES,a0),a0
                    lea      ((SCREEN_BYTES*8),a0),a1
                    moveq    #1,d0
                    eor.b    d0,(-((SCREEN_BYTES*7)+1),a1)
                    eor.b    d0,(-((SCREEN_BYTES*6)+1),a1)
                    eor.b    d0,(-((SCREEN_BYTES*5)+1),a1)
                    eor.b    d0,(-((SCREEN_BYTES*4)+1),a1)
                    eor.b    d0,(-((SCREEN_BYTES*3)+1),a1)
                    eor.b    d0,(-((SCREEN_BYTES*2)+1),a1)
                    eor.b    d0,(-((SCREEN_BYTES*1)+1),a1)
                    tst.w    d2
                    beq.b    lbC022EC2
                REPT 8
                    not.b    (a0)+
                ENDR
lbC022EC2:
                REPT 8
                    not.b    (a1)+
                ENDR
                    cmpi.w   #$48,d1
                    beq.b    lbC022EF8
                    move.b   #$80,d0
                    eor.b    d0,(-(SCREEN_BYTES*7),a1)
                    eor.b    d0,(-(SCREEN_BYTES*6),a1)
                    eor.b    d0,(-(SCREEN_BYTES*5),a1)
                    eor.b    d0,(-(SCREEN_BYTES*4),a1)
                    eor.b    d0,(-(SCREEN_BYTES*3),a1)
                    eor.b    d0,(-(SCREEN_BYTES*2),a1)
                    eor.b    d0,(-(SCREEN_BYTES*1),a1)
lbC022EF8:
                    rts

; ===========================================================================
OK_ReplayHandler:
                    bsr      draw_vumeters
                    bsr      OK_SetHWRegs
                    addq.w   #1,(OK_ActCyc)
                    move.w   (OK_ActSpeed,pc),d0
                    cmp.w    (OK_ActCyc,pc),d0
                    bgt.b    .OK_NoCyc
                    bsr      OK_NewRow
                    bsr      OK_GetPatternData
.OK_NoCyc:
                    bsr      lbC022A44
                    bsr      lbC022AF0
                    lea      (OK_PattLineBuff+2),a2
                    lea      (OK_ChannelsData),a5
                    move.b   (channels_mute_flags),d6
                    moveq    #8-1,d7
.OK_PLoop:
                    tst.b    (a5)
                    bne.b    .OK_MultiChan
                    addq.w   #4,a2
                    lea      (28,a5),a5
                    subq.w   #1,d7
                    dbra     d7,.OK_PLoop
                    rts
.OK_MultiChan:
                    btst     d7,d6
                    beq.b    .OK_NoEffect_Multi
                    moveq    #0,d0
                    move.b   (a2),d0
                    add.w    d0,d0
                    move.w   (OK_EffectTab_Tick0,pc,d0.w),d0
                    beq.b    .OK_NoEffect_Multi
                    moveq    #0,d1
                    move.b   (1,a2),d1
                    jsr      (OK_EffectTab_Tick0,pc,d0.w)
.OK_NoEffect_Multi:
                    addq.w   #4,a2
                    lea      (14,a5),a5
                    subq.w   #1,d7
                    btst     d7,d6
                    beq.b    .OK_NoEffect_Single
                    moveq    #0,d0
                    move.b   (a2),d0
                    add.w    d0,d0
                    move.w   (OK_EffectTab_Tick0,pc,d0.w),d0
                    beq.b    .OK_NoEffect_Single
                    moveq    #0,d1
                    move.b   (1,a2),d1
                    jsr      (OK_EffectTab_Tick0,pc,d0.w)
.OK_NoEffect_Single:
                    addq.w   #4,a2
                    lea      (14,a5),a5
                    dbra     d7,.OK_PLoop
                    rts
OK_EffectTab_Tick0:
                    dc.w     0,                                      0,                                  0
                    dc.w     0,                                      0,                                  0
                    dc.w     0,                                      0,                                  0
                    dc.w     0,                                      OK_Arp_Tick0-OK_EffectTab_Tick0,    OK_Arp2_Tick0-OK_EffectTab_Tick0
                    dc.w     OK_Arp3_Tick0-OK_EffectTab_Tick0,       OK_SlideD_Tick0-OK_EffectTab_Tick0, 0
                    dc.w     OK_Filt-OK_EffectTab_Tick0,             0,                                  OK_SlideUTick_Tick0-OK_EffectTab_Tick0
                    dc.w     0,                                      0,                                  0
                    dc.w     OK_SlideDTick_Tick0-OK_EffectTab_Tick0, 0,                                  0
                    dc.w     0,                                      OK_PosJmp-OK_EffectTab_Tick0,       0
                    dc.w     0,                                      OK_CSpeed-OK_EffectTab_Tick0,       0
                    dc.w     OK_SlideU_Tick0-OK_EffectTab_Tick0,     OK_Volume-OK_EffectTab_Tick0,       0
                    dc.W     0,                                      0,                                  0

; ===========================================================================
OK_NewRow:
                    clr.w    (OK_ActCyc)
                    move.l   (OK_TrkPos,pc),a1
                    adda.w   (OK_TrkSize,pc),a1
                    move.l   a1,(OK_TrkPos)
                    bsr      show_pattern_position_bar
                    move.w   (lbW01B2BA),(lbW01B2B6)
                    addq.w   #1,(OK_PattY)
                    bsr      OK_GetPPatt
                    tst.w    (OK_NextPt)
                    bpl.b    .OK_PattEnd
                    cmp.w    (OK_PattY,pc),d0
                    bgt.b    .OK_NoNew
.OK_PattEnd:
                    clr.w    (OK_PattY)
                    mulu.w   (OK_TrkSize,pc),d0
                    sub.l    d0,(OK_TrkPos)
                    tst.b    (pattern_play_flag)
                    beq.b    .OK_NoNew
                    tst.w    (OK_NextPt)
                    bmi.b    .OK_NoNextPt
                    move.w   (OK_NextPt,pc),(OK_PtPtr)
                    bra.b    .OK_NewPos
.OK_NoNextPt:
                    addq.w   #1,(OK_PtPtr)
.OK_NewPos:
                    move.w   (OK_PtPtr,pc),d0
                    cmp.w    (OK_PLen),d0
                    bne.b    .OK_NoNewInit
                    clr.w    (OK_PtPtr)
                    move.w   (OK_Speed),(OK_ActSpeed)
.OK_NoNewInit:
                    bsr      OK_GetTrkPos
.OK_NoNew:
                    move.l   (OK_TrkPos,pc),a0
                    movem.l  (a0),d0-d7
                    movem.l  d0-d7,(OK_PattLineBuff)
                    move.w   #-1,(OK_NextPt)
                    bra      show_pattern_position_bar

; ===========================================================================
OK_GetPPatt:
                    move.w   (OK_PtPtr,pc),d0
                    tst.b    (pattern_play_flag)
                    beq.b    .OK_PlayPattern
                    lea      (OK_Patterns),a0
                    move.b   (a0,d0.w),d0
.OK_PlayPattern:
                    bra      OK_GetPattern

; ===========================================================================
OK_GetTrkPos:
                    tst.b    (pattern_play_flag)
                    beq.b    .OK_PlayPattern
                    move.w   (OK_PtPtr,pc),d2
                    moveq    #12,d0
                    moveq    #1,d1
                    jsr      (lbC025E0C)
                    lea      (OK_Patterns),a0
                    move.w   (OK_PtPtr,pc),d2
                    move.b   (a0,d2.w),d2
                    move.w   d2,-(sp)
                    moveq    #13,d0
                    moveq    #2,d1
                    jsr      (lbC025E20)
                    move.w   (sp)+,d0
                    bra.b    lbC0230D2
.OK_PlayPattern:
                    move.w   (OK_PtPtr,pc),d0
lbC0230D2:
                    bsr      OK_GetPattern
                    move.l   a0,(OK_TrkPos)
                    clr.w    (OK_PattY)
                    rts

; ===========================================================================
OK_GetPattern:
                    lea      (OK_PatternList),a0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.l   (a0,d0.w),a0
                    move.w   (a0)+,d0
                    rts

; ===========================================================================
OK_GetPatternData:
                    lea      (OK_SampleTab),a0
                    lea      (OK_Samples),a1
                    lea      (OK_PattLineBuff),a2
                    lea      (OK_ChannelsData),a3
                    move.b   (channels_mute_flags),d6
                    moveq    #8-1,d7
.OK_Loop:
                    tst.b    (a3)
                    bne.b    .OK_FillData
                    addq.w   #4,a2
                    lea      (28,a3),a3
                    subq.w   #1,d7
                    dbra     d7,.OK_Loop
                    rts
.OK_FillData:
                    bsr.b    .OK_GetChannelData
                    subq.w   #1,d7
                    bsr.b    .OK_GetChannelData
                    dbra     d7,.OK_Loop
                    rts
.OK_GetChannelData:
                    btst     d7,d6
                    beq      .OK_NoData
                    moveq    #0,d3
                    move.b   (a2),d3
                    beq      .OK_NoData
                    subq.w   #1,d3
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    bne.b    .OK_Midi_Out
                    movem.l  d0-d4/a0/a1,-(sp)
                    move.b   d7,d4
                    moveq    #0,d0
                    move.b   (1,a2),d0
                    lsl.w    #5,d0
                    lea      (OK_Samples),a1
                    adda.w   d0,a1
                    cmpi.w   #1,(30,a1)
                    beq.b    .lbC023194
                    move.b   (1,a2),d0
                    move.b   d3,d1
                    addq.b   #1,d1
                    move.b   #64,d2
                    cmpi.b   #31,(2,a2)
                    bne.b    .OK_Max
                    cmpi.b   #64,(3,a2)
                    bhi.b    .OK_Max
                    move.b   (3,a2),d2
.OK_Max:
                    move.l   (20,a1),d3
                    jsr      (lbC022AA6,pc)
.lbC023194:
                    movem.l  (sp)+,d0-d4/a0/a1
                    bra.b    .OK_Done_Midi_Out
.OK_Midi_Out:
                    moveq    #0,d0
                    move.b   (1,a2),d0
                    lsl.w    #3,d0
                    move.l   (a0,d0.w),d2
                    beq.b    .OK_NoData
                    add.w    d0,d0
                    add.w    d0,d0
                    cmpi.w   #1,(30,a1,d0.w)
                    beq.b    .OK_NoData
                    move.l   d2,(2,a3)
                    move.l   (20,a1,d0.w),(6,a3)
                    move.w   d3,(10,a3)
                    move.w   d3,(12,a3)
.OK_Done_Midi_Out:
                    bsr      trigger_vumeter
.OK_NoData:
                    addq.w   #4,a2
                    lea      (14,a3),a3
                    rts

; ===========================================================================
OK_SetHWRegs:
                    bsr      OK_TurnDMAOn
                    move.w   (OK_ActCyc,pc),d0
                    bne.b    OK_NoNewRow
lbC0231DC:
                    bsr      OK_Set
                    or.w     d4,(OK_Dmacon)
OK_NoNewRow:
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    beq      .OK_Midi_Out
                    bsr      OK_HandleEffects_TicksX
                    lea      (OK_Volume2,pc),a0
                    move.l   (a0)+,(a0)
                    lea      (_CUSTOM|AUD0VOL),a1
                    moveq    #0,d0
                    move.b   (a0),d0
                    move.w   d0,(a1)
                    move.b   (1,a0),d0
                    move.w   d0,(AUD1VOL-AUD0VOL,a1)
                    move.b   (2,a0),d0
                    move.w   d0,(AUD2VOL-AUD0VOL,a1)
                    move.b   (3,a0),d0
                    move.w   d0,(AUD3VOL-AUD0VOL,a1)
                    move.b   (OK_Filter,pc),d0
                    beq.b    .OK_Blink
                    bclr     #1,(CIAB)
.OK_Midi_Out:
                    rts
.OK_Blink:
                    bset     #1,(CIAB)
                    rts

; ===========================================================================
OK_TurnDMAOn:
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    beq.b    .OK_SetChan4
                    lea      (OK_Dmacon,pc),a0
                    move.w   (a0),d0
                    beq.b    .OK_SetChan4
                    clr.w    (a0)
                    ori.w    #DMAF_SETCLR,d0
                    lea      (_CUSTOM|VHPOSR),a0
                    move.w   d0,(DMACON-VHPOSR,a0)
                    move.b   (a0),d1
.OK_NextLine:
                    cmp.b    (a0),d1
                    beq.b    .OK_NextLine
                    move.b   (a0),d1
.OK_WaitLine:
                    cmp.b    (a0),d1
                    beq.b    .OK_WaitLine
                    lea      (OK_ChannelsData+2),a1
                    btst     #0,d0
                    beq.b    .OK_SetChan1
                    move.l   (a1),(AUD0LCH-VHPOSR,a0)
                    move.w   (4,a1),(AUD0LEN-VHPOSR,a0)
.OK_SetChan1:
                    btst     #1,d0
                    beq.b    .OK_SetChan2
                    move.l   (28,a1),(AUD1LCH-VHPOSR,a0)
                    move.w   (32,a1),(AUD1LEN-VHPOSR,a0)
.OK_SetChan2:
                    btst     #2,d0
                    beq.b    .OK_SetChan3
                    move.l   (56,a1),(AUD2LCH-VHPOSR,a0)
                    move.w   (60,a1),(AUD2LEN-VHPOSR,a0)
.OK_SetChan3:
                    btst     #3,d0
                    beq.b    .OK_SetChan4
                    move.l   (84,a1),(AUD3LCH-VHPOSR,a0)
                    move.w   (88,a1),(AUD3LEN-VHPOSR,a0)
.OK_SetChan4:
                    rts

; ===========================================================================
OK_Set:
                    lea      (OK_SampleTab),a0
                    lea      (OK_PattLineBuff),a2
                    lea      (OK_ChannelsData),a3
                    lea      (_CUSTOM|AUD0LCH),a4
                    lea      (OK_FullPeriodTab,pc),a6
                    moveq    #0,d4
                    moveq    #1,d5
                    move.b   (channels_mute_flags),d6
                    moveq    #8-1,d7
.OK_Loop:
                    tst.b    (a3)
                    bne.b    .OK_MultiChannel
                    bsr.b    .OK_Set4
                    addq.w   #4,a2
                    lea      (28,a3),a3
                    lea      (16,a4),a4
                    add.w    d5,d5
                    subq.w   #1,d7
                    dbra     d7,.OK_Loop
                    rts
.OK_MultiChannel:
                    addq.w   #8,a2
                    lea      (28,a3),a3
                    lea      (16,a4),a4
                    add.w    d5,d5
                    subq.w   #1,d7
                    dbra     d7,.OK_Loop
                    rts
.OK_Set4:
                    btst     d7,d6
                    beq      .OK_NoSet
                    moveq    #0,d3
                    move.b   (a2),d3
                    beq      .OK_NoSet
                    subq.w   #1,d3
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    bne.b    .OK_Midi_Out
                    movem.l  d0-d4/a0/a1,-(sp)
                    move.b   d7,d4
                    moveq    #0,d0
                    move.b   (1,a2),d0
                    lsl.w    #5,d0
                    lea      (OK_Samples),a1
                    adda.w   d0,a1
                    tst.w    (30,a1)
                    beq.b    .lbC0232EE
                    move.b   (1,a2),d0
                    move.b   d3,d1
                    addq.b   #1,d1
                    move.b   (29,a1),d2
                    cmpi.b   #31,(2,a2)
                    bne.b    .OK_Max
                    cmpi.b   #64,(3,a2)
                    bhi.b    .OK_Max
                    move.b   (3,a2),d2
.OK_Max:
                    move.l   (20,a1),d3
                    jsr      (lbC022AA6,pc)
.lbC0232EE:
                    movem.l  (sp)+,d0-d4/a0/a1
                    bra.b    .OK_Done_Midi_Out
.OK_Midi_Out:
                    moveq    #0,d0
                    move.b   (1,a2),d0
                    lsl.w    #3,d0
                    move.l   (a0,d0.w),d2
                    beq      .OK_NoSet
                    add.w    d0,d0
                    add.w    d0,d0
                    lea      (OK_Samples),a1
                    adda.w   d0,a1
                    tst.w    (30,a1)
                    beq      .OK_NoSet
                    move.l   (20,a1),d1
                    lsr.l    #1,d1
                    tst.w    d1
                    beq      .OK_NoSet
                    move.w   d5,(_CUSTOM|DMACON)
                    or.w     d5,d4
                    move.l   d2,(a4)
                    move.w   d3,(8,a3)
                    add.w    d3,d3
                    move.w   (a6,d3.w),d0
                    move.w   d0,(10,a3)
                    move.w   d0,(6,a4)
                    move.l   a0,-(sp)
                    lea      (OK_Volume2,pc),a0
                    moveq    #0,d0
                    move.b   (-8,a0,d7.w),d0
                    move.b   (29,a1),(a0,d0.w)
                    move.l   (sp)+,a0
.OK_Done_Midi_Out:
                    bsr      trigger_vumeter
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    beq.b    .OK_NoSet
                    move.w   (26,a1),d0
                    bne.b    .OK_RealRep
                    move.w   d1,(4,a4)
                    move.l   #OK_EmptyWaveForm,(2,a3)
                    move.w   #2/2,(6,a3)
.OK_NoSet:
                    rts
.OK_RealRep:
                    move.w   d0,(6,a3)
                    moveq    #0,d1
                    move.w   (24,a1),d1
                    add.w    d1,d0
                    move.w   d0,(4,a4)
                    add.l    d1,d1
                    add.l    d2,d1
                    move.l   d1,(2,a3)
                    rts

; ===========================================================================
OK_HandleEffects_TicksX:
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    beq.b    .OK_Midi_Out
                    lea      (OK_PattLineBuff),a2
                    lea      (OK_ChannelsData),a3
                    lea      (_CUSTOM|AUD0LCH),a4
                    lea      (OK_FullPeriodTab,pc),a6
                    moveq    #1,d5
                    move.b   (channels_mute_flags),d6
                    moveq    #8-1,d7
.OK_Loop:
                    tst.b    (a3)
                    bne.b    .OK_MultiChannel
                    bsr.b    .OK_ProcessEffect
                    addq.w   #4,a2
                    lea      (28,a3),a3
                    lea      ($10,a4),a4
                    add.w    d5,d5
                    subq.w   #1,d7
                    dbra     d7,.OK_Loop
.OK_Midi_Out:
                    rts
.OK_MultiChannel:
                    addq.w   #8,a2
                    lea      (28,a3),a3
                    lea      ($10,a4),a4
                    add.w    d5,d5
                    subq.w   #1,d7
                    dbra     d7,.OK_Loop
                    rts
.OK_ProcessEffect:
                    btst     d7,d6
                    beq.b    OK_Nop
                    moveq    #0,d0
                    move.b   (2,a2),d0
                    add.w    d0,d0
                    moveq    #0,d1
                    move.b   (3,a2),d1
                    move.w   (OK_EffectTab_TickX,pc,d0.w),d0
                    jmp      (OK_EffectTab_TickX,pc,d0.w)
OK_Nop:
                    rts
OK_EffectTab_TickX:
                    dc.w     OK_Nop-OK_EffectTab_TickX,OK_PortD-OK_EffectTab_TickX,OK_PortU-OK_EffectTab_TickX
                    dc.w     OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX
                    dc.w     OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX
                    dc.w     OK_Nop-OK_EffectTab_TickX,OK_Arp_TickX-OK_EffectTab_TickX,OK_Arp2_TickX-OK_EffectTab_TickX
                    dc.w     OK_Arp3_TickX-OK_EffectTab_TickX,OK_SlideD_TickX-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX
                    dc.w     OK_Filt-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX,OK_SlideUTick_TickX-OK_EffectTab_TickX
                    dc.w     OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX
                    dc.w     OK_SlideDTick_TickX-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX
                    dc.w     OK_Release-OK_EffectTab_TickX,OK_PosJmp-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX
                    dc.w     OK_Nop-OK_EffectTab_TickX,OK_CSpeed-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX
                    dc.w     OK_SlideU_TickX-OK_EffectTab_TickX,OK_Volume-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX
                    dc.w     OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX,OK_Nop-OK_EffectTab_TickX

; ===========================================================================
OK_PortU:
                    add.w    d1,(10,a3)
                    cmpi.w   #$358,(10,a3)
                    ble.b    .OK_PortMax
                    move.w   #$358,(10,a3)
.OK_PortMax:
                    move.w   (10,a3),(6,a4)
                    rts

; ===========================================================================
OK_PortD:
                    sub.w    d1,(10,a3)
                    cmpi.w   #$71,(10,a3)
                    bge.b    .OK_PortMin
                    move.w   #$71,(10,a3)
.OK_PortMin:
                    move.w   (10,a3),(6,a4)
                    rts

; ===========================================================================
OK_Arp_TickX:
                    move.w   (8,a3),d2
                    move.w   (OK_ActCyc,pc),d0
                    move.b   (OK_DivTab_TickX,pc,d0.w),d0
                    bne.b    .OK_Val1
                    andi.w   #$F0,d1
                    lsr.w    #4,d1
                    sub.w    d1,d2
                    bra      OK_SetArp
.OK_Val1:
                    subq.b   #1,d0
                    bne.b    .OK_Val2
                    bra      OK_SetArp
.OK_Val2:
                    andi.w   #$F,d1
                    add.w    d1,d2
                    bra      OK_SetArp
OK_DivTab_TickX:
                    dc.b     0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0

; ===========================================================================
OK_Arp2_TickX:
                    move.w   (8,a3),d2
                    move.w   (OK_ActCyc,pc),d0
                    andi.w   #3,d0
                    bne.b    .OK_Val1
                    bra      OK_SetArp
.OK_Val1:
                    subq.b   #1,d0
                    bne.b    .OK_Val2
                    andi.w   #$F,d1
                    add.w    d1,d2
                    bra.b    OK_SetArp
.OK_Val2:
                    subq.b   #1,d0
                    beq.b    OK_SetArp
                    andi.w   #$F0,d1
                    lsr.w    #4,d1
                    sub.w    d1,d2
                    bra      OK_SetArp

; ===========================================================================
OK_Arp3_TickX:
                    move.w   (8,a3),d2
                    move.w   (OK_ActCyc,pc),d0
                    move.b   (OK_DivTab3_TickX,pc,d0.w),d0
                    bne.b    .OK_Val1
                    rts
.OK_Val1:
                    subq.b   #1,d0
                    bne.b    .OK_Val2
                    andi.w   #$F0,d1
                    lsr.w    #4,d1
                    add.w    d1,d2
                    bra.b    OK_SetArp
.OK_Val2:
                    subq.b   #1,d0
                    bne.b    .OK_Val3
                    andi.w   #$F,d1
                    add.w    d1,d2
.OK_Val3:
                    bra.b    OK_SetArp
OK_DivTab3_TickX:
                    dc.b     0,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3

; ===========================================================================
OK_SlideUTick_TickX:
                    move.w   (OK_ActCyc,pc),d0
                    beq.b    OK_SlideU_TickX
                    rts
OK_SlideU_TickX:
                    move.w   (8,a3),d2
                    add.w    d1,d2
                    move.w   d2,(8,a3)
                    bra.b    OK_SetArp

; ===========================================================================
OK_SlideDTick_TickX:
                    move.w   (OK_ActCyc,pc),d0
                    beq.b    OK_SlideD_TickX
                    rts
OK_SlideD_TickX:
                    move.w   (8,a3),d2
                    sub.w    d1,d2
                    move.w   d2,(8,a3)

; ===========================================================================
OK_SetArp:
                    tst.w    d2
                    bpl.b    .OK_ArpOk1
                    moveq    #0,d2
.OK_ArpOk1:
                    cmpi.w   #35,d2
                    ble.b    .OK_ArpOk2
                    moveq    #35,d2
.OK_ArpOk2:
                    add.w    d2,d2
                    move.w   (a6,d2.w),d0
                    move.w   d0,(6,a4)
                    move.w   d0,(10,a3)
                    rts

; ===========================================================================
OK_Arp_Tick0:
                    move.w   (12,a5),d2
                    move.w   (OK_ActCyc,pc),d0
                    move.b   (OK_DivTab_Tick0,pc,d0.w),d0
                    bne.b    .OK_Val1
                    andi.w   #$F0,d1
                    lsr.w    #4,d1
                    sub.w    d1,d2
                    move.w   d2,(10,a5)
                    rts
.OK_Val1:
                    subq.b   #1,d0
                    bne.b    .OK_Val2
                    move.w   d2,(10,a5)
                    rts
.OK_Val2:
                    andi.w   #$F,d1
                    add.w    d1,d2
                    move.w   d2,(10,a5)
                    rts
OK_DivTab_Tick0:
                    dc.b     0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0

; ===========================================================================
OK_Arp2_Tick0:
                    move.w   (12,a5),d2
                    move.w   (OK_ActCyc,pc),d0
                    andi.w   #3,d0
                    bne.b    .OK_Val2
.OK_Val1:
                    move.w   d2,(10,a5)
                    rts
.OK_Val2:
                    subq.b   #1,d0
                    bne.b    .OK_Val3
                    andi.w   #$F,d1
                    add.w    d1,d2
                    move.w   d2,(10,a5)
                    rts
.OK_Val3:
                    subq.b   #1,d0
                    beq.b    .OK_Val1
                    andi.w   #$F0,d1
                    lsr.w    #4,d1
                    sub.w    d1,d2
                    move.w   d2,(10,a5)
                    rts

; ===========================================================================
OK_Arp3_Tick0:
                    move.w   (12,a5),d2
                    move.w   (OK_ActCyc,pc),d0
                    move.b   (OK_DivTab3_Tick0,pc,d0.w),d0
                    bne.b    .OK_Val1
                    rts
.OK_Val1:
                    subq.b   #1,d0
                    bne.b    .OK_Val2
                    andi.w   #$F0,d1
                    lsr.w    #4,d1
                    add.w    d1,d2
                    move.w   d2,(10,a5)
                    rts
.OK_Val2:
                    subq.b   #1,d0
                    bne.b    .OK_Val3
                    andi.w   #$F,d1
                    add.w    d1,d2
.OK_Val3:
                    move.w   d2,(10,a5)
                    rts
OK_DivTab3_Tick0:
                    dc.b     0,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3

; ===========================================================================
OK_SlideUTick_Tick0:
                    move.w   (OK_ActCyc,pc),d0
                    beq.b    OK_SlideU_Tick0
                    rts
OK_SlideU_Tick0:
                    add.w    d1,(12,a5)
                    add.w    d1,(10,a5)
                    rts

; ===========================================================================
OK_SlideDTick_Tick0:
                    move.w   (OK_ActCyc,pc),d0
                    beq.b    OK_SlideD_Tick0
                    rts
OK_SlideD_Tick0:
                    sub.w    d1,(12,a5)
                    sub.w    d1,(10,a5)
                    rts

; ===========================================================================
OK_PosJmp:
                    move.w   (OK_ActCyc,pc),d0
                    bne.b    .OK_NoJmp
                    tst.b    (pattern_play_flag)
                    beq.b    .OK_NoJmp
                    move.w   d1,d0
                    andi.w   #$F,d0
                    lsr.w    #4,d1
                    mulu.w   #10,d1
                    add.w    d1,d0
                    cmp.w    (OK_PLen,pc),d0
                    bcc.b    .OK_NoJmp
                    move.w   d0,(OK_NextPt)
.OK_NoJmp:
                    rts

; ===========================================================================
OK_CSpeed:
                    move.w   (OK_ActCyc,pc),d0
                    bne.b    .OK_NoChange
                    andi.w   #$F,d1
                    tst.b    d1
                    beq.b    .OK_NoChange
                    move.w   d1,(OK_ActSpeed)
                    ; visually update the speed
                    movem.l  d0-d7/a0-a6,-(sp)
                    move.w   d1,d0
                    bsr      lbC01FCD6
                    movem.l  (sp)+,d0-d7/a0-a6
.OK_NoChange:
                    rts

; ===========================================================================
OK_Filt:
                    move.w   (OK_ActCyc,pc),d0
                    bne.b    .OK_NoChange
                    tst.b    d1
                    sne      (OK_Filter)
.OK_NoChange:
                    rts

; ===========================================================================
OK_Volume:
                    move.l   a0,-(sp)
                    moveq    #0,d0
                    lea      (OK_Volume2,pc),a0
                    move.b   (-8,a0,d7.w),d0
                    adda.w   d0,a0
                    cmpi.w   #64,d1
                    bgt.b    OK_ActVolume
                    move.b   d1,(a0)
OK_Vex:
                    move.l   (sp)+,a0
                    rts
OK_ActVolume:
                    subi.b   #64,d1
                    cmpi.b   #16,d1
                    blt.b    .OK_Val2
                    subi.b   #16,d1
                    cmpi.b   #16,d1
                    blt.b    .OK_Val4
                    subi.b   #16,d1
                    cmpi.b   #16,d1
                    blt.b    .OK_Val1
                    subi.b   #16,d1
                    cmpi.b   #16,d1
                    blt.b    .OK_Val3
                    bra.b    OK_Vex
.OK_Val1:
                    move.w   (OK_ActCyc,pc),d0
                    bne.b    OK_Vex
.OK_Val2:
                    sub.b    d1,(a0)
                    bpl.b    OK_Vex
                    sf       (a0)
                    bra.b    OK_Vex
.OK_Val3:
                    move.w   (OK_ActCyc,pc),d0
                    bne.b    OK_Vex
.OK_Val4:
                    add.b    d1,(a0)
                    cmpi.b   #64,(a0)
                    bls.b    OK_Vex
                    move.b   #64,(a0)
                    bra.b    OK_Vex

; ===========================================================================
OK_Release:
                    move.l   a0,-(sp)
                    moveq    #0,d0
                    lea      (OK_Volume2,pc),a0
                    move.b   (-8,a0,d7.w),d0
                    adda.w   d0,a0
                    move.b   (4,a0),(a0)
                    cmpi.b   #64,d1
                    bhi.b    OK_ActVolume
                    move.l   (sp)+,a0
                    rts

; ===========================================================================
lbC0237AC:
                    lea      (OK_ChannelsData),a0
                    move.w   #(28*4)-1,d0
.OK_ClearChannelsData:
                    sf       (a0)+
                    dbra     d0,.OK_ClearChannelsData
                    lea      (OK_ChannelsModes),a0
                    lea      (OK_ChannelsData),a1
                    moveq    #4-1,d0
                    moveq    #0,d1
.OK_GetTrackSize:
                    tst.w    (a0)
                    sne      (a1)
                    sne      (14,a1)
                    add.w    (a0)+,d1
                    lea      (28,a1),a1
                    dbra     d0,.OK_GetTrackSize
                    addq.w   #4,d1
                    add.w    d1,d1
                    add.w    d1,d1
                    move.w   d1,(OK_TrkSize)
                    lea      (OK_PattLineBuff),a0
                    moveq    #0,d1
                    moveq    #8-1,d0
.OK_ClearPattLineBuff:
                    move.l   d1,(a0)+
                    dbra     d0,.OK_ClearPattLineBuff
                    lea      (OK_Volume2-8,pc),a0
                    move.l   #$3030202,(a0)+
                    move.l   #$1010000,(a0)+
                    move.l   #$40404040,d0
                    move.l   d0,(a0)+
                    move.l   d0,(a0)+
                    bsr      OK_GetTrkPos
                    subq.w   #1,(OK_PattY)
                    moveq    #0,d0
                    move.w   (caret_pos_x),d0
                    divu.w   #5,d0
                    move.w   d0,(lbW01B2BA)
                    move.w   #-1,(lbW01B2B6)
                    move.w   #-1,(OK_NextPt)
                    move.l   (OK_TrkPos,pc),a0
                    suba.w   (OK_TrkSize,pc),a0
                    move.l   a0,(OK_TrkPos)
                    move.w   (OK_Speed),(OK_ActSpeed)
                    clr.w    (OK_ActCyc)
                    clr.w    (OK_Filter)
                    clr.w    (OK_Dmacon)
                    rts
OK_ActCyc:
                    dc.w     0
OK_TrkPos:
                    dc.l     0
OK_TrkSize:
                    dc.w     0
OK_PattY:
                    dc.w     0
OK_ActSpeed:
                    dc.w     0
OK_NextPt:
                    dc.w     0
OK_PtPtr:
                    dc.w     0
; ====
                    ds.l     2
OK_Volume2:
                    ds.l     2
; ====
OK_Filter:
                    dc.b     0
                    even
OK_Dmacon:
                    dc.w     0
current_song_position:
                    dc.w     0

; ===========================================================================
lbC023892:
                    move.l   a0,-(sp)
                    bsr      lbC0237AC
                    move.l   (sp)+,a0
                    move.l   a0,a1
                    adda.l   #43036,a1
                    move.l   a1,(lbL023E20)
                    move.l   a0,a1
                    adda.l   #43180,a1
                    move.l   a1,(lbL023E24)
                    bsr      lbC023BB0
                    sf       (lbB023940)
                    st       (ascii_MSG8)
                    lea      (OK_MixBuff_1),a0
                    moveq    #0,d1
                    move.w   #((MIX_BUFFERS_1*MIX_BUFFERS_LEN_1)/8)-1,d0
.clear_buffers:
                    move.l   d1,(a0)+
                    move.l   d1,(a0)+
                    dbra     d0,.clear_buffers
                    lea      (_CUSTOM),a1
                    move.w   #DMAF_AUDIO,(DMACON,a1)
                    lea      (OK_MixBuff_1),a0
                    move.l   a0,(AUD0LCH,a1)
                    lea      (MIX_BUFFERS_LEN_1,a0),a0
                    move.l   a0,(AUD1LCH,a1)
                    lea      (MIX_BUFFERS_LEN_1,a0),a0
                    move.l   a0,(AUD2LCH,a1)
                    lea      (MIX_BUFFERS_LEN_1,a0),a0
                    move.l   a0,(AUD3LCH,a1)
                    move.w   #MIX_BUFFERS_LEN_1/2,d0
                    move.w   d0,(AUD0LEN,a1)
                    move.w   d0,(AUD1LEN,a1)
                    move.w   d0,(AUD2LEN,a1)
                    move.w   d0,(AUD3LEN,a1)
                    move.w   #227,d0
                    move.w   d0,(AUD0PER,a1)
                    move.w   d0,(AUD1PER,a1)
                    move.w   d0,(AUD2PER,a1)
                    move.w   d0,(AUD3PER,a1)
                    move.w   #$FF,(ADKCON,a1)
                    bsr      wait_raster
                    bra      wait_raster
lbB023940:
                    dc.b     0
ascii_MSG8:
                    dc.b     0
OK_Play_1:
                    move.b   (ascii_MSG8,pc),d0
                    beq.b    lbC023956
                    move.w   #DMAF_SETCLR|DMAF_AUDIO,(_CUSTOM|DMACON)
                    sf       (ascii_MSG8)
lbC023956:
                    bsr      OK_ReplayHandler
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    beq.b    lbC0239AA
                    lea      (OK_ChannelsData),a2
                    moveq    #MIX_BUFFERS_1-1,d7
                    not.b    (lbB023940)
                    bne.b    lbC023960
                    bra.b    lbC0239AC
lbC023960:
                    lea      (OK_MixBuff_1+313),a5
lbC02397C:
                    tst.b    (a2)
                    beq.b    lbC02399E
                    lea      (lbB019D74+1),a1
                    move.l   a2,a3
                    bsr      lbC0239F8
                    lea      (lbB019EAE+1),a1
                    lea      (14,a2),a3
                    bsr      lbC0239F8
                    bsr      lbC023AA0
lbC02399E:
                    lea      (28,a2),a2
                    lea      (MIX_BUFFERS_LEN_1,a5),a5
                    dbra     d7,lbC02397C
lbC0239AA:
                    rts
lbC0239AC:
                    lea      (OK_MixBuff_1),a5
lbC0239C8:
                    tst.b    (a2)
                    beq.b    lbC0239EA
                    lea      (lbB019D74),a1
                    move.l   a2,a3
                    bsr      lbC0239F8
                    lea      (lbB019EAE),a1
                    lea      (14,a2),a3
                    bsr      lbC0239F8
                    bsr      lbC023A8A
lbC0239EA:
                    lea      (28,a2),a2
                    lea      (MIX_BUFFERS_LEN_1,a5),a5
                    dbra     d7,lbC0239C8
                    rts
lbC0239F8:
                    tst.l    (2,a3)
                    beq.b    lbC023A6C
                    tst.w    (10,a3)
                    bpl.b    lbC023A08
                    clr.w    (10,a3)
lbC023A08:
                    cmpi.w   #35,(10,a3)
                    ble.b    lbC023A16
                    move.w   #35,(10,a3)
lbC023A16:
                    move.l   (lbL023E24,pc),a4
                    move.w   (10,a3),d0
                    add.w    d0,d0
                    move.w   (a4,d0.w),d0
                    ext.l    d0
                    move.l   (6,a3),d2
                    cmp.l    d2,d0
                    blt.b    lbC023A40
                    clr.l    (2,a3)
                    clr.l    (6,a3)
                    clr.w    (10,a3)
                    clr.w    (12,a3)
                    bra.b    lbC023A6C
lbC023A40:
                    move.l   (2,a3),a0
                    move.w   (10,a3),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.l   (lbL023E20,pc),a4
                    move.l   (a4,d0.w),a4
                    jsr      (a4)
                    move.l   (2,a3),d0
                    move.l   a0,(2,a3)
                    sub.l    d0,a0
                    move.l   (6,a3),d2
                    sub.l    a0,d2
                    move.l   d2,(6,a3)
                    rts
lbC023A6C:
                    move.l   a1,d0
                    btst     #0,d0
                    beq.b    lbC023A84
                    sf       (a1)+
lbC023A76:
                    moveq    #0,d0
                    moveq    #39-1,d1
lbC023A7A:
                    move.l   d0,(a1)+
                    move.l   d0,(a1)+
                    dbra     d1,lbC023A7A
                    rts
lbC023A84:
                    bsr.b    lbC023A76
                    sf       (a1)+
                    rts
lbC023A8A:
                    lea      (lbB019D74),a0
                    lea      (314,a0),a1
                    move.l   a5,a4
                    bsr.b    lbC023AB6
                    move.b   (a0)+,d0
                    add.b    (a1)+,d0
                    move.b   d0,(a4)+
                    rts
lbC023AA0:
                    lea      (lbB019D74+1),a0
                    lea      (314,a0),a1
                    move.l   a5,a4
                    move.b   (a0)+,d0
                    add.b    (a1)+,d0
                    move.b   d0,(a4)+
lbC023AB6:
                    movem.l  d7/a2/a3/a5/a6,-(sp)
                REPT 6
                    movem.l  (a0)+,d0-d7/a2/a3/a5/a6
                    add.l    (a1)+,d0
                    add.l    (a1)+,d1
                    add.l    (a1)+,d2
                    add.l    (a1)+,d3
                    add.l    (a1)+,d4
                    add.l    (a1)+,d5
                    add.l    (a1)+,d6
                    add.l    (a1)+,d7
                    adda.l   (a1)+,a2
                    adda.l   (a1)+,a3
                    adda.l   (a1)+,a5
                    adda.l   (a1)+,a6
                    movem.l  d0-d7/a2/a3/a5/a6,(a4)
                    lea      (48,a4),a4
                ENDR
                    movem.l  (a0)+,d0-d5
                    add.l    (a1)+,d0
                    add.l    (a1)+,d1
                    add.l    (a1)+,d2
                    add.l    (a1)+,d3
                    add.l    (a1)+,d4
                    add.l    (a1)+,d5
                    movem.l  d0-d5,(a4)
                    lea      (24,a4),a4
                    movem.l  (sp)+,d7/a2/a3/a5/a6
                    rts
lbC023BB0:
                    lea      (lbL023D90),a6
                    lea      (a0),a1
                    move.l   a0,a2
                    adda.l   #43036,a2
                    move.l   a0,a3
                    adda.l   #43180,a3
                    moveq    #36-1,d7
lbC023BCA:
                    move.l   a1,(a2)+
                    moveq    #-1,d1
                    moveq    #0,d2
                    moveq    #0,d3
                    moveq    #-1,d4
                    move.l   (a6)+,d5
                    move.w   #313-1,d6
lbC023BDA:
                    cmp.w    d4,d3
                    beq      lbC023C72
                    move.w   d3,d0
                    sub.w    d4,d0
                    cmpi.w   #1,d0
                    beq.b    lbC023C06
                    cmpi.w   #2,d0
                    beq.b    lbC023BFC
                    lea      (lbC023CC6,pc),a0
                    move.l   (a0)+,(a1)+
                    move.w   (a0)+,(a1)+
                    moveq    #-1,d1
                    bra.b    lbC023C74
lbC023BFC:
                    lea      (lbC023CC2,pc),a0
                    move.l   (a0)+,(a1)+
                    moveq    #-1,d1
                    bra.b    lbC023C74
lbC023C06:
                    tst.w    d2
                    beq.b    lbC023C68
                    subq.w   #1,d2
                    beq.b    lbC023C40
                    subq.w   #1,d2
                    beq.b    lbC023C2A
                    subq.w   #1,d2
                    lea      (lbW023D40,pc),a0
                    tst.w    d1
                    bmi.b    lbC023C54
                    lea      (lbW023D64,pc),a0
                    subq.w   #1,d1
                    bmi.b    lbC023C54
                    lea      (lbW023D52,pc),a0
                    bra.b    lbC023C54
lbC023C2A:
                    lea      (lbW023D0A,pc),a0
                    tst.w    d1
                    bmi.b    lbC023C54
                    lea      (lbW023D2A,pc),a0
                    subq.w   #1,d1
                    bmi.b    lbC023C54
                    lea      (lbW023D1A,pc),a0
                    bra.b    lbC023C54
lbC023C40:
                    lea      (lbW023CDA,pc),a0
                    tst.w    d1
                    bmi.b    lbC023C54
                    lea      (lbW023CF6,pc),a0
                    subq.w   #1,d1
                    bmi.b    lbC023C54
                    lea      (lbW023CE8,pc),a0
lbC023C54:
                    move.w   (2,a0),d1
                    move.w   (a0),d0
                    suba.w   d0,a0
                    lsr.w    #1,d0
                    subq.w   #1,d0
lbC023C60:
                    move.w   (a0)+,(a1)+
                    dbra     d0,lbC023C60
                    bra.b    lbC023C74
lbC023C68:
                    move.w   (lbC023CC0),(a1)+
                    moveq    #-1,d1
                    bra.b    lbC023C74
lbC023C72:
                    addq.w   #1,d2
lbC023C74:
                    move.w   d3,d4
                    swap     d3
                    add.l    d5,d3
                    swap     d3
                    dbra     d6,lbC023BDA
                    tst.w    d2
                    ble.b    lbC023CB2
                    subq.w   #1,d2
                    beq.b    lbC023CA8
                    subq.w   #1,d2
                    beq.b    lbC023C9C
                    subq.w   #1,d2
                    lea      (lbC023D7E,pc),a0
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    bra.b    lbC023CB2
lbC023C9C:
                    lea      (lbC023D72,pc),a0
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    bra.b    lbC023CB2
lbC023CA8:
                    lea      (lbC023D68,pc),a0
                    move.l   (a0)+,(a1)+
                    move.l   (a0)+,(a1)+
                    move.w   (a0)+,(a1)+
lbC023CB2:
                    move.w   (lbC023D8E,pc),(a1)+
                    move.w   d3,(a3)+
                    dbra     d7,lbC023BCA
                    moveq    #OK,d0
                    rts
lbC023CC0:
                    move.b   (a0)+,(a1)+
lbC023CC2:
                    move.b   (a0)+,(a1)+
                    addq.w   #1,a0
lbC023CC6:
                    move.b   (1,a0),(a1)+
                    addq.w   #2,a0
                    move.b   (-1,a1),d0
                    move.b   (a0)+,d1
                    add.b    d1,d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
                    move.b   d1,(a1)+
lbW023CDA:
                    dc.w     14
                    dc.w     1
                    move.b   (a0)+,d0
                    add.b    d0,d1
                    asr.b    #1,d1
                    move.b   d1,(a1)+
                    move.b   d0,(a1)+
lbW023CE8:
                    dc.w     10,0
                    move.b   (a0)+,d1
                    add.b    d1,d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
                    move.b   d1,(a1)+
lbW023CF6:
                    dc.w     10,1
                    move.b   (a0)+,d0
                    move.b   d0,d1
                    add.b    (-1,a1),d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
                    move.b   d0,(a1)+
                    move.b   d1,(a1)+
lbW023D0A:
                    dc.w     16,1
                    move.b   (a0)+,d0
                    add.b    d0,d1
                    asr.b    #1,d1
                    move.b   d1,(a1)+
                    move.b   d1,(a1)+
                    move.b   d0,(a1)+
lbW023D1A:
                    dc.w     12,0
                    move.b   (a0)+,d1
                    add.b    d1,d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
                    move.b   d0,(a1)+
                    move.b   d1,(a1)+
lbW023D2A:
                    dc.w     12,1
                    move.b   (a0)+,d0
                    move.b   d0,d1
                    add.b    (-1,a1),d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
                    move.b   d0,(a1)+
                    move.b   d1,(a1)+
                    move.b   d1,(a1)+
lbW023D40:
                    dc.w     18,1
                    move.b   (a0)+,d0
                    add.b    d0,d1
                    asr.b    #1,d1
                    move.b   d1,(a1)+
                    move.b   d1,(a1)+
                    move.b   d0,(a1)+
                    move.b   d0,(a1)+
lbW023D52:
                    dc.w     14,0
                    move.b   (a0)+,d1
                    add.b    d1,d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
                    move.b   d0,(a1)+
                    move.b   d1,(a1)+
                    move.b   d1,(a1)+
lbW023D64:
                    dc.w     14,1
lbC023D68:
                    move.b   (-1,a1),d0
                    add.b    (a0),d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
lbC023D72:
                    move.b   (a0),d0
                    add.b    (-1,a1),d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
                    move.b   d0,(a1)+
lbC023D7E:
                    move.b   (a0),d0
                    move.b   d0,d1
                    add.b    (-1,a1),d0
                    asr.b    #1,d0
                    move.b   d0,(a1)+
                    move.b   d0,(a1)+
                    move.b   d1,(a1)+
lbC023D8E:
                    rts
lbL023D90:
                    dc.l     $4409,$4814,$4C6E,$50E3,$55E6,$5B00,$606C,$662C,$6C40,$72A5,$7955
                    dc.l     $8090,$8813,$9028,$98DC,$A1C7,$ABCC,$B600,$C0D9,$CC59,$D881,$E54A
                    dc.l     $F2AA,$101B2,$11026,$12051,$13286,$1438E,$15696,$16C00,$181B2,$19745
                    dc.l     $1AF68,$1CA95,$1E555,$20365
lbL023E20:
                    dc.l     0
lbL023E24:
                    dc.l     0
lbC023E28:
                    lea      (OK_PALTable,pc),a0
                    tst.b    d0
                    beq.b    lbC023E34
                    lea      (OK_NTSCTable,pc),a0
lbC023E34:
                    move.l   a0,(lbL0243B2)
                    bsr      lbC0237AC
                    moveq    #0,d1
                    lea      (OK_PBuffs),a0
                    moveq    #16-1,d0
.OK_ClearPBuffs:
                    move.l   d1,(a0)+
                    dbra     d0,.OK_ClearPBuffs
                    lea      (OK_MixBuff_2),a0
                    lea      (OK_MixBuff_2+MIX_BUFFERS_LEN_2),a1
                    move.w   #(MIX_BUFFERS_LEN_2/4)-1,d0
.OK_ClearMixBuffs:
                    move.l   d1,(a0)+
                    move.l   d1,(a1)+
                    dbra     d0,.OK_ClearMixBuffs
                    lea      (OK_ChannelsModes),a0
                    moveq    #0,d1
                    moveq    #4-1,d0
.OK_GetChannelsModes:
                    or.w     (a0)+,d1
                    ror.w    #1,d1
                    dbra     d0,.OK_GetChannelsModes
                    ror.w    #5,d1
                    move.w   d1,(OK_HWChansBits)
                    lea      (_CUSTOM),a6
                    move.w   #DMAF_AUDIO,(DMACON,a6)
                    lea      (OK_OuputBuff_2),a0
                    move.l   a0,(AUD0LCH,a6)
                    move.l   a0,(AUD1LCH,a6)
                    move.l   a0,(AUD2LCH,a6)
                    move.l   a0,(AUD3LCH,a6)
                    moveq    #82/2,d0
                    move.w   d0,(AUD0LEN,a6)
                    move.w   d0,(AUD1LEN,a6)
                    move.w   d0,(AUD2LEN,a6)
                    move.w   d0,(AUD3LEN,a6)
                    move.w   #856,d0
                    move.w   d0,(AUD0PER,a6)
                    move.w   d0,(AUD1PER,a6)
                    move.w   d0,(AUD2PER,a6)
                    move.w   d0,(AUD3PER,a6)
                    move.w   #$FF,(ADKCON,a6)
                    bsr      wait_raster
                    bsr      wait_raster
                    st       (OK_StartDMAFlg)
                    rts
OK_HWChansBits:
                    dc.w     0
OK_StartDMAFlg:
                    dc.w     0

; ===========================================================================
OK_Play_2:
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    beq.b    .OK_Midi_Out
                    move.b   (OK_StartDMAFlg,pc),d0
                    beq.b    .OK_TurnDMAOn
                    move.w   #DMAF_SETCLR|DMAF_AUDIO,(_CUSTOM|DMACON)
                    sf       (OK_StartDMAFlg)
.OK_TurnDMAOn:
                    bsr      OK_SetPeriods
.OK_Midi_Out:
                    bsr      OK_ReplayHandler
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    beq.b    .OK_Midi_Out_2
                    lea      (OK_ChannelsData),a0
                    lea      (OK_MixBuff1Ptr,pc),a2
                    move.l   (a2)+,a1
                    move.l   (a2),-(a2)
                    move.l   a1,(4,a2)
                    moveq    #0,d0
.OK_MixAllBuffers:
                    tst.w    (a0)
                    beq.b    .OK_NothingToMix
                    movem.l  d0/a0-a2,-(sp)
                    bsr      OK_MixBuffers
                    movem.l  (sp)+,d0/a0-a2
.OK_NothingToMix:
                    lea      (28,a0),a0
                    lea      ((MIX_BUFFERS_LEN_2/4),a1),a1
                    addq.w   #1,d0
                    cmpi.w   #4,d0
                    bne.b    .OK_MixAllBuffers
                    bra      OK_AudInt
.OK_Midi_Out_2:
                    rts

; ===========================================================================
OK_MixBuffers:
                    tst.l    (2,a0)
                    beq.b    lbC023F80
                    tst.l    (16,a0)
                    beq.b    lbC023F84
                    bsr      lbC023F8C
                    move.w   d1,d2
                    lea      (14,a0),a0
                    bsr      lbC023F8C
                    cmp.w    d1,d2
                    blt.b    lbC023F74
                    move.l   a1,a2
                    lea      (-14,a0),a1
                    bra      lbC023FA6
lbC023F74:
                    move.l   a1,a2
                    lea      (-14,a0),a1
                    exg      a0,a1
                    bra      lbC023FA6
lbC023F80:
                    lea      (14,a0),a0
lbC023F84:
                    bsr      lbC023F8C
                    bra      lbC0241D0
lbC023F8C:
                    move.w   (10,a0),d1
                    bpl.b    lbC023F98
                    clr.w    (10,a0)
                    rts
lbC023F98:
                    cmpi.w   #33,d1
                    ble.b    lbC023FA4
                    move.w   #33,(10,a0)
lbC023FA4:
                    rts
lbC023FA6:
                    lea      (OK_PBuffs),a3
                    lsl.w    #4,d0
                    adda.w   d0,a3
                    move.w   (10,a1),d0
                    add.w    d0,d0
                    lea      (OK_FullPeriodTab),a4
                    move.w   (a4,d0.w),d2
                    move.w   d2,(4,a3)
                    move.w   (10,a0),d3
                    add.w    d3,d3
                    move.w   (a4,d3.w),d3
                    move.l   (lbL0243B2,pc),a4
                    move.w   (a4,d0.w),d1
                    add.w    (8,a3),d1
                    move.w   d1,(6,a3)
                    swap     d2
                    clr.w    d2
                    divu.w   d3,d2
                    move.l   (6,a0),d0
                    lsr.l    #1,d0
                    move.l   a2,(a3)
                    movem.l  d0/a0/a1,-(sp)
                    move.l   (2,a0),a0
                    move.l   a2,a1
                    bsr      lbC0240DA
                    move.l   a0,a4
                    movem.l  (sp)+,d1/a0/a1
                    sub.w    d0,d1
                    bcc.b    lbC024016
                    clr.l    (2,a0)
                    clr.l    (6,a0)
                    clr.w    (10,a0)
                    clr.w    (12,a0)
                    bra.b    lbC024020
lbC024016:
                    move.l   a4,(2,a0)
                    add.l    d1,d1
                    move.l   d1,(6,a0)
lbC024020:
                    move.l   (6,a1),d0
                    lsr.l    #1,d0
                    move.w   (6,a3),d1
                    movem.l  d0/d1/a1,-(sp)
                    move.l   (2,a1),a0
                    move.l   a2,a1
                    bsr      lbC024060
                    move.l   a0,a4
                    movem.l  (sp)+,d0/d1/a1
                    sub.w    d1,d0
                    bcc.b    lbC024054
                    clr.l    (2,a1)
                    clr.l    (6,a1)
                    clr.w    (10,a1)
                    clr.w    (12,a1)
                    rts
lbC024054:
                    move.l   a4,(2,a1)
                    add.l    d0,d0
                    move.l   d0,(6,a1)
                    rts
lbC024060:
                    cmp.w    d0,d1
                    bhi.b    lbC02406A
                    move.w   d1,d0
lbC02406A:
                    cmpi.w   #32,d0
                    bcs.b    lbC0240B6
                REPT 16
                    move.l   (a0)+,d1
                    add.l    d1,(a1)+
                ENDR
                    subi.w   #32,d0
                    bra.b    lbC02406A
lbC0240B6:
                    cmpi.w   #8,d0
                    bcs.b    lbC0240D4
                REPT 4
                    move.l   (a0)+,d1
                    add.l    d1,(a1)+
                ENDR
                    subq.w   #8,d0
                    bra.b    lbC0240B6
lbC0240D0:
                    move.w   (a0)+,d1
                    add.w    d1,(a1)+
lbC0240D4:
                    dbra     d0,lbC0240D0
                    rts
lbC0240DA:
                    tst.w    d2
                    bne.b    lbC0240E8
                    move.w   d1,-(sp)
                    bsr      lbC0242F4
                    move.w   (sp)+,d0
                    rts
lbC0240E8:
                    move.l   d3,-(sp)
                    move.w   d2,d3
                    mulu.w   d1,d3
                    swap     d3
                    cmp.w    d0,d3
                    bhi.b    lbC0240FC
                    move.w   d2,d0
                    bsr      lbC02410A
                    bra.b    lbC024106
lbC0240FC:
                    move.w   d0,-(sp)
                    move.w   d1,d0
                    bsr      lbC024362
                    move.w   (sp)+,d0
lbC024106:
                    move.l   (sp)+,d3
                    rts
lbC02410A:
                    movem.l  d2-d5/a2,-(sp)
                    move.l   a0,a2
                    move.w   d1,d2
                    moveq    #0,d3
                    subq.w   #1,d1
lbC024116:
                    subq.w   #8,d2
                    bmi      lbC0241A0
            REPT    16
                INLINE
                    sub.w    d0,d3
                    bcc.b    .OK_NoFetch
                    move.b   (a0)+,d5
.OK_NoFetch:
                    move.b   d5,(a1)+
                EINLINE
            ENDR
                    bra      lbC024116
lbC0241A0:
                    addq.w   #8,d2
                    bra.b    lbC0241B4
lbC0241A4:
            REPT    2
                INLINE
                    sub.w    d0,d3
                    bcc.b    .OK_NoFetch
                    move.b   (a0)+,d5
.OK_NoFetch:
                    move.b   d5,(a1)+

                EINLINE
            ENDR
lbC0241B4:
                    dbra     d2,lbC0241A4
                    sub.l    a0,a2
                    move.w   a2,d0
                    neg.w    d0
                    btst     #0,d0
                    beq.b    .OK_NoOddLength
                    addq.w   #1,a0
                    addq.w   #1,d0
.OK_NoOddLength:
                    lsr.w    #1,d0
                    movem.l  (sp)+,d2-d5/a2
                    rts
lbC0241D0:
                    lea      (OK_PBuffs),a2
                    lsl.w    #4,d0
                    adda.w   d0,a2
                    tst.l    (2,a0)
                    beq.b    lbC02423E
                    move.w   (10,a0),d0
                    add.w    d0,d0
                    lea      (OK_FullPeriodTab),a3
                    move.w   (a3,d0.w),(4,a2)
                    move.l   (lbL0243B2,pc),a3
                    move.w   (a3,d0.w),d1
                    add.w    (8,a2),d1
                    move.w   d1,(6,a2)
                    move.l   (6,a0),d0
                    lsr.l    #1,d0
                    move.l   a1,(a2)
                    movem.l  d0/d1/a0,-(sp)
                    move.l   (2,a0),a0
                    bsr      lbC0242F4
                    move.l   a0,a1
                    movem.l  (sp)+,d0/d1/a0
                    sub.w    d1,d0
                    bcc.b    lbC024232
                    clr.l    (2,a0)
                    clr.l    (6,a0)
                    clr.w    (10,a0)
                    clr.w    (12,a0)
                    rts
lbC024232:
                    move.l   a1,(2,a0)
                    add.l    d0,d0
                    move.l   d0,(6,a0)
                    rts
lbC02423E:
                    move.l   a1,(a2)
                    move.w   (OK_FullPeriodTab),(4,a2)
                    move.l   (lbL0243B2,pc),a0
                    move.w   (a0),d0
                    add.w    (8,a2),d0
                    move.w   d0,(6,a2)
                    bra      lbC024362

; ===========================================================================
OK_SetPeriods:
                    movem.l  d2/d3/a2,-(sp)
                    lea      (OK_PBuffs),a0
                    lea      (_CUSTOM|INTREQR),a2
                    lea      (AUD0PER-INTREQR,a2),a1
                    moveq    #4-1,d0
.OK_SetHWChans:
                    move.w   (4,a0),d1
                    beq.b    .OK_NoNote
                    move.w   d1,(a1)
                    move.w   (a2),(10,a0)
.OK_NoNote:
                    lea      (16,a0),a0
                    lea      ($10,a1),a1
                    dbra     d0,.OK_SetHWChans
                    lea      (OK_PBuffs),a0
                    moveq    #7,d1
.OK_SetSWChans:
                    tst.l    (a0)
                    beq.b    .OK_NoData
                    clr.w    (8,a0)
                    move.w   (10,a0),d0
                    btst     d1,d0
                    beq.b    .OK_NoData
                    addq.w   #1,(8,a0)
.OK_NoData:
                    lea      (16,a0),a0
                    addq.w   #1,d1
                    cmpi.w   #7+4,d1
                    bne.b    .OK_SetSWChans
                    movem.l  (sp)+,d2/d3/a2
                    rts

; ===========================================================================
OK_AudInt:
                    move.w   (OK_HWChansBits,pc),d1
OK_WaitChannel:
                    move.w   (_CUSTOM|INTREQR),d0
                    and.w    d1,d0
                    cmp.w    d1,d0
                    bne.b    OK_WaitChannel
                    move.w   d1,(_CUSTOM|INTREQ)
                    lea      (OK_PBuffs),a0
                    lea      (_CUSTOM|AUD0LCH),a1
                    moveq    #4-1,d0
.OK_SetChannelsSamples:
                    move.l   (a0),d1
                    beq.b    .OK_NoNewSample
                    move.l   d1,(a1)
                    move.w   (6,a0),(4,a1)
.OK_NoNewSample:
                    lea      (16,a0),a0
                    lea      ($10,a1),a1
                    dbra     d0,.OK_SetChannelsSamples
                    rts

; ===========================================================================
lbC0242F4:
                    movem.l  d2/a2,-(sp)
                    move.w   d1,d2
                    cmp.w    d0,d2
                    bhi.b    lbC024306
                    move.w   d2,d0
                    bsr      lbC02431C
                    bra.b    lbC024316
lbC024306:
                    sub.w    d0,d2
                    bsr      lbC02431C
                    move.l   a0,a2
                    move.w   d2,d0
                    bsr      lbC024362
                    move.l   a2,a0
lbC024316:
                    movem.l  (sp)+,d2/a2
                    rts
lbC02431C:
                    cmpi.w   #32,d0
                    bcs.b    lbC024348
                REPT 16
                    move.l   (a0)+,(a1)+
                ENDR
                    subi.w   #32,d0
                    bra.b    lbC02431C
lbC024348:
                    cmpi.w   #8,d0
                    bcs.b    lbC02435C
                REPT 4
                    move.l   (a0)+,(a1)+
                ENDR
                    subq.w   #8,d0
                    bra.b    lbC024348
lbC02435A:
                    move.w   (a0)+,(a1)+
lbC02435C:
                    dbra     d0,lbC02435A
                    rts
lbC024362:
                    moveq    #0,d1
lbC024364:
                    cmpi.w   #32,d0
                    bcs.b    lbC024390
                REPT 16
                    move.l   d1,(a1)+
                ENDR
                    subi.w   #32,d0
                    bra.b    lbC024364
lbC024390:
                    cmpi.w   #8,d0
                    bcs.b    lbC0243A4
                REPT 4
                    move.l   d1,(a1)+
                ENDR
                    subq.w   #8,d0
                    bra.b    lbC024390
lbC0243A2:
                    move.w   d1,(a1)+
lbC0243A4:
                    dbra     d0,lbC0243A2
                    rts
OK_MixBuff1Ptr:
                    dc.l     OK_MixBuff_2
                    dc.l     OK_MixBuff_2+MIX_BUFFERS_LEN_2
lbL0243B2:
                    dc.l     0
OK_PALTable:
                    dc.w     $29,$2B,$2E,$31,$34,$37,$3A,$3E,$42,$45,$4A,$4E,$53,$57,$5D,$62,$68
                    dc.w     $6F,$75,$7C,$84,$8B,$94,$9D,$A6,$AF,$BA,$C5,$D0,$DE,$EB,$F8,$107,$117
OK_NTSCTable:
                    dc.w     $22,$25,$27,$29,$2C,$2E,$31,$34,$37,$3A,$3E,$42,$45,$4A,$4E,$53,$58
                    dc.w     $5D,$63,$68,$6F,$75,$7C,$84,$8B,$94,$9D,$A6,$AF,$BA,$C6,$D1,$DD,$EB

; ===========================================================================
trigger_vumeter:
                    move.w   d7,-(sp)
                    move.l   a0,-(sp)
                    lea      (vumeters_levels),a0
                    add.w    d7,d7
                    add.w    d7,d7
                    ; picture<<16|pause before decaying
                    move.l   #(8<<16)|2,(a0,d7.w)
                    move.l   (sp)+,a0
                    move.w   (sp)+,d7
                    rts

; ===========================================================================
clear_vumeters:
                    lea      (vumeters_levels),a0
                    moveq    #(32/4)-1,d0
.clear:
                    clr.l    (a0)+
                    dbra     d0,.clear
draw_vumeters:
                    lea      (vumeters_levels+32),a0
                    lea      (main_screen+2632),a1
                    lea      (vumeters_data,pc),a2
                    moveq    #8-1,d7
.loop:
                    subq.w   #4,a0
                    move.w   (a0),d0
                    lsl.w    #3,d0
                    lea      (a2,d0.w),a3
                    move.b   (a3)+,(a1)+
                    move.b   (a3)+,((SCREEN_BYTES*1)-1,a1)
                    move.b   (a3)+,((SCREEN_BYTES*2)-1,a1)
                    move.b   (a3)+,((SCREEN_BYTES*3)-1,a1)
                    move.b   (a3)+,((SCREEN_BYTES*4)-1,a1)
                    move.b   (a3)+,((SCREEN_BYTES*5)-1,a1)
                    move.b   (a3)+,((SCREEN_BYTES*6)-1,a1)
                    move.b   (a3)+,((SCREEN_BYTES*7)-1,a1)
                    tst.w    d0
                    beq.b    .sub
                    subq.w   #1,(2,a0)
                    bne.b    .sub
                    subq.w   #1,(a0)
                    move.w   #2,(2,a0)
.sub:
                    dbra     d7,.loop
                    rts
vumeters_data:
                    dc.b     %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
                    dc.b     %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%11111111
                    dc.b     %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%11111111,%11111111
                    dc.b     %00000000,%00000000,%00000000,%00000000,%00000000,%11111111,%10000001,%11111111
                    dc.b     %00000000,%00000000,%00000000,%00000000,%11111111,%10000001,%10000001,%11111111
                    dc.b     %00000000,%00000000,%00000000,%11111111,%10000001,%10000001,%10000001,%11111111
                    dc.b     %00000000,%00000000,%11111111,%10000001,%10000001,%10000001,%10000001,%11111111
                    dc.b     %00000000,%11111111,%10000001,%10000001,%10000001,%10000001,%10000001,%11111111
                    dc.b     %11111111,%10000001,%10000001,%10000001,%10000001,%10000001,%10000001,%11111111

; ===========================================================================
go_to_cli_workbench:
                    move.l   #do_go_to_cli_workbench,(current_cmd_ptr)
                    rts
do_go_to_cli_workbench:
                    EXEC     Disable
                    jsr      (restore_sys_requesters_function,pc)
                    jsr      (remove_midi_ints)
                    jsr      restore_screen
                    EXEC     Enable
                    jsr      (open_workbench)
                    beq.b    .error_workbench
                    lea      (our_window_struct),a0
                    INT      OpenWindow
                    move.l   d0,(window_handle)
                    beq.b    .error_window
                    move.l   d0,a0
                    move.l   (wd_UserPort,a0),(window_user_port)
                    move.l   (window_user_port),a0
                    EXEC     WaitPort
                    move.l   (window_user_port),a0
                    EXEC     GetMsg
                    move.l   d0,a1
                    EXEC     ReplyMsg
                    move.l   (window_handle),a0
                    INT      CloseWindow
.error_window:
                    jsr      (close_workbench)
.error_workbench:
                    EXEC     Disable
                    jsr      (patch_sys_requesters_function,pc)
                    jsr      (reinstall_midi_ints,pc)
                    EXEC     Enable
                    bsr      install_our_copperlist
                    bra      lbC01FBF2
lbC0245D0:
                    bsr      ask_are_you_sure_requester
                    bne.b    lbC0245DC
                    st       (quit_flag)
lbC0245DC:
                    rts

; ===========================================================================
display_error:
                    movem.l  d0-d7/a0-a6,-(sp)
                    move.l   (pattern_bitplane_offset,pc),d1
                    beq.b    .no_error
                    lea      (errors_text,pc),a0
                    mulu.w   #19,d0
                    adda.l   d0,a0
                    jsr      (display_messagebox)
                    bsr      lbC0246B8
                    jsr      (remove_messagebox)
.no_error:
                    movem.l  (sp)+,d0-d7/a0-a6
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
display_dos_error:
                    movem.l  d0-d7/a0-a6,-(sp)
                    move.l   (pattern_bitplane_offset,pc),d0
                    beq.b    .no_error
                    move.l   (DOSBase,pc),d0
                    beq.b    .no_error
                    DOS      IoErr
                    tst.l    d0
                    beq.b    .no_error
                    lea      (dos_errors_text-19,pc),a0
                    lea      (dos_errors_codes,pc),a1
.search:
                    lea      (19,a0),a0
                    move.w   (a1)+,d1
                    beq.b    .found
                    cmp.w    d1,d0
                    bne.b    .search
.found:
                    jsr      (display_messagebox)
                    bsr.b    lbC0246B8
                    jsr      (remove_messagebox)
.no_error:
                    movem.l  (sp)+,d0-d7/a0-a6
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
display_trackdisk_error:
                    movem.l  d0-d7/a0-a6,-(sp)
                    move.l   (pattern_bitplane_offset),d0
                    beq.b    .no_error
                    moveq    #0,d0
                    move.b   (trackdisk_device+IO_ERROR),d0
                    move.w   d0,-(sp)
                    lea      (trackdisk_device),a1
                    move.w   #TD_MOTOR,(IO_COMMAND,a1)
                    clr.l    (IO_LENGTH,a1)
                    EXEC     DoIO
                    move.w   (sp)+,d0
                    lea      (trackdisk_errors_text-19,pc),a0
                    lea      (trackdisk_errors_codes,pc),a1
.search:
                    lea      (19,a0),a0
                    move.w   (a1)+,d1
                    beq.b    .found
                    cmp.w    d1,d0
                    bne.b    .search
.found:
                    jsr      (display_messagebox)
                    bsr.b    lbC0246B8
                    jsr      (remove_messagebox)
.no_error:
                    movem.l  (sp)+,d0-d7/a0-a6
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
pattern_bitplane_offset:
                    dc.l     0
lbC0246B8:
                    lea      (lbW0246C0,pc),a0
                    bra      lbC020626
lbW0246C0:
                    dc.w     1
                    dc.l     lbC0246D4
                    dc.w     4
                    dc.l     lbC0246DE
                    dc.w     7
                    dc.l     lbC0246DE
                    dc.w     0
lbC0246D4:
                    btst     #15,d1
                    beq.b    lbC0246DE
                    moveq    #ERROR,d0
                    rts
lbC0246DE:
                    moveq    #OK,d0
                    rts

; ===========================================================================
ask_are_you_sure_requester:
                    lea      (are_you_sure_text,pc),a0
                    bra      ask_yes_no_requester
are_you_sure_text:
                    dc.b     '  Are You Sure ?  ',0
                    even

; ===========================================================================
ask_yes_no_requester:
                    move.l   (pattern_bitplane_offset,pc),d0
                    beq.b    .no_display
                    movem.l  d1-d7/a1-a6,-(sp)
                    jsr      (display_messagebox)
                    lea      (lbW02473A,pc),a0
                    bsr      lbC020626
                    jsr      (remove_messagebox)
                    movem.l  (sp)+,d1-d7/a1-a6
                    move.b   (lbB024768,pc),d0
                    rts
.no_display:
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    moveq    #0,d0
                    rts
lbW02473A:
                    dc.w     1
                    dc.l     lbC02474E
                    dc.w     4
                    dc.l     lbC02475C
                    dc.w     7
                    dc.l     lbC02475C
                    dc.w     0
lbC02474E:
                    moveq    #0,d0
                    cmpi.b   #$79,d1
                    beq.b    lbC02475E
                    cmpi.b   #$7A,d1
                    beq.b    lbC02475E
lbC02475C:
                    moveq    #ERROR,d0
lbC02475E:
                    move.b   d0,(lbB024768)
                    moveq    #OK,d0
                    rts
lbB024768:
                    dc.b     0
                    even

; ===========================================================================
display_waiting_for_drives_message:
                    tst.b    (waiting_for_drives_text_flag)
                    bne.b    .already_displayed
                    st       (waiting_for_drives_text_flag)
                    movem.l  d0-d7/a0-a6,-(sp)
                    move.l   (pattern_bitplane_offset,pc),d0
                    beq.b    .no_display
                    lea      (waiting_for_drives_text,pc),a0
                    jsr      (display_messagebox)
.no_display:
                    movem.l  (sp)+,d0-d7/a0-a6
.already_displayed:
                    rts

; ===========================================================================
remove_waiting_for_drives_message:
                    tst.b    (waiting_for_drives_text_flag)
                    beq.b    .not_already_displayed
                    sf       (waiting_for_drives_text_flag)
                    movem.l  d0-d7/a0-a6,-(sp)
                    move.l   (pattern_bitplane_offset,pc),d0
                    beq.b    .no_display
                    jsr      (remove_messagebox)
.no_display:
                    movem.l  (sp)+,d0-d7/a0-a6
.not_already_displayed:
                    rts
waiting_for_drives_text_flag:
                    dc.b     0
                    even

; ===========================================================================
lbC0247B8:
                    movem.l  a0/a1,(lbL01B7D2)
                    movem.l  d2-d7/a0-a6,-(sp)
                    clr.l    (lbW01B7DA)
                    move.l   (lbL01B7D2),a0
                    jsr      (display_messagebox)
lbC0247D6:
                    moveq    #$2F,d0
                    move.l   (pattern_bitplane_offset,pc),d1
                    subi.l   #main_screen,d1
                    divu.w   #(SCREEN_BYTES*8),d1
                    add.w    (lbW026954),d1
                    addq.w   #1,d1
                    move.w   d1,(lbW024874)
                    moveq    #2,d2
                    moveq    #2,d3
                    moveq    #0,d4
                    lea      (lbW01B7DA),a0
                    jsr      (lbC0264DC)
                    bmi.b    lbC024866
                    move.b   (lbW01B7DA),d0
                    bsr      lbC01F094
                    bmi.b    lbC0247D6
                    move.b   d0,(lbW01B7DA)
                    jsr      (remove_messagebox)
                    move.l   (lbL01B7D6),a0
                    jsr      (display_messagebox)
lbC02482C:
                    lea      (lbW01B7DC),a0
                    moveq    #$2F,d0
                    move.w   (lbW024874,pc),d1
                    moveq    #2,d2
                    moveq    #2,d3
                    moveq    #0,d4
                    jsr      (lbC0264DC)
                    bmi.b    lbC024866
                    move.b   (lbW01B7DC),d0
                    bsr      lbC01F094
                    bmi.b    lbC02482C
                    move.b   d0,(lbW01B7DC)
                    jsr      (remove_messagebox)
                    movem.l  (sp)+,d2-d7/a0-a6
                    moveq    #OK,d0
                    rts
lbC024866:
                    jsr      (remove_messagebox)
                    movem.l  (sp)+,d2-d7/a0-a6
                    moveq    #ERROR,d0
                    rts
lbW024874:
                    dc.w     0
lbC024876:
                    jsr      (display_messagebox)
lbC02487C:
                    moveq    #$2F,d0
                    move.l   (pattern_bitplane_offset,pc),d1
                    subi.l   #main_screen,d1
                    divu.w   #(SCREEN_BYTES*8),d1
                    add.w    (lbW026954),d1
                    addq.w   #1,d1
                    lea      (lbW0248CA,pc),a0
                    clr.w    (a0)
                    moveq    #2,d2
                    moveq    #2,d3
                    moveq    #0,d4
                    jsr      (lbC0264DC)
                    bmi.b    lbC0248C0
                    move.b   (lbW0248CA,pc),d0
                    bsr      lbC01F094
                    bmi.b    lbC02487C
                    move.w   d0,-(sp)
                    jsr      (remove_messagebox)
                    move.w   (sp)+,d0
                    moveq    #0,d1
                    rts
lbC0248C0:
                    jsr      (remove_messagebox)
                    moveq    #ERROR,d0
                    rts
lbW0248CA:
                    dc.w     0
lbC0248CC:
                    move.l   a0,-(sp)
                    move.l   a1,-(sp)
                    move.l   a1,a0
                    jsr      (lbC025DA6)
                    subq.w   #1,d0
                    move.w   d0,(lbW024948)
                    move.l   (sp)+,a1
                    move.l   a1,a0
                    lea      (lbL02494A,pc),a1
                    moveq    #3,d0
                    jsr      (lbC025DB2)
                    move.l   (sp)+,a0
                    jsr      (display_messagebox)
                    moveq    #46,d0
                    move.l   (pattern_bitplane_offset,pc),d1
                    subi.l   #main_screen,d1
                    divu.w   #(SCREEN_BYTES*8),d1
                    add.w    (lbW026954),d1
                    addq.w   #1,d1
                    lea      (lbL02494A,pc),a0
                    moveq    #3,d2
                    moveq    #3,d3
                    move.w   (lbW024948,pc),d4
                    jsr      (lbC0264DC)
                    bmi.b    lbC02493E
                    lea      (lbL02494A,pc),a0
                    jsr      (lbC0257A6)
                    bmi.b    lbC02493E
                    move.w   d0,-(sp)
                    jsr      (remove_messagebox)
                    move.w   (sp)+,d0
                    moveq    #0,d1
                    rts
lbC02493E:
                    jsr      (remove_messagebox)
                    moveq    #ERROR,d0
                    rts
lbW024948:
                    dc.w     0
lbL02494A:
                    dc.l     0

; ===========================================================================
waiting_for_drives_text:
                    dc.b     ' Drives Working ! ',0
errors_text:
                    dc.b     '   No Memory !!   ',0
                    dc.b     '   What Block ?   ',0
                    dc.b     ' What Position ?? ',0
                    dc.b     'Sample Too Long !!',0
                    dc.b     '  What Sample ??  ',0
                    dc.b     ' Sample Cleared ! ',0
                    dc.b     'No More Patterns !',0
                    dc.b     'No More Positions!',0
                    dc.b     ' Pattern In Use ! ',0
                    dc.b     'Copy Buffer Free !',0
                    dc.b     'No More Samples !!',0
                    dc.b     'Only In Mode 4/B !',0
                    dc.b     '  Left One Bit !  ',0
                    dc.b     '  Block Copied !  ',0
                    dc.b     ' Sample Clipped ! ',0
                    dc.b     'Sample Too Short !',0
                    dc.b     'IFF Struct Error !',0
                    dc.b     '  Same Sample !!  ',0
                    dc.b     'Different Modes !!',0
                    dc.b     ' Zero Not Found ! ',0
                    dc.b     ' Can''t Install !! ',0
                    dc.b     'Already Installed!',0
                    dc.b     '    No OkDir !    ',0
                    dc.b     'Can''t Open Device!',0
                    dc.b     '  Verify Error !  ',0
                    dc.b     '  What Samples ?  ',0
                    dc.b     'Can''t Convert Song',0
                    dc.b     'OK Struct Error !!',0
                    dc.b     'ST Struct Error !!',0
                    dc.b     '   What File ??   ',0
                    dc.b     'Not a Directory !!',0
                    dc.b     'No More Entries !!',0
                    dc.b     'Nothing Selected !',0
                    dc.b     'No MultiSelection!',0
                    dc.b     'CopyBuffer Empty !',0
                    dc.b     '   No Entries !   ',0
                    dc.b     'EF Struct Error !!',0
                    dc.b     '  Only in PAL !!  ',0
dos_errors_text:
                    dc.b     ' No Free Store !! ',0
                    dc.b     'Task Table Full !!',0
                    dc.b     ' Line Too Long !! ',0
                    dc.b     'File Not Object !!',0
                    dc.b     'Invalid Library !!',0
                    dc.b     ' No Default Dir ! ',0
                    dc.b     ' Object In Use !! ',0
                    dc.b     ' Object Exists !! ',0
                    dc.b     ' Dir Not Found !! ',0
                    dc.b     'Object Not Found !',0
                    dc.b     'Bad Stream Name !!',0
                    dc.b     'Object Too Large !',0
                    dc.b     'Action not known !',0
                    dc.b     '  Invalid Name !  ',0
                    dc.b     '  Invalid Lock !  ',0
                    dc.b     'Object Wrong Type!',0
                    dc.b     'Disk Not Validated',0
                    dc.b     ' Disk Protected ! ',0
                    dc.b     'Rename Across Devs',0
                    dc.b     ' Dir Not Empty !! ',0
                    dc.b     'Too Many Levels !!',0
                    dc.b     'Device Not Mounted',0
                    dc.b     '   Seek Error !   ',0
                    dc.b     'Comment Too Big !!',0
                    dc.b     '   Disk Full !!   ',0
                    dc.b     'Delete Protected !',0
                    dc.b     'Write Protected !!',0
                    dc.b     ' Read Protected ! ',0
                    dc.b     ' Not A Dos Disk ! ',0
                    dc.b     '    No Disk !!    ',0
                    dc.b     'No More Entries !!',0
                    dc.b     'Read/Write Error !',0
                    dc.b     '   DOS Error !!   ',0
dos_errors_codes:
                    dc.w     ERROR_NO_FREE_STORE,ERROR_TASK_TABLE_FULL,ERROR_LINE_TOO_LONG,ERROR_FILE_NOT_OBJECT
                    dc.w     ERROR_INVALID_RESIDENT_LIBRARY,ERROR_NO_DEFAULT_DIR,ERROR_OBJECT_IN_USE,ERROR_OBJECT_EXISTS
                    dc.w     ERROR_DIR_NOT_FOUND,ERROR_OBJECT_NOT_FOUND,ERROR_BAD_STREAM_NAME,ERROR_OBJECT_TOO_LARGE
                    dc.w     ERROR_ACTION_NOT_KNOWN,ERROR_INVALID_COMPONENT_NAME,ERROR_INVALID_LOCK,ERROR_OBJECT_WRONG_TYPE
                    dc.w     ERROR_DISK_NOT_VALIDATED,ERROR_DISK_WRITE_PROTECTED,ERROR_RENAME_ACROSS_DEVICES
                    dc.w     ERROR_DIRECTORY_NOT_EMPTY,ERROR_TOO_MANY_LEVELS,ERROR_DEVICE_NOT_MOUNTED,ERROR_SEEK_ERROR
                    dc.w     ERROR_COMMENT_TOO_BIG,ERROR_DISK_FULL,ERROR_DELETE_PROTECTED,ERROR_WRITE_PROTECTED
                    dc.w     ERROR_READ_PROTECTED,ERROR_NOT_A_DOS_DISK,ERROR_NO_DISK,ERROR_NO_MORE_ENTRIES
                    ; ????
                    dc.w     286
                    dc.W     0
trackdisk_errors_text:
                    dc.b     ' Not Specified !! ',0
                    dc.b     ' No Sector Head ! ',0
                    dc.b     'Bad Sec Preamble !',0
                    dc.b     ' Bad Sector ID !! ',0
                    dc.b     ' Bad Header Sum ! ',0
                    dc.b     ' Bad Sector Sum ! ',0
                    dc.b     'Too Few Sectors !!',0
                    dc.b     '  Bad Sec Head !  ',0
                    dc.b     'Write Protected !!',0
                    dc.b     '  Disk Changed !  ',0
                    dc.b     '   Seek Error !   ',0
                    dc.b     '   No Memory !!   ',0
                    dc.b     'Bad Unit Number !!',0
                    dc.b     ' Bad Drive Type ! ',0
                    dc.b     '  Drive In Use !  ',0
                    dc.b     '   Post Reset !   ',0
                    dc.b     'Trackdisk Error !!',0
                    even
trackdisk_errors_codes:
                    dc.w     TDERR_NotSpecified,TDERR_NoSecHdr,TDERR_BadSecPreamble,TDERR_BadSecID,TDERR_BadHdrSum
                    dc.w     TDERR_BadSecSum,TDERR_TooFewSecs,TDERR_BadSecHdr,TDERR_WriteProt,TDERR_DiskChanged
                    dc.w     TDERR_SeekError,TDERR_NoMem,TDERR_BadUnitNum,TDERR_BadDriveType,TDERR_DriveInUse,TDERR_PostReset
                    dc.w     0
error_no_memory:
                    moveq    #ERROR_NO_MEM,d0
                    bra      display_error
error_what_block:
                    moveq    #ERROR_WHAT_BLOCK,d0
                    bra      display_error
error_what_position:
                    moveq    #ERROR_WHAT_POS,d0
                    bra      display_error
error_sample_too_long:
                    moveq    #ERROR_SMP_TOO_LONG,d0
                    bra      display_error
error_what_sample:
                    moveq    #ERROR_WHAT_SMP,d0
                    bra      display_error
error_sample_cleared:
                    moveq    #ERROR_SMP_CLEARED,d0
                    bra      display_error
error_no_more_patterns:
                    moveq    #ERROR_NO_MORE_PATT,d0
                    bra      display_error
error_no_more_positions:
                    moveq    #ERROR_NO_MORE_POS,d0
                    bra      display_error
error_pattern_in_use:
                    moveq    #ERROR_PATT_IN_USE,d0
                    bra      display_error
error_copy_buffer_free:
                    moveq    #ERROR_COPY_BUF_FREE,d0
                    bra      display_error
error_no_more_samples:
                    moveq    #ERROR_NO_MORE_SMP,d0
                    bra      display_error
error_only_in_mode_4_b:
                    moveq    #ERROR_ONLY_4B_MODE,d0
                    bra      display_error
error_left_one_bit:
                    moveq    #ERROR_LEFT_ONE_BIT,d0
                    bra      display_error
error_block_copied:
                    moveq    #ERROR_BLOCK_COPIED,d0
                    bra      display_error
error_sample_clipped:
                    moveq    #ERROR_SMP_CLIPPED,d0
                    bra      display_error
error_sample_too_short:
                    moveq    #ERROR_SMP_TOO_SHORT,d0
                    bra      display_error
error_iff_struct_error:
                    moveq    #ERROR_IFF_ERROR,d0
                    bra      display_error
error_same_sample:
                    moveq    #ERROR_SAME_SMP,d0
                    bra      display_error
error_different_modes:
                    moveq    #ERROR_DIFF_MODES,d0
                    bra      display_error
error_zero_not_found:
                    moveq    #ERROR_Z_NOT_FOUND,d0
                    bra      display_error
error_cant_install:
                    moveq    #ERROR_CANT_INST,d0
                    bra      display_error
error_already_installed:
                    moveq    #ERROR_ALREADY_INST,d0
                    bra      display_error
error_no_okdir:
                    moveq    #ERROR_NO_OKDIR,d0
                    bra      display_error
error_cant_open_device:
                    moveq    #ERROR_OPEN_DEVICE,d0
                    bra      display_error
error_verify_error:
                    moveq    #ERROR_VERIFY,d0
                    bra      display_error
error_what_samples:
                    moveq    #ERROR_WHAT_SMPS,d0
                    bra      display_error
error_cant_convert_song:
                    moveq    #ERROR_CANT_CONVERT,d0
                    bra      display_error
error_ok_struct_error:
                    moveq    #ERROR_OK_STRUCT,d0
                    bra      display_error
error_st_struct_error:
                    moveq    #ERROR_ST_STRUCT,d0
                    bra      display_error
error_what_file:
                    moveq    #ERROR_WHAT_FILE,d0
                    bra      display_error
error_not_a_directory:
                    moveq    #ERROR_NOT_DIR,d0
                    bra      display_error
error_no_more_entries:
                    moveq    #ERROR_ENDOF_ENTRIES,d0
                    bra      display_error
error_nothing_selected:
                    moveq    #ERROR_NOTHING_SEL,d0
                    bra      display_error
error_no_multi_selection:
                    moveq    #ERROR_MULTI_SEL,d0
                    bra      display_error
error_copy_buffer_empty:
                    moveq    #ERROR_COPYBUF_EMPTY,d0
                    bra      display_error
error_no_entries:
                    moveq    #ERROR_NO_ENTRIES,d0
                    bra      display_error
error_ef_struct_error:
                    moveq    #ERROR_EF_STRUCT,d0
                    bra      display_error
error_only_in_pal:
                    moveq    #ERROR_ONLY_IN_PAL,d0
                    bra      display_error

; ===========================================================================
lbC025132:
                    moveq    #$A,d4
                    jmp      (draw_filled_box_with_minterms)

; ===========================================================================
lbW02513C:
                    dc.w     0
OK_FullPeriodTab:
                    dc.w     $358,$328,$2FA,$2D0,$2A6,$280,$25C,$23A,$21A,$1FC,$1E0,$1C5,$1AC,$194
                    dc.w     $17D,$168,$153,$140,$12E,$11D,$10D,$FE,$F0,$E2,$D6,$CA,$BE,$B4,$AA
                    dc.w     $A0,$97,$8F,$87,$7F,$78,$71,0
C1C1D1D1E1F1F_MSG:
                    dc.b     '--- '
                    dc.b     'C-1 C#1 D-1 D#1 E-1 F-1 F#1 G-1 G#1 A-1 A#1 B-1 '
                    dc.b     'C-2 C#2 D-2 D#2 E-2 F-2 F#2 G-2 G#2 A-2 A#2 B-2 '
                    dc.b     'C-3 C#3 D-3 D#3 E-3 F-3 F#3 G-3 G#3 A-3 A#3 B-3 '
zsxdcvgbhnjml_MSG:
                    dc.b     'zsxdcvgbhnjm,l.;/q2w3er5t6y7ui9o0p[=]\',0
lbB02526B:
                    dc.b     1,2,3,4,5,6,7,8,9,$A,$B,$C,$D,$E,$F,$10,$11,$D,$E,$F,$10,$11,$12,$13
                    dc.b     $14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F,$20,$21,0
C1C1D1D1E1F1F_MSG0:
                    dc.b     'C-1 C#1 D-1 D#1 E-1 F-1 F#1 G-1 G#1 A-1 A#1 B-1 '
                    dc.b     'C-2 C#2 D-2 D#2 E-2 '
                    dc.b     'C-2 C#2 D-2 D#2 E-2 F-2 F#2 G-2 G#2 A-2 A#2 B-2 '
                    dc.b     'C-3 C#3 D-3 D#3 E-3 F-3 F#3 G-3 G#3 --- '
lbB02532E:
                    dc.b     $D,$E,$F,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$19
                    dc.b     $1A,$1B,$1C,$1D,$1E,$1F,$20,$21,$22,$23,$24,$FF,$FF,$FF,$FF,$FF,$FF
                    dc.b     $FF,$FF,$FF,0,0
C2C2D2D2E2F2F_MSG:
                    dc.b     'C-2 C#2 D-2 D#2 E-2 F-2 F#2 G-2 G#2 A-2 A#2 B-2 '
                    dc.b     'C-3 C#3 D-3 D#3 E-3 '
                    dc.b     'C-3 C#3 D-3 D#3 E-3 F-3 F#3 G-3 G#3 A-3 A#3 B-3 '
                    dc.b     '                                    --- '
alpha_numeric_table:
                    dc.b     '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',0
                    even
OK_Speed:
                    dc.w     6
OK_PLen:
                    dc.w     1
OK_Patterns:
                    dcb.b    128,0
caret_pos_x:
                    dc.w     0
viewed_pattern_row:
                    dc.w     0
trackdisk_name:
                    TD_NAME
                    even

; ===========================================================================
mulu_32:
                    movem.l  d2-d4,-(sp)
                    move.l   d0,d4
                    bpl.b    lbC0254BE
                    neg.l    d0
lbC0254BE:
                    eor.l    d1,d4
                    tst.l    d1
                    bpl.b    lbC0254C6
                    neg.l    d1
lbC0254C6:
                    move.w   d1,d2
                    mulu.w   d0,d2
                    move.l   d1,d3
                    swap     d3
                    mulu.w   d0,d3
                    swap     d3
                    clr.w    d3
                    add.l    d3,d2
                    swap     d0
                    mulu.w   d1,d0
                    swap     d0
                    clr.w    d0
                    add.l    d2,d0
                    tst.l    d4
                    bpl.b    lbC0254E6
                    neg.l    d0
lbC0254E6:
                    movem.l  (sp)+,d2-d4
                    rts

; ===========================================================================
divu_32:
                    tst.l    d1
                    beq.b    lbC02555C
                    movem.l  d2-d4,-(sp)
                    move.l   d0,d4
                    bpl.b    lbC0254FA
                    neg.l    d0
lbC0254FA:
                    eor.l    d1,d4
                    tst.l    d1
                    bpl.b    lbC025502
                    neg.l    d1
lbC025502:
                    swap     d1
                    tst.w    d1
                    bne.b    lbC02552C
                    swap     d1
                    clr.w    d3
                    divu.w   d1,d0
                    bvc.b    lbC02551E
                    move.w   d0,d2
                    clr.w    d0
                    swap     d0
                    divu.w   d1,d0
                    move.w   d0,d3
                    move.w   d2,d0
                    divu.w   d1,d0
lbC02551E:
                    move.l   d0,d1
                    swap     d0
                    move.w   d3,d0
                    swap     d0
                    clr.w    d1
                    swap     d1
                    bra.b    lbC025552
lbC02552C:
                    swap     d1
                    moveq    #0,d2
                    moveq    #32-1,d3
lbC025532:
                    add.l    d0,d0
                    addx.l   d2,d2
                    sub.l    d1,d2
                    bmi.b    lbC02554A
lbC02553A:
                    addq.l   #1,d0
                    dbra     d3,lbC025532
                    bra.b    lbC02554E
lbC025542:
                    add.l    d0,d0
                    addx.l   d2,d2
                    add.l    d1,d2
                    bpl.b    lbC02553A
lbC02554A:
                    dbra     d3,lbC025542
lbC02554E:
                    add.l    d1,d2
                    move.l   d2,d1
lbC025552:
                    tst.l    d4
                    bpl.b    lbC025558
                    neg.l    d0
lbC025558:
                    movem.l  (sp)+,d2-d4
lbC02555C:
                    rts

; ===========================================================================
clear_main_menu_blitter:
                    bsr      own_blitter
                    move.l   #$1000000,(BLTCON0,a6)
                    move.w   #0,(BLTDMOD,a6)
                    lea      (main_screen),a0
                    move.l   a0,(BLTDPTH,a6)
                    move.w   #(56*64)+(SCREEN_BYTES/2),(BLTSIZE,a6)
                    bra      disown_blitter

; ===========================================================================
clear_1_line_blitter:
                    bsr      own_blitter
                    move.l   #$1000000,(BLTCON0,a6)
                    move.w   #0,(BLTDMOD,a6)
                    move.l   #main_screen+(56*80),(BLTDPTH,a6)
                    move.w   #(SCREEN_BYTES/2),(BLTSIZE,a6)
                    bra      disown_blitter

; ===========================================================================
own_blitter:
                    GFX      OwnBlitter
                    GFX      WaitBlit
                    lea      (_CUSTOM),a6
                    rts

; ===========================================================================
disown_blitter:
                    GFX      WaitBlit
                    GFX      DisownBlitter
                    rts

; ===========================================================================
draw_filled_box:
                    lea      (main_screen),a3
                    moveq    #$5A,d4
draw_filled_box_with_minterms:
                    move.w   d4,d6
                    cmp.w    d1,d3
                    bge.b    .y2_greater_y1
                    exg      d1,d3
.y2_greater_y1:
                    cmp.w    d0,d2
                    bge.b    .x2_greater_x1
                    exg      d0,d2
.x2_greater_x1:
                    sub.w    d1,d3
                    move.w   d1,d4
                    mulu.w   #SCREEN_BYTES,d4
                    adda.l   d4,a3
                    moveq    #$F,d4
                    and.w    d0,d4
                    add.w    d4,d4
                    lsr.w    #4,d0
                    adda.w   d0,a3
                    adda.w   d0,a3
                    moveq    #$F,d5
                    and.w    d2,d5
                    add.w    d5,d5
                    lsr.w    #4,d2
                    move.w   (line_mask_hi,pc,d4.w),d4
                    swap     d4
                    move.w   (line_mask_lo,pc,d5.w),d4
                    sub.w    d0,d2
                    moveq    #39,d5
                    sub.w    d2,d5
                    add.w    d5,d5
                    addq.w   #1,d3
                    lsl.w    #6,d3
                    add.w    d2,d3
                    addq.w   #1,d3
                    moveq    #0,d0
                    move.w   d6,d0
                    ori.w    #$300,d0
                    swap     d0
                    bsr      own_blitter
                    move.l   d0,(BLTCON0,a6)
                    move.l   d4,(BLTAFWM,a6)
                    move.w   #$FFFF,(BLTADAT,a6)
                    move.w   d5,(BLTCMOD,a6)
                    move.w   d5,(BLTDMOD,a6)
                    move.l   a3,(BLTCPTH,a6)
                    move.l   a3,(BLTDPTH,a6)
                    move.w   d3,(BLTSIZE,a6)
                    bra      disown_blitter
line_mask_hi:
                    dc.w     %1111111111111111
                    dc.w     %0111111111111111
                    dc.w     %0011111111111111
                    dc.w     %0001111111111111
                    dc.w     %0000111111111111
                    dc.w     %0000011111111111
                    dc.w     %0000001111111111
                    dc.w     %0000000111111111
                    dc.w     %0000000011111111
                    dc.w     %0000000001111111
                    dc.w     %0000000000111111
                    dc.w     %0000000000011111
                    dc.w     %0000000000001111
                    dc.w     %0000000000000111
                    dc.w     %0000000000000011
                    dc.w     %0000000000000001
line_mask_lo:
                    dc.w     %1000000000000000
                    dc.w     %1100000000000000
                    dc.w     %1110000000000000
                    dc.w     %1111000000000000
                    dc.w     %1111100000000000
                    dc.w     %1111110000000000
                    dc.w     %1111111000000000
                    dc.w     %1111111100000000
                    dc.w     %1111111110000000
                    dc.w     %1111111111000000
                    dc.w     %1111111111100000
                    dc.w     %1111111111110000
                    dc.w     %1111111111111000
                    dc.w     %1111111111111100
                    dc.w     %1111111111111110
                    dc.w     %1111111111111111

; ===========================================================================
prepare_line_drawing:
                    bsr      own_blitter
                    move.w   #$8000,(BLTADAT,a6)
                    moveq    #-1,d0
                    move.w   d0,(BLTAFWM,a6)
                    move.w   d0,(BLTBDAT,a6)
                    moveq    #80,d0
                    move.w   d0,(BLTCMOD,a6)
                    move.w   d0,(BLTDMOD,a6)
                    rts

; ===========================================================================
release_after_line_drawing:
                    bra      disown_blitter

; ===========================================================================
lbC0256DA:
                    movem.l  d4-d6,-(sp)
                    move.w   #$CA,d6
                    cmp.w    d1,d3
                    bgt.b    lbC0256EA
                    exg      d1,d3
                    exg      d0,d2
lbC0256EA:
                    move.l   a0,a1
                    move.w   d1,d4
                    mulu.w   #SCREEN_BYTES,d4
                    moveq    #-16,d5
                    and.w    d0,d5
                    lsr.w    #3,d5
                    add.w    d5,d4
                    adda.w   d4,a1
                    moveq    #0,d5
                    sub.w    d1,d3
                    sub.w    d0,d2
                    addx.b   d5,d5
                    tst.w    d2
                    bge.b    lbC02570A
                    neg.w    d2
lbC02570A:
                    move.w   d3,d1
                    sub.w    d2,d1
                    bge.b    lbC025712
                    exg      d2,d3
lbC025712:
                    addx.b   d5,d5
                    move.b   (lbB025768,pc,d5.w),d5
                    add.w    d2,d2
                    GFX      WaitBlit
                    move.w   d2,(BLTBMOD,a6)
                    sub.w    d3,d2
                    bge.b    lbC025734
                    ori.b    #$40,d5
lbC025734:
                    move.w   d2,(BLTAPTL,a6)
                    sub.w    d3,d2
                    move.w   d2,(BLTAMOD,a6)
                    andi.w   #$F,d0
                    ror.w    #4,d0
                    ori.w    #$B00,d0
                    or.w     d6,d0
                    movem.w  d0/d5,(BLTCON0,a6)
                    move.l   a1,(BLTCPTH,a6)
                    move.l   a1,(BLTDPTH,a6)
                    addq.w   #1,d3
                    lsl.w    #6,d3
                    addq.w   #2,d3
                    move.w   d3,(BLTSIZE,a6)
                    movem.l  (sp)+,d4-d6
                    rts
lbB025768:
                    dc.b     1,17,9,21
lbC02576C:
                    move.w   #314-1,d0
                    bsr.b    lbC025794
                    btst     #6,(CIAB)
                    beq.b    lbC02576C
                    btst     #2,(_CUSTOM|POTINP)
                    beq.b    lbC02576C
                    move.w   #314-1,d0
lbC025794:
                    lea      (_CUSTOM|VHPOSR),a0
lbC02579A:
                    move.b   (a0),d1
lbC02579C:
                    cmp.b    (a0),d1
                    beq.b    lbC02579C
                    dbra     d0,lbC02579A
                    rts
lbC0257A6:
                    movem.l  d2,-(sp)
                    sf       d2
                    moveq    #0,d0
lbC0257AE:
                    moveq    #0,d1
                    move.b   (a0)+,d1
                    beq.b    lbC0257D0
                    cmpi.b   #' ',d1
                    beq.b    lbC0257AE
                    subi.b   #'0',d1
                    bmi.b    lbC0257D8
                    cmpi.b   #9,d1
                    bgt.b    lbC0257D8
                    st       d2
                    mulu.w   #10,d0
                    add.l    d1,d0
                    bra.b    lbC0257AE
lbC0257D0:
                    tst.b    d2
                    beq.b    lbC0257D8
                    moveq    #OK,d1
                    bra.b    lbC0257DA
lbC0257D8:
                    moveq    #ERROR,d1
lbC0257DA:
                    movem.l  (sp)+,d2
                    rts

; ===========================================================================
file_exist:
                    move.l   a0,d1
                    moveq    #-2,d2
                    DOS      Lock
                    move.l   d0,d1
                    beq.b    .error
                    DOS      UnLock
                    moveq    #OK,d0
                    rts
.error:
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
load_file:
                    move.l   a1,(.address)
                    move.l   d0,(.size)
                    move.l   a0,d1
                    move.l   #MODE_OLDFILE,d2
                    DOS      Open
                    move.l   d0,d7
                    beq.b    .error
                    move.l   d7,d1
                    move.l   (.address,pc),d2
                    move.l   (.size,pc),d3
                    DOS      Read
                    cmp.l    (.size,pc),d0
                    bne.b    .error
                    bsr.b    .close
                    moveq    #OK,d0
                    rts
.error:
                    bsr.b    .close
                    moveq    #ERROR,d0
                    rts
.close:
                    move.l   d7,d1
                    beq.b    .no_filehandle
                    DOS      Close
.no_filehandle:
                    rts
.address:
                    dc.l     0
.size:
                    dc.l     0

; ===========================================================================
save_file:
                    move.l   a1,(.address)
                    move.l   d0,(.size)
                    move.l   a0,d1
                    move.l   #MODE_NEWFILE,d2
                    DOS      Open
                    move.l   d0,d7
                    beq.b    .error
                    move.l   d7,d1
                    move.l   (.address,pc),d2
                    move.l   (.size,pc),d3
                    DOS      Write
                    cmp.l    (.size,pc),d0
                    bne.b    .error
                    bsr.b    .close
                    moveq    #OK,d0
                    rts
.error:
                    bsr.b    .close
                    moveq    #ERROR,d0
                    rts
.close:
                    move.l   d7,d1
                    beq.b    .no_filehandle
                    DOS      Close
.no_filehandle:
                    rts
.address:
                    dc.l     0
.size:
                    dc.l     0

; ===========================================================================
delete_file:
                    move.l   a0,d1
                    DOS      DeleteFile
                    tst.l    d0
                    beq.b    .error
                    moveq    #OK,d0
                    rts
.error:
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
open_file_for_reading:
                    move.l   a0,d1
                    move.l   #MODE_OLDFILE,d2
                    DOS      Open
                    move.l   d0,(file_handle)
                    beq.b    .error
                    moveq    #OK,d0
                    rts
.error:
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
open_file_for_writing:
                    move.l   a0,d1
                    move.l   #MODE_NEWFILE,d2
                    DOS      Open
                    move.l   d0,(file_handle)
                    beq.b    .error
                    moveq    #OK,d0
                    rts
.error:
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
read_from_file:
                    move.l   (file_handle,pc),d1
                    beq.b    .error
                    move.l   a0,d2
                    move.l   d0,d3
                    move.l   d0,-(sp)
                    DOS      Read
                    cmp.l    (sp)+,d0
                    bne.b    .error
                    moveq    #OK,d0
                    rts
.error:
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
write_to_file:
                    move.l   (file_handle,pc),d1
                    beq.b    .error
                    move.l   a0,d2
                    move.l   d0,d3
                    move.l   d0,-(sp)
                    DOS      Write
                    cmp.l    (sp)+,d0
                    bne.b    .error
                    moveq    #OK,d0
                    rts
.error:
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
move_in_file:
                    move.l   (file_handle,pc),d1
                    beq.b    .error
                    move.l   d0,d2
                    moveq    #OFFSET_CURRENT,d3
                    DOS      Seek
                    tst.l    d0
                    bmi.b    .error
                    moveq    #OK,d0
                    rts
.error:
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
close_file:
                    move.l   (file_handle,pc),d1
                    beq.b    .error
                    DOS      Close
                    clr.l    (file_handle)
.error:
                    rts
file_handle:
                    dc.l     0

; ===========================================================================
wait_drive_ready:
                    movem.l  d7,-(sp)
                    move.l   #.drive_message_port,(.disk_resource+MN_REPLYPORT)
                    move.b   #NT_MESSAGE,(.disk_resource+LN_TYPE)
                    lea      (.drive_message_port,pc),a0
                    bsr      install_port
                    moveq    #-1,d0
                    EXEC     AllocSignal
                    move.b   d0,(.drive_message_port+MP_SIGBIT)
                    move.b   d0,(.signal_number)
                    moveq    #0,d1
                    bset     d0,d1
                    move.l   d1,d7
.retry:
                    lea      (.disk_resource,pc),a1
                    DISK     GetUnit
                    tst.l    d0
                    bne.b    .drive_ready
                    jsr      (display_waiting_for_drives_message)
.wait_drive_ready:
                    move.l   d7,d0
                    EXEC     Wait
                    lea      (.drive_message_port,pc),a0
                    EXEC     GetMsg
                    tst.l    d0
                    beq.b    .wait_drive_ready
                    bra.b    .retry
.drive_ready:
                    jsr      (remove_waiting_for_drives_message)
                    move.b   (.signal_number,pc),d0
                    EXEC     FreeSignal
                    lea      (.drive_message_port,pc),a0
                    bsr      remove_port
                    movem.l  (sp)+,d7
                    rts
.drive_message_port:
                    dcb.b    MP_SIZE,0
.disk_resource:
                    dcb.b    DRU_SIZE,0
.signal_number:
                    dc.b     0
                    even

; ===========================================================================
release_drive:
                    DISK     GiveUnit
                    rts

; ===========================================================================
inhibit_drive:
                    moveq    #DOSTRUE,d1
                    bra.b    do_inhibit_drive
uninhibit_drive:
                    moveq    #DOSFALSE,d1
do_inhibit_drive:
                    move.l   d1,(.packet+dp_Arg1)
                    lea      (.drives_list,pc),a0
                    move.l   a0,d1
                    mulu.w   #5,d0
                    add.l    d0,d1
                    DOS      DeviceProc
                    tst.l    d0
                    ble.b    .error
                    move.l   d0,-(sp)
                    lea      (.reply_port,pc),a0
                    bsr      install_port
                    move.l   (sp)+,a0
                    lea      (.packet,pc),a1
                    lea      (MN_SIZE,a1),a2
                    move.l   a2,(LN_NAME,a1)
                    move.l   a1,(MN_SIZE+dp_Link,a1)
                    move.l   #.reply_port,(MN_SIZE+dp_Port,a1)
                    moveq    #ACTION_INHIBIT,d0
                    move.l   d0,(MN_SIZE+dp_Type,a1)
                    EXEC     PutMsg
                    lea      (.reply_port,pc),a0
                    EXEC     WaitPort
                    lea      (.packet,pc),a1
                    EXEC     Remove
                    lea      (.reply_port,pc),a0
                    bra      remove_port
.error:
                    rts
.drives_list:
                    dc.b     'df0:',0
                    dc.b     'df1:',0
                    dc.b     'df2:',0
                    dc.b     'df3:',0
                    ; (must be aligned)
                    cnop     0,8
.packet:
                    dcb.b    sp_SIZEOF,0
.reply_port:
                    dcb.b    MP_SIZE,0

; ===========================================================================
lbC025C1A:
                    move.l   a0,d1
                    moveq    #-2,d2
                    DOS      Lock
                    move.l   d0,d7
                    beq.b    .error
                    move.l   d7,d1
                    lea      (.file_info_block),a0
                    move.l   a0,d2
                    DOS      Examine
                    tst.l    d0
                    beq.b    .error
                    move.l   d7,d1
                    DOS      UnLock
                    tst.l    (.file_info_block+fib_DirEntryType)
                    bpl.b    .error
                    move.l   (.file_info_block+fib_Size),d0
                    rts
.error:
                    moveq    #ERROR,d0
                    rts
                    ; (must be aligned)
                    cnop     0,8
.file_info_block:
                    dcb.b    fib_SIZEOF,0
lbC025D84:
                    clr.b    (-1,a1,d0.w)
                    bra.b    lbC025D8E
lbC025D8A:
                    tst.b    (a1)+
                    beq.b    lbC025D96
lbC025D8E:
                    dbra     d0,lbC025D8A
                    rts
lbC025D94:
                    clr.b    (a1)+
lbC025D96:
                    dbra     d0,lbC025D94
                    rts
lbC025D9C:
                    bra.b    lbC025DA0
lbC025D9E:
                    clr.b    (a1)+
lbC025DA0:
                    dbra     d0,lbC025D9E
                    rts
lbC025DA6:
                    move.l   a0,d0
lbC025DA8:
                    tst.b    (a0)+
                    bne.b    lbC025DA8
                    sub.l    d0,a0
                    move.l   a0,d0
                    rts
lbC025DB2:
                    move.l   a2,-(sp)
                    move.l   a1,a2
                    move.w   d0,d1
                    bra.b    lbC025DBC
lbC025DBA:
                    move.b   (a0)+,(a2)+
lbC025DBC:
                    dbra     d1,lbC025DBA
                    move.l   (sp)+,a2
                    bra.b    lbC025D84
lbC025DC4:
                    move.b   (a0)+,d0
                    cmp.b    (a1)+,d0
                    bne.b    lbC025DD2
                    tst.b    d0
                    bne.b    lbC025DC4
                    moveq    #OK,d0
                    rts
lbC025DD2:
                    moveq    #ERROR,d0
                    rts
lbC025DD6:
                    lea      (lbL025E52,pc),a0
                    lea      (lbL025E72,pc),a1
                    move.l   #'0000',(2,a1)
                    move.l   #('000'<<8),(6,a1)
                    bra.b    lbC025E34
lbC025DF0:
                    lea      (lbL025E56,pc),a0
                    lea      (lbL025E72,pc),a1
                    move.l   #'0000',(2,a1)
                    move.w   #'00',(6,a1)
                    sf       (8,a1)
                    bra.b    lbC025E34
lbC025E0C:
                    ext.l    d2
                    lea      (lbL025E62,pc),a0
                    lea      (lbL025E72,pc),a1
                    move.l   #('000'<<8),(2,a1)
                    bra.b    lbC025E34
lbC025E20:
                    ext.l    d2
                    lea      (lbL025E66,pc),a0
                    lea      (lbL025E72,pc),a1
                    move.w   #'00',(2,a1)
                    sf       (4,a1)
lbC025E34:
                    move.b   d0,(a1)+
                    move.b   d1,(a1)+
lbC025E38:
                    move.l   (a0)+,d3
                    beq.b    lbC025E4A
lbC025E3C:
                    sub.l    d3,d2
                    bmi.b    lbC025E44
                    addq.b   #1,(a1)
                    bra.b    lbC025E3C
lbC025E44:
                    add.l    d3,d2
                    addq.w   #1,a1
                    bra.b    lbC025E38
lbC025E4A:
                    lea      (lbL025E72,pc),a0
                    bra      draw_text_with_coords_struct
lbL025E52:
                    dc.l     1000000
lbL025E56:
                    dc.l     100000,10000,1000
lbL025E62:
                    dc.l     100
lbL025E66:
                    dc.l     10,1,0
lbL025E72:
                    dcb.l    3,0

; ===========================================================================
draw_2_digits_hex_number:
                    bsr.b    prepare_hex_number_text_block
                    bra.b    do_draw_2_digits_hex_number
draw_3_digits_hex_number:
                    bsr.b    prepare_hex_number_text_block
                    move.w   d2,d1
                    lsr.w    #8,d1
                    andi.w   #$F,d1
                    move.b   (a1,d1.w),(a0)+
do_draw_2_digits_hex_number:
                    move.w   d2,d1
                    lsr.w    #4,d1
                    andi.w   #$F,d1
                    move.b   (a1,d1.w),(a0)+
                    move.w   d2,d1
                    andi.w   #$F,d1
                    move.b   (a1,d1.w),(a0)+
                    lea      (hex_number_text_buffer,pc),a0
                    bra      draw_text_with_coords_struct
prepare_hex_number_text_block:
                    lea      (hex_number_text_buffer+4,pc),a0
                    lea      (alpha_numeric_table),a1
                    clr.l    (a0)
                    clr.l    -(a0)
                    move.b   d0,(a0)+
                    move.b   d1,(a0)+
                    rts
hex_number_text_buffer:
                    dcb.b    8,0

; ===========================================================================
draw_short_ascii_decimal_number:
                    movem.w  d0/d1,-(sp)
                    lea      (.ascii_buffer,pc),a1
                    moveq    #0,d0
                    move.w   d2,d0
                    move.w   d3,d1
                    bsr.b    prepare_ascii_decimal_number
                    lea      (.ascii_buffer,pc),a0
                    movem.w  (sp)+,d0/d1
                    bra      draw_text
.ascii_buffer:
                    dcb.b    12,0

; ===========================================================================
draw_long_ascii_decimal_number:
                    movem.w  d0/d1,-(sp)
                    lea      (.ascii_buffer,pc),a1
                    move.l   d2,d0
                    move.w   d3,d1
                    bsr.b    prepare_ascii_decimal_number
                    lea      (.ascii_buffer,pc),a0
                    movem.w  (sp)+,d0/d1
                    bra      draw_text
.ascii_buffer:
                    dcb.b    12,0

; ===========================================================================
prepare_ascii_decimal_number:
                    movem.l  d0-d3/a0,-(sp)
                    lea      (decimal_table,pc),a0
                    moveq    #10,d3
                    sub.w    d1,d3
                    add.w    d3,d3
                    add.w    d3,d3
                    adda.w   d3,a0
                    sf       d3
.loop:
                    move.l   (a0)+,d1
                    beq.b    .done
                    cmp.l    d1,d0
                    bcs.b    .threshold
                    moveq    #-1,d2
.search:
                    sub.l    d1,d0
                    dbcs     d2,.search
                    add.l    d1,d0
                    neg.b    d2
                    addi.b   #'0'-1,d2
                    move.b   d2,(a1)+
                    st       d3
                    bra.b    .loop
.threshold:
                    tst.b    d3
                    beq.b    .leading_zero
                    move.b   #'0',(a1)+
                    bra.b    .loop
.leading_zero:
                    move.b   #' ',(a1)+
                    bra.b    .loop
.done:
                    addi.b   #'0',d0
                    move.b   d0,(a1)+
                    movem.l  (sp)+,d0-d3/a0
                    sf       (a1)+
                    rts
decimal_table:
                    dc.l     1000000000,100000000,10000000,1000000,100000,10000,1000,100,10,0

; ===========================================================================
process_command:
                    movem.l  d2/d3/a2,-(sp)
                    sf       (current_draw_x)
                    sf       (current_draw_y)
                    move.l   a0,a2
                    move.w   d0,d2
                    move.w   d1,d3
next_command:
                    move.b   (a2)+,d0
                    beq      done_commands
                    cmpi.b   #CMD_TEXT,d0
                    beq.b    cmd_draw_text
                    cmpi.b   #CMD_CLEAR_MAIN_MENU,d0
                    beq      cmd_clear_main_menu
                    cmpi.b   #4,d0
                    beq      lbC02606E
                    cmpi.b   #5,d0
                    beq      lbC02607E
                    cmpi.b   #CMD_SUB_COMMAND,d0
                    beq      cmd_process_sub_command
                    cmpi.b   #7,d0
                    beq      lbC0260B2
                    cmpi.b   #CMD_TEXT_PTR,d0
                    beq.b    cmd_draw_text_from_pointer
                    cmpi.b   #9,d0
                    beq      lbC0260D2
                    cmpi.b   #CMD_CLEAR_CHARS,d0
                    beq      cmd_clear_chars
                    cmpi.b   #CMD_SET_SUB_SCREEN,d0
                    beq      cmd_set_full_screen_copperlist_ntsc
                    cmpi.b   #CMD_SET_MAIN_SCREEN,d0
                    beq      cmd_restore_full_screen_copperlist_ntsc
                    cmpi.b   #CMD_MOVE_TO_LINE,d0
                    beq      cmd_move_to_line
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra      done_commands

; ===========================================================================
cmd_draw_text:
                    bsr      get_xy_from_command
                    move.l   a2,a0
                    add.w    d2,d0
                    add.w    d3,d1
                    bsr      draw_text
                    move.l   a0,a2
                    bra      next_command

; ===========================================================================
cmd_draw_text_from_pointer:
                    bsr      get_xy_from_command
                    bsr      make_pointer_even
                    move.l   (a2)+,a0
                    add.w    d2,d0
                    add.w    d3,d1
                    bsr      draw_text
                    bra      next_command

; ===========================================================================
cmd_clear_main_menu:
                    bsr      clear_main_menu_blitter
                    bra      next_command

; ===========================================================================
lbC02606E:
                    bsr      clear_1_line_blitter
                    moveq    #0,d0
                    jsr      (set_pattern_bitplane_from_given_pos)
                    bra      next_command

; ===========================================================================
lbC02607E:
                    bsr      get_xy_from_command
                    add.w    d2,d0
                    add.w    d3,d1
                    movem.l  d2/d3,-(sp)
                    moveq    #0,d2
                    moveq    #0,d3
                    move.b   (a2)+,d2
                    move.b   (a2)+,d3
                    bsr      lbC0261EC
                    movem.l  (sp)+,d2/d3
                    bra      next_command

; ===========================================================================
cmd_process_sub_command:
                    bsr      make_pointer_even
                    move.l   (a2)+,a0
                    move.l   (a0),a0
                    move.w   d2,d0
                    move.w   d3,d1
                    bsr      process_command
                    bra      next_command

; ===========================================================================
lbC0260B2:
                    bsr      get_xy_from_command
                    add.w    d2,d0
                    add.w    d3,d1
                    movem.l  d2/d3,-(sp)
                    moveq    #0,d2
                    moveq    #0,d3
                    move.b   (a2)+,d2
                    move.b   (a2)+,d3
                    bsr      lbC026250
                    movem.l  (sp)+,d2/d3
                    bra      next_command

; ===========================================================================
lbC0260D2:
                    bsr      make_pointer_even
                    move.w   (a2)+,d0
                    movem.l  d2-d7/a2-a6,-(sp)
                    move.w   d0,d1
                    move.w   d0,d3
                    moveq    #0,d0
                    move.w   #SCREEN_WIDTH-1,d2
                    bsr      draw_filled_box
                    movem.l  (sp)+,d2-d7/a2-a6
                    bra      next_command

; ===========================================================================
cmd_clear_chars:
                    bsr      get_xy_from_command
                    add.w    d2,d0
                    add.w    d3,d1
                    move.l   d2,-(sp)
                    moveq    #0,d2
                    move.b   (a2)+,d2
                    bsr      clear_chars
                    move.l   (sp)+,d2
                    bra      next_command

; ===========================================================================
cmd_set_full_screen_copperlist_ntsc:
                    jsr      (set_full_screen_copperlist_ntsc)
                    bra      next_command

; ===========================================================================
cmd_restore_full_screen_copperlist_ntsc:
                    jsr      (restore_full_screen_copperlist_ntsc)
                    bra      next_command

; ===========================================================================
cmd_move_to_line:
                    bsr      make_pointer_even
                    move.l   (a2)+,a0
                    move.b   (1,a0),(current_draw_y)
                    bra      next_command

; ===========================================================================
done_commands:
                    movem.l  (sp)+,d2/d3/a2
                    rts

; ===========================================================================
make_pointer_even:
                    move.l   d0,-(sp)
                    move.l   a2,d0
                    btst     #0,d0
                    beq.b    .odd
                    addq.w   #1,a2
.odd:
                    move.l   (sp)+,d0
                    rts

; ===========================================================================
get_xy_from_command:
                    move.b   (a2)+,d0
                    add.b    (current_draw_x,pc),d0
                    move.b   (a2)+,d1
                    add.b    (current_draw_y,pc),d1
                    ext.w    d0
                    ext.w    d1
                    rts
current_draw_x:
                    dc.b     0
current_draw_y:
                    dc.b     0

; ===========================================================================
draw_text:
                    movem.l  a2-a6,-(sp)
                    lea      (main_screen),a2
                    adda.w   d0,a2
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a2
                    lea      (SCREEN_BYTES,a2),a3
                    lea      (SCREEN_BYTES,a3),a4
                    lea      (SCREEN_BYTES,a4),a5
                    lea      (SCREEN_BYTES,a5),a6
                    move.l   #text_font,d1
                    bra.b    .go
.loop:
                    lsl.w    #3,d0
                    move.l   d1,a1
                    adda.w   d0,a1
                    move.b   (a1)+,(a2)+
                    move.b   (a1)+,(a3)+
                    move.b   (a1)+,(a4)+
                    move.b   (a1)+,(a5)+
                    move.b   (a1)+,(a6)+
                    move.b   (a1)+,((SCREEN_BYTES*1)-1,a6)
                    move.b   (a1)+,((SCREEN_BYTES*2)-1,a6)
.go:
                    moveq    #0,d0
                    move.b   (a0)+,d0
                    bne.b    .loop
                    movem.l  (sp)+,a2-a6
                    rts

; ===========================================================================
invert_chars:
                    movem.l  a2-a6,-(sp)
                    lea      (main_screen),a2
                    adda.w   d0,a2
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a2
                    lea      (SCREEN_BYTES,a2),a3
                    lea      (SCREEN_BYTES,a3),a4
                    lea      (SCREEN_BYTES,a4),a5
                    lea      (SCREEN_BYTES,a5),a6
                    lea      (SCREEN_BYTES,a6),a0
                    lea      (SCREEN_BYTES,a0),a1
                    bra.b    .go
.loop:
                    not.b    (a2)+
                    not.b    (a3)+
                    not.b    (a4)+
                    not.b    (a5)+
                    not.b    (a6)+
                    not.b    (a0)+
                    not.b    (a1)+
.go:
                    dbra     d2,.loop
                    movem.l  (sp)+,a2-a6
                    rts

; ===========================================================================
lbC0261EC:
                    movem.l  d2-d6/a2,-(sp)
                    lea      (main_screen),a2
                    add.w    d0,d2
                    add.w    d1,d3
                    move.w   d3,d6
                    move.w   d2,d5
                    move.w   d1,d4
                    move.w   d0,d3
                    lsl.w    #3,d3
                    lsl.w    #3,d4
                    lsl.w    #3,d5
                    lsl.w    #3,d6
                    subq.w   #1,d3
                    subq.w   #1,d4
                    subq.w   #1,d5
                    subq.w   #1,d6
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d5,d1
                    move.w   d4,d2
                    jsr      (lbC020D42)
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d4,d1
                    move.w   d6,d2
                    jsr      (lbC020D84)
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d5,d1
                    move.w   d6,d2
                    jsr      (lbC020D42)
                    move.l   a2,a0
                    move.w   d5,d0
                    move.w   d4,d1
                    move.w   d6,d2
                    jsr      (lbC020D84)
                    movem.l  (sp)+,d2-d6/a2
                    rts
lbC026250:
                    movem.l  d2-d6/a2,-(sp)
                    lea      (main_screen),a2
                    add.w    d0,d2
                    add.w    d1,d3
                    move.w   d3,d6
                    move.w   d2,d5
                    move.w   d1,d4
                    move.w   d0,d3
                    lsl.w    #3,d3
                    lsl.w    #3,d4
                    lsl.w    #3,d5
                    lsl.w    #3,d6
                    subq.w   #1,d3
                    subq.w   #1,d4
                    subq.w   #1,d6
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d5,d1
                    move.w   d4,d2
                    jsr      (lbC020D42)
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d4,d1
                    move.w   d6,d2
                    jsr      (lbC020D84)
                    move.l   a2,a0
                    move.w   d3,d0
                    move.w   d5,d1
                    move.w   d6,d2
                    jsr      (lbC020D42)
                    move.l   a2,a0
                    move.w   d5,d0
                    move.w   d4,d1
                    move.w   d6,d2
                    jsr      (lbC020D84)
                    movem.l  (sp)+,d2-d6/a2
                    rts

; ===========================================================================
draw_text_with_coords_struct:
                    movem.l  a2/a3,-(sp)
                    moveq    #0,d0
                    moveq    #0,d1
                    move.b   (a0)+,d0
                    move.b   (a0)+,d1
                    lea      (main_screen),a3
                    adda.w   d0,a3
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a3
                    lea      (text_font),a2
.loop:
                    moveq    #0,d0
                    move.b   (a0)+,d0
                    beq.b    .done
                    lsl.w    #3,d0
                    lea      (a2,d0.w),a1
                    move.b   (a1)+,(a3)+
                    move.b   (a1)+,((SCREEN_BYTES*1)-1,a3)
                    move.b   (a1)+,((SCREEN_BYTES*2)-1,a3)
                    move.b   (a1)+,((SCREEN_BYTES*3)-1,a3)
                    move.b   (a1)+,((SCREEN_BYTES*4)-1,a3)
                    move.b   (a1)+,((SCREEN_BYTES*5)-1,a3)
                    move.b   (a1)+,((SCREEN_BYTES*6)-1,a3)
                    bra.b    .loop
.done:
                    movem.l  (sp)+,a2/a3
                    rts

; ===========================================================================
draw_text_without_coords:
                    movem.l  a2/a3,-(sp)
                    lea      (text_font),a3
.loop:
                    moveq    #0,d0
                    move.b   (a0)+,d0
                    beq.b    .done
                    lsl.w    #3,d0
                    lea      (a3,d0.w),a2
                    move.b   (a2)+,(a1)+
                    move.b   (a2)+,((SCREEN_BYTES*1)-1,a1)
                    move.b   (a2)+,((SCREEN_BYTES*2)-1,a1)
                    move.b   (a2)+,((SCREEN_BYTES*3)-1,a1)
                    move.b   (a2)+,((SCREEN_BYTES*4)-1,a1)
                    move.b   (a2)+,((SCREEN_BYTES*5)-1,a1)
                    move.b   (a2)+,((SCREEN_BYTES*6)-1,a1)
                    bra.b    .loop
.done:
                    movem.l  (sp)+,a2/a3
                    rts

; ===========================================================================
draw_text_with_blanks:
                    movem.l  a2/a3,-(sp)
                    lea      (main_screen),a2
                    adda.w   d0,a2
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a2
                    lea      (text_font),a3
                    bra.b    .go
.loop:
                    moveq    #0,d0
                    move.b   (a0)+,d0
                    beq.b    .clear_loop
                    lsl.w    #3,d0
                    lea      (a3,d0.w),a1
                    move.b   (a1)+,(a2)+
                    move.b   (a1)+,((SCREEN_BYTES*1)-1,a2)
                    move.b   (a1)+,((SCREEN_BYTES*2)-1,a2)
                    move.b   (a1)+,((SCREEN_BYTES*3)-1,a2)
                    move.b   (a1)+,((SCREEN_BYTES*4)-1,a2)
                    move.b   (a1)+,((SCREEN_BYTES*5)-1,a2)
                    move.b   (a1)+,((SCREEN_BYTES*6)-1,a2)
.go:
                    dbra     d2,.loop
                    bra.b    .clear_go
.clear_loop:
                    sf       (a2)+
                    sf       ((SCREEN_BYTES*1)-1,a2)
                    sf       ((SCREEN_BYTES*2)-1,a2)
                    sf       ((SCREEN_BYTES*3)-1,a2)
                    sf       ((SCREEN_BYTES*4)-1,a2)
                    sf       ((SCREEN_BYTES*5)-1,a2)
                    sf       ((SCREEN_BYTES*6)-1,a2)
                    dbra     d2,.clear_loop
.clear_go:
                    movem.l  (sp)+,a2/a3
                    rts

; ===========================================================================
draw_repeated_char:
                    movem.l  d2/d3,-(sp)
                    lea      (main_screen),a1
                    adda.w   d0,a1
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a1
                    lea      (text_font),a0
                    andi.w   #$FF,d2
                    lsl.w    #3,d2
                    adda.w   d2,a0
                    bra.b    .go
.loop:
                    move.b   (a0)+,(a1)+
                    move.b   (a0)+,((SCREEN_BYTES*1)-1,a1)
                    move.b   (a0)+,((SCREEN_BYTES*2)-1,a1)
                    move.b   (a0)+,((SCREEN_BYTES*3)-1,a1)
                    move.b   (a0)+,((SCREEN_BYTES*4)-1,a1)
                    move.b   (a0)+,((SCREEN_BYTES*5)-1,a1)
                    move.b   (a0)+,((SCREEN_BYTES*6)-1,a1)
                    subq.w   #7,a0
.go:
                    dbra     d3,.loop
                    movem.l  (sp)+,d2/d3
                    rts

; ===========================================================================
draw_one_char:
                    movem.l  d2,-(sp)
                    lea      (main_screen),a1
                    adda.w   d0,a1
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a1
                    lea      (text_font),a0
                    andi.w   #$FF,d2
                    lsl.w    #3,d2
                    adda.w   d2,a0
                    move.b   (a0)+,(a1)
                    move.b   (a0)+,((SCREEN_BYTES*1),a1)
                    move.b   (a0)+,((SCREEN_BYTES*2),a1)
                    move.b   (a0)+,((SCREEN_BYTES*3),a1)
                    move.b   (a0)+,((SCREEN_BYTES*4),a1)
                    move.b   (a0)+,((SCREEN_BYTES*5),a1)
                    move.b   (a0)+,((SCREEN_BYTES*6),a1)
                    movem.l  (sp)+,d2
                    rts

; ===========================================================================
; d2 = number of chars to clear
clear_chars:
                    lea      (main_screen),a1
                    adda.w   d0,a1
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a1
                    bra.b    .go
.loop:
                    sf       (a1)+
                    sf       ((SCREEN_BYTES*1)-1,a1)
                    sf       ((SCREEN_BYTES*2)-1,a1)
                    sf       ((SCREEN_BYTES*3)-1,a1)
                    sf       ((SCREEN_BYTES*4)-1,a1)
                    sf       ((SCREEN_BYTES*5)-1,a1)
                    sf       ((SCREEN_BYTES*6)-1,a1)
.go:
                    dbra     d2,.loop
                    rts

; ===========================================================================
draw_zoomed_char:
                    movem.l  d3-d7/a2,-(sp)
                    lea      (text_font),a2
                    lsl.w    #3,d2
                    adda.w   d2,a2
                    move.w   d0,d5
                    move.w   d1,d6
                    move.w   #7-1,d7
.loop_y:
                    swap     d7
                    move.w   #8-1,d7
.loop_x:
                    move.w   d5,d0
                    move.w   d6,d1
                    move.b   d3,d2
                    btst     d7,(a2)
                    beq.b    .no_dot_in_char
                    move.b   d4,d2
.no_dot_in_char:
                    bsr      draw_one_char
                    addq.w   #1,d5
                    dbra     d7,.loop_x
                    subq.w   #8,d5
                    addq.w   #1,a2
                    swap     d7
                    addq.w   #1,d6
                    dbra     d7,.loop_y
                    movem.l  (sp)+,d3-d7/a2
                    rts

; ===========================================================================
close_workbench:
                    tst.b    (workbench_opened_flag)
                    beq.b    .no_op
                    INT      CloseWorkBench
                    tst.l    d0
                    seq      (workbench_opened_flag)
.no_op:
                    rts

; ===========================================================================
open_workbench:
                    tst.b    (workbench_opened_flag)
                    bne.b    .no_op
                    INT      OpenWorkBench
                    tst.l    d0
                    sne      (workbench_opened_flag)
.no_op:
                    rts
workbench_opened_flag:
                    dc.b     -1
                    even

; ===========================================================================
lbC0264DC:
                    moveq    #0,d5
lbC0264DE:
                    move.l   a0,(lbL02680E)
                    movem.w  d0/d1,(lbW026812)
                    move.w   d2,(lbW02681C)
                    move.w   d3,(lbW026816)
                    move.b   d5,(lbB026824)
                    clr.w    (lbW02681E)
                    clr.w    (lbW026820)
                    sf       (lbB026822)
                    sf       (lbB026825)
                    move.l   (lbL02680E,pc),a1
                    move.w   (lbW02681C,pc),d0
                    jsr      (lbC025D84,pc)
                    subq.w   #1,d4
                    bmi.b    lbC02652E
lbC026526:
                    bsr      lbC02675E
                    dbmi     d4,lbC026526
lbC02652E:
                    bsr      lbC026618
                    bsr      lbC0267EA
                    lea      (lbW02654A,pc),a0
                    jsr      (lbC020626)
                    move.b   (lbB026825,pc),d1
                    move.b   (lbB026823,pc),d0
                    rts
lbW02654A:
                    dc.w     1
                    dc.l     lbC02655E
                    dc.w     4
                    dc.l     lbC0265AA
                    dc.w     7
                    dc.l     lbC0265AA
                    dc.w     0
lbC02655E:
                    move.w   d1,d0
                    cmpi.w   #5,d0
                    beq      lbC0265AA
                    move.w   d0,-(sp)
                    bsr      lbC026802
                    move.w   (sp)+,d0
                    btst     #10,d0
                    beq.b    lbC026582
                    cmpi.b   #120,d0
                    bne.b    lbC026582
                    bsr      lbC0267D8
                    bra.b    lbC026590
lbC026582:
                    cmpi.b   #32,d0
                    bcc.b    lbC02658E
                    bsr      lbC026630
                    bra.b    lbC026590
lbC02658E:
                    bsr.b    lbC0265CE
lbC026590:
                    move.b   (lbB026822,pc),d0
                    beq.b    lbC0265C2
                    clr.w    (lbW02681E)
                    bsr      lbC026618
                    sf       (lbB026823)
                    moveq    #OK,d0
                    rts
lbC0265AA:
                    bsr      lbC026802
                    clr.w    (lbW02681E)
                    bsr      lbC026618
                    st       (lbB026823)
                    moveq    #OK,d0
                    rts
lbC0265C2:
                    bsr      lbC026618
                    bsr      lbC0267EA
                    moveq    #ERROR,d0
                    rts
lbC0265CE:
                    tst.b    d0
                    bne.b    lbC0265E4
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC026616
lbC0265E4:
                    move.l   (lbL02680E,pc),a0
                    adda.w   (lbW02681C,pc),a0
                    tst.b    (-2,a0)
                    bne.b    lbC026616
                    move.l   (lbL02680E,pc),a0
                    adda.w   (lbW02681E,pc),a0
                    adda.w   (lbW026820,pc),a0
                    move.l   (lbL02680E,pc),a1
                    adda.w   (lbW02681C,pc),a1
lbC026606:
                    cmpa.l   a0,a1
                    ble.b    lbC026610
                    move.b   (-2,a1),-(a1)
                    bra.b    lbC026606
lbC026610:
                    move.b   d0,(a0)
                    bra      lbC02675E
lbC026616:
                    rts
lbC026618:
                    move.l   (lbL02680E,pc),a0
                    adda.w   (lbW02681E,pc),a0
                    movem.w  (lbW026812,pc),d0/d1
                    move.w   (lbW026816,pc),d2
                    jmp      (draw_text_with_blanks,pc)
lbC026630:
                    btst     #8,d0
                    beq.b    lbC026652
                    cmpi.b   #15,d0
                    beq      lbC0266DC
                    cmpi.b   #14,d0
                    beq      lbC0266EC
                    cmpi.b   #1,d0
                    beq.b    lbC0266A2
                    cmpi.b   #6,d0
                    beq.b    lbC0266A8
lbC026652:
                    cmpi.b   #4,d0
                    beq.b    lbC02669A
                    cmpi.b   #3,d0
                    beq.b    lbC02669A
                    cmpi.b   #1,d0
                    beq.b    lbC02668C
                    cmpi.b   #6,d0
                    beq.b    lbC0266B0
                    cmpi.b   #15,d0
                    beq      lbC0266F4
                    cmpi.b   #14,d0
                    beq      lbC02673E
                    cmpi.b   #12,d0
                    beq      lbC026792
                    cmpi.b   #13,d0
                    beq      lbC026798
                    rts
lbC02668C:
                    bsr      lbC026714
                    bmi.b    lbC026698
                    bsr      lbC0266B0
                    moveq    #0,d0
lbC026698:
                    rts
lbC02669A:
                    st       (lbB026822)
                    rts
lbC0266A2:
                    bsr.b    lbC02668C
                    beq.b    lbC0266A2
                    rts
lbC0266A8:
                    bsr      lbC0266B0
                    beq.b    lbC0266A8
                    rts
lbC0266B0:
                    move.l   (lbL02680E,pc),a0
                    adda.w   (lbW02681E,pc),a0
                    adda.w   (lbW026820,pc),a0
                    tst.b    (a0)
                    beq.b    lbC0266D8
                    move.l   (lbL02680E,pc),a1
                    adda.w   (lbW02681C,pc),a1
                    subq.w   #1,a1
lbC0266CA:
                    cmpa.l   a1,a0
                    bge.b    lbC0266D4
                    move.b   (1,a0),(a0)+
                    bra.b    lbC0266CA
lbC0266D4:
                    moveq    #OK,d0
                    rts
lbC0266D8:
                    moveq    #ERROR,d0
                    rts
lbC0266DC:
                    moveq    #0,d0
                    move.w   d0,(lbW02681E)
                    move.w   d0,(lbW026820)
                    rts
lbC0266EC:
                    bsr      lbC02675E
                    beq.b    lbC0266EC
                    rts
lbC0266F4:
                    move.w   d0,(lbW026712)
                    bsr      lbC026714
                    beq.b    lbC026710
                    move.w   (lbW026712,pc),d0
                    btst     #15,d0
                    bne.b    lbC026710
                    moveq    #1,d0
                    bra      lbC0267C0
lbC026710:
                    rts
lbW026712:
                    dc.w     0
lbC026714:
                    move.w   (lbW02681E,pc),d0
                    add.w    (lbW026820,pc),d0
                    beq.b    lbC02673A
                    tst.w    (lbW026820)
                    bne.b    lbC026730
                    subq.w   #1,(lbW02681E)
                    moveq    #OK,d0
                    rts
lbC026730:
                    subq.w   #1,(lbW026820)
                    moveq    #OK,d0
                    rts
lbC02673A:
                    moveq    #ERROR,d0
                    rts
lbC02673E:
                    move.w   d0,(lbW02675C)
                    bsr      lbC02675E
                    beq.b    lbC02675A
                    move.w   (lbW02675C,pc),d0
                    btst     #15,d0
                    bne.b    lbC02675A
                    moveq    #2,d0
                    bra      lbC0267C0
lbC02675A:
                    rts
lbW02675C:
                    dc.w     0
lbC02675E:
                    move.l   (lbL02680E,pc),a0
                    adda.w   (lbW02681E,pc),a0
                    adda.w   (lbW026820,pc),a0
                    tst.b    (a0)
                    beq.b    lbC02678E
                    move.w   (lbW026816,pc),d0
                    subq.w   #1,d0
                    cmp.w    (lbW026820,pc),d0
                    bne.b    lbC026784
                    addq.w   #1,(lbW02681E)
                    moveq    #OK,d0
                    rts
lbC026784:
                    addq.w   #1,(lbW026820)
                    moveq    #OK,d0
                    rts
lbC02678E:
                    moveq    #ERROR,d0
                    rts
lbC026792:
                    moveq    #3,d0
                    bra      lbC02679E
lbC026798:
                    moveq    #4,d0
lbC02679E:
                    btst     #0,(lbB026824)
                    bne.b    lbC0267B2
                    btst     #1,(lbB026824)
                    beq.b    lbC0267BE
lbC0267B2:
                    move.b   d0,(lbB026825)
                    st       (lbB026822)
lbC0267BE:
                    rts
lbC0267C0:
                    btst     #0,(lbB026824)
                    beq.b    lbC0267D6
                    move.b   d0,(lbB026825)
                    st       (lbB026822)
lbC0267D6:
                    rts
lbC0267D8:
                    move.l   (lbL02680E,pc),a1
                    sf       (a1)
                    move.w   (lbW02681C,pc),d0
                    jsr      (lbC025D84,pc)
                    bra      lbC0266DC
lbC0267EA:
                    movem.w  (lbW026812,pc),d0/d1
                    add.w    (lbW026820,pc),d0
                    movem.w  d0/d1,(lbW026818)
                    bra      invert_one_char
lbC026802:
                    movem.w  (lbW026818,pc),d0/d1
                    bra      invert_one_char
lbL02680E:
                    dc.l     0
lbW026812:
                    dcb.w    2,0
lbW026816:
                    dc.w     0
lbW026818:
                    dcb.w    2,0
lbW02681C:
                    dc.w     0
lbW02681E:
                    dc.w     0
lbW026820:
                    dc.w     0
lbB026822:
                    dc.b     0
lbB026823:
                    dc.b     0
lbB026824:
                    dc.b     0
lbB026825:
                    dc.b     0

; ===========================================================================
invert_one_char:
                    lea      (main_screen),a0
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a0
                    adda.w   d0,a0
                    not.b    (a0)
                    not.b    ((SCREEN_BYTES*1),a0)
                    not.b    ((SCREEN_BYTES*2),a0)
                    not.b    ((SCREEN_BYTES*3),a0)
                    not.b    ((SCREEN_BYTES*4),a0)
                    not.b    ((SCREEN_BYTES*5),a0)
                    not.b    ((SCREEN_BYTES*6),a0)
                    rts

; ===========================================================================
install_port:
                    move.l   a0,a1
                    moveq    #MP_SIZE-1,d0
.clear:
                    sf       (a0)+
                    dbra     d0,.clear
                    move.b   #NT_MSGPORT,(LN_TYPE,a1)
                    move.l   #port_name,(LN_NAME,a1)
                    move.l   a1,-(sp)
                    sub.l    a1,a1
                    EXEC     FindTask
                    move.l   (sp)+,a1
                    move.l   d0,(MP_SIGTASK,a1)
                    lea      (MP_MSGLIST,a1),a0
                    move.l   a0,(a0)
                    addq.l   #4,(a0)
                    clr.l    (LH_TAIL,a0)
                    move.l   a0,(LH_TAILPRED,a0)
                    move.b   #NT_MESSAGE,(MP_MSGLIST+LH_TYPE,a1)
                    EXEC     AddPort
                    rts
port_name:
                    dc.b     'OKPort',0
                    even

; ===========================================================================
remove_port:
                    move.l   a0,a1
                    EXEC     RemPort
                    rts

; ===========================================================================
display_messagebox:
                    move.l   a0,-(sp)
                    move.l   (pattern_bitplane_offset),a0
                    lea      (30,a0),a0
                    move.w   (lbW026954,pc),d0
                    mulu.w   #(SCREEN_BYTES*8),d0
                    adda.l   d0,a0
                    move.l   a0,(requester_screen_pos)
                    bsr      own_blitter
                    move.l   #$9F00000,(BLTCON0,a6)
                    moveq    #-1,d0
                    move.l   d0,(BLTAFWM,a6)
                    move.l   #60<<16,(BLTAMOD,a6)
                    move.l   (requester_screen_pos,pc),(BLTAPTH,a6)
                    move.l   #requesters_save_buffer,(BLTDPTH,a6)
                    move.w   #(24*64)+(20/2),(BLTSIZE,a6)
                    GFX      WaitBlit
                    move.l   #$1FF0000,(BLTCON0,a6)
                    move.w   #60,(BLTDMOD,a6)
                    move.l   (requester_screen_pos,pc),(BLTDPTH,a6)
                    move.w   #(24*64)+(20/2),(BLTSIZE,a6)
                    bsr      disown_blitter
                    move.l   (requester_screen_pos,pc),a3
                    moveq    #2,d0
                    moveq    #1,d1
                    move.w   #157,d2
                    moveq    #22,d3
                    moveq    #$A,d4
                    bsr      draw_filled_box_with_minterms
                    move.l   (sp)+,a0
                    move.l   (requester_screen_pos,pc),a1
                    lea      (641,a1),a1
                    bra      draw_text_without_coords
lbW026954:
                    dc.w     11

; ===========================================================================
remove_messagebox:
                    bsr      own_blitter
                    move.l   #$9F00000,(BLTCON0,a6)
                    move.l   #$FFFFFFFF,(BLTAFWM,a6)
                    move.l   #60,(BLTAMOD,a6)
                    move.l   #requesters_save_buffer,(BLTAPTH,a6)
                    move.l   (requester_screen_pos,pc),(BLTDPTH,a6)
                    move.w   #(24*64)+(20/2),(BLTSIZE,a6)
                    bra      disown_blitter
requester_screen_pos:
                    dc.l     0

; ===========================================================================
lbC026994:
                    movem.l  d3,-(sp)
                    subq.w   #1,d2
                    ble.b    lbC0269EC
                    moveq    #4,d3
                    lsr.w    #1,d0
                    bcc.b    lbC0269A4
                    addq.w   #1,d3
lbC0269A4:
                    lea      (main_screen+(56*80)),a1
                    add.w    d0,d0
                    adda.w   d0,a1
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a1
                    lea      ((SCREEN_BYTES*8),a1),a0
                    ror.w    #7,d2
                    or.w     d3,d2
                    moveq    #-1,d0
                    moveq    #SCREEN_BYTES,d1
                    sub.w    d3,d1
                    sub.w    d3,d1
                    bsr      own_blitter
                    move.l   #$9F00000,(BLTCON0,a6)
                    move.l   d0,(BLTAFWM,a6)
                    move.w   d1,(BLTAMOD,a6)
                    move.w   d1,(BLTDMOD,a6)
                    move.l   a0,(BLTAPTH,a6)
                    move.l   a1,(BLTDPTH,a6)
                    move.w   d2,(BLTSIZE,a6)
                    bsr      disown_blitter
lbC0269EC:
                    movem.l  (sp)+,d3
                    rts
lbC0269F2:
                    movem.l  d3,-(sp)
                    cmpi.w   #1,d2
                    ble.b    lbC026A54
                    lea      (main_screen+4408),a1
                    moveq    #4,d3
                    lsr.w    #1,d0
                    bcc.b    lbC026A0C
                    addq.w   #1,d3
                    addq.w   #2,a1
lbC026A0C:
                    subq.w   #2,a1
                    add.w    d0,d0
                    adda.w   d0,a1
                    add.w    d2,d1
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a1
                    lea      (-(SCREEN_BYTES*8),a1),a0
                    subq.w   #1,d2
                    ror.w    #7,d2
                    or.w     d3,d2
                    moveq    #-1,d0
                    moveq    #SCREEN_BYTES,d1
                    sub.w    d3,d1
                    sub.w    d3,d1
                    bsr      own_blitter
                    move.l   #$9F00002,(BLTCON0,a6)
                    move.l   d0,(BLTAFWM,a6)
                    move.w   d1,(BLTAMOD,a6)
                    move.w   d1,(BLTDMOD,a6)
                    move.l   a0,(BLTAPTH,a6)
                    move.l   a1,(BLTDPTH,a6)
                    move.w   d2,(BLTSIZE,a6)
                    bsr      disown_blitter
lbC026A54:
                    movem.l  (sp)+,d3
                    rts
lbC026A5A:
                    movem.l  d0/a0,-(sp)
                    bsr      lbC026AAC
                    movem.l  (sp)+,d0/a0
lbC026A6A:
                    tst.l    (a0)
                    beq.b    lbC026A80
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC026AA2
lbC026A80:
                    move.l   d0,(4,a0)
                    move.l   (8,a0),d1
                    move.l   a0,-(sp)
                    EXEC     AllocMem
                    move.l   (sp)+,a0
                    move.l   d0,(a0)
                    beq.b    lbC026AA2
                    move.l   d0,a0
                    moveq    #OK,d0
                    rts
lbC026AA2:
                    jsr      (error_no_memory)
                    moveq    #ERROR,d0
                    rts
lbC026AAC:
                    move.l   (a0),d0
                    beq.b    lbC026AC4
                    clr.l    (a0)
                    move.l   d0,a1
                    move.l   (4,a0),d0
                    EXEC     FreeMem
lbC026AC4:
                    rts

; ===========================================================================
display_file_requester:
                    sf       d1
                    bra.b    lbC026ACE
lbC026ACC:
                    st       d1
lbC026ACE:
                    move.b   d1,(lbB028008)
                    move.l   a0,-(sp)
                    bsr      set_current_directory_name
                    lea      (lbW026B22,pc),a0
                    jsr      (process_commands_sequence)
                    move.l   (sp)+,a0
                    moveq    #1,d0
                    moveq    #8,d1
                    jsr      (draw_text)
                    bsr      lbC026B42
                    bsr      lbC026F1C
                    lea      (lbW026B0C,pc),a0
                    jsr      (lbC020626)
                    bsr      lbC026E5A
                    move.l   (lbL027FDC,pc),d0
                    rts

; ===========================================================================
lbW026B0C:
                    dc.w     11
                    dc.l     lbC026B1A
                    dc.w     13
                    dc.l     lbC026EF0
                    dc.w     0
lbC026B1A:
                    jmp      (lbC0208FA)
lbW026B22:
                    dc.w     1
                    dc.l     files_sel_text
                    dc.w     2
                    dc.l     lbW018814
                    dc.w     3
                    dc.l     lbW018706
                    dc.w     0
                    dc.l     0,0,0
lbC026B42:
                    bsr      lbC027724
                    bsr      lbC027738
                    move.w   (trackdisk_unit_number,pc),d0
                    lsl.w    #2,d0
                    lea      (DF0_MSG,pc,d0.w),a0
                    moveq    #50,d0
                    moveq    #10,d1
                    jsr      (draw_text)
                    lea      (Off_MSG,pc),a0
                    tst.b    (verify_mode_flag)
                    beq.b    lbC026B6E
                    lea      (On_MSG,pc),a0
lbC026B6E:
                    moveq    #50,d0
                    moveq    #11,d1
                    jsr      (draw_text)
                    lea      (Off_MSG,pc),a0
                    tst.b    (clear_mode_flag)
                    beq.b    lbC026B88
                    lea      (On_MSG,pc),a0
lbC026B88:
                    moveq    #50,d0
                    moveq    #12,d1
                    jmp      (draw_text)
DF0_MSG:
                    dc.b     'DF0',0
                    dc.b     'DF1',0
                    dc.b     'DF2',0
                    dc.b     'DF3',0
On_MSG:
                    dc.b     ' On',0
Off_MSG:
                    dc.b     'Off',0
lbC026BAC:
                    moveq    #-1,d0
                    move.l   d0,(lbL027FDC)
                    st       (quit_flag)
                    rts
lbC026BBC:
                    bsr      get_current_directory_name
                    tst.b    (lbB028008)
                    beq.b    lbC026BDA
                    bsr      lbC026C1A
                    move.l   d0,(lbL027FDC)
                    st       (quit_flag)
                    rts
lbC026BDA:
                    lea      (curent_dir_name),a0
                    lea      (lbB01BEE8),a1
                    lea      (filename_to_load),a2
                    move.w   #160,d0
                    bsr      construct_filename
                    bmi.b    lbC026C0C
                    lea      (filename_to_load),a0
                    jsr      (lbC025C1A)
                    bmi.b    lbC026C0C
                    move.l   d0,(lbL027FDC)
                    bra.b    lbC026C12
lbC026C0C:
                    clr.l    (lbL027FDC)
lbC026C12:
                    st       (quit_flag)
                    rts
lbC026C1A:
                    move.l   (lbL027FFC,pc),a0
                    move.w   (lbW028004,pc),d0
                    bsr      lbC0275AC
                    tst.w    d0
                    beq.b    lbC026C5C
                    move.w   d0,(lbW026CAA)
                    mulu.w   #32,d0
                    lea      (lbL026CAC,pc),a0
                    jsr      (lbC026A6A)
                    bmi.b    lbC026C58
                    move.l   (lbL027FFC,pc),a0
                    move.l   (lbL026CAC,pc),a1
                    move.w   (lbW028004,pc),d0
                    bsr      lbC026CB8
                    moveq    #OK,d0
                    move.w   (lbW026CAA,pc),d0
                    rts
lbC026C58:
                    moveq    #ERROR,d0
                    rts
lbC026C5C:
                    lea      (curent_dir_name),a0
                    lea      (lbB01BEE8),a1
                    lea      (filename_to_load),a2
                    move.w   #160,d0
                    bsr      construct_filename
                    bmi.b    lbC026C58
                    lea      (filename_to_load),a0
                    jsr      (lbC025C1A)
                    bmi.b    lbC026C58
                    moveq    #32,d0
                    lea      (lbL026CAC,pc),a0
                    jsr      (lbC026A6A)
                    bmi.b    lbC026C58
                    lea      (lbB01BEE8),a0
                    move.l   (lbL026CAC,pc),a1
                    moveq    #32,d0
                    jsr      (lbC025DB2)
                    moveq    #1,d0
                    rts
lbW026CAA:
                    dc.w     0
lbL026CAC:
                    dc.l     0,0,$10000
lbC026CB8:
                    movem.l  a2,-(sp)
                    bra.b    lbC026CE8
lbC026CBE:
                    move.l   (a0)+,d1
                    bne.b    lbC026CD4
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC026CEC
lbC026CD4:
                    move.l   d1,a2
                    tst.b    (5,a2)
                    beq.b    lbC026CE8
                    lea      (10,a2),a2
                    moveq    #32-1,d1
lbC026CE2:
                    move.b   (a2)+,(a1)+
                    dbra     d1,lbC026CE2
lbC026CE8:
                    dbra     d0,lbC026CBE
lbC026CEC:
                    movem.l  (sp)+,a2
                    rts
lbC026CF2:
                    mulu.w   #32,d0
                    move.l   (lbL026CAC,pc),a1
                    adda.l   d0,a1
                    lea      (curent_dir_name),a0
                    lea      (filename_to_load),a2
                    move.w   #160,d0
                    move.l   a1,-(sp)
                    bsr      construct_filename
                    move.l   (sp)+,a1
                    bmi.b    lbC026D20
                    lea      (filename_to_load),a0
                    moveq    #OK,d0
                    rts
lbC026D20:
                    moveq    #ERROR,d0
                    rts
lbC026D24:
                    lea      (lbL026CAC,pc),a0
                    jsr      (lbC026AAC)
                    moveq    #ERROR,d0
                    rts
lbC026D32:
                    cmpi.w   #232,d1
                    bge.b    lbC026D62
                    cmpi.w   #136,d1
                    blt.b    lbC026D62
                    cmpi.w   #16,d0
                    blt.b    lbC026D62
                    cmpi.w   #624,d0
                    bge.b    lbC026D62
                    exg      d0,d1
                    subi.w   #136,d0
                    lsr.w    #3,d0
                    cmpi.w   #336,d1
                    bge      lbC02748C
                    cmpi.w   #304,d1
                    blt      lbC0275E0
lbC026D62:
                    rts
lbC026D64:
                    move.w   (lbW028006,pc),-(sp)
lbC026D68:
                    tst.w    d0
                    beq.b    lbC026D98
                    bpl.b    lbC026D86
                    move.w   (lbW028004,pc),d1
                    subi.w   #13,d1
                    cmp.w    (lbW028006,pc),d1
                    blt.b    lbC026D98
                    addq.w   #1,(lbW028006)
                    addq.w   #1,d0
                    bra.b    lbC026D68
lbC026D86:
                    tst.w    (lbW028006)
                    beq.b    lbC026D98
                    subq.w   #1,(lbW028006)
                    subq.w   #1,d0
                    bra.b    lbC026D68
lbC026D98:
                    move.w   (sp)+,d0
                    cmp.w    (lbW028006,pc),d0
                    beq.b    lbC026DA4
                    bra      lbC027350
lbC026DA4:
                    rts
lbC026DA6:
                    move.w   (lbW027FFA,pc),-(sp)
lbC026DAA:
                    tst.w    d0
                    beq.b    lbC026DDA
                    bpl.b    lbC026DC8
                    move.w   (lbW027FF8,pc),d1
                    subi.w   #13,d1
                    cmp.w    (lbW027FFA,pc),d1
                    blt.b    lbC026DDA
                    addq.w   #1,(lbW027FFA)
                    addq.w   #1,d0
                    bra.b    lbC026DAA
lbC026DC8:
                    tst.w    (lbW027FFA)
                    beq.b    lbC026DDA
                    subq.w   #1,(lbW027FFA)
                    subq.w   #1,d0
                    bra.b    lbC026DAA
lbC026DDA:
                    move.w   (sp)+,d0
                    cmp.w    (lbW027FFA,pc),d0
                    beq.b    lbC026DE6
                    bra      lbC02733A
lbC026DE6:
                    rts

; ===========================================================================
set_current_directory_name:
                    lea      (directories_table,pc),a0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.l   (a0,d0.w),a0
                    move.l   a0,(curent_dir_ptr)
                    lea      (curent_dir_name),a1
                    move.w   #160-1,d0
.copy:
                    move.b   (a0)+,(a1)+
                    dbra     d0,.copy
                    rts

; ===========================================================================
get_current_directory_name:
                    lea      (curent_dir_name),a0
                    move.l   (curent_dir_ptr,pc),a1
                    move.w   #160-1,d0
.copy:
                    move.b   (a0)+,(a1)+
                    dbra     d0,.copy
                    rts
directories_table:
                    dc.l     dir_songs
                    dc.l     dir_samples
                    dc.l     dir_prefs
                    dc.l     dir_effects
curent_dir_ptr:
                    dc.l     0

; ===========================================================================
lbC026E36:
                    lea      (lbL01C0C8),a1
                    tst.b    (a0)
                    beq.b    lbC026E44
lbC026E40:
                    move.b   (a0)+,(a1)+
                    bne.b    lbC026E40
lbC026E44:
                    rts
lbC026E5A:
                    bsr      lbC026EA0
                    move.l   (lbL027FEE,pc),a0
                    clr.l    (lbL027FEE)
                    clr.w    (lbW027FF2)
                    bsr      lbC026ED0
                    move.l   (lbL027FFC,pc),a0
                    clr.l    (lbL027FFC)
                    bsr      lbC027F4E
                    move.l   (lbL028000,pc),a0
                    clr.l    (lbL028000)
                    clr.w    (lbW028004)
                    clr.w    (lbW028006)
                    bsr.b    lbC026ED0
                    clr.l    (disk_size)
                    rts
lbC026EA0:
                    clr.w    (lbW027FFA)
                    clr.w    (lbW027FF8)
                    move.l   (lbL027FF4,pc),a0
                    clr.l    (lbL027FF4)
                    bsr      lbC027F4E
                    move.l   (lbL027FE8,pc),a0
                    clr.l    (lbL027FE8)
                    clr.w    (lbW027FEC)
lbC026ED0:
                    move.l   a2,-(sp)
                    move.l   a0,a2
lbC026ED4:
                    move.l   a2,a1
                    move.l   a1,d0
                    beq.b    lbC026EEC
                    move.l   (a2),a2
                    moveq    #42,d0
                    EXEC     FreeMem
                    bra.b    lbC026ED4
lbC026EEC:
                    move.l   (sp)+,a2
                    rts
lbC026EF0:
                    bsr      lbC027308
                    bsr.b    lbC026EA0
                    bsr      lbC027102
                    bsr      lbC027076
                    beq.b    lbC026F06
                    bsr      lbC02733A
                    bra.b    lbC026F14
lbC026F06:
                    jsr      (error_no_memory)
                    bsr      lbC0272FE
                    bsr      lbC026E5A
lbC026F14:
                    moveq    #ERROR,d0
                    rts
lbC026F18:
                    st       d0
                    bra.b    lbC026F1E
lbC026F1C:
                    sf       d0
lbC026F1E:
                    move.b   d0,(lbB027074)
                    bsr      lbC0272FE
                    bsr      lbC026E5A
                    bsr      lbC027102
                    bsr      lbC02774C
                    bsr      lbC027762
                    bsr      display_disk_size
                    move.l   #curent_dir_name,d1
                    moveq    #-2,d2
                    DOS      Lock
                    move.l   d0,(dir_lock_handle)
                    beq      lbC027010
                    move.l   (dir_lock_handle,pc),d1
                    move.l   #disk_info_data,d2
                    DOS      Info
                    tst.l    d0
                    beq      lbC027010
                    bsr      get_disk_size
                    bsr      display_disk_size
                    move.b   (lbB027074,pc),d0
                    bsr      lbC027B40
                    beq      lbC027016
                    bsr      lbC026E5A
                    bsr      lbC027102
                    bsr      lbC02774C
                    bsr      lbC027762
                    move.l   (dir_lock_handle,pc),d1
                    lea      (file_info_block),a0
                    move.l   a0,d2
                    DOS      Examine
                    tst.l    d0
                    beq.b    lbC027016
                    tst.l    (file_info_block+fib_DirEntryType)
                    bmi.b    lbC027008
lbC026FC4:
                    move.l   (dir_lock_handle,pc),d1
                    move.l   #file_info_block,d2
                    DOS      ExNext
                    tst.l    d0
                    beq.b    lbC027016
                    tst.l    (file_info_block+fib_DirEntryType)
                    bmi.b    lbC026FF6
                    lea      (file_info_block+fib_FileName),a0
                    bsr      lbC0271CC
                    bmi.b    lbC027016
                    bra.b    lbC026FC4
lbC026FF6:
                    lea      (file_info_block+fib_FileName),a0
                    move.l   (fib_Size-fib_FileName,a0),d0
                    bsr      lbC0271EC
                    bmi.b    lbC027016
                    bra.b    lbC026FC4
lbC027008:
                    jsr      (error_not_a_directory)
                    bra.b    lbC027016
lbC027010:
                    jsr      (display_dos_error)
lbC027016:
                    bsr      lbC027076
                    beq.b    lbC02702C
                    bsr      lbC0270D4
                    beq.b    lbC02702C
                    bsr      lbC02733A
                    bsr      lbC027350
                    bra.b    lbC02703A
lbC02702C:
                    jsr      (error_no_memory)
                    bsr      lbC026E5A
                    bsr      display_disk_size
lbC02703A:
                    lea      (dir_lock_handle,pc),a0
                    move.l   (a0),d1
                    beq.b    lbC027052
                    clr.l    (a0)
                    DOS      UnLock
lbC027052:
                    bsr      lbC027E2A
                    bsr      lbC02774C
                    bsr      lbC027762
                    tst.b    (lbB027FDA)
                    beq.b    lbC027072
                    tst.b    (lbB027074)
                    beq.b    lbC027072
                    bra      lbC027D04
lbC027072:
                    rts
lbB027074:
                    dc.b     0
                    even
lbC027076:
                    move.w   (lbW027FEC,pc),d0
                    add.w    (lbW027FF2,pc),d0
                    move.w   d0,(lbW027FF8)
                    bsr      lbC027F1A
                    beq.b    lbC0270D2
                    move.l   a0,(lbL027FF4)
                    lea      (lbL027FE8,pc),a0
                    move.l   (lbL027FF4,pc),a1
                    move.w   (lbW027FEC,pc),d0
                    bsr      lbC027F86
                    move.l   (lbL027FF4,pc),a0
                    moveq    #10,d0
                    bsr      lbC02728E
                    lea      (lbL027FEE,pc),a0
                    move.l   (lbL027FF4,pc),a1
                    move.w   (lbW027FEC,pc),d0
                    move.w   (lbW027FF2,pc),d1
                    bsr      lbC027F70
                    move.l   (lbL027FF4,pc),a0
                    move.w   (lbW027FEC,pc),d0
                    bsr      lbC027F64
                    moveq    #10,d0
                    bsr      lbC02728E
                    moveq    #ERROR,d0
lbC0270D2:
                    rts
lbC0270D4:
                    move.w   (lbW028004,pc),d0
                    bsr      lbC027F1A
                    beq.b    lbC027100
                    move.l   a0,(lbL027FFC)
                    lea      (lbL028000,pc),a0
                    move.l   (lbL027FFC,pc),a1
                    move.w   (lbW028004,pc),d0
                    bsr      lbC027F86
                    move.l   (lbL027FFC,pc),a0
                    moveq    #10,d0
                    bsr      lbC02728E
                    moveq    #ERROR,d0
lbC027100:
                    rts
lbC027102:
                    EXEC     Forbid
                    move.l   (DOSBase),a0
                    move.l   (34,a0),a0
                    move.l   (24,a0),a0
                    adda.l   a0,a0
                    adda.l   a0,a0
                    move.l   (4,a0),a0
                    adda.l   a0,a0
                    adda.l   a0,a0
                    clr.w    (lbW027FEC)
lbC02712E:
                    cmpi.l   #2,(4,a0)
                    bne.b    lbC027176
                    tst.l    (8,a0)
                    beq.b    lbC027176
                    move.l   (40,a0),d0
                    ble.b    lbC027176
                    add.l    d0,d0
                    add.l    d0,d0
                    move.l   d0,a1
                    moveq    #0,d0
                    move.b   (a1)+,d0
                    cmpi.w   #30,d0
                    bls.b    lbC027156
                    moveq    #30,d0
lbC027156:
                    lea      (lbL027190,pc),a2
                    bra.b    lbC02715E
lbC02715C:
                    move.b   (a1)+,(a2)+
lbC02715E:
                    dbra     d0,lbC02715C
                    move.b   #':',(a2)+
                    sf       (a2)+
                    move.l   a0,-(sp)
                    lea      (lbL027190,pc),a0
                    bsr      lbC0271B0
                    move.l   (sp)+,a0
                    bmi.b    lbC027182
lbC027176:
                    move.l   (a0),d0
                    beq.b    lbC027182
                    add.l    d0,d0
                    add.l    d0,d0
                    move.l   d0,a0
                    bra.b    lbC02712E
lbC027182:
                    EXEC     Permit
                    rts
lbL027190:
                    dcb.l    8,0
lbC0271B0:
                    move.l   a0,a1
                    lea      (lbL027FE8,pc),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    bsr.b    lbC027226
                    bmi.b    lbC0271C8
                    addq.w   #1,(lbW027FEC)
                    moveq    #OK,d0
                    rts
lbC0271C8:
                    moveq    #ERROR,d0
                    rts
lbC0271CC:
                    move.l   a0,a1
                    lea      (lbL027FEE,pc),a0
                    moveq    #2,d0
                    moveq    #0,d1
                    bsr.b    lbC027226
                    bmi.b    lbC0271E8
                    addq.w   #1,(lbW027FF2)
                    bsr      lbC02774C
                    moveq    #OK,d0
                    rts
lbC0271E8:
                    moveq    #ERROR,d0
                    rts
lbC0271EC:
                    movem.l  d2/a2,-(sp)
                    move.l   a0,a2
                    move.l   d0,d2
                    move.l   a2,a0
                    lea      (okdir_MSG,pc),a1
                    jsr      (lbC025DC4)
                    beq.b    lbC02721A
                    move.l   a2,a1
                    lea      (lbL028000,pc),a0
                    moveq    #1,d0
                    move.l   d2,d1
                    bsr.b    lbC027226
                    bmi.b    lbC027222
                    addq.w   #1,(lbW028004)
                    bsr      lbC027762
lbC02721A:
                    moveq    #OK,d0
lbC02721C:
                    movem.l  (sp)+,d2/a2
                    rts
lbC027222:
                    moveq    #ERROR,d0
                    bra.b    lbC02721C
lbC027226:
                    movem.l  d2/d3/a2-a4,-(sp)
                    move.l   a0,a4
                    move.l   a1,a2
                    move.b   d0,d2
                    move.l   d1,d3
                    bsr.b    lbC027266
                    bmi.b    lbC027262
                    move.l   a0,a3
lbC027238:
                    move.l   (a4),d0
                    beq.b    lbC027240
                    move.l   d0,a4
                    bra.b    lbC027238
lbC027240:
                    move.l   a3,(a4)
                    clr.l    (a3)
                    move.b   d2,(4,a3)
                    move.l   d3,(6,a3)
                    move.l   a2,a0
                    lea      (10,a3),a1
                    moveq    #32,d0
                    jsr      (lbC025DB2)
                    moveq    #OK,d0
lbC02725C:
                    movem.l  (sp)+,d2/d3/a2-a4
                    rts
lbC027262:
                    moveq    #ERROR,d0
                    bra.b    lbC02725C
lbC027266:
                    moveq    #42,d0
                    move.l   #$10000,d1
                    EXEC     AllocMem
                    move.l   d0,a0
                    tst.l    d0
                    beq.b    lbC027284
                    moveq    #OK,d0
                    rts
lbC027284:
                    jsr      (error_no_memory)
                    moveq    #ERROR,d0
                    rts
lbC02728E:
                    movem.l  d2/a2/a3,-(sp)
                    move.l   a0,a2
                    move.w   d0,d2
lbC027296:
                    move.l   a2,a3
lbC027298:
                    move.l   (a3)+,d0
                    beq.b    lbC0272BE
                    move.l   d0,a0
                    adda.w   d2,a0
                    move.l   (a3),d0
                    beq.b    lbC0272BE
                    move.l   d0,a1
                    adda.w   d2,a1
                    bsr.b    lbC0272C4
                    bne.b    lbC027298
                    move.l   -(a3),d0
                    move.l   (4,a3),(a3)+
                    move.l   d0,(a3)
                    lea      (-8,a3),a3
                    cmpa.l   a2,a3
                    bcc.b    lbC027298
                    bra.b    lbC027296
lbC0272BE:
                    movem.l  (sp)+,d2/a2/a3
                    rts
lbC0272C4:
                    move.b   (a0)+,d0
                    beq.b    lbC0272FA
                    move.b   (a1)+,d1
                    beq.b    lbC0272F6
                    cmp.b    #'a',d0
                    blt.b    lbC0272DC
                    cmp.b    #'z',d0
                    bgt.b    lbC0272DC
                    sub.b    #' ',d0
lbC0272DC:
                    cmp.b    #'a',d1
                    blt.b    lbC0272EC
                    cmp.b    #'z',d1
                    bgt.b    lbC0272EC
                    sub.b    #' ',d1
lbC0272EC:
                    cmp.b    d0,d1
                    beq.b    lbC0272C4
                    sgt      d0
                    tst.b    d0
                    rts
lbC0272F6:
                    moveq    #OK,d0
                    rts
lbC0272FA:
                    moveq    #ERROR,d0
                    rts
lbC0272FE:
                    bsr      lbC027308
                    bra      lbC027310
lbC027308:
                    lea      (main_screen+((136*80)+2)),a0
                    bra.b    lbC02731A
lbC027310:
                    lea      (main_screen+((136*80)+42)),a0
lbC02731A:
                    moveq    #96-1,d1
                    moveq    #0,d0
lbC02731E:
                REPT 9
                    move.l   d0,(a0)+
                ENDR
                    lea      (44,a0),a0
                    dbra     d1,lbC02731E
                    rts
lbC02733A:
                    move.l   (lbL027FF4,pc),a5
                    move.w   (lbW027FF8,pc),d7
                    move.w   (lbW027FFA,pc),d6
                    sub.w    d6,d7
                    moveq    #2,d5
                    sub.w    d6,d4
                    sf       d3
                    bra.b    lbC027366
lbC027350:
                    move.l   (lbL027FFC,pc),a5
                    move.w   (lbW028004,pc),d7
                    move.w   (lbW028006,pc),d6
                    sub.w    d6,d7
                    moveq    #42,d5
                    st       d3
lbC027366:
                    move.l   a5,d0
                    beq      lbC02740A
                    move.b   d3,(lbB02740C)
                    moveq    #0,d0
                    move.w   d6,d0
                    lsl.l    #2,d0
                    adda.l   d0,a5
                    moveq    #17,d6
                    cmpi.w   #12,d7
                    ble      lbC027406
                    moveq    #12,d7
                    bra      lbC027406
lbC02738A:
                    tst.b    (lbB02740C)
                    bne.b    lbC02739A
                    move.w   d5,d0
                    move.w   d6,d1
                    bsr      lbC027432
lbC02739A:
                    move.l   (a5)+,d0
                    beq.b    lbC02740A
                    move.l   d0,a4
                    tst.b    (lbB02740C)
                    beq      lbC0273EA
                    lea      (lbB027427,pc),a1
                    move.l   (6,a4),d0
                    moveq    #10,d1
                    jsr      (prepare_ascii_decimal_number)
                    lea      (lbB027427,pc),a2
lbC0273BE:
                    cmpi.b   #' ',(a2)+
                    beq.b    lbC0273BE
                    subq.l   #2,a2
                    lea      (10,a4),a0
                    lea      (lbB02740D,pc),a1
lbC0273CE:
                    move.b   (a0)+,d0
                    beq.b    lbC0273DA
                    cmpa.l   a1,a2
                    beq.b    lbC0273E4
                    move.b   d0,(a1)+
                    bra.b    lbC0273CE
lbC0273DA:
                    cmpa.l   a1,a2
                    beq.b    lbC0273E4
                    move.b   #' ',(a1)+
                    bra.b    lbC0273CE
lbC0273E4:
                    lea      (lbB02740D,pc),a0
                    bra.b    lbC0273EE
lbC0273EA:
                    lea      (10,a4),a0
lbC0273EE:
                    move.w   d5,d0
                    move.w   d6,d1
                    jsr      (draw_text)
                    tst.b    (5,a4)
                    beq.b    lbC027404
                    move.w   d5,d0
                    move.w   d6,d1
                    bsr.b    lbC027460
lbC027404:
                    addq.w   #1,d6
lbC027406:
                    dbra     d7,lbC02738A
lbC02740A:
                    rts
lbB02740C:
                    dc.b     0
lbB02740D:
                    dcb.b    26,0
lbB027427:
                    dcb.b    11,0
lbC027432:
                    lea      (main_screen),a0
                    adda.w   d0,a0
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a0
                    moveq    #0,d1
                    moveq    #8-1,d0
lbC027444:
                REPT 9
                    move.l   d1,(a0)+
                ENDR
                    lea      (SCREEN_BYTES-(9*4),a0),a0
                    dbra     d0,lbC027444
                    rts
lbC027460:
                    lea      (main_screen),a0
                    adda.w   d0,a0
                    mulu.w   #(SCREEN_BYTES*8),d1
                    adda.l   d1,a0
                    moveq    #7-1,d0
lbC027470:
                REPT 9
                    not.l    (a0)+
                ENDR
                    lea      (SCREEN_BYTES-(9*4),a0),a0
                    dbra     d0,lbC027470
                    rts
lbC02748C:
                    add.w    (lbW028006,pc),d0
                    cmp.w    (lbW028004,pc),d0
                    bcc      lbC027516
                    move.l   (lbL027FFC,pc),a0
                    moveq    #0,d1
                    move.w   d0,d1
                    add.l    d1,d1
                    add.l    d1,d1
                    move.l   (a0,d1.l),a0
                    tst.b    (lbB028008)
                    beq.b    lbC0274B8
                    moveq    #7,d1
                    and.w    d2,d1
                    bne      lbC0274E6
lbC0274B8:
                    move.l   a0,-(sp)
                    move.l   (lbL027FFC,pc),a0
                    move.w   (lbW028004,pc),d0
                    bsr      lbC0275AC
                    move.l   (sp)+,a0
                    cmpi.w   #1,d0
                    bhi.b    lbC0274D4
                    tst.b    (5,a0)
                    bne.b    lbC02750E
lbC0274D4:
                    movem.l  d0/a0,-(sp)
                    bsr      lbC02753A
                    movem.l  (sp)+,d0/a0
                    st       (5,a0)
                    bra.b    lbC027518
lbC0274E6:
                    move.l   a0,-(sp)
                    move.l   (lbL027FFC,pc),a0
                    move.w   (lbW028004,pc),d0
                    bsr      lbC0275AC
                    move.l   (sp)+,a0
                    tst.w    d0
                    bhi.b    lbC027500
                    st       (5,a0)
                    bra.b    lbC027518
lbC027500:
                    tst.b    (5,a0)
                    bne.b    lbC02750E
                    st       (5,a0)
                    bra      lbC027350
lbC02750E:
                    bsr      lbC026BBC
                    bra      lbC027738
lbC027516:
                    rts
lbC027518:
                    lea      (10,a0),a0
                    lea      (lbB01BEE8),a1
                    moveq    #80,d0
                    jsr      (lbC025DB2)
                    bsr      lbC027738
                    bra      lbC027350
lbC027532:
                    bsr      lbC02753A
                    bra      lbC027350
lbC02753A:
                    move.l   (lbL027FFC,pc),a0
                    move.w   (lbW028004,pc),d0
lbC027546:
                    bra.b    lbC027564
lbC027548:
                    move.l   (a0)+,d1
                    bne.b    lbC02755E
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC027568
lbC02755E:
                    move.l   d1,a1
                    sf       (5,a1)
lbC027564:
                    dbra     d0,lbC027548
lbC027568:
                    rts
lbC02756A:
                    tst.b    (lbB028008)
                    beq.b    lbC02757A
                    bsr      lbC02757C
                    bra      lbC027350
lbC02757A:
                    rts
lbC02757C:
                    move.l   (lbL027FFC,pc),a0
                    move.w   (lbW028004,pc),d0
                    bra.b    lbC0275A6
lbC02758A:
                    move.l   (a0)+,d1
                    bne.b    lbC0275A0
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC0275AA
lbC0275A0:
                    move.l   d1,a1
                    st       (5,a1)
lbC0275A6:
                    dbra     d0,lbC02758A
lbC0275AA:
                    rts
lbC0275AC:
                    movem.l  d2,-(sp)
                    moveq    #0,d1
                    bra.b    lbC0275D4
lbC0275B4:
                    move.l   (a0)+,d2
                    bne.b    lbC0275CA
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC0275D8
lbC0275CA:
                    move.l   d2,a1
                    tst.b    (5,a1)
                    beq.b    lbC0275D4
                    addq.w   #1,d1
lbC0275D4:
                    dbra     d0,lbC0275B4
lbC0275D8:
                    move.w   d1,d0
                    movem.l  (sp)+,d2
                    rts
lbC0275E0:
                    add.w    (lbW027FFA,pc),d0
                    cmp.w    (lbW027FF8,pc),d0
                    bcc      lbC027672
                    move.w   d0,d2
                    move.l   (lbL027FF4,pc),a0
                    moveq    #0,d1
                    move.w   d0,d1
                    add.l    d1,d1
                    add.l    d1,d1
                    move.l   (a0,d1.l),a0
                    tst.b    (5,a0)
                    bne.b    lbC02761C
                    move.l   a0,-(sp)
                    move.l   (lbL027FF4,pc),a0
                    move.w   (lbW027FF8,pc),d0
                    bsr      lbC027546
                    move.l   (sp)+,a0
                    st       (5,a0)
                    bra      lbC02733A
lbC02761C:
                    cmpi.b   #2,(4,a0)
                    beq.b    lbC027652
                    cmpi.b   #0,(4,a0)
                    beq.b    lbC02763E
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC027672
lbC02763E:
                    lea      (10,a0),a0
                    lea      (curent_dir_name),a1
                    moveq    #80,d0
                    jsr      (lbC025DB2)
                    bra.b    lbC027666
lbC027652:
                    lea      (10,a0),a1
                    lea      (curent_dir_name),a0
                    move.l   a0,a2
                    moveq    #80,d0
                    bsr      construct_filename
                    bmi.b    lbC02766E
lbC027666:
                    bsr      lbC027724
                    bra      lbC026F1C
lbC02766E:
                    bra      lbC027724
lbC027672:
                    rts
lbC027674:
                    lea      (curent_dir_name),a0
                    moveq    #9,d0
                    moveq    #10,d1
                    moveq    #80,d2
                    moveq    #29,d3
                    moveq    #0,d4
                    moveq    #2,d5
                    jsr      (lbC0264DE)
                    bmi.b    lbC027696
                    tst.b    d1
                    bne.b    lbC027698
                    bra      lbC026F1C
lbC027696:
                    rts
lbC027698:
                    lea      (lbB01BEE8),a0
                    moveq    #9,d0
                    moveq    #11,d1
                    moveq    #80,d2
                    moveq    #29,d3
                    moveq    #0,d4
                    moveq    #2,d5
                    jsr      (lbC0264DE)
                    bmi.b    lbC0276BA
                    tst.b    d1
                    bne.b    lbC027674
                    bra      lbC026BBC
lbC0276BA:
                    rts
lbC0276BC:
                    lea      (curent_dir_name),a0
                    move.l   a0,a1
                    moveq    #80,d0
                    bsr      lbC027EC6
                    bne.b    lbC0276D6
                    bsr      lbC027724
                    bra      lbC026F1C
lbC0276D6:
                    bra      lbC027724
lbC0276DC:
                    tst.b    (lbB01BEE8)
                    beq.b    lbC02771C
                    jsr      (ask_are_you_sure_requester)
                    bne.b    lbC02771A
                    lea      (curent_dir_name),a0
                    lea      (lbB01BEE8),a1
                    lea      (filename_to_load),a2
                    move.w   #160,d0
                    bsr      construct_filename
                    bmi.b    lbC02771A
                    lea      (filename_to_load),a0
                    jsr      (delete_file)
                    bmi.b    lbC02771A
                    bra      lbC026F18
lbC02771A:
                    rts
lbC02771C:
                    jmp      (error_what_file)
lbC027724:
                    lea      (curent_dir_name),a0
                    moveq    #9,d0
                    moveq    #10,d1
                    moveq    #29,d2
                    jmp      (draw_text_with_blanks)
lbC027738:
                    lea      (lbB01BEE8),a0
                    moveq    #9,d0
                    moveq    #11,d1
                    moveq    #29,d2
                    jmp      (draw_text_with_blanks)
lbC02774C:
                    moveq    #34,d0
                    moveq    #15,d1
                    move.w   (lbW027FEC,pc),d2
                    add.w    (lbW027FF2,pc),d2
                    moveq    #5,d3
                    jmp      (draw_short_ascii_decimal_number)
lbC027762:
                    movem.l  d2,-(sp)
                    moveq    #74,d0
                    moveq    #15,d1
                    move.w   (lbW028004,pc),d2
                    moveq    #5,d3
                    jsr      (draw_short_ascii_decimal_number)
                    movem.l  (sp)+,d2
                    rts

; ===========================================================================
get_disk_size:
                    lea      (disk_info_data),a0
                    move.l   (id_NumBlocks,a0),d0
                    sub.l    (id_NumBlocksUsed,a0),d0
                    bmi.b    .error
                    move.l   (id_BytesPerBlock,a0),d1
                    jsr      (mulu_32)
                    move.l   d0,(disk_size)
                    rts
.error:
                    clr.l    (disk_size)
                    rts

; ===========================================================================
display_disk_size:
                    moveq    #29,d0
                    moveq    #8,d1
                    move.l   (disk_size,pc),d2
                    moveq    #10,d3
                    jmp      (draw_long_ascii_decimal_number)

; ===========================================================================
increase_trackdisk_unit_number:
                    cmpi.w   #3,(trackdisk_unit_number)
                    beq.b    .max
                    addq.w   #1,(trackdisk_unit_number)
                    bra      lbC026B42
.max:
                    rts

; ===========================================================================
decrease_trackdisk_unit_number:
                    tst.w    (trackdisk_unit_number)
                    beq.b    .min
                    subq.w   #1,(trackdisk_unit_number)
                    bra      lbC026B42
.min:
                    rts

; ===========================================================================
switch_verify_mode:
                    not.b    (verify_mode_flag)
                    bra      lbC026B42

; ===========================================================================
switch_clear_mode:
                    not.b    (clear_mode_flag)
                    bra      lbC026B42

; ===========================================================================
format_disk:
                    jsr      (ask_are_you_sure_requester)
                    bne      .cancelled
                    move.w   (trackdisk_unit_number),d0
                    jsr      (inhibit_drive)
                    lea      (trackdisk_message_port,pc),a0
                    jsr      (install_port)
                    lea      (trackdisk_name),a0
                    lea      (trackdisk_device),a1
                    moveq    #0,d0
                    move.w   (trackdisk_unit_number,pc),d0
                    moveq    #0,d1
                    EXEC     OpenDevice
                    tst.l    d0
                    beq      .no_device_error
                    jsr      (error_cant_open_device)
                    bra      .remove_trackdisk_port
.no_device_error:
                    lea      (trackdisk_device),a1
                    move.l   #trackdisk_message_port,(MN_REPLYPORT,a1)
                    move.l   #TRACK_LEN,d0
                    move.l   #$10002,d1
                    EXEC     AllocMem
                    move.l   d0,(track_buffer)
                    bne.b    .no_memory_error
                    jsr      (error_no_memory)
                    bra      .close_trackdisk_device
.no_memory_error:
                    clr.w    (current_formatted_track)
.loop:
                    move.w   #3,(verify_counter)
.reformat_track:
                    bsr      prepare_track_buffer
                    moveq    #'F',d0
                    bsr      draw_trackdisk_status
                    lea      (trackdisk_device),a1
                    move.w   #TD_FORMAT,(IO_COMMAND,a1)
                    move.l   (track_buffer,pc),(IO_DATA,a1)
                    move.l   #TRACK_LEN,(IO_LENGTH,a1)
                    move.w   (current_formatted_track,pc),d0
                    mulu.w   #TRACK_LEN,d0
                    move.l   d0,(IO_OFFSET,a1)
                    EXEC     DoIO
                    tst.b    (trackdisk_device+IO_ERROR)
                    beq.b    .no_format_error
                    jsr      (display_trackdisk_error)
                    bra      .done
.no_format_error:
                    tst.b    (verify_mode_flag)
                    beq.b    .no_verify
                    moveq    #'V',d0
                    bsr      draw_trackdisk_status
                    lea      (trackdisk_device),a1
                    move.w   #CMD_READ,(IO_COMMAND,a1)
                    move.l   (track_buffer,pc),(IO_DATA,a1)
                    move.l   #TRACK_LEN,(IO_LENGTH,a1)
                    move.w   (current_formatted_track,pc),d0
                    mulu.w   #TRACK_LEN,d0
                    move.l   d0,(IO_OFFSET,a1)
                    EXEC     DoIO
                    tst.b    (trackdisk_device+IO_ERROR)
                    beq.b    .no_verify
                    subq.w   #1,(verify_counter)
                    bne      .reformat_track
                    jsr      (display_trackdisk_error)
                    jsr      (error_verify_error)
                    bra      .done
.no_verify:
                    tst.b    (clear_mode_flag)
                    beq.b    .next_track
                    ; stop at track 40 if fast formatting is selected
                    cmpi.w   #40,(current_formatted_track)
                    beq.b    .done
                    ; go to track 40 after bootblock if fast formatting is selected
                    move.w   #40,(current_formatted_track)
                    bra      .loop
.next_track:
                    addq.w   #1,(current_formatted_track)
                    cmpi.w   #80,(current_formatted_track)
                    bne      .loop
.done:
                    move.l   (track_buffer,pc),a1
                    move.l   #TRACK_LEN,d0
                    EXEC     FreeMem
.close_trackdisk_device:
                    lea      (trackdisk_device),a1
                    move.w   #TD_MOTOR,(IO_COMMAND,a1)
                    clr.l    (IO_LENGTH,a1)
                    EXEC     DoIO
                    lea      (trackdisk_device),a1
                    EXEC     CloseDevice
.remove_trackdisk_port:
                    lea      (trackdisk_message_port,pc),a0
                    jsr      (remove_port)
                    move.w   (trackdisk_unit_number),d0
                    jsr      (uninhibit_drive)
.cancelled:
                    bra      erase_trackdisk_status
trackdisk_message_port:
                    dcb.b    MP_SIZE,0
draw_trackdisk_status:
                    move.b   d0,d2
                    moveq    #58,d0
                    moveq    #8,d1
                    jsr      (draw_one_char)
                    moveq    #59,d0
                    moveq    #8,d1
                    move.w   (current_formatted_track,pc),d2
                    moveq    #2,d3
                    jmp      (draw_short_ascii_decimal_number)
erase_trackdisk_status:
                    lea      (.empty_status_text,pc),a0
                    jmp      (draw_text_with_coords_struct)
.empty_status_text:
                    dc.b     58,8,'   ',0

; ===========================================================================
prepare_track_buffer:
                    move.l   (track_buffer,pc),a1
                    lea      (1024,a1),a1
                    moveq    #0,d0
                    moveq    #0,d1
                    moveq    #0,d2
                    moveq    #0,d3
                    moveq    #0,d4
                    moveq    #0,d5
                    moveq    #0,d6
                    move.l   d0,a0
                    moveq    #8-1,d7
.loop:
                    movem.l  d0-d6/a0,-(a1)
                    movem.l  d0-d6/a0,-(a1)
                    movem.l  d0-d6/a0,-(a1)
                    movem.l  d0-d6/a0,-(a1)
                    dbra     d7,.loop
                    move.w   (current_formatted_track,pc),d0
                    beq.b    copy_bootblock_to_track_buffer
                    ; reached rootblock track (at 22*512*40=450560 bytes)
                    cmpi.w   #40,d0
                    beq.b    copy_rootblock_to_track_buffer
                    rts

; ===========================================================================
copy_bootblock_to_track_buffer:
                    lea      (bootblock_data,pc),a0
                    move.l   (track_buffer,pc),a1
                    move.w   #(ebootblock_data-bootblock_data)-1,d0
.loop:
                    move.b   (a0)+,(a1)+
                    dbra     d0,.loop
                    rts

; ===========================================================================
copy_rootblock_to_track_buffer:
                    move.l   (track_buffer,pc),a0
                    ; type (T.SHORT)
                    move.b   #2,(3,a0)
                    ; size of hashtable
                    move.b   #72,(15,a0)
                    ; BMFLAG
                    moveq    #-1,d0
                    move.l   d0,(312,a0)
                    ; bitmap block
                    move.w   #881,(318,a0)
                    ; disk name
                    move.l   #(5<<24)|'Emp',(432,a0)
                    move.w   #'ty',(436,a0)
                    ; sub type of the block (ST.ROOT)
                    move.b   #1,(511,a0)
                    lea      (512+4,a0),a1
                    moveq    #-1,d1
                    moveq    #55-1,d0
                    ; fill the bitmap blocks field
.fill_bitmap:
                    move.l   d1,(a1)+
                    dbra     d0,.fill_bitmap
                    ; mark the root and bitmap blocks as occupied
                    moveq    #%00111111,d0
                    move.b   d0,(626,a0)
                    ; calc the checksum of the bitmap block
                    lea      (512,a0),a1
                    clr.l    (a1)
                    bsr      .calc_checksum
                    move.l   d0,(a1)
                    move.l   a0,-(sp)
                    ; last write access date (day.l/minutes.l/ticks.l)
                    lea      (420,a0),a0
                    move.l   a0,d1
                    DOS      DateStamp
                    move.l   (sp)+,a0
                    ; copy it to disk creation date
                    move.l   (420,a0),(484,a0)
                    move.l   (424,a0),(488,a0)
                    move.l   (428,a0),(492,a0)
                    ; calc the checksum of the root block
                    lea      (a0),a1
                    clr.l    (20,a0)
                    bsr      .calc_checksum
                    move.l   d0,(20,a0)
                    rts
.calc_checksum:
                    move.l   a1,-(a7)
                    moveq    #0,d0
                    moveq    #128-1,d1
.loop:
                    sub.l    (a1)+,d0
                    dbra     d1,.loop
                    move.l   (a7)+,a1
                    rts

; ===========================================================================
bootblock_data:
                    BBID_DOS
                    dc.l     $C0200F19,880
                    lea      (.dos_name,pc),a1
                    jsr      (_LVOFindResident,a6)
                    tst.l    d0
                    beq.b    .error
                    move.l   d0,a0
                    move.l   (22,a0),a0
                    moveq    #OK,d0
.exit:
                    rts
.error:
                    moveq    #ERROR,d0
                    bra.b    .exit
.dos_name:
                    DOSNAME
ebootblock_data:

; ===========================================================================
trackdisk_unit_number:
                    dc.w     0
verify_mode_flag:
                    dc.b     -1
clear_mode_flag:
                    dc.b     0
track_buffer:
                    dc.l     0
current_formatted_track:
                    dcb.w    3,0
verify_counter:
                    dc.w     0
lbC027B40:
                    tst.b    d0
                    bne.b    lbC027B5C
                    bsr      lbC027B6A
                    seq      (lbB027FDA)
                    bsr      lbC027B86
                    bmi.b    lbC027B58
                    moveq    #OK,d0
                    rts
lbC027B58:
                    moveq    #ERROR,d0
                    rts
lbC027B5C:
                    bsr      lbC027B6A
                    seq      (lbB027FDA)
                    moveq    #ERROR,d0
                    rts
lbC027B6A:
                    bsr      lbC027E12
                    bmi.b    lbC027B82
                    lea      (filename_to_load),a0
                    jsr      (file_exist)
                    bmi.b    lbC027B82
                    moveq    #OK,d0
                    rts
lbC027B82:
                    moveq    #ERROR,d0
                    rts
lbC027B86:
                    bsr      lbC027E12
                    bmi      lbC027C84
                    lea      (filename_to_load),a0
                    jsr      (lbC025C1A)
                    bmi      lbC027C84
                    move.l   d0,(lbL027C9E)
                    lea      (filename_to_load),a0
                    jsr      (open_file_for_reading)
                    bmi      lbC027C84
                    lea      (lbW027FD0,pc),a0
                    moveq    #10,d0
                    jsr      (read_from_file)
                    bmi      lbC027C84
                    lea      (lbW027FD0,pc),a0
                    cmpi.l   #'.okd',(a0)+
                    bne      lbC027C84
                    cmpi.w   #'ir',(a0)+
                    bne      lbC027C84
                    move.l   (lbL027C9E,pc),d0
                    subi.l   #10,d0
                    bmi      lbC027C84
                    beq      lbC027C7C
                    bsr      lbC027CA2
                    bmi      lbC027C84
                    move.l   (lbL027CEC,pc),a0
                    move.l   (lbL027CF0,pc),d0
                    jsr      (read_from_file)
                    bmi      lbC027C84
                    move.l   (lbL027CEC,pc),a0
                    move.w   (lbW027FD6,pc),d7
                    bmi.b    lbC027C84
                    bra.b    lbC027C38
lbC027C12:
                    move.l   a0,(lbL027C98)
                    move.w   d7,(lbW027C9C)
                    bsr      lbC0271CC
                    bmi.b    lbC027C84
                    move.l   (lbL027C98,pc),a0
                    jsr      (lbC025DA6)
                    move.l   (lbL027C98,pc),a0
                    adda.l   d0,a0
                    move.w   (lbW027C9C,pc),d7
lbC027C38:
                    dbra     d7,lbC027C12
                    move.w   (lbW027FD8,pc),d7
                    bmi.b    lbC027C84
                    bra.b    lbC027C78
lbC027C44:
                    move.w   d7,(lbW027C9C)
                    move.b   (a0)+,d0
                    lsl.l    #8,d0
                    move.b   (a0)+,d0
                    lsl.l    #8,d0
                    move.b   (a0)+,d0
                    lsl.l    #8,d0
                    move.b   (a0)+,d0
                    move.l   a0,(lbL027C98)
                    bsr      lbC0271EC
                    bmi.b    lbC027C84
                    move.l   (lbL027C98,pc),a0
                    jsr      (lbC025DA6)
                    move.l   (lbL027C98,pc),a0
                    adda.l   d0,a0
                    move.w   (lbW027C9C,pc),d7
lbC027C78:
                    dbra     d7,lbC027C44
lbC027C7C:
                    bsr      lbC027C8C
                    moveq    #OK,d0
                    rts
lbC027C84:
                    bsr      lbC027C8C
                    moveq    #ERROR,d0
                    rts
lbC027C8C:
                    bsr      lbC027CCE
                    jmp      (close_file)
lbL027C98:
                    dc.l     0
lbW027C9C:
                    dc.w     0
lbL027C9E:
                    dc.l     0
lbC027CA2:
                    move.l   d0,(lbL027CF0)
                    move.l   #$10000,d1
                    EXEC     AllocMem
                    move.l   d0,(lbL027CEC)
                    beq.b    lbC027CC6
                    moveq    #0,d0
                    rts
lbC027CC6:
                    jmp      (error_no_memory)
lbC027CCE:
                    lea      (lbL027CEC,pc),a0
                    move.l   (a0),d0
                    beq.b    lbC027CEA
                    clr.l    (a0)
                    move.l   d0,a1
                    move.l   (lbL027CF0,pc),d0
                    EXEC     FreeMem
lbC027CEA:
                    rts
lbL027CEC:
                    dc.l     0
lbL027CF0:
                    dc.l     0
lbC027CF4:
                    tst.b    (lbB027FDA)
                    beq.b    lbC027D04
                    jmp      (error_already_installed)
lbC027D04:
                    bsr      lbC027E12
                    bmi      lbC027DCC
                    lea      (filename_to_load),a0
                    jsr      (open_file_for_writing)
                    bmi      lbC027DCC
                    lea      (lbW027FD0,pc),a0
                    move.l   #'.okd',(a0)+
                    move.w   #'ir',(a0)+
                    move.w   (lbW027FF2,pc),d0
                    sub.w    (lbW027FC6),d0
                    move.w   d0,(a0)+
                    move.w   (lbW028004,pc),(a0)+
                    lea      (lbW027FD0,pc),a0
                    moveq    #10,d0
                    jsr      (write_to_file)
                    bne      lbC027DCC
                    lea      (lbL027FEE,pc),a5
                    move.w   (lbW027FD6,pc),d7
                    bra.b    lbC027D7A
lbC027D54:
                    move.l   (a5),d0
                    beq      lbC027DCC
                    move.l   d0,a5
                    tst.l    (6,a5)
                    bne.b    lbC027D54
                    lea      (10,a5),a0
                    jsr      (lbC025DA6)
                    lea      (10,a5),a0
                    jsr      (write_to_file)
                    bne      lbC027DCC
lbC027D7A:
                    dbra     d7,lbC027D54
                    lea      (lbL028000,pc),a5
                    move.w   (lbW027FD8,pc),d7
                    bra.b    lbC027DB4
lbC027D88:
                    move.l   (a5),d0
                    beq      lbC027DCC
                    move.l   d0,a5
                    lea      (6,a5),a0
                    moveq    #4,d0
                    jsr      (write_to_file)
                    bne.b    lbC027DCC
                    lea      (10,a5),a0
                    jsr      (lbC025DA6)
                    lea      (10,a5),a0
                    jsr      (write_to_file)
                    bne.b    lbC027DCC
lbC027DB4:
                    dbra     d7,lbC027D88
                    st       (lbB027FDA)
                    bsr      lbC027E2A
                    jsr      (close_file)
                    moveq    #0,d0
                    rts
lbC027DCC:
                    jsr      (close_file)
                    jmp      (error_cant_install)
lbC027DDA:
                    tst.b    (lbB027FDA)
                    bne.b    lbC027DEA
                    jmp      (error_no_okdir)
lbC027DEA:
                    bsr      lbC027E12
                    bmi      lbC027E0E
                    lea      (filename_to_load),a0
                    jsr      (delete_file)
                    bmi.b    lbC027E0E
                    sf       (lbB027FDA)
                    bsr      lbC027E2A
                    moveq    #OK,d0
                    rts
lbC027E0E:
                    moveq    #ERROR,d0
                    rts
lbC027E12:
                    lea      (curent_dir_name),a0
                    lea      (okdir_MSG,pc),a1
                    lea      (filename_to_load),a2
                    move.w   #160,d0
                    bra      construct_filename
lbC027E2A:
                    lea      (On_MSG0,pc),a0
                    tst.b    (lbB027FDA)
                    bne.b    lbC027E3A
                    lea      (Off_MSG0,pc),a0
lbC027E3A:
                    moveq    #76,d0
                    moveq    #10,d1
                    jmp      (draw_text)
On_MSG0:
                    dc.b     ' On',0
Off_MSG0:
                    dc.b     'Off',0

; ===========================================================================
construct_filename:
                    move.w   d0,d2
                    moveq    #0,d1
lbC027E52:
                    move.b   (a0)+,d0
                    beq.b    lbC027E62
                    move.b   d0,(a2,d1.w)
                    addq.w   #1,d1
                    cmp.w    d1,d2
                    bne.b    lbC027E52
                    bra.b    lbC027EB8
lbC027E62:
                    move.w   d1,d3
                    tst.w    d1
                    beq.b    lbC027E84
                    move.b   (-2,a0),d0
                    cmpi.b   #':',d0
                    beq.b    lbC027E84
                    cmpi.b   #'/',d0
                    beq.b    lbC027E84
                    move.b   #'/',(a2,d1.w)
                    addq.w   #1,d1
                    cmp.w    d1,d2
                    beq.b    lbC027EA6
lbC027E84:
                    move.b   (a1)+,d0
                    beq.b    lbC027E94
                    move.b   d0,(a2,d1.w)
                    addq.w   #1,d1
                    cmp.w    d1,d2
                    bne.b    lbC027E84
                    bra.b    lbC027EA6
lbC027E94:
                    sf       (a2,d1.w)
                    move.l   a2,a1
                    move.w   d2,d0
                    jsr      (lbC025D84)
                    moveq    #OK,d0
                    rts
lbC027EA6:
                    move.l   a2,a1
                    move.w   d2,d0
                    sf       (a1,d3.w)
                    jsr      (lbC025D84)
                    moveq    #ERROR,d0
                    rts
lbC027EB8:
                    move.l   a2,a1
                    move.w   d2,d0
                    jsr      (lbC025D9C)
                    moveq    #ERROR,d0
                    rts

; ===========================================================================
lbC027EC6:
                    move.w   d0,d2
                    tst.b    (a0)
                    beq.b    lbC027F0E
                    moveq    #0,d1
                    move.w   d1,d3
lbC027ED0:
                    move.b   (a0)+,d0
                    beq.b    lbC027EFA
                    cmpi.b   #'/',d0
                    bne.b    lbC027EE0
                    tst.b    (a0)
                    beq.b    lbC027EE0
                    move.w   d1,d3
lbC027EE0:
                    cmpi.b   #':',d0
                    bne.b    lbC027EEE
                    tst.b    (a0)
                    beq.b    lbC027EEE
                    move.w   d1,d3
                    addq.w   #1,d3
lbC027EEE:
                    move.b   d0,(a1,d1.w)
                    addq.w   #1,d1
                    cmp.w    d1,d2
                    bne.b    lbC027ED0
                    bra.b    lbC027F0E
lbC027EFA:
                    cmp.w    d2,d3
                    bge.b    lbC027F0E
                    sf       (a1,d3.w)
                    move.w   d2,d0
                    jsr      (lbC025D84)
                    moveq    #OK,d0
                    rts
lbC027F0E:
                    move.w   d2,d0
                    jsr      (lbC025D9C)
                    moveq    #ERROR,d0
                    rts
lbC027F1A:
                    movem.l  d2,-(sp)
                    andi.l   #$FFFF,d0
                    addq.l   #2,d0
                    add.l    d0,d0
                    add.l    d0,d0
                    move.l   d0,d2
                    move.l   #$10000,d1
                    EXEC     AllocMem
                    move.l   d0,a0
                    tst.l    d0
                    beq.b    lbC027F48
                    move.l   d2,(a0)+
                    move.l   a0,d0
lbC027F48:
                    movem.l  (sp)+,d2
                    rts
lbC027F4E:
                    move.l   a0,d0
                    beq.b    lbC027F62
                    move.l   -(a0),d0
                    move.l   a0,a1
                    EXEC     FreeMem
lbC027F62:
                    rts
lbC027F64:
                    moveq    #0,d1
                    move.w   d0,d1
                    add.l    d1,d1
                    add.l    d1,d1
                    adda.l   d1,a0
                    rts
lbC027F70:
                    move.l   d2,-(sp)
                    moveq    #0,d2
                    move.w   d0,d2
                    add.l    d2,d2
                    add.l    d2,d2
                    adda.l   d2,a1
                    move.w   d1,d0
                    bsr      lbC027F86
                    move.l   (sp)+,d2
                    rts
lbC027F86:
                    bra.b    lbC027F90
lbC027F88:
                    move.l   a0,d1
                    beq.b    lbC027F96
                    move.l   (a0),a0
                    move.l   a0,(a1)+
lbC027F90:
                    dbra     d0,lbC027F88
                    rts
lbC027F96:
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    rts
lbC027FA8:
                    move.l   (a0)+,d0
                    move.l   d0,(a1)
                    beq.b    lbC027FB2
                    move.l   d0,a1
                    bra.b    lbC027FA8
lbC027FB2:
                    rts
lbW027FC6:
                    dc.w     0
okdir_MSG:
                    dc.b     '.okdir',0
                    even
lbW027FD0:
                    dcb.w    3,0
lbW027FD6:
                    dc.w     0
lbW027FD8:
                    dc.w     0
lbB027FDA:
                    dc.b     0,0
lbL027FDC:
                    dc.l     0
dir_lock_handle:
                    dc.l     0
disk_size:
                    dc.l     0
lbL027FE8:
                    dc.l     0
lbW027FEC:
                    dc.w     0
lbL027FEE:
                    dc.l     0
lbW027FF2:
                    dc.w     0
lbL027FF4:
                    dc.l     0
lbW027FF8:
                    dc.w     0
lbW027FFA:
                    dc.w     0
lbL027FFC:
                    dc.l     0
lbL028000:
                    dc.l     0
lbW028004:
                    dc.w     0
lbW028006:
                    dc.w     0
lbB028008:
                    dc.b     0
                    even
lbC02800C:
                    sf       (lbB028218)
                    moveq    #-1,d0
                    move.l   d0,(lbW0289C0)
lbC02801A:
                    lea      (lbW02821A,pc),a0
                    jsr      (process_commands_sequence)
                    move.w   #161,d0
                    bsr      lbC02823A
                    move.w   #190,d0
                    bsr      lbC02823A
                    move.w   #226,d0
                    bsr      lbC02823A
                    st       (lbB029EE7)
                    bsr      lbC028284
                    bsr      lbC0280AE
                    lea      (lbW028074,pc),a0
                    jsr      (lbC020626)
                    bsr      lbC028292
                    move.l   (current_cmd_ptr),d0
                    beq.b    lbC028066
                    move.l   d0,a0
                    jsr      (a0)
                    bra.b    lbC02801A
lbC028066:
                    tst.b    (quit_flag)
                    beq.b    lbC02801A
                    bra      lbC0280FE
lbW028074:
                    dc.w     11
                    dc.l     lbC0281F6
                    dc.w     11
                    dc.l     lbC0282B8
                    dc.w     1
                    dc.l     lbC02814E
                    dc.w     2
                    dc.l     lbC0281AE
                    dc.w     14
                    dc.l     lbC029E1A
                    dc.w     0
max_lines:
                    dc.w     21
lbL028096:
                    dc.l     lbW018A04
                    dc.l     lbW028FDC
                    dc.l     lbL0291B8
                    dc.l     lbL0293F0
                    dc.l     lbL029A1E,0
lbC0280AE:
                    tst.b    (ntsc_flag)
                    beq.b    lbC0280FC
                    EXEC     Disable
                    move.w   #DMAF_COPPER,(_CUSTOM|DMACON)
                    addq.b   #1,(dma_copper_spinlock)
                    move.b   #$F0,(copper_credits_line)
                    move.b   #$F8,(copper_end_line)
                    subq.b   #1,(dma_copper_spinlock)
                    bgt.b    lbC0280F0
                    move.w   #DMAF_SETCLR|DMAF_COPPER,(_CUSTOM|DMACON)
lbC0280F0:
                    EXEC     Enable
lbC0280FC:
                    rts
lbC0280FE:
                    tst.b    (ntsc_flag)
                    beq.b    lbC02814C
                    EXEC     Disable
                    move.w   #DMAF_COPPER,(_CUSTOM|DMACON)
                    addq.b   #1,(dma_copper_spinlock)
                    move.b   #$EC,(copper_credits_line)
                    move.b   #$F4,(copper_end_line)
                    subq.b   #1,(dma_copper_spinlock)
                    bgt.b    lbC028140
                    move.w   #DMAF_SETCLR|DMAF_COPPER,(_CUSTOM|DMACON)
lbC028140:
                    EXEC     Enable
lbC02814C:
                    rts
lbC02814E:
                    move.w   d1,d0
                    andi.w   #$FF00,d0
                    bne.b    lbC0281A8
                    cmpi.b   #16,d1
                    bne.b    lbC028164
                    jsr      (lbC01F298)
                    bra.b    lbC0281A8
lbC028164:
                    cmpi.b   #17,d1
                    bne.b    lbC028172
                    jsr      (lbC01F2B2)
                    bra.b    lbC0281A8
lbC028172:
                    move.w   d1,d0
                    jsr      (lbC01F06E)
                    bmi.b    lbC0281A8
                    move.l   (lbL01F2D0),a1
                    moveq    #0,d1
                    move.b   (a1,d0.w),d1
                    bmi.b    lbC0281A8
                    lea      (lbW0281AC,pc),a0
                    move.w   (a0),d0
                    addq.w   #1,(a0)
                    andi.w   #3,(a0)
                    movem.l  d0/d1,-(sp)
                    bsr      lbC029E3E
                    movem.l  (sp)+,d0/d1
                    jsr      (lbC01EF1E)
lbC0281A8:
                    moveq    #ERROR,d0
                    rts
lbW0281AC:
                    dc.w     0
lbC0281AE:
                    cmpi.b   #MIDI_IN,(midi_mode)
                    bne.b    lbC0281F2
                    move.w   d1,d0
                    subi.w   #$30,d0
                    bmi.b    lbC0281F2
                    cmpi.w   #$24,d0
                    bge.b    lbC0281F2
                    addq.w   #1,d0
                    tst.w    d2
                    bne.b    lbC0281D2
                    bsr      lbC029E50
                    bra.b    lbC0281F2
lbC0281D2:
                    move.w   d0,d1
                    lea      (lbW0281AC,pc),a0
                    move.w   (a0),d0
                    addq.w   #1,(a0)
                    andi.w   #3,(a0)
                    movem.l  d0/d1,-(sp)
                    bsr      lbC029E3E
                    movem.l  (sp)+,d0/d1
                    jsr      (lbC01EF1E)
lbC0281F2:
                    moveq    #ERROR,d0
                    rts
lbC0281F6:
                    jmp      (lbC0208FA)
lbC0281FE:
                    tst.b    (lbB028218)
                    beq.b    lbC028210
                    jsr      (ask_are_you_sure_requester)
                    beq.b    lbC028210
                    rts
lbC028210:
                    st       (quit_flag)
                    rts
lbB028218:
                    dcb.b    2,0
lbW02821A:
                    dc.w     1
                    dc.l     samples_ed_text
                    dc.w     2
                    dc.l     lbW018B00
                    dc.w     3
                    dc.l     lbW01892C
                    dc.w     0
                    dc.l     0,0,0
lbC02823A:
                    movem.l  d2-d7/a2-a6,-(sp)
                    tst.b    (ntsc_flag)
                    beq.b    lbC02824A
                    subi.w   #32,d0
lbC02824A:
                    move.w   d0,d1
                    move.w   d0,d3
                    moveq    #0,d0
                    move.w   #SCREEN_WIDTH-1,d2
                    jsr      (draw_filled_box)
                    movem.l  (sp)+,d2-d7/a2-a6
                    rts
lbC028260:
                    move.l   #lbC02826C,(current_cmd_ptr)
                    rts
lbC02826C:
                    lea      (samples_ed_help_text),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    jmp      (lbC0246B8)
lbC028284:
                    moveq    #-1,d0
                    move.l   d0,(lbW028BE2)
                    bra      lbC02837A
lbC028292:
                    sf       (lbB029EE7)
                    lea      (lbW0282A8,pc),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jmp      (process_command)
lbW0282A8:
                    dc.b     CMD_MOVE_TO_LINE,0
                    dc.l     max_lines
                    ; x,y,amount of chars to clear from position
                    dc.b     CMD_CLEAR_CHARS,0,0,SCREEN_BYTES
                    dc.b     CMD_CLEAR_CHARS,0,1,SCREEN_BYTES
                    dc.b     CMD_END
                    even
lbC0282B8:
                    move.l   d4,-(sp)
                    cmpi.w   #4,d0
                    beq.b    lbC0282CE
                    cmpi.w   #3,d0
                    bne.b    lbC028306
                    tst.b    d3
                    beq.b    lbC028306
                    sf       d4
                    bra.b    lbC0282D0
lbC0282CE:
                    st       d4
lbC0282D0:
                    move.w   d2,d0
                    cmpi.w   #96,d0
                    blt.b    lbC028306
                    tst.b    (ntsc_flag)
                    beq.b    lbC0282E8
                    cmpi.w   #128,d0
                    bge.b    lbC028306
                    bra.b    lbC0282EE
lbC0282E8:
                    cmpi.w   #160,d0
                    bge.b    lbC028306
lbC0282EE:
                    tst.b    d4
                    beq.b    lbC0282FA
                    move.w   d1,d0
                    bsr      lbC028938
                    bra.b    lbC028306
lbC0282FA:
                    move.w   (lbW0289C0),d0
                    bmi.b    lbC028306
                    bsr      lbC028938
lbC028306:
                    move.l   (sp)+,d4
                    moveq    #ERROR,d0
                    rts
lbC02830C:
                    jsr      (do_free_sample)
                    bsr      lbC02896C
                    bsr.b    lbC02837A
                    bsr      lbC028C3E
                    jmp      (error_sample_cleared)
lbC028324:
                    move.l   (lbL029ECE),d0
                    cmpi.l   #2,d0
                    blt.b    lbC02836A
                    cmpi.l   #131070,d0
                    bgt.b    lbC028372
                    jsr      (lbC021F9E)
                    bmi.b    lbC02830C
                    move.l   d0,a1
                    move.l   (lbL01A130),d0
                    beq.b    lbC02830C
                    move.l   d0,a0
                    move.l   (lbL029ECE),d0
                    EXEC     CopyMem
                    jsr      (lbC02001C)
                    moveq    #0,d0
                    rts
lbC02836A:
                    jsr      (error_sample_too_short)
                    bra.b    lbC02830C
lbC028372:
                    jsr      (error_sample_too_long)
                    bra.b    lbC02830C
lbC02837A:
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    cmpi.w   #1,(30,a0,d0.w)
                    seq      (lbB029EE6)
                    bsr      lbC0284F6
                    cmpi.l   #SCREEN_WIDTH,(lbL01A134)
                    bcs      lbC028460
                    move.l   (lbL01A134),d1
                    lsl.l    #8,d1
                    divu.w   #(SCREEN_BYTES*8),d1
                    move.w   d1,(lbW029ED2)
                    movem.l  d2-d7/a2,-(sp)
                    move.b   (lbB029EE6,pc),d2
                    move.l   (lbL01A130),a2
                    move.l   (lbL01A134),a3
                    move.w   #SCREEN_WIDTH-1,d3
                    jsr      (prepare_line_drawing)
                    moveq    #2,d4
                    tst.b    (ntsc_flag)
                    beq.b    lbC0283E2
                    moveq    #3,d4
lbC0283E2:
                    swap     d4
                    moveq    #0,d5
                    move.w   (lbW029ED2),d5
                    moveq    #0,d6
                    moveq    #0,d7
                    bra.b    lbC028446
lbC0283F2:
                    moveq    #0,d0
                    moveq    #0,d1
                    move.b   (a2,d7.l),d0
                    add.l    d5,d6
                    move.l   d6,d7
                    lsr.l    #8,d7
                    cmp.l    a3,d7
                    bcc.b    lbC02844A
                    move.b   (a2,d7.l),d1
                    tst.b    d2
                    bne.b    lbC028410
                    add.b    d0,d0
                    add.b    d1,d1
lbC028410:
                    eori.b   #$80,d0
                    eori.b   #$80,d1
                    swap     d4
                    lsr.w    d4,d0
                    lsr.w    d4,d1
                    swap     d4
                    movem.l  d2/d3,-(sp)
                    lea      (main_screen),a0
                    move.w   d1,d3
                    move.w   d0,d1
                    move.w   d4,d0
                    addq.w   #1,d4
                    move.w   d4,d2
                    addi.w   #$60,d1
                    addi.w   #$60,d3
                    jsr      (lbC0256DA)
                    movem.l  (sp)+,d2/d3
lbC028446:
                    dbra     d3,lbC0283F2
lbC02844A:
                    jsr      (release_after_line_drawing)
                    movem.l  (sp)+,d2-d7/a2
                    bsr      lbC028E96
                    bsr      lbC028B5A
                    bra      lbC02895C
lbC028460:
                    movem.l  d2-d4/a2,-(sp)
                    move.b   (lbB029EE6,pc),d2
                    move.l   (lbL01A130),a2
                    move.l   (lbL01A134),d3
                    subq.w   #1,d3
                    bmi.b    lbC0284DE
                    jsr      (prepare_line_drawing)
                    moveq    #2,d4
                    tst.b    (ntsc_flag)
                    beq.b    lbC02848A
                    moveq    #3,d4
lbC02848A:
                    swap     d4
                    bra.b    lbC0284D4
lbC02848E:
                    moveq    #0,d0
                    moveq    #0,d1
                    move.b   (a2)+,d0
                    move.b   (a2),d1
                    tst.b    d2
                    bne.b    lbC02849E
                    add.b    d0,d0
                    add.b    d1,d1
lbC02849E:
                    eori.b   #$80,d0
                    eori.b   #$80,d1
                    swap     d4
                    lsr.w    d4,d0
                    lsr.w    d4,d1
                    swap     d4
                    movem.l  d2/d3,-(sp)
                    lea      (main_screen),a0
                    move.w   d1,d3
                    move.w   d0,d1
                    move.w   d4,d0
                    addq.w   #1,d4
                    move.w   d4,d2
                    addi.w   #$60,d1
                    addi.w   #$60,d3
                    jsr      (lbC0256DA)
                    movem.l  (sp)+,d2/d3
lbC0284D4:
                    dbra     d3,lbC02848E
                    jsr      (release_after_line_drawing)
lbC0284DE:
                    movem.l  (sp)+,d2-d4/a2
                    move.w   #$100,(lbW029ED2)
                    bsr      lbC028E96
                    bsr      lbC028B5A
                    bra      lbC02895C
lbC0284F6:
                    bsr      own_blitter
                    move.l   #$1000000,(BLTCON0,a6)
                    move.w   #0,(BLTDMOD,a6)
                    move.l   #main_screen+7680,(BLTDPTH,a6)
                    move.w   #(64*64)+(SCREEN_BYTES/2),d0
                    tst.b    (ntsc_flag)
                    beq.b    lbC028520
                    move.w   #(32*64)+(SCREEN_BYTES/2),d0
lbC028520:
                    move.w   d0,(BLTSIZE,a6)
                    bra      disown_blitter
lbC02852A:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    moveq    #14,d0
                    moveq    #10,d1
                    moveq    #21,d2
                    moveq    #21,d3
                    moveq    #0,d4
                    jsr      (lbC0264DC)
                    jmp      (lbC01FBF2)
lbC02855C:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.l    (lbL029EDC)
                    beq      lbC029E9E
                    move.l   (lbL029EE0),(lbL029EEA)
                    move.l   (lbL029EEA),d0
                    move.l   #$10002,d1
                    EXEC     AllocMem
                    move.l   d0,(lbL029EEE)
                    beq      lbC029EA6
                    move.l   (lbL029EDC),a0
                    move.l   (lbL029EEE),a1
                    move.l   (lbL029EEA),d0
                    EXEC     CopyMem
                    bsr      lbC028914
                    jsr      (stop_audio_channels)
                    move.l   (lbL01A130),(lbL029EDC)
                    move.l   (lbL01A134),(lbL029EE0)
                    move.l   (lbL029EEE),(lbL01A130)
                    move.l   (lbL029EEA),d0
                    move.l   d0,(lbL01A134)
                    move.l   d0,(lbL029ECE)
                    not.b    (lbB028218)
                    bsr      lbC02896C
                    bsr      lbC028324
                    bsr      lbC02837A
                    bra      lbC028C3E
lbC02860A:
                    moveq    #0,d0
                    move.w   #639,d1
                    bra      lbC028938
lbC028614:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    clr.w    (lbW029EE4)
                    bsr.b    lbC02869A
                    bmi.b    lbC02862A
                    bra.b    lbC02862C
lbC02862A:
                    rts
lbC02862C:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.b    (lbB029EE8)
                    beq      lbC029E9E
                    movem.l  (lbW029ED4),d0/d1
                    sub.l    d0,d1
                    beq      lbC029E9E
                    jsr      (stop_audio_channels)
                    move.l   (lbL01A130),a3
                    movem.l  (lbW029ED4),a0/a1
                    move.l   (lbL01A134),a2
                    adda.l   a3,a0
                    adda.l   a3,a1
                    adda.l   a3,a2
lbC02866E:
                    cmpa.l   a2,a1
                    bge.b    lbC028676
                    move.b   (a1)+,(a0)+
                    bra.b    lbC02866E
lbC028676:
                    sub.l    (lbL01A130),a0
                    move.l   a0,(lbL029ECE)
                    bsr      lbC02896C
                    bsr      lbC028324
                    bsr      lbC02837A
                    bra      lbC028C3E
lbC028692:
                    move.w   #-1,(lbW029EE4)
lbC02869A:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.b    (lbB029EE8)
                    beq      lbC029E9E
                    movem.l  (lbW029ED4),a0/a1
                    sub.l    a0,a1
                    move.l   a1,d0
                    beq      lbC029E9E
                    bsr      lbC0288CA
                    beq      lbC029EA6
                    move.l   d0,a1
                    move.l   (lbL01A130),a0
                    adda.l   (lbW029ED4),a0
                    move.l   d1,d0
                    EXEC     CopyMem
                    tst.w    (lbW029EE4)
                    beq.b    lbC0286F0
                    jsr      (error_block_copied)
lbC0286F0:
                    moveq    #0,d0
                    rts
lbC0286F4:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.l    (lbL029EDC)
                    beq      lbC029E9E
                    tst.w    (lbW0289C0)
                    bmi      lbC029EAE
                    move.l   (lbL01A134),d0
                    add.l    (lbL029EE0),d0
                    cmpi.l   #131070,d0
                    bgt      lbC029EB6
                    jsr      (stop_audio_channels)
                    jsr      (lbC021F9E)
                    bmi      lbC028324
                    move.l   (lbL01A130),a0
                    move.l   d0,a1
                    move.l   (lbW029ED4),d0
                    EXEC     CopyMem
                    move.l   a0,-(sp)
                    move.l   (lbL029EDC),a0
                    move.l   (lbL029EE0),d0
                    EXEC     CopyMem
                    move.l   (sp)+,a0
                    move.l   (lbL01A134),d0
                    sub.l    (lbW029ED4),d0
                    EXEC     CopyMem
                    jsr      (lbC02001C)
                    bmi      lbC02830C
                    bsr      lbC02896C
                    bsr      lbC02837A
                    bra      lbC028C3E
lbC02879C:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.l    (lbL029EDC)
                    beq      lbC029E9E
                    tst.w    (lbW0289C0)
                    bmi      lbC029EAE
                    move.l   (lbL01A134),d1
                    move.l   d1,d0
                    sub.l    (lbW029ED4),d1
                    cmp.l    (lbL029EE0),d1
                    bgt.b    lbC0287DC
                    move.l   (lbW029ED4),d0
                    add.l    (lbL029EE0),d0
lbC0287DC:
                    cmpi.l   #131070,d0
                    bgt      lbC029EB6
                    jsr      (lbC021F9E)
                    bmi      lbC028324
                    jsr      (stop_audio_channels)
                    move.l   (lbL01A130),a0
                    move.l   d0,a1
                    move.l   (lbW029ED4),d0
                    EXEC     CopyMem
                    move.l   a0,-(sp)
                    move.l   (lbL029EDC),a0
                    move.l   (lbL029EE0),d0
                    EXEC     CopyMem
                    move.l   (sp)+,a0
                    adda.l   (lbL029EE0),a0
                    move.l   (lbL01A134),d0
                    sub.l    (lbW029ED4),d0
                    sub.l    (lbL029EE0),d0
                    bmi.b    lbC028852
                    EXEC     CopyMem
lbC028852:
                    jsr      (lbC02001C)
                    bmi      lbC02830C
                    bsr      lbC02896C
                    bsr      lbC02837A
                    bra      lbC028C3E
lbC028868:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.b    (lbB029EE8)
                    beq.b    lbC028884
                    movem.l  (lbW029ED4),d0/d1
                    bra.b    lbC02888C
lbC028884:
                    moveq    #0,d0
                    move.l   (lbL01A134),d1
lbC02888C:
                    cmp.l    d0,d1
                    beq      lbC029E9E
                    jsr      (stop_audio_channels)
                    move.l   d0,d2
                    add.l    d1,d2
                    lsr.l    #1,d2
                    move.l   (lbL01A130),a3
                    lea      (a3,d0.l),a0
                    lea      (a3,d1.l),a1
                    lea      (a3,d2.l),a2
lbC0288B0:
                    cmpa.l   a2,a0
                    bge.b    lbC0288BE
                    move.b   (a0),d0
                    move.b   -(a1),d1
                    move.b   d0,(a1)
                    move.b   d1,(a0)+
                    bra.b    lbC0288B0
lbC0288BE:
                    bsr      lbC028324
                    bsr      lbC02837A
                    bra      lbC028C3E
lbC0288CA:
                    move.l   d0,(lbL029F04)
                    bsr.b    lbC028914
                    move.l   (lbL029F04),d0
                    move.l   #$10000,d1
                    EXEC     AllocMem
                    move.l   d0,(lbL029EDC)
                    beq.b    lbC028900
                    move.l   (lbL029F04),d2
                    move.l   d2,(lbL029EE0)
                    move.l   d2,d1
lbC028900:
                    tst.l    d0
                    rts
lbC028904:
                    bsr.b    lbC028914
                    jsr      (error_copy_buffer_free)
                    jmp      (lbC01FBF2)
lbC028914:
                    move.l   (lbL029EDC),d0
                    beq.b    lbC028936
                    clr.l    (lbL029EDC)
                    move.l   d0,a1
                    move.l   (lbL029EE0),d0
                    EXEC     FreeMem
lbC028936:
                    rts
lbC028938:
                    move.l   d2,-(sp)
                    move.w   d0,d2
                    swap     d2
                    move.w   d1,d2
                    cmp.l    (lbW0289C0),d2
                    beq.b    lbC028958
                    movem.w  d0/d1,-(sp)
                    bsr.b    lbC02896C
                    movem.w  (sp)+,d0/d1
                    bsr.b    lbC02898A
                    bsr      lbC028C3E
lbC028958:
                    move.l   (sp)+,d2
                    rts
lbC02895C:
                    move.l   (lbW0289C0),-(sp)
                    bsr.b    lbC02896C
                    move.l   (sp)+,(lbW0289C0)
                    rts
lbC02896C:
                    moveq    #-1,d0
                    cmp.l    (lbW0289C0),d0
                    beq.b    lbC028988
                    movem.w  (lbW0289C0),d0/d1
                    bsr.b    lbC02898A
                    moveq    #-1,d0
                    move.l   d0,(lbW0289C0)
lbC028988:
                    rts
lbC02898A:
                    movem.l  d2/d3,-(sp)
                    movem.w  d0/d1,(lbW0289C0)
                    move.w   d1,d2
                    move.w   #96,d1
                    move.w   #159,d3
                    tst.b    (ntsc_flag)
                    beq.b    lbC0289AC
                    move.w   #127,d3
lbC0289AC:
                    movem.l  d0-d7/a0-a6,-(sp)
                    jsr      (draw_filled_box)
                    movem.l  (sp)+,d0-d7/a0-a6
                    movem.l  (sp)+,d2/d3
                    rts
lbW0289C0:
                    dc.w     $FFFF
lbW0289C2:
                    dc.w     $FFFF
lbC0289C4:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    tst.w    (30,a0)
                    beq      lbC029EBE
                    clr.l    (24,a0)
                    bra      lbC028B58
lbC0289EE:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    tst.w    (30,a0)
                    beq      lbC029EBE
                    moveq    #0,d0
                    move.w   (24,a0),d0
                    add.l    d0,d0
                    moveq    #0,d1
                    move.w   (26,a0),d1
                    add.l    d1,d1
                    add.l    d0,d1
                    move.l   (lbL01A130),a0
                    move.l   d0,d2
lbC028A2A:
                    addq.l   #2,d0
                    cmp.l    d0,d1
                    ble      lbC029EC6
                    tst.b    (a0,d0.l)
                    bne.b    lbC028A2A
                    sub.l    d2,d0
                    lsr.l    #1,d0
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d1
                    lsl.w    #5,d1
                    adda.w   d1,a0
                    add.w    d0,(24,a0)
                    sub.w    d0,(26,a0)
                    bra      lbC028B58
lbC028A58:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    tst.w    (30,a0)
                    beq      lbC029EBE
                    moveq    #0,d0
                    move.w   (24,a0),d0
                    add.l    d0,d0
                    moveq    #0,d1
                    move.w   (26,a0),d1
                    add.l    d1,d1
                    add.l    d0,d1
                    move.l   (lbL01A130),a0
lbC028A92:
                    subq.l   #2,d1
                    cmp.l    d0,d1
                    ble      lbC029EC6
                    tst.b    (-1,a0,d1.l)
                    bne.b    lbC028A92
                    sub.l    d0,d1
                    lsr.l    #1,d1
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    move.w   d1,(26,a0)
                    bra      lbC028B58
lbC028ABC:
                    moveq    #0,d0
                    bra.b    lbC028AC6
lbC028AC0:
                    moveq    #1,d0
                    bra.b    lbC028AC6
lbC028AC4:
                    moveq    #2,d0
lbC028AC6:
                    bsr.b    lbC028B1E
                    bmi.b    lbC028AD6
                    sub.w    d0,(24,a0)
                    add.w    d0,(26,a0)
                    bra      lbC028B58
lbC028AD6:
                    rts
lbC028AD8:
                    moveq    #0,d0
                    bra.b    lbC028AE2
lbC028ADC:
                    moveq    #1,d0
                    bra.b    lbC028AE2
lbC028AE0:
                    moveq    #2,d0
lbC028AE2:
                    bsr.b    lbC028B1E
                    bmi.b    lbC028AF0
                    add.w    d0,(24,a0)
                    sub.w    d0,(26,a0)
                    bra.b    lbC028B58
lbC028AF0:
                    rts
lbC028AF2:
                    moveq    #0,d0
                    bra.b    lbC028AFC
lbC028AF6:
                    moveq    #1,d0
                    bra.b    lbC028AFC
lbC028AFA:
                    moveq    #2,d0
lbC028AFC:
                    bsr.b    lbC028B1E
                    bmi.b    lbC028B06
                    sub.w    d0,(26,a0)
                    bra.b    lbC028B58
lbC028B06:
                    rts
lbC028B08:
                    moveq    #0,d0
                    bra.b    lbC028B12
lbC028B0C:
                    moveq    #1,d0
                    bra.b    lbC028B12
lbC028B10:
                    moveq    #2,d0
lbC028B12:
                    bsr.b    lbC028B1E
                    bmi.b    lbC028B1C
                    add.w    d0,(26,a0)
                    bra.b    lbC028B58
lbC028B1C:
                    rts
lbC028B1E:
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d1
                    lsl.w    #5,d1
                    adda.w   d1,a0
                    tst.w    (30,a0)
                    beq      lbC029EBE
                    subq.w   #1,d0
                    beq.b    lbC028B42
                    subq.w   #1,d0
                    beq.b    lbC028B4C
                    moveq    #1,d0
                    bra.b    lbC028B54
lbC028B42:
                    move.w   (lbW029ED2),d0
                    lsr.w    #8,d0
                    bra.b    lbC028B54
lbC028B4C:
                    move.w   (lbW029ED2),d0
                    lsr.w    #5,d0
lbC028B54:
                    tst.w    d0
                    rts
lbC028B58:
                    bsr.b    lbC028BC0
lbC028B5A:
                    bsr      lbC028EB2
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    tst.w    (30,a0)
                    beq.b    lbC028BBC
                    tst.w    (26,a0)
                    beq.b    lbC028BBC
                    moveq    #0,d0
                    move.w   (24,a0),d0
                    add.l    d0,d0
                    lsl.l    #8,d0
                    divu.w   (lbW029ED2),d0
                    move.w   d0,(lbW028BE2)
                    move.l   a0,-(sp)
                    moveq    #0,d1
                    bsr.b    lbC028BE6
                    move.l   (sp)+,a0
                    moveq    #0,d0
                    move.w   (24,a0),d0
                    add.l    d0,d0
                    moveq    #0,d1
                    move.w   (26,a0),d1
                    add.l    d1,d1
                    add.l    d1,d0
                    lsl.l    #8,d0
                    divu.w   (lbW029ED2),d0
                    move.w   d0,(lbW028BE4)
                    moveq    #1,d1
                    bsr.b    lbC028BE6
lbC028BBC:
                    bra      lbC028C3E
lbC028BC0:
                    tst.l    (lbW028BE2)
                    bmi.b    lbC028BE0
                    move.w   (lbW028BE2,pc),d0
                    moveq    #0,d1
                    bsr.b    lbC028BE6
                    move.w   (lbW028BE4,pc),d0
                    moveq    #1,d1
                    bsr.b    lbC028BE6
                    moveq    #-1,d0
                    move.l   d0,(lbW028BE2)
lbC028BE0:
                    rts
lbW028BE2:
                    dc.w     -1
lbW028BE4:
                    dc.w     -1
lbC028BE6:
                    cmpi.w   #SCREEN_WIDTH-1,d0
                    ble.b    lbC028BF0
                    move.w   #SCREEN_WIDTH-1,d0
lbC028BF0:
                    move.w   d1,d4
                    lea      (main_screen+7680),a0
                    move.w   d0,d1
                    lsr.w    #3,d0
                    adda.w   d0,a0
                    moveq    #-$80,d0
                    ror.b    d1,d0
                    moveq    #8-1,d1
                    tst.b    (ntsc_flag)
                    beq.b    lbC028C0E
                    moveq    #4-1,d1
lbC028C0E:
                    tst.w    d4
                    bne.b    lbC028C26
lbC028C12:
                    eor.b    d0,(a0)
                    eor.b    d0,((SCREEN_BYTES*1),a0)
                    eor.b    d0,((SCREEN_BYTES*2),a0)
                    lea      ((SCREEN_BYTES*8),a0),a0
                    dbra     d1,lbC028C12
                    rts
lbC028C26:
                    lea      ((SCREEN_BYTES*4),a0),a0
lbC028C2A:
                    eor.b    d0,(a0)
                    eor.b    d0,((SCREEN_BYTES*1),a0)
                    eor.b    d0,((SCREEN_BYTES*2),a0)
                    lea      ((SCREEN_BYTES*8),a0),a0
                    dbra     d1,lbC028C2A
                    rts
lbC028C3E:
                    tst.b    (lbB029EE7)
                    beq.b    lbC028C8C
                    lea      (C1C1D1D1E1F1F_MSG),a1
                    move.w   (lbW029E10),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    lea      (lbL028DD8,pc),a0
                    move.l   (a1,d0.w),(a0)
                    sf       (3,a0)
                    moveq    #73,d0
                    move.w   (max_lines,pc),d1
                    jsr      (draw_text)
                    lea      (L_MSG,pc),a0
                    move.w   (lbW029EFE),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    adda.w   d0,a0
                    moveq    #73,d0
                    move.w   (max_lines,pc),d1
                    addq.w   #1,d1
                    jsr      (draw_text)
lbC028C8C:
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    moveq    #14,d0
                    moveq    #10,d1
                    moveq    #21,d2
                    jsr      (draw_text_with_blanks)
                    move.l   (lbL01A134),d2
                    moveq    #38,d0
                    moveq    #10,d1
                    jsr      (lbC025DF0)
                    bsr      lbC028EB2
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    tst.w    (30,a0)
                    beq.b    lbC028CFC
                    move.l   a0,-(sp)
                    moveq    #0,d2
                    move.w   (24,a0),d2
                    add.l    d2,d2
                    moveq    #45,d0
                    moveq    #10,d1
                    jsr      (lbC025DF0)
                    move.l   (sp)+,a0
                    moveq    #0,d2
                    move.w   (26,a0),d2
                    add.l    d2,d2
                    moveq    #52,d0
                    moveq    #10,d1
                    jsr      (lbC025DF0)
                    bra.b    lbC028D06
lbC028CFC:
                    lea      (ascii_MSG,pc),a0
                    jsr      (draw_text_with_coords_struct)
lbC028D06:
                    lea      (Block_MSG),a0
                    st       d1
                    move.w   (lbW0289C0,pc),d0
                    cmp.w    (lbW0289C2,pc),d0
                    bne.b    lbC028D20
                    lea      (All_MSG),a0
                    sf       d1
lbC028D20:
                    move.b   d1,(lbB029EE8)
                    jsr      (draw_text_with_coords_struct)
                    movem.w  (lbW0289C0,pc),d6/d7
                    cmp.w    d7,d6
                    blt.b    lbC028D38
                    exg      d6,d7
lbC028D38:
                    tst.w    d6
                    bmi.b    lbC028D6C
                    cmpi.w   #SCREEN_WIDTH-1,d6
                    beq.b    lbC028D54
                    move.w   d6,d2
                    mulu.w   (lbW029ED2),d2
                    lsr.l    #8,d2
                    cmp.l    (lbL01A134),d2
                    ble.b    lbC028D5A
lbC028D54:
                    move.l   (lbL01A134),d2
lbC028D5A:
                    move.l   d2,(lbW029ED4)
                    moveq    #66,d0
                    moveq    #10,d1
                    jsr      (lbC025DF0)
                    bra.b    lbC028D82
lbC028D6C:
                    move.l   #-1,(lbW029ED4)
                    lea      (B_MSG),a0
                    jsr      (draw_text_with_coords_struct)
lbC028D82:
                    tst.b    (lbB029EE8)
                    beq.b    lbC028DBA
                    cmpi.w   #SCREEN_WIDTH-1,d7
                    beq.b    lbC028DA2
                    move.w   d7,d2
                    mulu.w   (lbW029ED2),d2
                    lsr.l    #8,d2
                    cmp.l    (lbL01A134),d2
                    ble.b    lbC028DA8
lbC028DA2:
                    move.l   (lbL01A134),d2
lbC028DA8:
                    move.l   d2,(lbL029ED8)
                    moveq    #73,d0
                    moveq    #10,d1
                    jsr      (lbC025DF0)
                    bra.b    lbC028DD0
lbC028DBA:
                    move.l   #-1,(lbL029ED8)
                    lea      (I_MSG),a0
                    jsr      (draw_text_with_coords_struct)
lbC028DD0:
                    jmp      (lbC01FBF2)
lbL028DD8:
                    dc.l     0
All_MSG:
                    dc.b     60,10,'All  ',0
Block_MSG:
                    dc.b     60,10,'Block',0
B_MSG:
                    dc.b     66,10,'------',0
I_MSG:
                    dc.b     73,10,'------',0
ascii_MSG:
                    dc.b     45,10,'------ ------',0
lbC028E0E:
                    jsr      (lbC021E38)
                    bmi.b    lbC028E1A
                    bra      lbC02837A
lbC028E1A:
                    rts
lbC028E1C:
                    jsr      (lbC021E54)
                    bmi.b    lbC028E28
                    bra      lbC02837A
lbC028E28:
                    rts
lbC028E2A:
                    jsr      (lbC021EA2)
                    bmi.b    lbC028E36
                    bra      lbC02837A
lbC028E36:
                    rts
lbC028E38:
                    jsr      (lbC021EF4)
                    bmi.b    lbC028E44
                    bra      lbC02837A
lbC028E44:
                    rts
lbC028E46:
                    jsr      (lbC021E2A)
                    bra      lbC02837A
lbC028E50:
                    jmp      (lbC02191E)
lbC028E58:
                    jmp      (lbC021C72)
lbC028E60:
                    jsr      (lbC02189C)
                    bra      lbC02837A
lbC028E6A:
                    jsr      (lbC02168E)
                    bra      lbC02837A
lbC028E74:
                    jsr      (lbC02163C)
                    bra      lbC02837A
lbC028E7E:
                    jsr      (lbC02177E)
                    bra      lbC02837A
lbC028E88:
                    jmp      (lbC028904,pc)
lbC028E8E:
                    jmp      (lbC0216DC)
lbC028E96:
                    movem.l  d2,-(sp)
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    move.l   (lbL01A134),d2
                    bra.b    lbC028ECA
lbC028EB2:
                    movem.l  d2,-(sp)
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    move.l   (20,a0),d2
lbC028ECA:
                    moveq    #0,d0
                    move.w   (24,a0),d0
                    add.l    d0,d0
                    moveq    #0,d1
                    move.w   (26,a0),d1
                    add.l    d1,d1
                    add.l    d0,d1
                    cmp.l    d2,d0
                    ble.b    lbC028EE2
                    move.l   d2,d0
lbC028EE2:
                    cmp.l    d2,d1
                    ble.b    lbC028EE8
                    move.l   d2,d1
lbC028EE8:
                    cmp.l    d0,d1
                    bne.b    lbC028EF0
                    subq.l   #2,d0
                    bmi.b    lbC028F06
lbC028EF0:
                    cmp.l    d0,d1
                    bgt.b    lbC028EF6
                    exg      d0,d1
lbC028EF6:
                    sub.l    d0,d1
                    lsr.l    #1,d0
                    lsr.l    #1,d1
                    move.w   d0,(24,a0)
                    move.w   d1,(26,a0)
                    bra.b    lbC028F0A
lbC028F06:
                    clr.l    (24,a0)
lbC028F0A:
                    movem.l  (sp)+,d2
                    rts
lbC028F10:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.b    (lbB029EE8)
                    beq.b    lbC028F32
                    move.l   (lbW029ED4),d0
                    cmp.l    (lbL029ED8),d0
                    beq      lbC029E9E
lbC028F32:
                    move.l   #lbC028F3E,(current_cmd_ptr)
                    rts
lbC028F3E:
                    move.w   #100,(lbW029F0E)
                    lea      (lbW028FA0,pc),a0
                    jsr      (process_commands_sequence)
                    bsr      lbC029026
                    lea      (lbW028F60,pc),a0
                    jmp      (lbC020626)
lbW028F60:
                    dc.w     11
                    dc.l     lbC028F7A
                    dc.w     1
                    dc.l     lbC02814E
                    dc.w     2
                    dc.l     lbC0281AE
                    dc.w     14
                    dc.l     lbC029E1A
                    dc.w     0
lbC028F7A:
                    jmp      (lbC0208FA)
lbC028F82:
                    jsr      (lbC02001C)
                    st       (quit_flag)
                    rts
lbC028F90:
                    bsr      lbC029066
                    bsr      lbC028324
                    st       (quit_flag)
                    rts
lbW028FA0:
                    dc.w     1
                    dc.l     ascii_MSG15
                    dc.w     2
                    dc.l     lbW029012
                    dc.w     3
                    dc.l     lbW028FDC
                    dc.w     0
                    dc.l     0,0,0
ascii_MSG15:
                    dc.b     CMD_MOVE_TO_LINE
                    dc.b     0
                    dc.l     max_lines
                    dc.b     CMD_TEXT,28,0,'    % ',0
                    dc.b     CMD_TEXT,28,1,'Do! Ok',0
                    dc.b     CMD_END
                    even
lbW028FDC:
                    dc.l     lbW028FEE
                    dc.w     1,$1C00,$601
                    dc.l     lbC02903A
                    dc.l     lbC02904C
lbW028FEE:
                    dc.l     lbW029000
                    dc.w     $1001,$1C01,$301
                    dc.l     lbC02905E
                    dc.l     0
lbW029000:
                    dc.w     0,0,1,$2001,$201
                    dc.l     lbC028F90
                    dc.l     0
lbW029012:
                    dc.w     10,0
                    dc.l     lbW02901C
                    dc.w     0
lbW02901C:
                    dc.w     2,5
                    dc.l     lbC028F82
                    dc.w     0
lbC029026:
                    moveq    #$1D,d0
                    move.w   (max_lines,pc),d1
                    move.w   (lbW029F0E),d2
                    jmp      (lbC025E0C)
lbC02903A:
                    lea      (lbW029F0E,pc),a0
                    cmpi.w   #395,(a0)
                    blt.b    lbC029048
                    move.w   #395,(a0)
lbC029048:
                    addq.w   #5,(a0)
                    bra.b    lbC029026
lbC02904C:
                    lea      (lbW029F0E,pc),a0
                    cmpi.w   #5,(a0)
                    bgt.b    lbC02905A
                    move.w   #5,(a0)
lbC02905A:
                    subq.w   #5,(a0)
                    bra.b    lbC029026
lbC02905E:
                    bsr      lbC029066
                    bra      lbC02837A
lbC029066:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    jsr      (stop_audio_channels)
                    lea      (lbL01C958),a0
                    move.w   (lbW029F0E),d1
                    moveq    #-$40,d2
                    moveq    #$3F,d3
                    tst.b    (lbB029EE6)
                    beq.b    lbC029092
                    moveq    #-$80,d2
                    moveq    #$7F,d3
lbC029092:
                    moveq    #$64,d4
                    moveq    #0,d7
lbC029096:
                    move.w   d7,d0
                    ext.w    d0
                    muls.w   d1,d0
                    divs.w   d4,d0
                    cmp.w    d2,d0
                    bgt.b    lbC0290A4
                    move.w   d2,d0
lbC0290A4:
                    cmp.w    d3,d0
                    blt.b    lbC0290AA
                    move.w   d3,d0
lbC0290AA:
                    move.b   d0,(a0)+
                    addq.b   #1,d7
                    bne.b    lbC029096
                    jsr      (lbC02161C)
                    move.l   (a0),a1
                    lea      (lbL01C958),a0
                    move.l   (lbL01A130),a2
                    move.l   (lbL01A134),d0
                    moveq    #0,d1
                    tst.b    (lbB029EE8)
                    beq.b    lbC0290EE
                    adda.l   (lbW029ED4),a2
                    adda.l   (lbW029ED4),a1
                    move.l   (lbL029ED8),d0
                    sub.l    (lbW029ED4),d0
                    move.l   a2,a3
lbC0290EE:
                    subq.l   #1,d0
                    bmi.b    lbC0290FA
                    move.b   (a1)+,d1
                    move.b   (a0,d1.w),(a2)+
                    bra.b    lbC0290EE
lbC0290FA:
                    rts
lbC0290FC:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.b    (lbB029EE8)
                    beq.b    lbC02911E
                    move.l   (lbW029ED4),d0
                    cmp.l    (lbL029ED8),d0
                    beq      lbC029E9E
lbC02911E:
                    move.l   #lbC02912A,(current_cmd_ptr)
                    rts
lbC02912A:
                    lea      (lbW02917C,pc),a0
                    jsr      (process_commands_sequence)
                    bsr      lbC029762
                    lea      (lbW029148,pc),a0
                    jsr      (lbC020626)
                    bra      lbC0298CC
lbW029148:
                    dc.w     11
                    dc.l     lbC029168
                    dc.w     11
                    dc.l     lbC0297AC
                    dc.w     1
                    dc.l     lbC02814E
                    dc.w     2
                    dc.l     lbC0281AE
                    dc.w     14
                    dc.l     lbC029E1A
                    dc.w     0
lbC029168:
                    jmp      (lbC0208FA)
lbC029170:
                    bsr      lbC0298CC
                    st       (quit_flag)
                    rts
lbW02917C:
                    dc.w     1
                    dc.l     ascii_MSG16
                    dc.w     2
                    dc.l     lbW0291EE
                    dc.w     3
                    dc.l     lbL0291B8
                    dc.W     0
                    dc.l     0,0,0
ascii_MSG16:
                    dc.b     CMD_MOVE_TO_LINE
                    dc.b     0
                    dc.l     max_lines
                    dc.b     CMD_TEXT,28,0,'Cancel',0
                    dc.b     CMD_TEXT,28,1,'Do! Ok',0
                    dc.b     CMD_END
                    even
lbL0291B8:
                    dc.l     lbL0291CA,$11C00
                    dc.w     $601
                    dc.l     lbC029202
                    dc.l     0
lbL0291CA:
                    dc.l     lbW0291DC,$10011C01
                    dc.w     $301
                    dc.l     lbC02920C
                    dc.l     0
lbW0291DC:
                    dc.w     0,0,1,$2001,$201
                    dc.l     lbC029214
                    dc.l     0
lbW0291EE:
                    dc.w     $A,0
                    dc.l     lbW0291F8
                    dc.w     0
lbW0291F8:
                    dc.w     2,5
                    dc.l     lbC029202
                    dc.w     0
lbC029202:
                    jsr      (lbC02001C)
                    bra      lbC029170
lbC02920C:
                    bsr      lbC02921E
                    bra      lbC02837A
lbC029214:
                    bsr.b    lbC02921E
                    bsr      lbC028324
                    bra      lbC029170
lbC02921E:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    jsr      (stop_audio_channels)
                    move.l   (lbL01A130),a0
                    move.l   a0,a4
                    adda.l   (lbL01A134),a4
                    lea      (lbL01CA58),a1
                    move.l   a1,a2
                    movem.w  (lbB029F1C),d0/d1
                    adda.w   d1,a2
                    adda.w   d1,a2
                    moveq    #-1,d0
                    bsr      lbC02930C
                    bmi.b    lbC02929A
                    move.w   d0,d1
                    move.l   a0,a3
lbC02925C:
                    bsr      lbC02930A
                    bmi.b    lbC029272
                    move.w   d0,d2
                    movem.l  d2/a0-a2,-(sp)
                    bsr.b    lbC02929C
                    movem.l  (sp)+,d2/a0-a2
                    move.w   d2,d1
                    bra.b    lbC02925C
lbC029272:
                    cmpi.w   #639,(lbW029F1E)
                    bne.b    lbC02929A
lbC02927C:
                    cmpa.l   a4,a3
                    bge.b    lbC02929A
                    move.b   (a5)+,d0
                    ext.w    d0
                    muls.w   d3,d0
                    muls.w   d5,d0
                    swap     d0
                    cmp.w    d6,d0
                    bge.b    lbC029290
                    move.w   d6,d0
lbC029290:
                    cmp.w    d7,d0
                    ble.b    lbC029296
                    move.w   d7,d0
lbC029296:
                    move.b   d0,(a3)+
                    bra.b    lbC02927C
lbC02929A:
                    rts
lbC02929C:
                    moveq    #0,d3
                    move.w   d1,d3
                    move.w   #624,d5
                    moveq    #-$40,d6
                    moveq    #$3F,d7
                    tst.b    (lbB029EE6)
                    beq.b    lbC0292B4
                    moveq    #-$80,d6
                    moveq    #$7F,d7
lbC0292B4:
                    move.l   a0,-(sp)
                    jsr      (lbC02161C)
                    move.l   (a0),a5
                    move.l   (sp)+,a0
                    move.l   a3,a6
                    sub.l    (lbL01A130),a6
                    adda.l   a6,a5
                    move.l   a0,d4
                    sub.l    a3,d4
                    sub.w    d1,d2
                    swap     d2
                    clr.w    d2
                    move.l   d2,d0
                    move.l   d4,d1
                    jsr      (divu_32)
                    move.l   d0,d2
lbC0292E0:
                    cmpa.l   a0,a3
                    bge.b    lbC029308
                    cmpa.l   a4,a3
                    bge.b    lbC029308
                    move.b   (a5)+,d0
                    ext.w    d0
                    muls.w   d3,d0
                    muls.w   d5,d0
                    swap     d0
                    cmp.w    d6,d0
                    bge.b    lbC0292F8
                    move.w   d6,d0
lbC0292F8:
                    cmp.w    d7,d0
                    ble.b    lbC0292FE
                    move.w   d7,d0
lbC0292FE:
                    move.b   d0,(a3)+
                    swap     d3
                    add.l    d2,d3
                    swap     d3
                    bra.b    lbC0292E0
lbC029308:
                    rts
lbC02930A:
                    moveq    #0,d0
lbC02930C:
                    cmpa.l   a2,a1
                    bgt.b    lbC02932C
                    addq.w   #1,d0
                    tst.w    (a1)+
                    bmi.b    lbC02930C
                    mulu.w   (lbW029ED2),d0
                    lsr.l    #8,d0
                    adda.l   d0,a0
                    moveq    #32,d0
                    sub.w    (-2,a1),d0
                    mulu.w   #7,d0
                    rts
lbC02932C:
                    moveq    #ERROR,d0
                    rts
lbC029330:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.b    (lbB029EE8)
                    beq.b    lbC029366
                    move.l   (lbW029ED4),d0
                    cmp.l    (lbL029ED8),d0
                    beq      lbC029E9E
                    move.l   (lbW029ED4),(lbL029F14)
                    move.l   (lbL029ED8),(lbL029F18)
lbC029366:
                    move.l   #lbC029372,(current_cmd_ptr)
                    rts
lbC029372:
                    move.w   #$64,(lbW029F10)
                    lea      (lbW0293B6,pc),a0
                    jsr      (process_commands_sequence)
                    bsr      lbC029488
                    lea      (lbW029394,pc),a0
                    jmp      (lbC020626)
lbW029394:
                    dc.w     11
                    dc.l     lbC0293AE
                    dc.w     1
                    dc.l     lbC02814E
                    dc.w     2
                    dc.l     lbC0281AE
                    dc.w     14
                    dc.l     lbC029E1A
                    dc.w     0
lbC0293AE:
                    jmp      (lbC0208FA)
lbW0293B6:
                    dc.w     1
                    dc.l     ascii_MSG17
                    dc.w     2
                    dc.l     lbW029438
                    dc.w     3
                    dc.l     lbL0293F0
                    dc.w     0
                    dc.l     0,0,0
ascii_MSG17:
                    dc.b     CMD_MOVE_TO_LINE
                    dc.b     0
                    dc.l     max_lines
                    dc.b     CMD_TEXT,38,0,'to',0
                    dc.b     CMD_TEXT,35,1,'Do!   Ok',0
                    dc.b     CMD_END
                    even
lbL0293F0:
                    dc.l     lbL029402,$12200
                    dc.w     $301
                    dc.l     lbC029492
                    dc.l     lbC0294AA
lbL029402:
                    dc.l     lbL029414,$12900
                    dc.w     $301
                    dc.l     lbC0294EA
                    dc.l     lbC029502
lbL029414:
                    dc.l     lbL029426,$10012201
                    dc.w     $501
                    dc.l     lbC029472
                    dc.l     0
lbL029426:
                    dc.l     0,$12801
                    dc.w     $401
                    dc.l     lbC02945A
                    dc.l     0
lbW029438:
                    dc.w     $A,0
                    dc.l     lbW029442
                    dc.w     0
lbW029442:
                    dc.w     2,5
                    dc.l     lbC02944C
                    dc.w     0
lbC02944C:
                    jsr      (lbC02001C)
                    st       (quit_flag)
                    rts
lbC02945A:
                    lea      (lbC029688,pc),a0
                    lea      (lbC0296A4,pc),a1
                    bsr      lbC029564
                    bsr      lbC028324
                    st       (quit_flag)
                    rts
lbC029472:
                    lea      (lbC029688,pc),a0
                    lea      (lbC0296A4,pc),a1
                    bsr      lbC029564
                    bsr      lbC02837A
                    bra      lbC028C3E
lbC029488:
                    bsr      lbC0294C2
                    bra      lbC02951A
lbC029492:
                    lea      (lbW0294E6,pc),a0
                    cmpi.w   #36,(a0)
                    beq.b    lbC0294A8
                    addq.w   #1,(a0)
                    st       (lbW029F12)
                    bra      lbC0294C2
lbC0294A8:
                    rts
lbC0294AA:
                    lea      (lbW0294E6,pc),a0
                    cmpi.w   #1,(a0)
                    beq.b    lbC0294C0
                    subq.w   #1,(a0)
                    st       (lbW029F12)
                    bra      lbC0294C2
lbC0294C0:
                    rts
lbC0294C2:
                    moveq    #34,d0
                    move.w   (max_lines,pc),d1
                    move.w   (lbW0294E6,pc),d2
                    bra      lbC029542
lbC0294D0:
                    move.w   (lbW0294E6,pc),d0
                    add.w    d0,d0
                    lea      (lbW02513C),a0
                    move.w   (a0,d0.w),(lbW0294E8)
                    rts
lbW0294E6:
                    dc.w     25
lbW0294E8:
                    dc.w     0
lbC0294EA:
                    lea      (lbW02953E,pc),a0
                    cmpi.w   #36,(a0)
                    beq.b    lbC029500
                    addq.w   #1,(a0)
                    st       (lbW029F12)
                    bra      lbC02951A
lbC029500:
                    rts
lbC029502:
                    lea      (lbW02953E,pc),a0
                    cmpi.w   #1,(a0)
                    beq.b    lbC029518
                    subq.w   #1,(a0)
                    st       (lbW029F12)
                    bra      lbC02951A
lbC029518:
                    rts
lbC02951A:
                    moveq    #41,d0
                    move.w   (max_lines,pc),d1
                    move.w   (lbW02953E,pc),d2
                    bra      lbC029542
lbC029528:
                    move.w   (lbW02953E,pc),d0
                    add.w    d0,d0
                    lea      (lbW02513C),a0
                    move.w   (a0,d0.w),(lbW029540)
                    rts
lbW02953E:
                    dc.w     25
lbW029540:
                    dc.w     0
lbC029542:
                    lea      (C1C1D1D1E1F1F_MSG),a1
                    add.w    d2,d2
                    add.w    d2,d2
                    lea      (lbL029560,pc),a0
                    move.l   (a1,d2.w),(a0)
                    sf       (3,a0)
                    jmp      (draw_text)
lbL029560:
                    dc.l     0
lbC029564:
                    movem.l  d2/d3/a2/a3,-(sp)
                    move.l   a0,a2
                    move.l   a1,a3
                    jsr      (stop_audio_channels)
                    tst.l    (lbL01A130)
                    beq      lbC02966E
                    tst.b    (lbB029EE8)
                    beq      lbC029634
                    move.l   (lbL029F18,pc),d0
                    sub.l    (lbL029F14,pc),d0
                    move.l   a2,d1
                    beq.b    lbC029594
                    jsr      (a2)
lbC029594:
                    move.l   d0,d3
                    jsr      (lbC02161C)
                    move.l   (4,a0),d0
                    move.l   (lbL029F18,pc),d1
                    sub.l    (lbL029F14,pc),d1
                    sub.l    d1,d0
                    blt      lbC029682
                    add.l    d3,d0
                    move.l   d0,d2
                    cmpi.l   #131070,d2
                    bgt      lbC02967A
                    move.l   d2,d0
                    jsr      (lbC01FFC0)
                    bmi      lbC029674
                    jsr      (lbC02161C)
                    move.l   (a0),a0
                    move.l   (lbL01A130),a1
                    move.l   (lbL029F14,pc),d0
                    EXEC     CopyMem
                    jsr      (lbC02161C)
                    move.l   (4,a0),d0
                    move.l   (a0),a0
                    adda.l   (lbL029F18,pc),a0
                    move.l   (lbL01A130),a1
                    adda.l   (lbL029F14,pc),a1
                    adda.l   d3,a1
                    sub.l    (lbL029F18,pc),d0
                    EXEC     CopyMem
                    jsr      (lbC02161C)
                    move.l   (a0),a0
                    adda.l   (lbL029F14,pc),a0
                    move.l   (lbL01A130),a1
                    adda.l   (lbL029F14,pc),a1
                    move.l   (lbL029F18,pc),d0
                    sub.l    (lbL029F14,pc),d0
                    jsr      (a3)
                    bra.b    lbC029682
lbC029634:
                    jsr      (lbC02161C)
                    move.l   (4,a0),d0
                    jsr      (a2)
                    move.l   d0,d2
                    cmpi.l   #131070,d2
                    bgt      lbC02967A
                    move.l   d2,d0
                    jsr      (lbC01FFC0)
                    bmi      lbC029674
                    jsr      (lbC02161C)
                    move.l   (4,a0),d0
                    move.l   (a0),a0
                    move.l   (lbL01A130),a1
                    jsr      (a3)
                    bra.b    lbC029682
lbC02966E:
                    bsr      lbC029E96
                    bra.b    lbC029682
lbC029674:
                    bsr      lbC02830C
                    bra.b    lbC029682
lbC02967A:
                    bsr      lbC029EB6
lbC029682:
                    movem.l  (sp)+,d2/d3/a2/a3
                    rts
lbC029688:
                    move.l   d2,-(sp)
                    move.l   d0,d2
                    bsr      lbC0294D0
                    bsr      lbC029528
                    move.w   (lbW0294E8,pc),d0
                    move.w   (lbW029540,pc),d1
                    bsr      lbC0296C8
                    move.l   (sp)+,d2
                    rts
lbC0296A4:
                    move.l   d2,-(sp)
                    move.l   d0,d2
                    movem.l  a0/a1,-(sp)
                    bsr      lbC0294D0
                    bsr      lbC029528
                    movem.l  (sp)+,a0/a1
                    move.w   (lbW0294E8,pc),d0
                    move.w   (lbW029540,pc),d1
                    bsr      lbC0296D4
                    move.l   (sp)+,d2
                    rts
lbC0296C8:
                    move.l   d3,-(sp)
                    sf       d3
                    bsr      lbC0296E0
                    move.l   (sp)+,d3
                    rts
lbC0296D4:
                    move.l   d3,-(sp)
                    st       d3
                    bsr      lbC0296E0
                    move.l   (sp)+,d3
                    rts
lbC0296E0:
                    movem.l  d4-d7/a2-a4,-(sp)
                    move.l   a0,a3
                    move.l   a1,a4
                    moveq    #1,d4
                    cmp.l    d4,d2
                    bls.b    lbC029756
                    cmp.w    d0,d1
                    beq.b    lbC029740
                    subq.l   #1,d2
                    swap     d0
                    clr.w    d0
                    asr.l    #4,d0
                    ext.l    d1
                    jsr      (divu_32)
                    moveq    #12,d1
                    asl.l    d1,d2
                    moveq    #0,d1
                    moveq    #0,d7
lbC02970A:
                    cmp.l    d2,d1
                    bcc.b    lbC02973C
                    tst.b    d3
                    beq.b    lbC029736
                    move.l   d1,d4
                    moveq    #12,d5
                    asr.l    d5,d4
                    lea      (a3,d4.l),a2
                    move.b   (a2)+,d4
                    ext.w    d4
                    move.b   (a2),d5
                    ext.w    d5
                    sub.w    d4,d5
                    move.w   d1,d6
                    andi.w   #$FFF,d6
                    muls.w   d6,d5
                    moveq    #12,d6
                    asr.l    d6,d5
                    add.w    d5,d4
                    move.b   d4,(a4)+
lbC029736:
                    addq.l   #1,d7
                    add.l    d0,d1
                    bra.b    lbC02970A
lbC02973C:
                    move.l   d7,d0
                    bra.b    lbC02975C
lbC029740:
                    tst.b    d3
                    beq.b    lbC029752
                    move.l   d2,d0
                    EXEC     CopyMem
lbC029752:
                    move.l   d2,d0
                    bra.b    lbC02975C
lbC029756:
                    moveq    #0,d0
lbC02975C:
                    movem.l  (sp)+,d4-d7/a2-a4
                    rts
lbC029762:
                    move.l   #639,(lbB029F1C)
                    tst.b    (lbB029EE8)
                    beq.b    lbC029788
                    movem.w  (lbW0289C0,pc),d0/d1
                    cmp.w    d0,d1
                    bgt.b    lbC029780
                    exg      d0,d1
lbC029780:
                    movem.w  d0/d1,(lbB029F1C)
lbC029788:
                    cmpi.l   #639,(lbL01A134)
                    bge.b    lbC0297A8
                    move.l   (lbL01A134),d0
                    cmp.w    (lbW029F1E),d0
                    bgt.b    lbC0297A8
                    move.w   d0,(lbW029F1E)
lbC0297A8:
                    bra      lbC029892
lbC0297AC:
                    cmpi.w   #4,d0
                    beq      lbC0297C0
                    cmpi.w   #3,d0
                    beq      lbC0297C4
                    bra      lbC02988E
lbC0297C0:
                    st       d4
                    bra.b    lbC0297CC
lbC0297C4:
                    tst.b    d3
                    beq      lbC02988E
                    sf       d4
lbC0297CC:
                    move.w   d1,d0
                    move.w   d2,d1
                    move.w   #$B8,d5
                    tst.b    (ntsc_flag)
                    beq.b    lbC0297E0
                    subi.w   #$20,d5
lbC0297E0:
                    sub.w    d5,d1
                    bmi      lbC02988E
                    cmpi.w   #$30,d1
                    bgt      lbC02988E
                    subq.w   #8,d1
                    bpl.b    lbC0297F4
                    moveq    #0,d1
lbC0297F4:
                    cmpi.w   #$20,d1
                    ble.b    lbC0297FE
                    move.w   #$20,d1
lbC0297FE:
                    movem.w  (lbB029F1C),d2/d3
                    cmp.w    d2,d0
                    bgt.b    lbC02980C
                    move.w   d2,d0
lbC02980C:
                    cmp.w    d3,d0
                    blt.b    lbC029812
                    move.w   d3,d0
lbC029812:
                    tst.b    d4
                    beq.b    lbC029832
                    move.w   d0,(lbW029F20)
                    move.w   d0,(lbW029F22)
                    lea      (lbL01CA58),a0
                    add.w    d0,d0
                    move.w   d1,(a0,d0.w)
                    bra      lbC029902
lbC029832:
                    movem.w  (lbW029F20),d2/d3
                    cmp.w    d2,d0
                    bgt.b    lbC029840
                    move.w   d0,d2
lbC029840:
                    cmp.w    d3,d0
                    blt.b    lbC029846
                    move.w   d0,d3
lbC029846:
                    movem.w  d2/d3,(lbW029F20)
                    lea      (lbL01CA58),a0
                    move.l   a0,a1
                    move.l   a0,a2
                    adda.w   d2,a0
                    adda.w   d2,a0
                    adda.w   d3,a1
                    adda.w   d3,a1
                    movem.w  (lbB029F1C),d4/d5
                    add.w    d4,d4
                    add.w    d5,d5
                    move.w   (a2,d4.w),d2
                    move.w   (a2,d5.w),d3
lbC029874:
                    cmpa.l   a0,a1
                    blt.b    lbC02987E
                    move.w   #-1,(a0)+
                    bra.b    lbC029874
lbC02987E:
                    move.w   d2,(a2,d4.w)
                    move.w   d3,(a2,d5.w)
                    adda.w   d0,a2
                    adda.w   d0,a2
                    move.w   d1,(a2)
                    bsr.b    lbC029902
lbC02988E:
                    moveq    #ERROR,d0
                    rts
lbC029892:
                    lea      (lbL01CA58),a0
                    move.w   #640-1,d0
                    moveq    #-1,d1
lbC02989E:
                    move.w   d1,(a0)+
                    dbra     d0,lbC02989E
                    bsr.b    lbC0298A8
                    bra.b    lbC029902
lbC0298A8:
                    lea      (lbL01CA58),a0
                    move.w   (lbB029F1C),d0
                    add.w    d0,d0
                    move.w   #17,(a0,d0.w)
                    move.w   (lbW029F1E),d0
                    add.w    d0,d0
                    move.w   #17,(a0,d0.w)
                    rts
lbC0298CC:
                    jsr      (own_blitter)
                    move.l   #$1000000,(BLTCON0,a6)
                    clr.w    (BLTDMOD,a6)
                    lea      (main_screen+15360),a0
                    tst.b    (ntsc_flag)
                    beq.b    lbC0298F0
                    lea      (-(32*SCREEN_BYTES),a0),a0
lbC0298F0:
                    move.l   a0,(BLTDPTH,a6)
                    move.w   #(33*64)+(SCREEN_BYTES/2),(BLTSIZE,a6)
                    jmp      (disown_blitter)
lbC029902:
                    bsr.b    lbC0298CC
                    jsr      (prepare_line_drawing)
                    lea      (lbL01CA58),a0
                    moveq    #0,d7
lbC029912:
                    move.w   (a0)+,d5
                    bpl.b    lbC029920
                    addq.w   #1,d7
                    cmpi.w   #SCREEN_WIDTH,d7
                    bne.b    lbC029912
                    bra.b    lbC02993A
lbC029920:
                    move.w   d7,d4
                    addq.w   #1,d7
                    cmpi.w   #SCREEN_WIDTH,d7
                    beq.b    lbC02993A
lbC02992A:
                    move.w   (a0)+,d6
                    bmi.b    lbC029932
                    bsr      lbC029942
lbC029932:
                    addq.w   #1,d7
                    cmpi.w   #SCREEN_WIDTH,d7
                    bne.b    lbC02992A
lbC02993A:
                    jmp      (release_after_line_drawing)
lbC029942:
                    movem.l  d0-d7/a0,-(sp)
                    move.w   d4,d0
                    move.w   d5,d1
                    move.w   d7,d2
                    move.w   d6,d3
                    addi.w   #$88,d1
                    addi.w   #$88,d3
                    tst.b    (ntsc_flag)
                    beq.b    lbC029966
                    subi.w   #$20,d1
                    subi.w   #$20,d3
lbC029966:
                    lea      (main_screen+(56*80)),a0
                    jsr      (lbC0256DA)
                    movem.l  (sp)+,d0-d7/a0
                    move.w   d7,d4
                    move.w   d6,d5
                    rts
lbC02997C:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    tst.b    (lbB029EE8)
                    beq.b    lbC02999E
                    move.l   (lbW029ED4),d0
                    cmp.l    (lbL029ED8),d0
                    beq      lbC029E9E
lbC02999E:
                    move.l   #lbC0299AA,(current_cmd_ptr)
                    rts
lbC0299AA:
                    lea      (lbW0299E2,pc),a0
                    jsr      (process_commands_sequence)
                    lea      (lbW0299C0,pc),a0
                    jmp      (lbC020626)
lbW0299C0:
                    dc.w     11
                    dc.l     lbC0299DA
                    dc.w     1
                    dc.l     lbC02814E
                    dc.w     2
                    dc.l     lbC0281AE
                    dc.w     14
                    dc.l     lbC029E1A
                    dc.w     0
lbC0299DA:
                    jmp      (lbC0208FA)
lbW0299E2:
                    dc.w     1
                    dc.l     ascii_MSG19
                    dc.w     2
                    dc.l     lbW029A54
                    dc.w     3
                    dc.l     lbL029A1E
                    dc.w     0
                    dc.l     0,0,0
ascii_MSG19:
                    dc.b     CMD_MOVE_TO_LINE
                    dc.b     0
                    dc.l     max_lines
                    dc.b     CMD_TEXT,44,0,'Cancel',0
                    dc.b     CMD_TEXT,44,1,'Do! Ok',0
                    dc.b     CMD_END
                    even
lbL029A1E:
                    dc.l     lbL029A30,$12C00
                    dc.w     $601
                    dc.l     lbC029A68
                    dc.l     0
lbL029A30:
                    dc.l     lbL029A42,$10012C01
                    dc.w     $301
                    dc.l     lbC029A82
                    dc.l     0
lbL029A42:
                    dc.l     0,$13001
                    dc.w     $201
                    dc.l     lbC029A76
                    dc.l     0
lbW029A54:
                    dc.w     $A,0
                    dc.l     lbW029A5E
                    dc.w     0
lbW029A5E:
                    dc.w     2,5
                    dc.l     lbC029A68
                    dc.w     0
lbC029A68:
                    jsr      (lbC02001C)
                    st       (quit_flag)
                    rts
lbC029A76:
                    bsr      lbC028324
                    st       (quit_flag)
                    rts
lbC029A82:
                    bsr.b    lbC029A88
                    bra      lbC02837A
lbC029A88:
                    tst.l    (lbL01A130)
                    beq      lbC029E96
                    move.l   (lbL01A130),a0
                    move.l   (lbL01A134),d0
                    tst.b    (lbB029EE8)
                    beq.b    lbC029AB8
                    adda.l   (lbW029ED4),a0
                    move.l   (lbL029ED8),d0
                    sub.l    (lbW029ED4),d0
lbC029AB8:
                    subq.l   #2,d0
                    bmi.b    lbC029AE4
                    jsr      (stop_audio_channels)
                    moveq    #3,d4
                    move.b   (a0)+,d1
                    ext.w    d1
lbC029AC8:
                    subq.l   #1,d0
                    bmi.b    lbC029AE4
                    move.b   (1,a0),d3
                    ext.w    d3
                    add.w    d1,d3
                    move.b   (a0),d2
                    ext.w    d2
                    move.w   d2,d1
                    add.w    d2,d3
                    ext.l    d3
                    divs.w   d4,d3
                    move.b   d3,(a0)+
                    bra.b    lbC029AC8
lbC029AE4:
                    rts
lbC029AE6:
                    jsr      (lbC01E0C2)
                    move.l   sp,(lbL029F00)
                    bsr      lbC029CAE
lbC029AF6:
                    lea      (main_screen+15360),a0
                    tst.b    (ntsc_flag)
                    beq.b    lbC029B08
                    lea      (-(32*SCREEN_BYTES),a0),a0
lbC029B08:
                    lea      (lbL01C258),sp
                    moveq    #SCREEN_BYTES-1,d4
lbC029B10:
                    moveq    #8-1,d5
                    btst     d6,(-256,a2)
                    beq.b    lbC029B46
lbC029B18:
                    btst     d7,(a3)
                    beq.b    lbC029B18
                    move.w   d7,(a4)
                    moveq    #0,d0
                    move.b   (a2),d0
                    sub.b    d7,d0
                    move.b   d0,(a5)
                    move.b   d0,(a6)
                    add.w    d0,d0
                    move.w   (a1,d0.w),d1
                    move.w   (sp),d2
                    move.w   d1,(sp)+
                    bclr     d5,(a0,d2.w)
                    bset     d5,(a0,d1.w)
                    dbra     d5,lbC029B18
                    addq.w   #1,a0
                    dbra     d4,lbC029B10
                    bra.b    lbC029AF6
lbC029B46:
                    move.l   (lbL029F00),sp
                    jsr      (stop_audio_channels)
                    jmp      (lbC01E0FA)
lbC029B5A:
                    tst.l    (lbL01A130)
                    beq.b    lbC029B72
                    jsr      (ask_are_you_sure_requester)
                    bne      lbC029CAC
                    jsr      (lbC01FF8C)
lbC029B72:
                    bsr      lbC029D30
                    bmi      lbC029CAC
                    jsr      (lbC01E0C2)
                    move.l   sp,(lbL029F00)
                    bsr      lbC029CAE
lbC029B8A:
                    lea      (main_screen+15360),a0
                    tst.b    (ntsc_flag)
                    beq.b    lbC029B9C
                    lea      (-(32*SCREEN_BYTES),a0),a0
lbC029B9C:
                    lea      (lbL01C258),sp
                    moveq    #SCREEN_BYTES-1,d4
lbC029BA4:
                    moveq    #8-1,d5
                    btst     d6,(-256,a2)
                    beq.b    lbC029BDA
lbC029BAC:
                    btst     d7,(a3)
                    beq.b    lbC029BAC
                    move.w   d7,(a4)
                    moveq    #0,d0
                    move.b   (a2),d0
                    sub.b    d7,d0
                    move.b   d0,(a5)
                    move.b   d0,(a6)
                    add.w    d0,d0
                    move.w   (a1,d0.w),d1
                    move.w   (sp),d2
                    move.w   d1,(sp)+
                    bclr     d5,(a0,d2.w)
                    bset     d5,(a0,d1.w)
                    dbra     d5,lbC029BAC
                    addq.w   #1,a0
                    dbra     d4,lbC029BA4
                    bra.b    lbC029B8A
lbC029BDA:
                    move.w   (main_back_color+2),(lbW029F0C)
                    move.w   #$400,(main_back_color+2)
                    move.l   (lbL029EF2),a6
                    move.l   (lbL029EF6),d3
                    moveq    #2,d6
lbC029BFA:
                    lea      (main_screen+15360),a0
                    tst.b    (ntsc_flag)
                    beq.b    lbC029C0C
                    lea      (-(32*SCREEN_BYTES),a0),a0
lbC029C0C:
                    lea      (lbL01C258),sp
                    moveq    #SCREEN_BYTES-1,d4
lbC029C14:
                    moveq    #8-1,d5
                    btst     d6,(-148,a5)
                    beq.b    lbC029C50
lbC029C1C:
                    btst     d7,(a3)
                    beq.b    lbC029C1C
                    move.w   d7,(a4)
                    moveq    #0,d0
                    move.b   (a2),d0
                    sub.b    d7,d0
                    move.b   d0,(a5)
                    move.b   d0,(16,a5)
                    move.b   d0,(a6)+
                    add.w    d0,d0
                    move.w   (a1,d0.w),d1
                    move.w   (sp),d2
                    move.w   d1,(sp)+
                    bclr     d5,(a0,d2.w)
                    bset     d5,(a0,d1.w)
                    dbra     d5,lbC029C1C
                    addq.w   #1,a0
                    dbra     d4,lbC029C14
                    cmp.l    a6,d3
                    bne.b    lbC029BFA
lbC029C50:
                    move.w   (lbW029F0C),(main_back_color+2)
                    move.l   a6,d0
                    moveq    #-8,d1
                    and.l    d1,d0
                    move.l   d0,(lbL029EFA)
                    move.l   (lbL029F00),sp
                    jsr      (stop_audio_channels)
                    jsr      (lbC01E0FA)
                    bsr      lbC029D92
                    bmi      lbC02830C
                    lea      (OK_Samples),a0
                    move.w   (current_sample),d0
                    lsl.w    #5,d0
                    adda.w   d0,a0
                    move.w   #1,(30,a0)
                    move.w   #64,(28,a0)
                    bsr      lbC02896C
                    bsr      lbC028324
                    bsr      lbC02837A
                    bra      lbC028C3E
lbC029CAC:
                    rts
lbC029CAE:
                    jsr      (stop_audio_channels)
                    lea      (_CUSTOM),a6
                    lea      (lbW02513C),a0
                    move.w   (lbW029E10),d0
                    add.w    d0,d0
                    adda.w   d0,a0
                    move.w   (a0),d0
                    lsr.w    #1,d0
                    move.w   d0,(AUD0PER,a6)
                    move.w   d0,(AUD1PER,a6)
                    moveq    #32,d0
                    move.w   d0,(AUD0VOL,a6)
                    move.w   d0,(AUD1VOL,a6)
                    lea      (AUD0DAT,a6),a5
                    lea      (AUD1DAT,a6),a6
                    moveq    #0,d0
                    move.w   d0,(a5)
                    move.w   d0,(a6)
                    move.b   #6,(CIAA|CIADDRA)
                    moveq    #2,d0
                    tst.w    (lbW029EFE)
                    beq.b    lbC029D02
                    moveq    #4,d0
lbC029D02:
                    move.b   d0,(CIAA)
                    move.b   #0,(CIAB|CIADDRB)
                    lea      (mult_table),a1
                    lea      (CIAB|CIAPRB),a2
                    lea      (_CUSTOM|INTREQR),a3
                    lea      (_CUSTOM|INTREQ),a4
                    move.w   #384,d7
                    moveq    #6,d6
                    rts
lbC029D30:
                    move.l   #$20002,d1
                    EXEC     AvailMem
                    divu.w   #640,d0
                    mulu.w   #640,d0
lbC029D4A:
                    cmpi.l   #131070,d0
                    ble.b    lbC029D5A
                    subi.l   #640,d0
                    bra.b    lbC029D4A
lbC029D5A:
                    cmpi.l   #2,d0
                    blt      lbC029EA6
                    move.l   d0,(lbL029F08)
                    moveq    #0,d1
                    EXEC     AllocMem
                    move.l   d0,(lbL029EF2)
                    beq      lbC029EA6
                    add.l    (lbL029F08),d0
                    move.l   d0,(lbL029EF6)
                    moveq    #0,d0
                    rts
lbC029D92:
                    move.l   (lbL029EF6),d0
                    cmp.l    (lbL029EFA),d0
                    beq.b    lbC029DBA
                    move.l   (lbL029EFA),a1
                    move.l   (lbL029EF6),d0
                    sub.l    a1,d0
                    EXEC     FreeMem
lbC029DBA:
                    move.l   (lbL029EF2),(lbL01A130)
                    move.l   (lbL029EFA),d0
                    sub.l    (lbL029EF2),d0
                    move.l   d0,(lbL01A134)
                    move.l   d0,(lbL029ECE)
                    moveq    #0,d0
                    rts
lbC029DE0:
                    lea      (lbW029E10,pc),a0
                    cmpi.w   #1,(a0)
                    beq.b    lbC029DF0
                    subq.w   #1,(a0)
                    bra      lbC028C3E
lbC029DF0:
                    rts
lbC029DF2:
                    lea      (lbW029E10,pc),a0
                    cmpi.w   #36,(a0)
                    beq.b    lbC029E02
                    addq.w   #1,(a0)
                    bra      lbC028C3E
lbC029E02:
                    rts
lbC029E04:
                    eori.w   #1,(lbW029EFE)
                    bra      lbC028C3E
lbW029E10:
                    dc.w     25
L_MSG:
                    dc.b     'L  ',0
                    dc.b     '  R',0
lbC029E1A:
                    moveq    #0,d0
                    move.b   d1,d0
                    jsr      (lbC01F06E)
                    bmi.b    lbC029E3A
                    move.l   (lbL01F2D0),a0
                    moveq    #0,d1
                    move.b   (a0,d0.w),d1
                    bmi.b    lbC029E3A
                    move.w   d1,d0
                    bsr      lbC029E50
lbC029E3A:
                    moveq    #ERROR,d0
                    rts
lbC029E3E:
                    lea      (lbL029E92,pc),a0
                    move.b   d1,(a0,d0.w)
                    rts
lbC029E48:
                    clr.l    (lbL029E92)
                    rts
lbC029E50:
                    cmpi.b   #MIDI_OUT,(midi_mode)
                    bne.b    lbC029E6A
                    move.b   d0,d1
                    move.w   (current_sample),d0
                    jmp      (lbC0229FC)
lbC029E6A:
                    lea      (lbL029E92,pc),a0
                    lea      (_CUSTOM|AUD0LCH),a1
                    moveq    #4-1,d1
lbC029E76:
                    cmp.b    (a0)+,d0
                    beq.b    lbC029E84
                    lea      ($10,a1),a1
                    dbra     d1,lbC029E76
                    rts
lbC029E84:
                    sf       -(a0)
                    move.l   #OK_EmptyWaveForm,(a1)+
                    move.w   #1,(a1)+
                    rts
lbL029E92:
                    dc.l     0
lbC029E96:
                    jmp      (error_what_sample)
lbC029E9E:
                    jmp      (error_what_block)
lbC029EA6:
                    jmp      (error_no_memory)
lbC029EAE:
                    jmp      (error_what_position)
lbC029EB6:
                    jmp      (error_sample_too_long)
lbC029EBE:
                    jmp      (error_only_in_mode_4_b)
lbC029EC6:
                    jmp      (error_zero_not_found)
lbL029ECE:
                    dc.l     0
lbW029ED2:
                    dc.w     0
lbW029ED4:
                    dc.l     0
lbL029ED8:
                    dc.l     0
lbL029EDC:
                    dc.l     0
lbL029EE0:
                    dc.l     0
lbW029EE4:
                    dc.w     0
lbB029EE6:
                    dc.b     0
lbB029EE7:
                    dc.b     0
lbB029EE8:
                    dc.b     0
                    even
lbL029EEA:
                    dc.l     0
lbL029EEE:
                    dc.l     0
lbL029EF2:
                    dc.l     0
lbL029EF6:
                    dc.l     0
lbL029EFA:
                    dc.l     0
lbW029EFE:
                    dc.w     0
lbL029F00:
                    dc.l     0
lbL029F04:
                    dc.l     0
lbL029F08:
                    dc.l     0
lbW029F0C:
                    dc.w     0
lbW029F0E:
                    dc.w     0
lbW029F10:
                    dc.w     0
lbW029F12:
                    dc.w     0
lbL029F14:
                    dc.l     0
lbL029F18:
                    dc.l     0
lbB029F1C:
                    dc.w     0
lbW029F1E:
                    dc.w     0
lbW029F20:
                    dc.w     0
lbW029F22:
                    dc.w     0

; ===========================================================================
prefs_data:
                    dc.b     'OK__'
OK_ChannelsModes:
                    dc.w     1,0,1,0
default_pattern_length:
                    dc.w     $40
samples_load_mode:
                    dc.w     1
samples_save_format:
                    dc.w     0
prefs_palette:
                    dc.w     $0DD,$004,$08A,$004,$19E,$004
polyphony:
                    dc.b     0,1,2,3,4,5,6,7
mouse_repeat_delay:
                    dc.w     10
mouse_repeat_speed:
                    dc.w     2
f6_key_line_jump_value:
                    dc.w     0
f7_key_line_jump_value:
                    dc.w     $10
f8_key_line_jump_value:
                    dc.w     $20
f9_key_line_jump_value:
                    dc.w     $30
f10_key_line_jump_value:
                    dc.w     $40
text_font:
                    incbin   "font_2048x8.lo1"
st_load_tracks_samples:
                    dc.b     -1
st_load_tracks_mode:
                    dc.b     0

; ===========================================================================
lbW02A75A:
                    dc.w     0
lbL02A75C:
                    dc.l     0
channels_mute_flags:
                    dc.b     0
channels_number_text:
                    dcb.b    8,0
                    dc.b     0
lbL02A76A:
                    dcb.l    2,0

; ===========================================================================
lbC02A772:
                    bsr      backup_prefs
.loop:
                    lea      (lbW02A7BA,pc),a0
                    jsr      (process_commands_sequence)
                    bsr      lbC02A9E2
                    lea      (lbW02A7AA,pc),a0
                    jsr      (lbC020626)
                    bsr      lbC02B12E
                    move.l   (current_cmd_ptr),d0
                    beq.b    .no_command
                    move.l   d0,a0
                    jsr      (a0)
                    bra.b    .loop
.no_command:
                    tst.b    (quit_flag)
                    beq.b    .loop
                    rts
lbW02A7AA:
                    dc.w     11
                    dc.l     lbC02A7B2
                    dc.w     0
lbC02A7B2:
                    jmp      (lbC0208FA)
lbW02A7BA:
                    dc.w     1
                    dc.l     prefs_text
                    dc.w     2
                    dc.l     lbW0194A6
                    dc.w     3
                    dc.l     lbW019080
                    dc.w     0
                    dc.l     0,0,0
lbC02A7DA:
                    move.l   #lbC02A7E6,(current_cmd_ptr)
                    rts
lbC02A7E6:
                    lea      (prefs_help_text),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    jmp      (lbC0246B8)

; ===========================================================================
load_prefs:
                    move.l   #do_load_prefs,(current_cmd_ptr)
                    rts
do_load_prefs:
                    lea      (load_prefs_text,pc),a0
                    moveq    #DIR_PREFS,d0
                    jsr      (display_file_requester)
                    ble.b    .cancelled
                    lea      (filename_to_load),a0
                    bsr      load_prefs_file
                    bmi.b    .load_error
.cancelled:
                    bra      lbC02A9E2
.load_error:
                    jsr      (display_dos_error)
                    bra.b    .cancelled
load_prefs_text:
                    dc.b     'Load Preferences',0
                    even

; ===========================================================================
save_prefs:
                    move.l   #do_save_prefs,(current_cmd_ptr)
                    rts
do_save_prefs:
                    lea      (save_prefs_text,pc),a0
                    moveq    #DIR_PREFS,d0
                    jsr      (display_file_requester)
                    bmi.b    .cancelled
                    lea      (filename_to_load),a0
                    lea      (prefs_data,pc),a1
                    move.l   #PREFS_FILE_LEN,d0
                    jsr      (save_file)
                    bmi.b    .save_error
.cancelled:
                    rts
.save_error:
                    jmp      (display_dos_error)
save_prefs_text:
                    dc.b     'Save Preferences',0
                    even

; ===========================================================================
lbC02A966:
                    bsr      lbC02B350
                    st       (quit_flag)
                    rts
lbC02A972:
                    bsr      restore_prefs
                    bra      lbC02A9E2
lbC02A97A:
                    bsr      restore_prefs
                    bsr      lbC02B354
                    st       (quit_flag)
                    rts
auto_load_prefs:
                    lea      (prefs_filename,pc),a0
                    bsr      load_prefs_file
                    bra      lbC02B354
prefs_filename:
                    dc.b     'ok.inf',0
                    even

; ===========================================================================
load_prefs_file:
                    movem.l  d7/a2,-(sp)
                    sf       d7
                    move.l   a0,a2
                    bsr      lbC02B2BC
                    smi      d7
                    bmi.b    lbC02A9DA
                    move.l   a2,a0
                    lea      (prefs_data,pc),a1
                    move.l   #PREFS_FILE_LEN,d0
                    jsr      (load_file)
                    smi      d7
                    bmi.b    lbC02A9D2
                    move.l   (prefs_data,pc),d0
                    move.l   (lbL02B34C),a0
                    cmp.l    (a0),d0
                    beq.b    lbC02A9D6
lbC02A9D2:
                    bsr      lbC02B2FE
lbC02A9D6:
                    bsr      lbC02B31A
lbC02A9DA:
                    move.b   d7,d0
                    movem.l  (sp)+,d7/a2
                    rts

; ===========================================================================
lbC02A9E2:
                    bsr      lbC02AA86
                    bsr      lbC02AAD6
                    bsr      lbC02AB08
                    bsr      lbC02AB32
                    bsr      lbC02AB78
                    bsr      lbC02ABAC
                    bsr      lbC02ACA6
                    bsr      lbC02AD72
                    bsr      update_f_keys_line_jump_values
                    bsr      draw_font
                    bsr      draw_selected_char_grid
                    bra      lbC02AA28
lbC02AA14:
                    not.b    (st_load_tracks_samples)
                    bra      lbC02AA28
lbC02AA1E:
                    not.b    (st_load_tracks_mode)
lbC02AA28:
                    lea      (ascii_MSG22,pc),a0
                    tst.b    (st_load_tracks_samples)
                    beq.b    lbC02AA38
                    lea      (ascii_MSG23,pc),a0
lbC02AA38:
                    jsr      (draw_text_with_coords_struct)
                    lea      (ascii_MSG24,pc),a0
                    tst.b    (st_load_tracks_mode)
                    beq.b    lbC02AA4E
                    lea      (ascii_MSG25,pc),a0
lbC02AA4E:
                    jmp      (draw_text_with_coords_struct)
ascii_MSG22:
                    dc.b     39,27,'16',0
ascii_MSG23:
                    dc.b     39,27,'32',0
ascii_MSG24:
                    dc.b     48,27,'4',0
ascii_MSG25:
                    dc.b     48,27,'8',0
lbC02AA68:
                    moveq    #0,d0
                    bra.b    lbC02AA76
lbC02AA6C:
                    moveq    #1,d0
                    bra.b    lbC02AA76
lbC02AA70:
                    moveq    #2,d0
                    bra.b    lbC02AA76
lbC02AA74:
                    moveq    #3,d0
lbC02AA76:
                    lea      (OK_ChannelsModes,pc),a0
                    add.w    d0,d0
                    eori.w   #1,(a0,d0.w)
lbC02AA86:
                    moveq    #14,d2
                    lea      (OK_ChannelsModes,pc),a5
                    moveq    #4-1,d7
lbC02AA8E:
                    lea      (DD_MSG,pc),a0
                    tst.w    (a5)+
                    bne.b    lbC02AA9A
                    lea      (S_MSG,pc),a0
lbC02AA9A:
                    move.w   d2,d0
                    moveq    #12,d1
                    jsr      (draw_text)
                    addq.w   #3,d2
                    dbra     d7,lbC02AA8E
                    rts
S_MSG:
                    dc.b     'S ',0
DD_MSG:
                    dc.b     'DD',0
lbC02AAB2:
                    lea      (default_pattern_length,pc),a0
                    cmpi.w   #$80,(a0)
                    beq.b    lbC02AAC2
                    addq.w   #1,(a0)
                    bra      lbC02AAD6
lbC02AAC2:
                    rts
lbC02AAC4:
                    lea      (default_pattern_length,pc),a0
                    cmpi.w   #1,(a0)
                    beq.b    lbC02AAD4
                    subq.w   #1,(a0)
                    bra      lbC02AAD6
lbC02AAD4:
                    rts
lbC02AAD6:
                    move.w   (default_pattern_length,pc),d2
                    moveq    #23,d0
                    moveq    #13,d1
                    jmp      (draw_2_digits_hex_number)
lbC02AAE6:
                    lea      (samples_load_mode,pc),a0
                    cmpi.w   #2,(a0)
                    beq.b    lbC02AAF6
                    addq.w   #1,(a0)
                    bra      lbC02AB08
lbC02AAF6:
                    rts
lbC02AAF8:
                    lea      (samples_load_mode,pc),a0
                    tst.w    (a0)
                    beq.b    lbC02AB06
                    subq.w   #1,(a0)
                    bra      lbC02AB08
lbC02AB06:
                    rts
lbC02AB08:
                    lea      (B_MSG1,pc),a0
                    move.w   (samples_load_mode,pc),d2
                    move.b   (a0,d2.w),d2
                    moveq    #24,d0
                    moveq    #15,d1
                    jmp      (draw_one_char)
B_MSG1:
                    dc.b     '84B'
                    even
lbC02AB24:
                    eori.w   #1,(samples_save_format)
                    bra      lbC02AB32
lbC02AB32:
                    lea      (IFF_MSG,pc),a0
                    move.w   (samples_save_format,pc),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    adda.w   d0,a0
                    moveq    #22,d0
                    moveq    #16,d1
                    jmp      (draw_text)
IFF_MSG:
                    dc.b     'IFF',0
                    dc.b     'RAW',0
lbC02AB54:
                    lea      (mouse_repeat_delay,pc),a0
                    cmpi.w   #50,(a0)
                    beq.b    lbC02AB64
                    addq.w   #1,(a0)
                    bra      lbC02AB78
lbC02AB64:
                    rts
lbC02AB66:
                    lea      (mouse_repeat_delay,pc),a0
                    cmpi.w   #1,(a0)
                    beq.b    lbC02AB76
                    subq.w   #1,(a0)
                    bra      lbC02AB78
lbC02AB76:
                    rts
lbC02AB78:
                    moveq    #23,d0
                    moveq    #18,d1
                    move.w   (mouse_repeat_delay,pc),d2
                    jmp      (lbC025E20)
lbC02AB88:
                    lea      (mouse_repeat_speed,pc),a0
                    cmpi.w   #50,(a0)
                    beq.b    lbC02AB98
                    addq.w   #1,(a0)
                    bra      lbC02ABAC
lbC02AB98:
                    rts
lbC02AB9A:
                    lea      (mouse_repeat_speed,pc),a0
                    cmpi.w   #1,(a0)
                    beq.b    lbC02ABAA
                    subq.w   #1,(a0)
                    bra      lbC02ABAC
lbC02ABAA:
                    rts
lbC02ABAC:
                    moveq    #23,d0
                    moveq    #19,d1
                    move.w   (mouse_repeat_speed,pc),d2
                    jmp      (lbC025E20)
lbC02ABBC:
                    lea      (lbW02ACE0,pc),a0
                    cmpi.w   #2,(a0)
                    beq.b    lbC02ABCC
                    addq.w   #1,(a0)
                    bra      lbC02ACA6
lbC02ABCC:
                    rts
lbC02ABCE:
                    lea      (lbW02ACE0,pc),a0
                    tst.w    (a0)
                    beq.b    lbC02ABDC
                    subq.w   #1,(a0)
                    bra      lbC02ACA6
lbC02ABDC:
                    rts
lbC02ABDE:
                    moveq    #8,d0
                    bra.b    lbC02ABE8
lbC02ABE2:
                    moveq    #4,d0
                    bra.b    lbC02ABE8
lbC02ABE6:
                    moveq    #0,d0
lbC02ABE8:
                    lea      (prefs_palette+2,pc),a0
                    move.w   (lbW02ACE0,pc),d1
                    add.w    d1,d1
                    add.w    d1,d1
                    adda.w   d1,a0
                    moveq    #0,d1
                    move.w   (a0),d1
                    ror.l    d0,d1
                    moveq    #$F,d2
                    and.b    d1,d2
                    cmpi.b   #$F,d2
                    beq.b    lbC02AC10
                    addq.b   #1,d1
                    rol.l    d0,d1
                    move.w   d1,(a0)
                    bra      lbC02ACA6
lbC02AC10:
                    rts
lbC02AC12:
                    moveq    #8,d0
                    bra.b    lbC02AC1C
lbC02AC16:
                    moveq    #4,d0
                    bra.b    lbC02AC1C
lbC02AC1A:
                    moveq    #0,d0
lbC02AC1C:
                    lea      (prefs_palette+2,pc),a0
                    move.w   (lbW02ACE0,pc),d1
                    add.w    d1,d1
                    add.w    d1,d1
                    adda.w   d1,a0
                    moveq    #0,d1
                    move.w   (a0),d1
                    ror.l    d0,d1
                    moveq    #$F,d2
                    and.b    d1,d2
                    beq.b    lbC02AC40
                    subq.b   #1,d1
                    rol.l    d0,d1
                    move.w   d1,(a0)
                    bra      lbC02ACA6
lbC02AC40:
                    rts
lbC02AC42:
                    moveq    #8,d0
                    bra.b    lbC02AC4C
lbC02AC46:
                    moveq    #4,d0
                    bra.b    lbC02AC4C
lbC02AC4A:
                    moveq    #0,d0
lbC02AC4C:
                    lea      (prefs_palette,pc),a0
                    move.w   (lbW02ACE0,pc),d1
                    add.w    d1,d1
                    add.w    d1,d1
                    adda.w   d1,a0
                    moveq    #0,d1
                    move.w   (a0),d1
                    ror.l    d0,d1
                    moveq    #$F,d2
                    and.b    d1,d2
                    cmpi.b   #$F,d2
                    beq.b    lbC02AC74
                    addq.b   #1,d1
                    rol.l    d0,d1
                    move.w   d1,(a0)
                    bra      lbC02ACA6
lbC02AC74:
                    rts
lbC02AC76:
                    moveq    #8,d0
                    bra.b    lbC02AC80
lbC02AC7A:
                    moveq    #4,d0
                    bra.b    lbC02AC80
lbC02AC7E:
                    moveq    #0,d0
lbC02AC80:
                    lea      (prefs_palette,pc),a0
                    move.w   (lbW02ACE0,pc),d1
                    add.w    d1,d1
                    add.w    d1,d1
                    adda.w   d1,a0
                    moveq    #0,d1
                    move.w   (a0),d1
                    ror.l    d0,d1
                    moveq    #$F,d2
                    and.b    d1,d2
                    beq.b    lbC02ACA4
                    subq.b   #1,d1
                    rol.l    d0,d1
                    move.w   d1,(a0)
                    bra      lbC02ACA6
lbC02ACA4:
                    rts
lbC02ACA6:
                    moveq    #16,d0
                    moveq    #21,d1
                    move.w   (lbW02ACE0,pc),d2
                    addq.w   #1,d2
                    jsr      (draw_one_char_alpha_numeric)
                    lea      (prefs_palette,pc),a5
                    move.w   (lbW02ACE0,pc),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    adda.w   d0,a5
                    move.w   (a5)+,d2
                    moveq    #18,d0
                    moveq    #21,d1
                    jsr      (draw_3_digits_hex_number)
                    move.w   (a5)+,d2
                    moveq    #22,d0
                    moveq    #21,d1
                    jsr      (draw_3_digits_hex_number)
                    bra      set_colors_palette
lbW02ACE0:
                    dc.w     0
lbC02ACE2:
                    lea      (polyphony,pc),a0
                    adda.w   d0,a0
                    subq.b   #1,(a0)
                    andi.b   #7,(a0)
                    bra      lbC02AD72
lbC02ACF2:
                    moveq    #0,d0
                    bra.b    lbC02ACE2
lbC02ACF6:
                    moveq    #1,d0
                    bra.b    lbC02ACE2
lbC02ACFA:
                    moveq    #2,d0
                    bra.b    lbC02ACE2
lbC02ACFE:
                    moveq    #3,d0
                    bra.b    lbC02ACE2
lbC02AD02:
                    moveq    #4,d0
                    bra.b    lbC02ACE2
lbC02AD06:
                    moveq    #5,d0
                    bra.b    lbC02ACE2
lbC02AD0A:
                    moveq    #6,d0
                    bra.b    lbC02ACE2
lbC02AD0E:
                    moveq    #7,d0
                    bra.b    lbC02ACE2
lbC02AD12:
                    lea      (polyphony,pc),a0
                    adda.w   d0,a0
                    addq.b   #1,(a0)
                    andi.b   #7,(a0)
                    bra      lbC02AD72
lbC02AD22:
                    moveq    #0,d0
                    bra.b    lbC02AD12
lbC02AD26:
                    moveq    #1,d0
                    bra.b    lbC02AD12
lbC02AD2A:
                    moveq    #2,d0
                    bra.b    lbC02AD12
lbC02AD2E:
                    moveq    #3,d0
                    bra.b    lbC02AD12
lbC02AD32:
                    moveq    #4,d0
                    bra.b    lbC02AD12
lbC02AD36:
                    moveq    #5,d0
                    bra.b    lbC02AD12
lbC02AD3A:
                    moveq    #6,d0
                    bra.b    lbC02AD12
lbC02AD3E:
                    moveq    #7,d0
                    bra.b    lbC02AD12
lbC02AD42:
                    lea      (polyphony,pc),a1
                    moveq    #0,d0
lbC02AD48:
                    move.b   d0,(a1)+
                    addq.b   #1,d0
                    cmpi.b   #8,d0
                    bne.b    lbC02AD48
                    bra      lbC02AD72
lbC02AD56:
                    lea      (lbB02AD6A,pc),a0
                    lea      (polyphony,pc),a1
                    moveq    #8-1,d0
lbC02AD60:
                    move.b   (a0)+,(a1)+
                    dbra     d0,lbC02AD60
                    bra      lbC02AD72
lbB02AD6A:
                    dc.b     0,2,1,3,6,4,7,5
lbC02AD72:
                    move.w   #244,d0
                    move.w   #99,d1
                    move.w   #300,d2
                    move.w   #156,d3
                    lea      (main_screen),a3
                    jsr      (lbC025132)
                    jsr      (prepare_line_drawing)
                    lea      (polyphony,pc),a5
                    move.w   #99,d6
                    moveq    #7-1,d7
lbC02AD9E:
                    moveq    #0,d0
                    move.b   (a5),d0
                    lsl.w    #3,d0
                    addi.w   #244,d0
                    move.w   d6,d1
                    moveq    #0,d2
                    addq.w   #1,a5
                    move.b   (a5),d2
                    lsl.w    #3,d2
                    addi.w   #244,d2
                    addq.w   #8,d6
                    move.w   d6,d3
                    movem.w  d6/d7,-(sp)
                    lea      (main_screen),a0
                    jsr      (lbC0256DA)
                    movem.w  (sp)+,d6/d7
                    dbra     d7,lbC02AD9E
                    jmp      (release_after_line_drawing)

; ===========================================================================
increase_f6_key_line_jump_value:
                    lea      (f6_key_line_jump_value,pc),a0
                    cmpi.w   #127,(a0)
                    beq.b    .max
                    addq.w   #1,(a0)
                    bra      update_f6_key_line_jump_value
.max:
                    rts

; ===========================================================================
decrease_f6_key_line_jump_value:
                    lea      (f6_key_line_jump_value,pc),a0
                    tst.w    (a0)
                    beq.b    .min
                    subq.w   #1,(a0)
                    bra      update_f6_key_line_jump_value
.min:
                    rts

; ===========================================================================
update_f6_key_line_jump_value:
                    moveq    #47,d0
                    moveq    #13,d1
                    move.w   (f6_key_line_jump_value,pc),d2
                    jmp      (draw_2_digits_hex_number)

; ===========================================================================
increase_f7_key_line_jump_value:
                    lea      (f7_key_line_jump_value,pc),a0
                    cmpi.w   #127,(a0)
                    beq.b    .max
                    addq.w   #1,(a0)
                    bra      update_f7_key_line_jump_value
.max:
                    rts

; ===========================================================================
decrease_f7_key_line_jump_value:
                    lea      (f7_key_line_jump_value,pc),a0
                    tst.w    (a0)
                    beq.b    .min
                    subq.w   #1,(a0)
                    bra      update_f7_key_line_jump_value
.min:
                    rts

; ===========================================================================
update_f7_key_line_jump_value:
                    moveq    #47,d0
                    moveq    #15,d1
                    move.w   (f7_key_line_jump_value,pc),d2
                    jmp      (draw_2_digits_hex_number)

; ===========================================================================
increase_f8_key_line_jump_value:
                    lea      (f8_key_line_jump_value,pc),a0
                    cmpi.w   #127,(a0)
                    beq.b    .max
                    addq.w   #1,(a0)
                    bra      update_f8_key_line_jump_value
.max:
                    rts

; ===========================================================================
decrease_f8_key_line_jump_value:
                    lea      (f8_key_line_jump_value,pc),a0
                    tst.w    (a0)
                    beq.b    .min
                    subq.w   #1,(a0)
                    bra      update_f8_key_line_jump_value
.min:
                    rts

; ===========================================================================
update_f8_key_line_jump_value:
                    moveq    #47,d0
                    moveq    #17,d1
                    move.w   (f8_key_line_jump_value,pc),d2
                    jmp      (draw_2_digits_hex_number)

; ===========================================================================
increase_f9_key_line_jump_value:
                    lea      (f9_key_line_jump_value,pc),a0
                    cmpi.w   #127,(a0)
                    beq.b    .max
                    addq.w   #1,(a0)
                    bra      update_f9_key_line_jump_value
.max:
                    rts

; ===========================================================================
decrease_f9_key_line_jump_value:
                    lea      (f9_key_line_jump_value,pc),a0
                    tst.w    (a0)
                    beq.b    .min
                    subq.w   #1,(a0)
                    bra      update_f9_key_line_jump_value
.min:
                    rts

; ===========================================================================
update_f9_key_line_jump_value:
                    moveq    #47,d0
                    moveq    #19,d1
                    move.w   (f9_key_line_jump_value,pc),d2
                    jmp      (draw_2_digits_hex_number)

; ===========================================================================
increase_f10_key_line_jump_value:
                    lea      (f10_key_line_jump_value,pc),a0
                    cmpi.w   #127,(a0)
                    beq.b    .max
                    addq.w   #1,(a0)
                    bra      update_f10_key_line_jump_value
.max:
                    rts

; ===========================================================================
decrease_f10_key_line_jump_value:
                    lea      (f10_key_line_jump_value,pc),a0
                    tst.w    (a0)
                    beq.b    .min
                    subq.w   #1,(a0)
                    bra      update_f10_key_line_jump_value
.min:
                    rts

; ===========================================================================
update_f10_key_line_jump_value:
                    moveq    #47,d0
                    moveq    #21,d1
                    move.w   (f10_key_line_jump_value,pc),d2
                    jmp      (draw_2_digits_hex_number)

; ===========================================================================
update_f_keys_line_jump_values:
                    bsr      update_f6_key_line_jump_value
                    bsr      update_f7_key_line_jump_value
                    bsr.b    update_f8_key_line_jump_value
                    bsr.b    update_f9_key_line_jump_value
                    bra.b    update_f10_key_line_jump_value

; ===========================================================================
save_font:
                    lea      (chars3_MSG,pc),a0
                    lea      (text_font,pc),a1
                    move.l   #2048,d0
                    jsr      (save_file)
                    bmi.b    .error
                    rts
.error:
                    jmp      (display_dos_error)
chars3_MSG:
                    dc.b     'chars3',0
                    even 

; ===========================================================================
lbC02AF0C:
                    lea      (current_selected_char,pc),a0
                    cmpi.w   #$FF,(a0)
                    beq.b    lbC02AF1C
                    addq.w   #1,(a0)
                    bra      draw_selected_char_grid
lbC02AF1C:
                    rts
lbC02AF1E:
                    lea      (current_selected_char,pc),a0
                    tst.w    (a0)
                    beq.b    lbC02AF2C
                    subq.w   #1,(a0)
                    bra      draw_selected_char_grid
lbC02AF2C:
                    rts
lbC02AF2E:
                    lea      (current_selected_char,pc),a0
                    moveq    #$F,d0
                    and.w    (a0),d0
                    beq.b    lbC02AF3E
                    subq.w   #1,(a0)
                    bra      draw_selected_char_grid
lbC02AF3E:
                    rts
lbC02AF40:
                    lea      (current_selected_char,pc),a0
                    moveq    #$F,d0
                    and.w    (a0),d0
                    cmpi.w   #$F,d0
                    beq.b    lbC02AF54
                    addq.w   #1,(a0)
                    bra      draw_selected_char_grid
lbC02AF54:
                    rts
lbC02AF56:
                    lea      (current_selected_char,pc),a0
                    cmpi.w   #16,(a0)
                    blt.b    lbC02AF68
                    subi.w   #16,(a0)
                    bra      draw_selected_char_grid
lbC02AF68:
                    rts
lbC02AF6A:
                    lea      (current_selected_char,pc),a0
                    cmpi.w   #239,(a0)
                    bgt.b    lbC02AF7C
                    addi.w   #16,(a0)
                    bra      draw_selected_char_grid
lbC02AF7C:
                    rts
lbC02AF7E:
                    asr.w    #3,d0
                    asr.w    #3,d1
                    subi.w   #62,d0
                    bmi.b    lbC02AFA8
                    subi.w   #12,d1
                    bmi.b    lbC02AFA8
                    cmpi.w   #16,d0
                    bcc.b    lbC02AFA8
                    cmpi.w   #16,d1
                    bcc.b    lbC02AFA8
                    lsl.w    #4,d1
                    or.w     d1,d0
                    move.w   d0,(current_selected_char)
                    bra      draw_selected_char_grid
lbC02AFA8:
                    rts
lbC02AFAA:
                    lea      (lbB01D88E),a0
                    move.w   (current_selected_char),d0
                    bsr      lbC02B16E
                    bra      draw_selected_char_grid
lbC02AFBE:
                    lea      (lbB01D88E),a0
                    move.w   (current_selected_char),d0
                    bsr      lbC02B180
                    bra      draw_selected_char_grid
lbC02AFD2:
                    lea      (lbB01D895),a0
                    move.w   (current_selected_char),d0
                    bsr      lbC02B16E
                    bra      draw_selected_char_grid
lbC02AFE6:
                    lea      (lbB01D895),a0
                    move.w   (current_selected_char),d0
                    bsr      lbC02B180
                    bra      draw_selected_char_grid
lbC02AFFA:
                    lea      (lbB01D895),a0
                    move.w   (current_selected_char),d0
                    bsr      lbC02B15C
                    bra      draw_selected_char_grid
lbC02B00E:
                    lea      (lbB01D895),a0
                    move.w   (current_selected_char),d0
                    bsr      lbC02B15C
                    move.w   (current_selected_char),d0
                    bsr      lbC02B196
                    bra      draw_selected_char_grid
lbC02B02C:
                    move.w   (current_selected_char),d0
                    bsr      lbC02B196
                    bra      draw_selected_char_grid

; ===========================================================================
mirror_char_x:
                    movem.l  d2/d3,-(sp)
                    lea      (text_font,pc),a0
                    move.w   (current_selected_char),d0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    moveq    #7-1,d0
.loop_y:
                    move.b   (a0),d1
                    moveq    #0,d2
                    moveq    #8-1,d3
.loop_x:
                    addx.b   d1,d1
                    roxr.b   #1,d2
                    dbra     d3,.loop_x
                    move.b   d2,(a0)+
                    dbra     d0,.loop_y
                    movem.l  (sp)+,d2/d3
                    bra      draw_selected_char_grid

; ===========================================================================
mirror_char_y:
                    lea      (text_font,pc),a0
                    move.w   (current_selected_char),d0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    lea      (7,a0),a1
                    moveq    #3-1,d0
.loop:
                    move.b   (a0),d1
                    move.b   -(a1),(a0)+
                    move.b   d1,(a1)
                    dbra     d0,.loop
                    bra      draw_selected_char_grid

; ===========================================================================
; draw the complete set of chars
draw_font:
                    movem.l  d3-d7,-(sp)
                    moveq    #0,d5
                    moveq    #12,d4
                    moveq    #16-1,d7
.loop_y:
                    moveq    #62,d3
                    moveq    #16-1,d6
.loop_x:
                    move.w   d3,d0
                    move.w   d4,d1
                    move.b   d5,d2
                    jsr      (draw_one_char)
                    addq.b   #1,d5
                    addq.w   #1,d3
                    dbra     d6,.loop_x
                    addq.w   #1,d4
                    dbra     d7,.loop_y
                    movem.l  (sp)+,d3-d7
                    rts

; ===========================================================================
draw_selected_char_grid:
                    move.w   (current_selected_char),d0
                    cmp.w    (lbW02B15A),d0
                    beq.b    lbC02B0D4
                    lea      (lbB01D88E),a0
                    bsr      lbC02B15C
lbC02B0D4:
                    bsr      lbC02B12E
                    bsr      draw_selected_char
                    move.w   (current_selected_char,pc),d0
                    move.w   d0,(lbW02B15A)
                    bsr      invert_selected_char
                    moveq    #53,d0
                    moveq    #12,d1
                    move.w   (current_selected_char,pc),d2
                    move.b   #$84,d3
                    move.b   #$85,d4
                    jsr      (draw_zoomed_char)
                    moveq    #59,d0
                    moveq    #20,d1
                    move.w   (current_selected_char),d2
                    bra      draw_2_digits_hex_number

; ===========================================================================
draw_selected_char:
                    move.l   d2,-(sp)
                    move.w   (current_selected_char,pc),d2
                    move.w   d2,d1
                    moveq    #$F,d0
                    and.w    d1,d0
                    lsr.w    #4,d1
                    addi.w   #62,d0
                    addi.w   #12,d1
                    bsr      draw_one_char
                    move.l   (sp)+,d2
                    rts

; ===========================================================================
lbC02B12E:
                    lea      (lbW02B15A,pc),a0
                    move.w   (a0),d0
                    bmi.b    lbC02B13E
                    move.w   #-1,(a0)
                    bra      invert_selected_char
lbC02B13E:
                    rts
invert_selected_char:
                    moveq    #$F,d1
                    and.w    d0,d1
                    lsr.w    #4,d0
                    exg      d0,d1
                    addi.w   #62,d0
                    addi.w   #12,d1
                    jmp      (invert_one_char)
current_selected_char:
                    dc.w     $20
lbW02B15A:
                    dc.w     -1
lbC02B15C:
                    lea      (text_font,pc),a1
                    lsl.w    #3,d0
                    adda.w   d0,a1
                    moveq    #7-1,d0
lbC02B166:
                    move.b   (a1)+,(a0)+
                    dbra     d0,lbC02B166
                    rts
lbC02B16E:
                    lea      (text_font,pc),a1
                    lsl.w    #3,d0
                    adda.w   d0,a1
                    moveq    #7-1,d0
lbC02B178:
                    move.b   (a0)+,(a1)+
                    dbra     d0,lbC02B178
                    rts
lbC02B180:
                    lea      (text_font,pc),a1
                    lsl.w    #3,d0
                    adda.w   d0,a1
                    moveq    #7-1,d0
lbC02B18A:
                    move.b   (a0),d1
                    move.b   (a1),(a0)+
                    move.b   d1,(a1)+
                    dbra     d0,lbC02B18A
                    rts
lbC02B196:
                    lea      (text_font,pc),a1
                    lsl.w    #3,d0
                    adda.w   d0,a1
                    moveq    #7-1,d0
lbC02B1A0:
                    sf       (a1)+
                    dbra     d0,lbC02B1A0
                    rts
lbC02B1A8:
                    movem.l  d2,-(sp)
                    st       d2
                    bra.b    lbC02B1B6
lbC02B1B0:
                    movem.l  d2,-(sp)
                    sf       d2
lbC02B1B6:
                    asr.w    #3,d0
                    subi.w   #53,d0
                    cmpi.w   #8,d0
                    bcc.b    lbC02B1EA
                    not.b    d0
                    asr.w    #3,d1
                    subi.w   #12,d1
                    cmpi.w   #7,d1
                    bcc.b    lbC02B1EA
                    lea      (text_font,pc),a0
                    adda.w   d1,a0
                    move.w   (current_selected_char,pc),d1
                    lsl.w    #3,d1
                    adda.w   d1,a0
                    bclr     d0,(a0)
                    tst.b    d2
                    beq.b    lbC02B1E6
                    bset     d0,(a0)
lbC02B1E6:
                    bsr      draw_selected_char_grid
lbC02B1EA:
                    movem.l  (sp)+,d2
                    rts

; ===========================================================================
move_char_left:
                    lea      (text_font,pc),a0
                    move.w   (current_selected_char,pc),d0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    moveq    #7-1,d1
.loop:
                    move.b   (a0),d0
                    rol.b    #1,d0
                    move.b   d0,(a0)+
                    dbra     d1,.loop
                    bra      draw_selected_char_grid

; ===========================================================================
move_char_right:
                    lea      (text_font,pc),a0
                    move.w   (current_selected_char,pc),d0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    moveq    #7-1,d1
.loop:
                    move.b   (a0),d0
                    ror.b    #1,d0
                    move.b   d0,(a0)+
                    dbra     d1,.loop
                    bra      draw_selected_char_grid

; ===========================================================================
move_char_up:
                    lea      (text_font,pc),a0
                    move.w   (current_selected_char,pc),d0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    move.b   (a0)+,d0
                    moveq    #6-1,d1
.loop:
                    move.b   (a0)+,(-2,a0)
                    dbra     d1,.loop
                    move.b   d0,-(a0)
                    bra      draw_selected_char_grid

; ===========================================================================
move_char_down:
                    lea      (text_font,pc),a0
                    move.w   (current_selected_char,pc),d0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    lea      (6,a0),a0
                    move.b   (a0),d0
                    moveq    #6-1,d1
.loop:
                    move.b   -(a0),(1,a0)
                    dbra     d1,.loop
                    move.b   d0,(a0)
                    bra      draw_selected_char_grid

; ===========================================================================
outline_char:
                    lea      (text_font,pc),a0
                    move.w   (current_selected_char,pc),d0
                    lsl.w    #3,d0
                    adda.w   d0,a0
                    moveq    #7-1,d0
.loop:
                    not.b    (a0)+
                    dbra     d0,.loop
                    bra      draw_selected_char_grid

; ===========================================================================
backup_prefs:
                    lea      (prefs_data,pc),a0
                    lea      (prefs_backup_data),a1
                    move.l   #PREFS_FILE_LEN,d0
                    EXEC     CopyMem
                    rts

; ===========================================================================
restore_prefs:
                    lea      (prefs_backup_data),a0
                    lea      (prefs_data,pc),a1
                    move.l   #PREFS_FILE_LEN,d0
                    EXEC     CopyMem
                    rts

; ===========================================================================
lbC02B2BC:
                    move.l   #PREFS_FILE_LEN,d0
                    moveq    #0,d1
                    EXEC     AllocMem
                    move.l   d0,(lbL02B34C)
                    beq.b    lbC02B2F6
                    lea      (prefs_data,pc),a0
                    move.l   (lbL02B34C,pc),a1
                    move.l   #PREFS_FILE_LEN,d0
                    EXEC     CopyMem
                    moveq    #0,d0
                    rts
lbC02B2F6:
                    jmp      (error_no_memory)
lbC02B2FE:
                    move.l   (lbL02B34C,pc),a0
                    lea      (prefs_data,pc),a1
                    move.l   #PREFS_FILE_LEN,d0
                    EXEC     CopyMem
                    rts
lbC02B31A:
                    lea      (lbL02B34C,pc),a0
                    move.l   (a0),d0
                    beq.b    lbC02B33A
                    clr.l    (a0)
                    move.l   d0,a1
                    move.l   #PREFS_FILE_LEN,d0
                    EXEC     FreeMem
                    rts
lbC02B33A:
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    rts
lbL02B34C:
                    dc.l     0
lbC02B350:
                    st       d0
                    bra.b    lbC02B35A
lbC02B354:
                    sf       d0
lbC02B35A:
                    lea      (OK_ChannelsModes,pc),a0
                    lea      (OK_ChannelsModes_backup),a1
                    cmpm.l   (a0)+,(a1)+
                    bne.b    lbC02B36C
                    cmpm.l   (a0)+,(a1)+
                    beq.b    lbC02B38C
lbC02B36C:
                    tst.b    d0
                    beq.b    lbC02B378
                    jsr      (ask_are_you_sure_requester)
                    bne.b    lbC02B388
lbC02B378:
                    lea      (OK_ChannelsModes_backup),a0
                    lea      (OK_ChannelsModes,pc),a1
                    bsr      lbC02B3B2
                    beq.b    lbC02B38C
lbC02B388:
                    bsr      restore_prefs
lbC02B38C:
                    lea      (prefs_data,pc),a0
                    bsr      lbC02B590
                    tst.l    (OK_PatternList)
                    bne.b    lbC02B3AA
                    jsr      (lbC020112)
                    beq.b    lbC02B3AA
                    jmp      (exit)
lbC02B3AA:
                    bsr      set_colors_palette
                    bra      construct_caret_positions
lbC02B3B2:
                    movem.l  d2/d3/a2-a5,-(sp)
                    bsr      lbC02B506
                    lea      (OK_PatternList),a2
                    lea      (lbL01CF58),a3
                    moveq    #64-1,d3
lbC02B3C8:
                    move.l   (a2),d0
                    beq.b    lbC02B3FC
                    move.l   d0,a4
                    move.w   (a4),d2
                    move.w   d2,d0
                    mulu.w   (lbW02B58E,pc),d0
                    addq.l   #2,d0
                    move.l   #$10000,d1
                    EXEC     AllocMem
                    tst.l    d0
                    beq.b    lbC02B432
                    move.l   d0,a5
                    move.l   a5,(a3)
                    move.w   d2,(a5)
                    move.l   a4,a0
                    move.l   a5,a1
                    bsr      lbC02B452
lbC02B3FC:
                    lea      (4,a2),a2
                    lea      (4,a3),a3
                    dbra     d3,lbC02B3C8
                    lea      (OK_PatternList),a0
                    move.w   (lbW02B584),d0
                    bsr      lbC02B54C
                    lea      (lbL01CF58),a0
                    lea      (OK_PatternList),a1
                    moveq    #64-1,d0
lbC02B426:
                    move.l   (a0),(a1)+
                    clr.l    (a0)+
                    dbra     d0,lbC02B426
                    moveq    #0,d0
                    bra.b    lbC02B44C
lbC02B432:
                    lea      (lbL01CF58),a0
                    move.w   (lbW02B58E,pc),d0
                    bsr      lbC02B54C
                    jsr      (error_no_memory)
                    jsr      (error_cant_convert_song)
lbC02B44C:
                    movem.l  (sp)+,d2/d3/a2-a5
                    rts
lbC02B452:
                    movem.l  d2/d3/a2-a5,-(sp)
                    move.w   (a1),d2
                    lea      (2,a0),a2
                    lea      (2,a1),a3
                    lea      (lbL02B57C),a4
                    lea      (lbL02B586),a5
                    moveq    #4-1,d3
lbC02B46E:
                    move.l   a2,a0
                    move.l   a3,a1
                    move.w   d2,d0
                    move.w   (a4),d1
                    add.w    d1,d1
                    or.w     (a5),d1
                    add.w    d1,d1
                    move.w   (lbW02B4A2,pc,d1.w),d1
                    jsr      (lbW02B4A2,pc,d1.w)
                    move.w   (a4)+,d0
                    addq.w   #1,d0
                    add.w    d0,d0
                    add.w    d0,d0
                    adda.w   d0,a2
                    move.w   (a5)+,d0
                    addq.w   #1,d0
                    add.w    d0,d0
                    add.w    d0,d0
                    adda.w   d0,a3
                    dbra     d3,lbC02B46E
                    movem.l  (sp)+,d2/d3/a2-a5
                    rts
lbW02B4A2:
                    dc.w     lbC02B4AA-lbW02B4A2,lbC02B4BC-lbW02B4A2,lbC02B4CE-lbW02B4A2,lbC02B4EE-lbW02B4A2
lbC02B4AA:
                    bra.b    lbC02B4B6
lbC02B4AC:
                    move.l   (a0),(a1)
                    adda.w   (lbW02B584,pc),a0
                    adda.w   (lbW02B58E,pc),a1
lbC02B4B6:
                    dbra     d0,lbC02B4AC
                    rts
lbC02B4BC:
                    bra.b    lbC02B4C8
lbC02B4BE:
                    move.l   (a0),(a1)
                    adda.w   (lbW02B584,pc),a0
                    adda.w   (lbW02B58E,pc),a1
lbC02B4C8:
                    dbra     d0,lbC02B4BE
                    rts
lbC02B4CE:
                    bra.b    lbC02B4E8
lbC02B4D0:
                    tst.l    (4,a0)
                    beq.b    lbC02B4DA
                    move.l   (4,a0),(a1)
lbC02B4DA:
                    tst.l    (a0)
                    beq.b    lbC02B4E0
                    move.l   (a0),(a1)
lbC02B4E0:
                    adda.w   (lbW02B584,pc),a0
                    adda.w   (lbW02B58E,pc),a1
lbC02B4E8:
                    dbra     d0,lbC02B4D0
                    rts
lbC02B4EE:
                    bra.b    lbC02B500
lbC02B4F0:
                    move.l   (a0),(a1)
                    move.l   (4,a0),(4,a1)
                    adda.w   (lbW02B584,pc),a0
                    adda.w   (lbW02B58E,pc),a1
lbC02B500:
                    dbra     d0,lbC02B4F0
                    rts
lbC02B506:
                    move.l   (a0)+,(lbL02B57C)
                    move.l   (a0)+,(lbL02B580)
                    move.l   (a1)+,(lbL02B586)
                    move.l   (a1)+,(lbL02B58A)
                    lea      (lbL02B57C,pc),a0
                    bsr      lbC02B53C
                    move.w   d0,(lbW02B584)
                    lea      (lbL02B586,pc),a0
                    bsr      lbC02B53C
                    move.w   d0,(lbW02B58E)
                    rts
lbC02B53C:
                    move.w   (a0)+,d0
                    add.w    (a0)+,d0
                    add.w    (a0)+,d0
                    add.w    (a0)+,d0
                    addq.w   #4,d0
                    add.w    d0,d0
                    add.w    d0,d0
                    rts
lbC02B54C:
                    movem.l  d2/d3/a2,-(sp)
                    move.l   a0,a2
                    move.w   d0,d2
                    moveq    #64-1,d3
lbC02B556:
                    move.l   (a2)+,d0
                    beq.b    lbC02B572
                    clr.l    (-4,a2)
                    move.l   d0,a1
                    move.w   (a1),d0
                    mulu.w   d2,d0
                    addq.l   #2,d0
                    EXEC     FreeMem
lbC02B572:
                    dbra     d3,lbC02B556
                    movem.l  (sp)+,d2/d3/a2
                    rts
lbL02B57C:
                    dc.l     0
lbL02B580:
                    dc.l     0
lbW02B584:
                    dc.w     0
lbL02B586:
                    dc.l     0
lbL02B58A:
                    dc.l     0
lbW02B58E:
                    dc.w     0
lbC02B590:
                    addq.w   #4,a0
                    move.w   (a0)+,d0
                    add.w    (a0)+,d0
                    add.w    (a0)+,d0
                    add.w    (a0)+,d0
                    addq.w   #4,d0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.w   d0,(lbW02A75A)
                    mulu.w   (a0)+,d0
                    move.l   d0,(lbL02A75C)
                    st       (channels_mute_flags)
                    rts

; ===========================================================================
construct_caret_positions:
                    lea      (lbL02A76A,pc),a0
                    move.l   a0,(lbL02B61E)
                    move.l   #-1,(a0)
                    move.l   #-1,(4,a0)
                    lea      (channels_number_text,pc),a2
                    lea      (lbL02B684,pc),a3
                    lea      (OK_ChannelsModes,pc),a4
                    lea      (caret_default_positions,pc),a5
                    lea      (caret_current_positions),a6
                    moveq    #0,d3
                    moveq    #0,d4
                    moveq    #'1',d6
                    moveq    #4-1,d7
.loop:
                    tst.w    (a4)+
                    beq.b    .single
                    bsr.b    copy_caret_position
                    bsr.b    copy_caret_position
                    bra.b    .done
.single:
                    bsr.b    copy_caret_position
                    bsr.b    skip_caret_position
.done:
                    dbra     d7,.loop
                    sf       (a6)
                    subq.w   #1,d4
                    clr.w    (caret_pos_x)
                    move.w   d4,(lbW01B294)
                    moveq    #-1,d0
                    move.l   d0,(lbW01F5C4)
                    jmp      (lbC01F430)
lbL02B61E:
                    dc.l     0
copy_caret_position:
                    move.b   d6,(a2)+
                    addq.b   #1,d6
                    move.b   (a5)+,(a6)+
                    move.b   (a5)+,(a6)+
                    move.b   (a5)+,(a6)+
                    move.b   (a5)+,(a6)+
                    move.b   (a5)+,(a6)+
                    addq.w   #5,d4
                    move.l   (a3)+,a0
                    jsr      (lbC020C8A)
                    lea      (lbL02B61E,pc),a1
                    move.l   (a1),a0
                    move.b   d3,(a0)+
                    move.l   a0,(a1)
                    addq.w   #1,d3
                    rts
skip_caret_position:
                    move.b   #' ',(a2)+
                    addq.w   #5,a5
                    move.l   (a3)+,a0
                    jsr      (lbC020C92)
                    addq.w   #1,d3
                    rts
caret_default_positions:
                    dc.b     6,10,11,12,13
                    dc.b     15,19,20,21,22
                    dc.b     24,28,29,30,31
                    dc.b     33,37,38,39,40
                    dc.b     45,49,50,51,52
                    dc.b     54,58,59,60,61
                    dc.b     63,67,68,69,70
                    dc.b     72,76,77,78,79

; ===========================================================================
set_colors_palette:
                    lea      (prefs_palette,pc),a0
                    move.w   (a0)+,(copper_credits_front_color+2)
                    move.w   (a0)+,(copper_credits_back_color+2)
                    move.w   (a0)+,(main_menu_front_color+2)
                    move.w   (a0)+,(main_menu_back_color+2)
                    move.w   (a0)+,(main_front_color+2)
                    move.w   (a0),(main_back_color+2)
                    rts

; ===========================================================================
lbL02B684:
                    dc.l     lbB0178BE
                    dc.l     lbB0178D0
                    dc.l     lbB0178E2
                    dc.l     lbB0178F4
                    dc.l     lbB017906
                    dc.l     lbB017918
                    dc.l     lbB01792A
                    dc.l     lbB01793C
lbC02B6CC:
                    lea      (lbW02B712,pc),a0
                    jsr      (process_commands_sequence)
                    bsr      lbC02C054
                    lea      (lbW02B706,pc),a0
                    jsr      (lbC020626)
                    move.l   (current_cmd_ptr),d0
                    beq.b    lbC02B6F2
                    move.l   d0,a0
                    jsr      (a0)
                    bra.b    lbC02B6CC
lbC02B6F2:
                    tst.b    (quit_flag)
                    beq.b    lbC02B6CC
                    lea      (lbL02C53C,pc),a0
                    jmp      (lbC026AAC)
lbW02B706:
                    dc.w     11
                    dc.l     lbC0208FA
                    dc.w     0
lbW02B70E:
                    dc.w     0
lbW02B710:
                    dc.w     0
lbW02B712:
                    dc.w     1
                    dc.l     effects_ed_text
                    dc.w     2
                    dc.l     lbW0196F0
                    dc.w     3
                    dc.l     lbW0195F4
                    dc.w     0
                    dc.l     0,0,0
lbC02B732:
                    bra      lbC02BFE0
lbC02B738:
                    move.l   #lbC02B744,(current_cmd_ptr)
                    rts
lbC02B744:
                    lea      (effects_ed_help_text),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    jmp      (lbC0246B8)
lbC02B75C:
                    move.l   #lbC02B768,(current_cmd_ptr)
                    rts
lbC02B768:
                    lea      (compute_help_text),a0
                    moveq    #0,d0
                    moveq    #0,d1
                    jsr      (process_command)
                    jmp      (lbC0246B8)
lbC02B780:
                    bsr      lbC02BF88
                    bmi.b    lbC02B7A2
                    bsr      lbC02C05C
                    move.w   (lbW02B70E,pc),d0
                    bne.b    lbC02B7A2
                    move.w   (lbW02B710,pc),d0
                    cmpi.w   #$C,d0
                    bhi.b    lbC02B7A2
                    subq.w   #1,d0
                    move.w   d0,d1
                    bra      lbC02C0B2
lbC02B7A2:
                    rts
lbC02B7A4:
                    bsr      lbC02BFE8
                    bmi.b    lbC02B7D6
                    bsr      lbC02C05C
                    move.w   (lbW02B70E,pc),d0
                    beq.b    lbC02B7C4
                    addi.w   #11,d0
                    cmp.w    (lbW02B710,pc),d0
                    bne.b    lbC02B7C2
                    bra      lbC02C278
lbC02B7C2:
                    rts
lbC02B7C4:
                    move.w   (lbW02B710,pc),d0
                    cmpi.w   #12,d0
                    bcc.b    lbC02B7C2
                    move.w   d0,d1
                    bra      lbC02C0B2
lbC02B7D6:
                    jmp      (error_no_more_entries)
lbC02B7DE:
                    st       (quit_flag)
                    rts
lbC02B7E6:
                    st       d2
                    bra.b    lbC02B7EC
lbC02B7EA:
                    sf       d2
lbC02B7EC:
                    bsr      lbC02B82A
                    bmi.b    lbC02B828
                    move.b   d0,d3
                    move.w   d1,d4
                    lea      (lbL01D89C),a0
                    add.w    d1,d1
                    add.w    d1,d1
                    move.l   (a0,d1.w),d0
                    beq.b    lbC02B828
                    move.l   d0,a0
                    move.b   d2,(a0)
                    tst.b    d3
                    beq.b    lbC02B81C
                    bmi.b    lbC02B816
                    bsr      lbC02C21A
                    bra.b    lbC02B828
lbC02B816:
                    bsr      lbC02C278
                    bra.b    lbC02B828
lbC02B81C:
                    move.w   d4,d1
                    move.w   d1,d0
                    sub.w    (lbW02B70E,pc),d0
                    bra      lbC02C0B2
lbC02B828:
                    rts
lbC02B82A:
                    move.l   d2,-(sp)
                    subi.w   #128,d1
                    bmi.b    lbC02B85E
                    lsr.w    #3,d1
                    cmpi.w   #13,d1
                    bhi.b    lbC02B85E
                    sf       d0
                    subq.w   #1,d1
                    bpl.b    lbC02B842
                    st       d0
lbC02B842:
                    cmpi.w   #12,d1
                    bne.b    lbC02B84A
                    moveq    #1,d0
lbC02B84A:
                    add.w    (lbW02B70E,pc),d1
                    bmi.b    lbC02B85E
                    cmp.w    (lbW02B710,pc),d1
                    bcc.b    lbC02B85E
                    moveq    #OK,d2
                    movem.l  (sp)+,d2
                    rts
lbC02B85E:
                    moveq    #ERROR,d2
                    movem.l  (sp)+,d2
                    rts
lbC02B866:
                    bsr      lbC02B914
                    bmi.b    lbC02B87C
                    bsr      lbC02B880
                    bsr      lbC02BAEA
                    bsr      lbC02C054
                    moveq    #OK,d0
                    rts
lbC02B87C:
                    moveq    #ERROR,d0
                    rts
lbC02B880:
                    movem.l  d2/d3/a2,-(sp)
                    lea      (lbL01D89C),a2
                    move.w   (lbW02B710,pc),d2
                    move.w   d2,d3
                    bra.b    lbC02B8B6
lbC02B892:
                    move.l   (a2)+,d0
                    bne.b    lbC02B8A8
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02B8C4
lbC02B8A8:
                    move.l   d0,a0
                    tst.b    (a0)
                    beq.b    lbC02B8B6
                    clr.l    (-4,a2)
                    bsr      lbC02C020
lbC02B8B6:
                    dbra     d2,lbC02B892
                    move.w   d3,d0
                    move.w   (lbW02B710,pc),d1
                    bsr      lbC02B8CA
lbC02B8C4:
                    movem.l  (sp)+,d2/d3/a2
                    rts
lbC02B8CA:
                    movem.l  d2,-(sp)
                    lea      (lbL01D89C),a0
                    move.l   a0,a1
                    bra.b    lbC02B8E0
lbC02B8D8:
                    move.l   (a0)+,d2
                    beq.b    lbC02B8E0
                    move.l   d2,(a1)+
                    subq.w   #1,d1
lbC02B8E0:
                    dbra     d0,lbC02B8D8
                    tst.w    d1
                    beq.b    lbC02B8F8
                    move.w   #$F00,(_CUSTOM|COLOR00)
lbC02B8F8:
                    movem.l  (sp)+,d2
                    rts
lbC02B8FE:
                    bsr      lbC02B914
                    bmi.b    lbC02B910
                    bsr      lbC02BAEA
                    bsr      lbC02C054
                    moveq    #OK,d0
                    rts
lbC02B910:
                    moveq    #ERROR,d0
                    rts
lbC02B914:
                    bsr      lbC02BA78
                    tst.w    d0
                    beq.b    lbC02B940
                    mulu.w   #131,d0
                    lea      (lbL02C53C,pc),a0
                    jsr      (lbC026A5A)
                    bmi.b    lbC02B93C
                    move.l   a0,a1
                    lea      (lbL01D89C),a0
                    move.w   (lbW02B710,pc),d0
                    bsr      lbC02B94A
lbC02B93C:
                    moveq    #OK,d0
                    rts
lbC02B940:
                    jsr      (error_nothing_selected)
                    moveq    #ERROR,d0
                    rts
lbC02B94A:
                    movem.l  a2,-(sp)
                    bra.b    lbC02B97A
lbC02B950:
                    move.l   (a0)+,d1
                    bne.b    lbC02B966
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02B97E
lbC02B966:
                    move.l   d1,a2
                    tst.b    (a2)
                    beq.b    lbC02B97A
                    move.w   #131-1,d2
lbC02B970:
                    move.b   (a2)+,(a1)+
                    dbra     d2,lbC02B970
                    sf       (-$83,a1)
lbC02B97A:
                    dbra     d0,lbC02B950
lbC02B97E:
                    movem.l  (sp)+,a2
                    rts
lbC02B984:
                    movem.l  a2,-(sp)
                    bra.b    lbC02B9B0
lbC02B98A:
                    move.l   (a0)+,d1
                    bne.b    lbC02B9A0
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02B9B4
lbC02B9A0:
                    move.l   d1,a2
                    move.w   #131-1,d2
lbC02B9A6:
                    move.b   (a2)+,(a1)+
                    dbra     d2,lbC02B9A6
                    sf       (-131,a1)
lbC02B9B0:
                    dbra     d0,lbC02B98A
lbC02B9B4:
                    movem.l  (sp)+,a2
                    rts
lbC02B9BA:
                    bsr      lbC02BA78
                    cmpi.w   #1,d0
                    bhi      lbC02BA12
                    bsr      lbC02BAB2
                    move.l   (lbL02C53C,pc),d1
                    beq      lbC02BA1A
                    move.l   d1,a0
                    move.l   (lbL02C540,pc),d1
                    beq      lbC02BA1A
                    divu.w   #131,d1
                    bra.b    lbC02B9F6
lbC02B9E2:
                    movem.l  d0/d1/a0,-(sp)
                    bsr      lbC02BA22
                    movem.l  (sp)+,d0/d1/a0
                    bmi.b    lbC02BA06
                    lea      (131,a0),a0
                    addq.w   #1,d0
lbC02B9F6:
                    dbra     d1,lbC02B9E2
                    bsr      lbC02BAEA
                    bsr      lbC02C054
                    moveq    #OK,d0
                    rts
lbC02BA06:
                    bsr      lbC02BAEA
                    bsr      lbC02C054
                    moveq    #ERROR,d0
                    rts
lbC02BA12:
                    jmp      (error_no_multi_selection)
lbC02BA1A:
                    jmp      (error_copy_buffer_empty)
lbC02BA22:
                    move.l   a0,(lbL02BA72)
                    move.w   d0,(lbW02BA76)
                    bsr      lbC02BF88
                    bmi.b    lbC02BA6E
                    move.l   (lbL02BA72,pc),a1
                    move.l   a0,d1
                    move.w   #131-1,d0
lbC02BA3E:
                    move.b   (a1)+,(a0)+
                    dbra     d0,lbC02BA3E
                    lea      (lbL01D89C),a1
                    move.w   (lbW02BA76,pc),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    adda.w   d0,a1
                    move.w   (lbW02B710,pc),d0
                    sub.w    (lbW02BA76,pc),d0
                    bmi.b    lbC02BA6A
                    bra.b    lbC02BA66
lbC02BA60:
                    move.l   (a1),a0
                    move.l   d1,(a1)+
                    move.l   a0,d1
lbC02BA66:
                    dbra     d0,lbC02BA60
lbC02BA6A:
                    moveq    #OK,d0
                    rts
lbC02BA6E:
                    moveq    #ERROR,d0
                    rts
lbL02BA72:
                    dc.l     0
lbW02BA76:
                    dc.w     0
lbC02BA78:
                    movem.l  d2,-(sp)
                    lea      (lbL01D89C),a0
                    moveq    #0,d0
                    move.w   (lbW02B710,pc),d1
                    bra.b    lbC02BAA8
lbC02BA8A:
                    move.l   (a0)+,d2
                    bne.b    lbC02BAA0
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02BAAC
lbC02BAA0:
                    move.l   d2,a1
                    tst.b    (a1)
                    beq.b    lbC02BAA8
                    addq.w   #1,d0
lbC02BAA8:
                    dbra     d1,lbC02BA8A
lbC02BAAC:
                    movem.l  (sp)+,d2
                    rts
lbC02BAB2:
                    move.l   d2,-(sp)
                    lea      (lbL01D89C),a0
                    moveq    #0,d0
                    move.w   (lbW02B710,pc),d1
                    bra.b    lbC02BAE0
lbC02BAC2:
                    move.l   (a0)+,d2
                    bne.b    lbC02BAD8
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02BAE4
lbC02BAD8:
                    move.l   d2,a1
                    tst.b    (a1)
                    bne.b    lbC02BAE4
                    addq.w   #1,d0
lbC02BAE0:
                    dbra     d1,lbC02BAC2
lbC02BAE4:
                    movem.l  (sp)+,d2
                    rts
lbC02BAEA:
                    lea      (lbL01D89C),a0
                    move.w   (lbW02B710,pc),d0
                    bra.b    lbC02BB10
lbC02BAF6:
                    move.l   (a0)+,d1
                    bne.b    lbC02BB0C
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02BB14
lbC02BB0C:
                    move.l   d1,a1
                    sf       (a1)
lbC02BB10:
                    dbra     d0,lbC02BAF6
lbC02BB14:
                    rts
lbC02BB16:
                    move.l   #lbC02BB22,(current_cmd_ptr)
                    rts
lbC02BB22:
                    lea      (LoadEffectTab_MSG,pc),a0
                    moveq    #DIR_EFFECTS,d0
                    jsr      (display_file_requester)
                    bgt.b    lbC02BB32
                    rts
lbC02BB32:
                    lea      (filename_to_load),a0
                    jsr      (lbC025C1A)
                    bmi      lbC02BBD8
                    subq.l   #4,d0
                    divu.w   #131,d0
                    swap     d0
                    tst.w    d0
                    bne      lbC02BBD0
                    swap     d0
                    move.w   d0,(lbW02BC12)
                    lea      (filename_to_load),a0
                    jsr      (open_file_for_reading)
                    bmi.b    lbC02BBD8
                    lea      (lbL02BC0E,pc),a0
                    moveq    #4,d0
                    jsr      (read_from_file)
                    bmi.b    lbC02BBD8
                    cmpi.l   #'OK_E',(lbL02BC0E)
                    bne.b    lbC02BBD0
                    move.w   (lbW02BC12,pc),d0
                    mulu.w   #131,d0
                    lea      (lbL02BC14,pc),a0
                    jsr      (lbC026A6A)
                    bmi.b    lbC02BBE2
                    move.l   (lbL02BC18,pc),d0
                    jsr      (read_from_file)
                    bmi.b    lbC02BBD8
                    bsr      lbC02BFE0
                    move.l   (lbL02BC14,pc),a0
                    moveq    #0,d0
                    move.w   (lbW02BC12,pc),d1
                    bra.b    lbC02BBC4
lbC02BBB0:
                    movem.l  d0/d1/a0,-(sp)
                    bsr      lbC02BA22
                    movem.l  (sp)+,d0/d1/a0
                    bmi.b    lbC02BBE2
                    addq.w   #1,d0
                    lea      (131,a0),a0
lbC02BBC4:
                    dbra     d1,lbC02BBB0
                    bsr      lbC02BBEA
                    moveq    #OK,d0
                    rts
lbC02BBD0:
                    jsr      (error_ef_struct_error)
                    bra.b    lbC02BBE2
lbC02BBD8:
                    jsr      (display_dos_error)
lbC02BBE2:
                    bsr      lbC02BBEA
                    moveq    #ERROR,d0
                    rts
lbC02BBEA:
                    jsr      (close_file)
                    lea      (lbL02BC14,pc),a0
                    jmp      (lbC026AAC)
LoadEffectTab_MSG:
                    dc.b     'Load EffectTable',0
                    even
lbL02BC0E:
                    dc.l     0
lbW02BC12:
                    dc.w     0
lbL02BC14:
                    dc.l     0
lbL02BC18:
                    dc.l     0,$10000
lbC02BC20:
                    move.w   (lbW02B710,pc),d0
                    bne.b    lbC02BC2E
                    jmp      (error_no_entries)
lbC02BC2E:
                    move.l   #lbC02BC3A,(current_cmd_ptr)
                    rts
lbC02BC3A:
                    lea      (SaveEffectTab_MSG,pc),a0
                    moveq    #DIR_EFFECTS,d0
                    jsr      (display_file_requester)
                    bpl.b    lbC02BC4A
                    rts
lbC02BC4A:
                    lea      (lbL02BCDA,pc),a0
                    move.w   (lbW02B710,pc),d0
                    mulu.w   #131,d0
                    jsr      (lbC026A6A)
                    bmi.b    lbC02BCAA
                    move.l   a0,a1
                    lea      (lbL01D89C),a0
                    move.w   (lbW02B710,pc),d0
                    bsr      lbC02B984
                    lea      (filename_to_load),a0
                    jsr      (open_file_for_writing)
                    bmi.b    lbC02BCA0
                    lea      (OK_E_MSG,pc),a0
                    moveq    #4,d0
                    jsr      (write_to_file)
                    bmi.b    lbC02BCA0
                    move.l   (lbL02BCDA,pc),a0
                    move.l   (lbL02BCDE,pc),d0
                    jsr      (write_to_file)
                    bmi.b    lbC02BCA0
                    bsr.b    lbC02BCB2
                    moveq    #OK,d0
                    rts
lbC02BCA0:
                    jsr      (display_dos_error)
lbC02BCAA:
                    bsr      lbC02BCB2
                    moveq    #ERROR,d0
                    rts
lbC02BCB2:
                    jsr      (close_file)
                    lea      (lbL02BCDA,pc),a0
                    jmp      (lbC026AAC)
SaveEffectTab_MSG:
                    dc.b     'Save EffectTable',0
                    even
OK_E_MSG:
                    dc.b     'OK_E'
lbL02BCDA:
                    dc.l     0
lbL02BCDE:
                    dc.l     0,$10000
lbC02BCE6:
                    bsr      lbC02B82A
                    bmi.b    lbC02BCFC
                    tst.b    d0
                    bne      lbC02C20A
                    lea      (lbC02BDA2,pc),a0
                    move.w   d1,d0
                    bra      lbC02BD46
lbC02BCFC:
                    rts
lbC02BCFE:
                    bsr      lbC02B82A
                    bmi.b    lbC02BD14
                    tst.b    d0
                    bne      lbC02C20A
                    lea      (lbC02BE18,pc),a0
                    move.w   d1,d0
                    bra      lbC02BD46
lbC02BD14:
                    rts
lbC02BD16:
                    bsr      lbC02B82A
                    bmi.b    lbC02BD2C
                    tst.b    d0
                    bne      lbC02C20A
                    lea      (lbC02BE8E,pc),a0
                    move.w   d1,d0
                    bra      lbC02BD46
lbC02BD2C:
                    rts
lbC02BD2E:
                    bsr      lbC02B82A
                    bmi.b    lbC02BD44
                    tst.b    d0
                    bne      lbC02C20A
                    lea      (lbC02BEB4,pc),a0
                    move.w   d1,d0
                    bra      lbC02BD46
lbC02BD44:
                    rts
lbC02BD46:
                    move.l   a0,a1
                    cmp.w    (lbW02B710,pc),d0
                    bcc.b    lbC02BD76
                    lea      (lbL01D89C),a0
                    move.w   d0,(lbW02BD78)
                    move.w   d0,d1
                    sub.w    (lbW02B70E,pc),d0
                    bmi.b    lbC02BD76
                    add.w    d1,d1
                    add.w    d1,d1
                    move.l   (a0,d1.w),d1
                    beq.b    lbC02BD76
                    move.l   d1,a0
                    moveq    #0,d1
                    addi.w   #17,d0
                    jmp      (a1)
lbC02BD76:
                    rts
lbW02BD78:
                    dc.w     0
lbC02BD7A:
                    move.l   a0,a1
                    move.w   d0,d1
                    lea      (lbL01D89C),a0
                    move.w   (lbW02BD78,pc),d0
                    move.w   d0,d2
                    sub.w    (lbW02B70E,pc),d0
                    addi.w   #17,d0
                    add.w    d2,d2
                    add.w    d2,d2
                    move.l   (a0,d2.w),d2
                    beq.b    lbC02BDA0
                    move.l   d2,a0
                    jmp      (a1)
lbC02BDA0:
                    rts
lbC02BDA2:
                    move.w   d0,(lbW02BE0E)
                    move.w   d1,(lbW02BE10)
                    move.l   a0,(lbL02BE12)
lbC02BDB4:
                    lea      (lbB02BE16,pc),a0
                    move.l   (lbL02BE12,pc),a1
                    moveq    #0,d0
                    move.b   (1,a1),d0
                    lea      (alpha_numeric_table),a1
                    move.b   (a1,d0.w),(a0)
                    moveq    #11,d0
                    move.w   (lbW02BE0E,pc),d1
                    moveq    #2,d2
                    moveq    #2,d3
                    move.w   (lbW02BE10,pc),d4
                    moveq    #1,d5
                    jsr      (lbC0264DE)
                    move.w   d0,d2
                    move.w   d1,d3
                    move.b   (lbB02BE16,pc),d0
                    jsr      (lbC01F094)
                    bmi.b    lbC02BDB4
                    move.l   (lbL02BE12,pc),a0
                    move.b   d0,(1,a0)
                    move.w   d2,d0
                    move.w   d3,d1
                    lea      (lbC02BEB4,pc),a0
                    lea      (lbC02BDA2,pc),a1
                    lea      (lbC02BE18,pc),a2
                    bra      lbC02BEDA
lbW02BE0E:
                    dc.w     0
lbW02BE10:
                    dc.w     0
lbL02BE12:
                    dc.l     0
lbB02BE16:
                    dcb.b    2,0
lbC02BE18:
                    move.w   d0,(lbW02BE84)
                    move.w   d1,(lbW02BE86)
                    move.l   a0,(lbL02BE88)
lbC02BE2A:
                    lea      (lbB02BE8C,pc),a0
                    move.l   (lbL02BE88,pc),a1
                    moveq    #0,d0
                    move.b   (2,a1),d0
                    lea      (alpha_numeric_table),a1
                    move.b   (a1,d0.w),(a0)
                    moveq    #16,d0
                    move.w   (lbW02BE84,pc),d1
                    moveq    #2,d2
                    moveq    #2,d3
                    move.w   (lbW02BE86,pc),d4
                    moveq    #1,d5
                    jsr      (lbC0264DE)
                    move.w   d0,d2
                    move.w   d1,d3
                    move.b   (lbB02BE8C,pc),d0
                    jsr      (lbC01F094)
                    bmi.b    lbC02BE2A
                    move.l   (lbL02BE88,pc),a0
                    move.b   d0,(2,a0)
                    move.w   d2,d0
                    move.w   d3,d1
                    lea      (lbC02BDA2,pc),a0
                    lea      (lbC02BE18,pc),a1
                    lea      (lbC02BE8E,pc),a2
                    bra      lbC02BEDA
lbW02BE84:
                    dc.w     0
lbW02BE86:
                    dc.w     0
lbL02BE88:
                    dc.l     0
lbB02BE8C:
                    dcb.b    2,0
lbC02BE8E:
                    move.w   d1,d4
                    move.w   d0,d1
                    lea      (3,a0),a0
                    moveq    #21,d0
                    moveq    #64,d2
                    moveq    #24,d3
                    moveq    #1,d5
                    jsr      (lbC0264DE)
                    lea      (lbC02BE18,pc),a0
                    lea      (lbC02BE8E,pc),a1
                    lea      (lbC02BEB4,pc),a2
                    bra      lbC02BEDA
lbC02BEB4:
                    move.w   d1,d4
                    move.w   d0,d1
                    lea      (67,a0),a0
                    moveq    #53,d0
                    moveq    #64,d2
                    moveq    #24,d3
                    moveq    #1,d5
                    jsr      (lbC0264DE)
                    lea      (lbC02BE8E,pc),a0
                    lea      (lbC02BEB4,pc),a1
                    lea      (lbC02BDA2,pc),a2
lbC02BEDA:
                    movem.l  d0/d1/a0-a2,-(sp)
                    move.w   (lbW02BD78,pc),d0
                    move.w   d0,d1
                    sub.w    (lbW02B70E,pc),d0
                    bsr      lbC02C0B2
                    movem.l  (sp)+,d0/d1/a0-a2
                    tst.b    d0
                    bmi      lbC02BF86
                    tst.b    d1
                    beq.b    lbC02BF24
                    cmpi.b   #1,d1
                    beq.b    lbC02BF2C
                    cmpi.b   #2,d1
                    beq.b    lbC02BF24
                    cmpi.b   #3,d1
                    beq.b    lbC02BF32
                    cmpi.b   #4,d1
                    beq.b    lbC02BF56
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02BF86
lbC02BF24:
                    move.l   a2,a0
                    moveq    #0,d0
                    bra      lbC02BD7A
lbC02BF2C:
                    moveq    #127,d0
                    bra      lbC02BD7A
lbC02BF32:
                    move.l   a1,a0
                    move.w   (lbW02B70E,pc),d0
                    cmp.w    (lbW02BD78,pc),d0
                    bne.b    lbC02BF4A
                    tst.w    d0
                    beq.b    lbC02BF50
                    move.l   a0,-(sp)
                    bsr      lbC02C278
                    move.l   (sp)+,a0
lbC02BF4A:
                    subq.w   #1,(lbW02BD78)
lbC02BF50:
                    moveq    #0,d0
                    bra      lbC02BD7A
lbC02BF56:
                    move.l   a1,a0
                    move.w   (lbW02B710,pc),d0
                    subq.w   #1,d0
                    cmp.w    (lbW02BD78,pc),d0
                    beq.b    lbC02BF80
                    move.w   (lbW02B70E,pc),d0
                    addi.w   #11,d0
                    cmp.w    (lbW02BD78,pc),d0
                    bne.b    lbC02BF7A
                    move.l   a0,-(sp)
                    bsr      lbC02C21A
                    move.l   (sp)+,a0
lbC02BF7A:
                    addq.w   #1,(lbW02BD78)
lbC02BF80:
                    moveq    #0,d0
                    bra      lbC02BD7A
lbC02BF86:
                    rts
lbC02BF88:
                    cmpi.w   #100,(lbW02B710)
                    beq.b    lbC02BFCC
                    move.l   #131,d0
                    move.l   #$10000,d1
                    EXEC     AllocMem
                    tst.l    d0
                    beq.b    lbC02BFD6
                    move.w   (lbW02B710,pc),d1
                    add.w    d1,d1
                    add.w    d1,d1
                    lea      (lbL01D89C),a0
                    move.l   d0,(a0,d1.w)
                    move.l   d0,a0
                    addq.w   #1,(lbW02B710)
                    moveq    #OK,d0
                    rts
lbC02BFCC:
                    jsr      (error_no_more_entries)
                    moveq    #ERROR,d0
                    rts
lbC02BFD6:
                    jsr      (error_no_memory)
                    moveq    #ERROR,d0
                    rts
lbC02BFE0:
                    bsr      lbC02BFE8
                    beq.b    lbC02BFE0
                    rts
lbC02BFE8:
                    move.w   (lbW02B710,pc),d0
                    beq.b    lbC02C01C
                    subq.w   #1,(lbW02B710)
                    move.w   (lbW02B710,pc),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    lea      (lbL01D89C),a0
                    move.l   (a0,d0.w),a1
                    move.l   #131,d0
                    EXEC     FreeMem
                    moveq    #OK,d0
                    rts
lbC02C01C:
                    moveq    #ERROR,d0
                    rts
lbC02C020:
                    move.w   (lbW02B710,pc),d0
                    bne.b    lbC02C038
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02C052
lbC02C038:
                    subq.w   #1,(lbW02B710)
                    move.l   a0,a1
                    move.l   #131,d0
                    EXEC     FreeMem
lbC02C052:
                    rts
lbC02C054:
                    bsr      lbC02C05C
                    bra      lbC02C06E
lbC02C05C:
                    moveq    #76,d0
                    moveq    #15,d1
                    move.w   (lbW02B710,pc),d2
                    moveq    #3,d3
                    jmp      (draw_short_ascii_decimal_number)
lbC02C06E:
                    tst.w    (lbW02B70E)
                    bpl.b    lbC02C07C
                    clr.w    (lbW02B70E)
lbC02C07C:
                    move.w   (lbW02B710,pc),d0
                    subi.w   #12,d0
                    cmp.w    (lbW02B70E,pc),d0
                    bgt.b    lbC02C096
                    tst.w    d0
                    bpl.b    lbC02C090
                    moveq    #0,d0
lbC02C090:
                    move.w   d0,(lbW02B70E)
lbC02C096:
                    moveq    #0,d0
                    move.w   (lbW02B70E,pc),d1
                    moveq    #12-1,d2
lbC02C09E:
                    movem.w  d0-d2,-(sp)
                    bsr.b    lbC02C0B2
                    movem.w  (sp)+,d0-d2
                    addq.w   #1,d0
                    addq.w   #1,d1
                    dbra     d2,lbC02C09E
                    rts
lbC02C0B2:
                    addi.w   #17,d0
                    cmp.w    (lbW02B710,pc),d1
                    bcc      lbC02C1D4
                    move.w   d0,(lbW02C186)
                    lea      (xxFROMxTOxIFx_MSG,pc),a1
                    moveq    #0,d0
                    move.w   d1,d0
                    divu.w   #10,d0
                    move.b   (lbB02C13E,pc,d0.w),(1,a1)
                    swap     d0
                    move.b   (lbB02C13E,pc,d0.w),(2,a1)
                    add.w    d1,d1
                    add.w    d1,d1
                    lea      (lbL01D89C),a0
                    move.l   (a0,d1.w),a0
                    moveq    #0,d0
                    move.b   (1,a0),d0
                    move.b   (lbB02C13E,pc,d0.w),(9,a1)
                    moveq    #0,d0
                    move.b   (2,a0),d0
                    move.b   (lbB02C13E,pc,d0.w),(14,a1)
                    lea      (3,a0),a2
                    lea      (19,a1),a3
                    bsr.b    lbC02C162
                    lea      (67,a0),a2
                    lea      (51,a1),a3
                    bsr.b    lbC02C162
                    move.l   a0,-(sp)
                    move.l   a1,a0
                    moveq    #2,d0
                    move.w   (lbW02C186,pc),d1
                    jsr      (draw_text)
                    move.l   (sp)+,a0
                    tst.b    (a0)
                    beq.b    lbC02C13C
                    moveq    #2,d0
                    move.w   (lbW02C186,pc),d1
                    moveq    #4,d2
                    jmp      (invert_chars)
lbC02C13C:
                    rts
lbB02C13E:
                    dc.b     '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
lbC02C162:
                    moveq    #23-1,d1
lbC02C164:
                    move.b   (a2)+,(a3)+
                    beq.b    lbC02C176
                    dbra     d1,lbC02C164
                    tst.b    (a2)
                    beq.b    lbC02C180
                    move.b   #$83,(a3)+
                    rts
lbC02C176:
                    subq.w   #1,a3
                    moveq    #32,d2
lbC02C17A:
                    move.b   d2,(a3)+
                    dbra     d1,lbC02C17A
lbC02C180:
                    move.b   #' ',(a3)+
                    rts
lbW02C186:
                    dc.w     0
xxFROMxTOxIFx_MSG:
                    dc.b     ' xx FROM x TO x IF xxxxxxxxxxxxxxxxxxxxxxxl THEN V=xxxxxxxxxxxxxxxxxxxxxxxl',0
lbC02C1D4:
                    move.w   d0,-(sp)
                    jsr      (own_blitter)
                    move.l   #$1000000,(BLTCON0,a6)
                    move.w   #4,(BLTDMOD,a6)
                    lea      (main_screen+2),a0
                    move.w   (sp)+,d0
                    mulu.w   #(SCREEN_BYTES*8),d0
                    adda.l   d0,a0
                    move.l   a0,(BLTDPTH,a6)
                    move.w   #(8*64)+((SCREEN_BYTES/2)-(4/2)),(BLTSIZE,a6)
                    jmp      (disown_blitter)
lbC02C20A:
                    tst.b    d0
                    bmi.b    lbC02C214
                    bsr      lbC02C21A
                    bra.b    lbC02C218
lbC02C214:
                    bra      lbC02C278
lbC02C218:
                    rts
lbC02C21A:
                    move.w   (lbW02B710,pc),d0
                    sub.w    (lbW02B70E,pc),d0
                    cmpi.w   #12,d0
                    bls.b    lbC02C276
                    lea      (main_screen+((136*80)+2)),a0
                    jsr      (own_blitter)
                    move.l   #$9F00000,(BLTCON0,a6)
                    moveq    #-1,d0
                    move.l   d0,(BLTAFWM,a6)
                    move.l   #$40004,(BLTAMOD,a6)
                    move.l   a0,(BLTDPTH,a6)
                    lea      ((SCREEN_BYTES*8),a0),a0
                    move.l   a0,(BLTAPTH,a6)
                    move.w   #(88*64)+((SCREEN_BYTES/2)-(4/2)),(BLTSIZE,a6)
                    jsr      (disown_blitter)
                    addq.w   #1,(lbW02B70E)
                    moveq    #11,d0
                    move.w   (lbW02B70E,pc),d1
                    addi.w   #11,d1
                    bra      lbC02C0B2
lbC02C276:
                    rts
lbC02C278:
                    tst.w    (lbW02B70E)
                    beq.b    lbC02C2CA
                    lea      (main_screen+17916),a0
                    jsr      (own_blitter)
                    move.l   #$9F00002,(BLTCON0,a6)
                    moveq    #-1,d0
                    move.l   d0,(BLTAFWM,a6)
                    move.l   #$40004,(BLTAMOD,a6)
                    move.l   a0,(BLTAPTH,a6)
                    lea      ((SCREEN_BYTES*8),a0),a0
                    move.l   a0,(BLTDPTH,a6)
                    move.w   #(88*64)+((SCREEN_BYTES/2)-(4/2)),(BLTSIZE,a6)
                    jsr      (disown_blitter)
                    subq.w   #1,(lbW02B70E)
                    moveq    #0,d0
                    move.w   (lbW02B70E,pc),d1
                    bra      lbC02C0B2
lbC02C2CA:
                    rts
lbC02C2CC:
                    subi.w   #12,(lbW02B70E)
                    bra      lbC02C06E
lbC02C2D8:
                    addi.w   #12,(lbW02B70E)
                    bra      lbC02C06E
lbC02C2E4:
                    move.w   (lbW02B710,pc),d0
                    beq      lbC02C424
                    moveq    #76,d0
                    moveq    #11,d1
                    moveq    #'_',d2
                    jsr      (draw_one_char)
                    moveq    #61,d0
                    moveq    #12,d1
                    moveq    #'_',d2
                    moveq    #16,d3
                    jsr      (draw_repeated_char)
                    moveq    #0,d0
                    move.l   d0,(lbL02C9B4)
                    moveq    #1,d0
                    move.l   d0,(lbL02C9FC)
                    clr.l    (lbB02C9E4)
                    clr.l    (lbB02C9C0)
                    clr.l    (lbB02C9D8)
                    clr.l    (lbB02CA08)
                    clr.l    (lbB02C9CC)
                    sf       (lbB02C470)
                    move.w   (lbW01BC6E),d7
                    bra      lbC02C418
lbC02C344:
                    movem.l  d4-d7/a2-a5,-(sp)
                    moveq    #77,d0
                    moveq    #8,d1
                    move.w   (lbW02C9E6),d2
                    moveq    #2,d3
                    jsr      (draw_short_ascii_decimal_number)
                    movem.l  (sp)+,d4-d7/a2-a5
                    lea      (OK_PatternList),a0
                    move.w   (lbW02C9E6,pc),d0
                    add.w    d0,d0
                    add.w    d0,d0
                    move.l   (a0,d0.w),d0
                    bne.b    lbC02C386
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra      lbC02C42C
lbC02C386:
                    move.l   d0,a5
                    move.w   (a5)+,d6
                    move.w   d6,(lbW02C9C2)
                    clr.l    (lbB02CA20)
                    bra.b    lbC02C40E
lbC02C398:
                    movem.l  d4-d7/a2-a5,-(sp)
                    moveq    #75,d0
                    moveq    #10,d1
                    move.w   (lbW02CA22,pc),d2
                    jsr      (draw_2_digits_hex_number)
                    movem.l  (sp)+,d4-d7/a2-a5
                    lea      (OK_ChannelsModes),a4
                    moveq    #1,d0
                    move.l   d0,(lbB02CA14)
                    moveq    #4,d5
                    bra.b    lbC02C3FE
lbC02C3C0:
                    tst.w    (a4)+
                    bne.b    lbC02C3D6
                    moveq    #1,d0
                    move.l   d0,(lbL02C9F0)
                    moveq    #0,d0
                    move.l   d0,(lbL02C9A8)
                    bra.b    lbC02C3F2
lbC02C3D6:
                    moveq    #0,d0
                    move.l   d0,(lbL02C9F0)
                    moveq    #1,d0
                    move.l   d0,(lbL02C9A8)
                    bsr      lbC02C472
                    bmi.b    lbC02C42C
                    addq.w   #1,(lbW02CA16)
lbC02C3F2:
                    bsr      lbC02C472
                    bmi.b    lbC02C42C
                    addq.w   #1,(lbW02CA16)
lbC02C3FE:
                    dbra     d5,lbC02C3C0
                    subq.w   #1,(lbW02CA16)
                    addq.w   #1,(lbW02CA22)
lbC02C40E:
                    dbra     d6,lbC02C398
                    addq.w   #1,(lbW02C9E6)
lbC02C418:
                    dbra     d7,lbC02C344
                    bsr      lbC02C45E
                    moveq    #0,d0
                    rts
lbC02C424:
                    jmp      (error_no_entries)
lbC02C42C:
                    bsr      lbC02C45E
                    tst.b    (lbB02C470)
                    beq.b    lbC02C45A
                    move.w   (lbW02C538,pc),(lbW02B70E)
                    jsr      (lbC02C054,pc)
                    lea      (lbC02BE8E,pc),a0
                    move.b   (lbB02C53A,pc),d0
                    beq.b    lbC02C452
                    lea      (lbC02BEB4,pc),a0
lbC02C452:
                    move.w   (lbW02C538,pc),d0
                    bra      lbC02BD46
lbC02C45A:
                    moveq    #ERROR,d0
                    rts
lbC02C45E:
                    moveq    #76,d0
                    moveq    #11,d1
                    move.w   (lbW02CA16),d2
                    jmp      (draw_one_char_alpha_numeric)
lbB02C470:
                    dc.b     0
                    even
lbC02C472:
                    move.b   (a5),(lbB02C9DB)
                    move.b   (1,a5),(lbB02C9CF)
                    move.b   (2,a5),(lbB02C536)
                    move.b   (3,a5),(lbB02CA0B)
                    lea      (lbL01D89C),a3
                    move.w   (lbW02B710,pc),d4
                    clr.w    (lbW02C538)
                    bra.b    lbC02C4FC
lbC02C4A2:
                    move.l   (a3)+,d0
                    bne.b    lbC02C4B8
                    move.w   #$F00,(_CUSTOM|COLOR00)
                    bra.b    lbC02C506
lbC02C4B8:
                    move.l   d0,a2
                    move.b   (1,a2),d0
                    cmp.b    (lbB02C536,pc),d0
                    bne.b    lbC02C4F6
                    movem.l  d4-d7/a2-a5,-(sp)
                    lea      (3,a2),a0
                    bsr      lbC02C548
                    movem.l  (sp)+,d4-d7/a2-a5
                    bmi.b    lbC02C50A
                    tst.l    d0
                    beq.b    lbC02C4F6
                    movem.l  d4-d7/a2-a5,-(sp)
                    lea      (67,a2),a0
                    bsr      lbC02C548
                    movem.l  (sp)+,d4-d7/a2-a5
                    bmi.b    lbC02C516
                    move.b   (2,a2),(2,a5)
                    move.b   d0,(3,a5)
lbC02C4F6:
                    addq.w   #1,(lbW02C538)
lbC02C4FC:
                    dbra     d4,lbC02C4A2
                    addq.w   #4,a5
                    moveq    #OK,d0
                    rts
lbC02C506:
                    moveq    #ERROR,d0
                    rts
lbC02C50A:
                    sf       (lbB02C53A)
                    bsr      lbC02C522
                    bra.b    lbC02C506
lbC02C516:
                    st       (lbB02C53A)
                    bsr      lbC02C522
                    bra.b    lbC02C506
lbC02C522:
                    moveq    #61,d0
                    moveq    #12,d1
                    moveq    #16,d2
                    jsr      (draw_text_with_blanks)
                    st       (lbB02C470)
                    rts
lbB02C536:
                    dc.b     0
                    even
lbW02C538:
                    dc.w     0
lbB02C53A:
                    dc.b     0
                    even
lbL02C53C:
                    dc.l     0
lbL02C540:
                    dc.l     0,$10000
lbC02C548:
                    move.l   sp,(lbL02C568)
                    bsr.b    lbC02C56C
                    tst.b    (a0)
                    bne.b    lbC02C558
                    moveq    #OK,d1
                    rts
lbC02C558:
                    lea      (EOLexpected_MSG,pc),a0
lbC02C560:
                    move.l   (lbL02C568,pc),sp
                    moveq    #ERROR,d1
                    rts
lbL02C568:
                    dc.l     0
lbC02C56C:
                    lea      (lbL01DA2C),a5
lbC02C572:
                    clr.w    (2,a5)
lbC02C576:
                    bsr      lbC02CA24
lbC02C57A:
                    moveq    #0,d1
                    move.b   (a0)+,d1
                    add.w    d1,d1
                    move.w   (lbW02C588,pc,d1.w),d1
                    jmp      (lbW02C588,pc,d1.w)
lbW02C588:
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C57A-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C57A-lbW02C588
                    dc.w     lbC02C7FA-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C7EC-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C794-lbW02C588
                    dc.w     lbC02C7D0-lbW02C588,lbC02C7B4-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C7C2-lbW02C588,lbC02C788-lbW02C588,lbC02C7DE-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C832-lbW02C588,lbC02C816-lbW02C588,lbC02C854-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C808-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C7FA-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588,lbC02C788-lbW02C588,lbC02C788-lbW02C588
                    dc.w     lbC02C788-lbW02C588
lbC02C788:
                    cmpa.l   #lbL01DA2C,a5
                    bne.b    lbC02C7AC
                    subq.w   #1,a0
                    bra.b    lbC02C79C
lbC02C794:
                    cmpa.l   #lbL01DA2C,a5
                    beq.b    lbC02C7A4
lbC02C79C:
                    bsr      lbC02C91C
                    moveq    #OK,d1
                    rts
lbC02C7A4:
                    lea      (Toomuch_MSG,pc),a0
                    bra      lbC02C560
lbC02C7AC:
                    lea      (expected_MSG,pc),a0
                    bra      lbC02C560
lbC02C7B4:
                    move.w   #lbC02C942-lbC02C56C,d5
                    moveq    #2,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C7C2:
                    move.w   #lbC02C946-lbC02C56C,d5
                    moveq    #2,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C7D0:
                    move.w   #lbC02CE8C-lbC02C56C,d5
                    moveq    #3,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C7DE:
                    move.w   #lbC02CEA4-lbC02C56C,d5
                    moveq    #3,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C7EC:
                    move.w   #lbC02C950-lbC02C56C,d5
                    moveq    #4,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C7FA:
                    move.w   #lbC02C94C-lbC02C56C,d5
                    moveq    #4,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C808:
                    move.w   #lbC02C954-lbC02C56C,d5
                    moveq    #4,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C816:
                    move.b   (a0),d1
                    cmpi.b   #'<',d1
                    beq.b    lbC02C876
                    cmpi.b   #'>',d1
                    beq.b    lbC02C886
                    move.w   #lbC02C958-lbC02C56C,d5
                    moveq    #1,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C832:
                    move.b   (a0),d1
                    cmpi.b   #'=',d1
                    beq.b    lbC02C876
                    cmpi.b   #'>',d1
                    beq.b    lbC02C896
                    cmpi.b   #'<',d1
                    beq.b    lbC02C8A6
                    move.w   #lbC02C962-lbC02C56C,d5
                    moveq    #1,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C854:
                    move.b   (a0),d1
                    cmpi.b   #'=',d1
                    beq.b    lbC02C886
                    cmpi.b   #'<',d1
                    beq.b    lbC02C896
                    cmpi.b   #'>',d1
                    beq.b    lbC02C8B6
                    move.w   #lbC02C96C-lbC02C56C,d5
                    moveq    #1,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C876:
                    addq.w   #1,a0
                    move.w   #lbC02C976-lbC02C56C,d5
                    moveq    #1,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C886:
                    addq.w   #1,a0
                    move.w   #lbC02C980-lbC02C56C,d5
                    moveq    #1,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C896:
                    addq.w   #1,a0
                    move.w   #lbC02C98A-lbC02C56C,d5
                    moveq    #1,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C8A6:
                    addq.w   #1,a0
                    move.w   #lbC02C994-lbC02C56C,d5
                    moveq    #5,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C8B6:
                    addq.w   #1,a0
                    move.w   #lbC02C99A-lbC02C56C,d5
                    moveq    #5,d6
                    bsr      lbC02C8C6
                    bra      lbC02C576
lbC02C8C6:
                    lea      (4,a5),a4
                    move.w   (2,a5),d7
                    beq.b    lbC02C90C
                    lea      (-8,a4,d7.w),a4
                    cmp.w    (a4),d6
                    bgt.b    lbC02C90A
                    beq.b    lbC02C8F0
                    move.w   (2,a4),d2
                    move.l   (4,a4),d1
                    lea      (lbC02C56C,pc),a1
                    jsr      (a1,d2.w)
                    subq.w   #8,(2,a5)
                    bra.b    lbC02C8C6
lbC02C8F0:
                    move.w   (2,a4),d2
                    move.l   (4,a4),d1
                    lea      (lbC02C56C,pc),a1
                    jsr      (a1,d2.w)
                    move.l   d0,(4,a4)
                    move.w   d5,(2,a4)
                    rts
lbC02C90A:
                    addq.w   #8,a4
lbC02C90C:
                    move.w   d6,(a4)
                    move.w   d5,(2,a4)
                    move.l   d0,(4,a4)
                    addq.w   #8,(2,a5)
                    rts
lbC02C91C:
                    lea      (4,a5),a4
lbC02C920:
                    move.w   (2,a5),d7
                    beq.b    lbC02C940
                    lea      (-8,a4,d7.w),a3
                    move.w   (2,a3),d2
                    move.l   (4,a3),d1
                    lea      (lbC02C56C,pc),a1
                    jsr      (a1,d2.w)
                    subq.w   #8,(2,a5)
                    bra.b    lbC02C920
lbC02C940:
                    rts
lbC02C942:
                    add.l    d1,d0
                    rts
lbC02C946:
                    sub.l    d0,d1
                    move.l   d1,d0
                    rts
lbC02C94C:
                    or.l     d1,d0
                    rts
lbC02C950:
                    and.l    d1,d0
                    rts
lbC02C954:
                    eor.l    d1,d0
                    rts
lbC02C958:
                    cmp.l    d0,d1
                    seq      d0
                    ext.w    d0
                    ext.l    d0
                    rts
lbC02C962:
                    cmp.l    d0,d1
                    slt      d0
                    ext.w    d0
                    ext.l    d0
                    rts
lbC02C96C:
                    cmp.l    d0,d1
                    sgt      d0
                    ext.w    d0
                    ext.l    d0
                    rts
lbC02C976:
                    cmp.l    d0,d1
                    sle      d0
                    ext.w    d0
                    ext.l    d0
                    rts
lbC02C980:
                    cmp.l    d0,d1
                    sge      d0
                    ext.w    d0
                    ext.l    d0
                    rts
lbC02C98A:
                    cmp.l    d0,d1
                    sne      d0
                    ext.w    d0
                    ext.l    d0
                    rts
lbC02C994:
                    lsl.l    d0,d1
                    move.l   d1,d0
                    rts
lbC02C99A:
                    lsr.l    d0,d1
                    move.l   d1,d0
                    rts
lbC02C9A0:
                    move.l   (lbL02C9A8,pc),d1
                    bra      lbC02CE74
lbL02C9A8:
                    dc.l     0
lbC02C9AC:
                    move.l   (lbL02C9B4,pc),d1
                    bra      lbC02CE74
lbL02C9B4:
                    dc.l     0
lbC02C9B8:
                    move.l   (lbB02C9C0,pc),d1
                    bra      lbC02CE74
lbB02C9C0:
                    dc.b     0,0
lbW02C9C2:
                    dc.w     0
lbC02C9C4:
                    move.l   (lbB02C9CC,pc),d1
                    bra      lbC02CE74
lbB02C9CC:
                    dc.b     0,0,0
lbB02C9CF:
                    dc.b     0
lbC02C9D0:
                    move.l   (lbB02C9D8,pc),d1
                    bra      lbC02CE74
lbB02C9D8:
                    dc.b     0,0,0
lbB02C9DB:
                    dc.b     0
lbC02C9DC:
                    move.l   (lbB02C9E4,pc),d1
                    bra      lbC02CE74
lbB02C9E4:
                    dc.b     0,0
lbW02C9E6:
                    dc.w     0
lbC02C9E8:
                    move.l   (lbL02C9F0,pc),d1
                    bra      lbC02CE74
lbL02C9F0:
                    dc.l     0
lbC02C9F4:
                    move.l   (lbL02C9FC,pc),d1
                    bra      lbC02CE74
lbL02C9FC:
                    dc.l     0
lbC02CA00:
                    move.l   (lbB02CA08,pc),d1
                    bra      lbC02CE74
lbB02CA08:
                    dc.b     0,0,0
lbB02CA0B:
                    dc.b     0
lbC02CA0C:
                    move.l   (lbB02CA14,pc),d1
                    bra      lbC02CE74
lbB02CA14:
                    dc.b     0,0
lbW02CA16:
                    dc.w     0
lbC02CA18:
                    move.l   (lbB02CA20,pc),d1
                    bra      lbC02CE74
lbB02CA20:
                    dc.b     0,0
lbW02CA22:
                    dc.w     0
lbC02CA24:
                    sf       (a5)
                    sf       (1,a5)
lbC02CA2A:
                    moveq    #0,d0
                    move.b   (a0)+,d0
                    add.w    d0,d0
                    move.w   (lbW02CA38,pc,d0.w),d0
                    jmp      (lbW02CA38,pc,d0.w)
lbW02CA38:
                    dc.w     lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38
                    dc.w     lbC02CA2A-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38
                    dc.w     lbC02CA2A-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38
                    dc.w     lbC02CE16-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CCF0-lbW02CA38,lbC02CC4E-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CE16-lbW02CA38,lbC02CE5E-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC38-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CCB6-lbW02CA38,lbC02CCB6-lbW02CA38
                    dc.w     lbC02CCB6-lbW02CA38,lbC02CCB6-lbW02CA38,lbC02CCB6-lbW02CA38
                    dc.w     lbC02CCB6-lbW02CA38,lbC02CCB6-lbW02CA38,lbC02CCB6-lbW02CA38
                    dc.w     lbC02CCB6-lbW02CA38,lbC02CCB6-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC82-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02C9A0-lbW02CA38,lbC02CC46-lbW02CA38,lbC02C9AC-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02C9B8-lbW02CA38,lbC02C9C4-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02C9D0-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02C9DC-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02C9E8-lbW02CA38,lbC02C9F4-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CA00-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CA0C-lbW02CA38
                    dc.w     lbC02CA18-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02C9A0-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02C9AC-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02C9B8-lbW02CA38,lbC02C9C4-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02C9D0-lbW02CA38,lbC02CC46-lbW02CA38,lbC02C9DC-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02C9E8-lbW02CA38
                    dc.w     lbC02C9F4-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CA00-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CA0C-lbW02CA38,lbC02CA18-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC3E-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
                    dc.w     lbC02CC46-lbW02CA38,lbC02CC46-lbW02CA38
lbC02CC38:
                    not.b    (a5)
                    bra      lbC02CA2A
lbC02CC3E:
                    not.b    (1,a5)
                    bra      lbC02CA2A
lbC02CC46:
                    lea      (Valueexpected_MSG,pc),a0
                    bra      lbC02C560
lbC02CC4E:
                    moveq    #0,d1
                    move.b   (a0)+,d1
                    subi.b   #'0',d1
                    bmi      lbC02CC7A
                    cmpi.b   #1,d1
                    bhi      lbC02CC7A
lbC02CC62:
                    move.b   (a0)+,d0
                    subi.b   #'0',d0
                    bmi      lbC02CE72
                    cmpi.b   #1,d0
                    bhi      lbC02CE72
                    add.l    d1,d1
                    add.b    d0,d1
                    bra.b    lbC02CC62
lbC02CC7A:
                    lea      (expected_MSG0,pc),a0
                    bra      lbC02C560
lbC02CC82:
                    moveq    #0,d1
                    move.b   (a0)+,d1
                    subi.b   #'0',d1
                    bmi      lbC02CCAE
                    cmpi.b   #7,d1
                    bhi      lbC02CCAE
lbC02CC96:
                    move.b   (a0)+,d0
                    subi.b   #'0',d0
                    bmi      lbC02CE72
                    cmpi.b   #7,d0
                    bhi      lbC02CE72
                    lsl.l    #3,d1
                    add.b    d0,d1
                    bra.b    lbC02CC96
lbC02CCAE:
                    lea      (expected_MSG1,pc),a0
                    bra      lbC02C560
lbC02CCB6:
                    subq.w   #1,a0
                    moveq    #0,d0
                    moveq    #0,d1
                    moveq    #'0',d3
                    moveq    #9,d4
                    move.b   (a0)+,d1
                    sub.b    d3,d1
                    bmi      lbC02CCE8
                    cmp.b    d4,d1
                    bhi      lbC02CCE8
lbC02CCCE:
                    move.b   (a0)+,d0
                    sub.b    d3,d0
                    bmi      lbC02CE72
                    cmp.b    d4,d0
                    bhi      lbC02CE72
                    add.l    d1,d1
                    move.l   d1,d2
                    lsl.l    #2,d1
                    add.l    d2,d1
                    add.l    d0,d1
                    bra.b    lbC02CCCE
lbC02CCE8:
                    lea      (expected_MSG2,pc),a0
                    bra      lbC02C560
lbC02CCF0:
                    moveq    #0,d0
                    moveq    #0,d1
                    move.b   (a0)+,d1
                    move.b   (hexa_truth_table,pc,d1.w),d1
                    bmi      lbC02CE0E
lbC02CCFE:
                    move.b   (a0)+,d0
                    move.b   (hexa_truth_table,pc,d0.w),d0
                    bmi      lbC02CE72
                    lsl.l    #4,d1
                    add.b    d0,d1
                    bra.b    lbC02CCFE
hexa_truth_table:
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0,1,2,3,4,5,6
                    dc.b     7,8,9,-1,-1,-1,-1,-1,-1,-1,$A,$B,$C,$D,$E,$F,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,$A,$B,$C,$D,$E,$F,0,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
                    dc.b     -1,-1,-1,-1,-1,-1,-1,-1,-1
lbC02CE0E:
                    lea      (fexpected_MSG,pc),a0
                    bra      lbC02C560
lbC02CE16:
                    move.b   (-1,a0),d2
                    moveq    #0,d1
                    moveq    #4,d3
lbC02CE1E:
                    move.b   (a0)+,d0
                    beq      lbC02CE56
                    cmpi.b   #10,d0
                    beq      lbC02CE56
                    cmp.b    d2,d0
                    beq.b    lbC02CE3A
                    lsl.l    #8,d1
                    move.b   d0,d1
                    dbra     d3,lbC02CE1E
                    bra.b    lbC02CE56
lbC02CE3A:
                    cmp.b    (a0)+,d2
                    bne.b    lbC02CE4A
                    lsl.l    #8,d1
                    move.b   d2,d1
                    dbra     d3,lbC02CE1E
                    bra      lbC02CE56
lbC02CE4A:
                    cmpi.w   #4,d3
                    beq      lbC02CE56
                    bra      lbC02CE72
lbC02CE56:
                    lea      (ErrorinString_MSG,pc),a0
                    bra      lbC02C560
lbC02CE5E:
                    move.l   a5,-(sp)
                    move.w   (2,a5),d1
                    lea      (4,a5,d1.w),a5
                    bsr      lbC02C572
                    move.l   (sp)+,a5
                    move.l   d0,d1
                    bra.b    lbC02CE74
lbC02CE72:
                    subq.w   #1,a0
lbC02CE74:
                    tst.b    (a5)
                    beq.b    lbC02CE7A
                    neg.l    d1
lbC02CE7A:
                    tst.b    (1,a5)
                    beq.b    lbC02CE82
                    not.l    d1
lbC02CE82:
                    move.l   d1,d0
                    moveq    #0,d1
                    rts
lbC02CE8C:
                    move.w   d0,d2
                    move.w   d1,d3
                    swap     d0
                    swap     d1
                    mulu.w   d2,d1
                    mulu.w   d3,d0
                    mulu.w   d3,d2
                    add.w    d1,d0
                    swap     d0
                    clr.w    d0
                    add.l    d2,d0
                    rts
lbC02CEA4:
                    exg      d0,d1
                    moveq    #0,d4
                    tst.l    d1
                    beq.b    lbC02CEC6
                    bpl.b    lbC02CEB2
                    addq.w   #1,d4
                    neg.l    d1
lbC02CEB2:
                    tst.l    d0
                    bpl.b    lbC02CEBA
                    addq.w   #1,d4
                    neg.l    d0
lbC02CEBA:
                    bsr.b    lbC02CECE
                    btst     #0,d4
                    beq.b    lbC02CEC4
                    neg.l    d0
lbC02CEC4:
                    rts
lbC02CEC6:
                    lea      (ZeroDivision_MSG,pc),a0
                    bra      lbC02C560
lbC02CECE:
                    swap     d1
                    tst.w    d1
                    bne.b    lbC02CEF0
                    swap     d1
                    move.w   d1,d3
                    move.w   d0,d2
                    clr.w    d0
                    swap     d0
                    divu.w   d3,d0
                    move.l   d0,d1
                    swap     d0
                    move.w   d2,d1
                    divu.w   d3,d1
                    move.w   d1,d0
                    clr.w    d1
                    swap     d1
                    rts
lbC02CEF0:
                    swap     d1
                    move.l   d1,d3
                    move.l   d0,d1
                    clr.w    d1
                    swap     d1
                    swap     d0
                    clr.w    d0
                    moveq    #15,d2
lbC02CF00:
                    add.l    d0,d0
                    addx.l   d1,d1
                    cmp.l    d1,d3
                    bhi.b    lbC02CF0C
                    sub.l    d3,d1
                    addq.w   #1,d0
lbC02CF0C:
                    dbra     d2,lbC02CF00
                    rts
expected_MSG0:
                    dc.b     '0/1 expected',0
EOLexpected_MSG:
                    dc.b     'EOL expected',0
expected_MSG:
                    dc.b     '")" expected',0
Toomuch_MSG:
                    dc.b     'Too much ")"',0
Valueexpected_MSG:
                    dc.b     'Value expected',0
expected_MSG1:
                    dc.b     '0-7 expected',0
expected_MSG2:
                    dc.b     '0-9 expected',0
fexpected_MSG:
                    dc.b     '0-f expected',0
ErrorinString_MSG:
                    dc.b     'Error in String',0
ZeroDivision_MSG:
                    dc.b     'Zero-Division',0
                    even

; ===========================================================================
open_input_device:
                    subq.w   #4,sp
                    movem.l  d6/d7/a3/a5/a6,-(sp)
                    move.l   d0,d7
                    move.l   a0,a5
                    moveq    #0,d6
                    moveq    #0,d0
                    sub.l    a0,a0
                    jsr      (lbC02D1E4,pc)
                    move.l   d0,a3
                    move.l   a3,d0
                    beq.b    lbC02D00A
                    move.l   a3,a0
                    moveq    #48,d0
                    jsr      (lbC02D274,pc)
                    move.l   d0,(20,sp)
                    beq.b    lbC02D004
                    move.l   d0,a1
                    lea      (inputdevice_MSG,pc),a0
                    moveq    #0,d0
                    move.l   d0,d1
                    EXEC     OpenDevice
                    tst.b    d0
                    bne.b    lbC02CFFC
                    move.l   d7,d0
                    move.l   (20,sp),a0
                    move.w   d0,(28,a0)
                    move.l   a5,(40,a0)
                    move.l   a0,a1
                    EXEC     DoIO
                    tst.b    d0
                    bne.b    lbC02CFF4
                    moveq    #1,d6
lbC02CFF4:
                    move.l   (20,sp),a1
                    EXEC     CloseDevice
lbC02CFFC:
                    move.l   (20,sp),a0
                    jsr      (lbC02D1B4,pc)
lbC02D004:
                    move.l   a3,a0
                    jsr      (lbC02D170,pc)
lbC02D00A:
                    move.w   d6,d0
                    movem.l  (sp)+,d6/d7/a3/a5/a6
                    addq.w   #4,sp
                    rts
inputdevice_MSG:
                    dc.b     'input.device',0
                    even
lbC02D022:
                    movem.l  a4/a5,-(sp)
                    move.l   a0,a5
                    moveq    #9,d0
                    bsr      open_input_device
                    tst.w    d0
                    beq.b    lbC02D03E
                    move.l   a5,d0
                    bra.b    lbC02D040
lbC02D03E:
                    moveq    #0,d0
lbC02D040:
                    movem.l  (sp)+,a4/a5
                    rts
lbC02D046:
                    movem.l  a4/a5,-(sp)
                    move.l   a0,a5
                    move.l   a5,a0
                    moveq    #10,d0
                    bsr      open_input_device
                    movem.l  (sp)+,a4/a5
                    rts

; ===========================================================================
setup_screen:
                    subq.w   #4,sp
                    movem.l  a2-a6,-(sp)
                    move.l   a0,a5
                    moveq    #44,d0
                    jsr      (alloc_mem_block,pc)
                    move.l   d0,(20,sp)
                    tst.l    d0
                    beq      .err_mem
                    lea      our_screen_struct,a0
                    INT      OpenScreen
                    move.l   (20,sp),a0
                    move.l   d0,(a0)
                    beq.b    .error_screen
                    moveq    #10,d1
                    DOS      Delay
                    move.l   GFXBase,a0
                    move.l   (20,sp),a1
                    move.l   (gb_ActiView,a0),(40,a1)
                    sub.l    a1,a1
                    GFX      LoadView
                    GFX      WaitTOF
                    GFX      WaitTOF
                    move.l   GFXBase,a0
                    move.l   (20,sp),a1
                    move.l   (gb_copinit,a0),(36,a1)
                    lea      (_CUSTOM|COP1LCH),a0
                    move.l   a5,(a0)
                    move.l   a1,d0
                    bra.b    .all_ok
.error_screen:
                    move.l   (20,sp),a0
                    jsr      (free_mem_block,pc)
.err_mem:
                    moveq    #0,d0
.all_ok:
                    movem.l  (sp)+,a2-a6
                    addq.w   #4,sp
                    rts

; ===========================================================================
restore_screen:
                    move.l   (screen_mem_block),a0
                    movem.l  a1/a4-a6,-(sp)
                    move.l   a0,a5
                    movea.l  (40,a5),a1
                    cmpa.w   #0,a1
                    beq.b    .no_view
                    GFX      LoadView
                    GFX      WaitTOF
                    GFX      WaitTOF
.no_view:
                    lea      (_CUSTOM|COP1LCH),a0
                    move.l   (36,a5),(a0)
                    moveq    #5,d1
                    DOS      Delay
                    move.l   (a5),a0
                    INT      CloseScreen
                    move.l   a5,a0
                    jsr      (free_mem_block,pc)
                    movem.l  (sp)+,a1/a4-a6
                    rts

; ===========================================================================
get_screen_metrics:
                    movem.l  d7/a4/a5,-(sp)
                    moveq    #0,d6
                    moveq    #0,d7
                    move.l   #sc_SIZEOF,d0
                    jsr      (alloc_mem_block,pc)
                    move.l   d0,a5
                    move.l   a5,d0
                    beq.b    .err_mem
                    move.l   a5,a0
                    move.l   #sc_SIZEOF,d0
                    moveq    #WBENCHSCREEN,d1
                    ; workbench screen
                    sub.l    a1,a1
                    jsr      (get_current_screen_data,pc)
                    tst.l    d0
                    beq.b    .err_screen
                    moveq    #0,d7
                    move.w   (sc_RastPort+rp_TxHeight,a5),d7
                    subq.l   #8,d7
                    moveq    #0,d6
                    move.w   (sc_Width,a5),d6
.err_screen:
                    move.l   a5,a0
                    jsr      (free_mem_block,pc)
.err_mem:
                    move.l   d7,d0
                    move.l   d6,d1
                    movem.l  (sp)+,d7/a4/a5
                    rts

; ===========================================================================
lbC02D170:
                    movem.l  a5/a6,-(sp)
                    move.l   a0,a5
                    tst.l    (10,a5)
                    beq.b    lbC02D186
                    move.l   a5,a1
                    EXEC     RemPort
lbC02D186:
                    move.b   #$FF,(8,a5)
                    moveq    #-1,d0
                    move.l   d0,(20,a5)
                    moveq    #0,d0
                    move.b   (15,a5),d0
                    EXEC     FreeSignal
                    move.l   a5,a1
                    moveq    #34,d0
                    EXEC     FreeMem
                    movem.l  (sp)+,a5/a6
                    rts
lbC02D1B4:
                    move.l   a0,a1
                    move.b   #$FF,(8,a1)
                    move.w   #$FFFF,a0
                    move.l   a0,(20,a1)
                    move.l   a0,(24,a1)
                    moveq    #0,d0
                    move.w   (18,a1),d0
                    EXEC     FreeMem
                    rts
lbC02D1E4:
                    movem.l  d6/d7/a3/a5/a6,-(sp)
                    move.l   d0,d7
                    move.l   a0,a5
                    moveq    #-1,d0
                    EXEC     AllocSignal
                    move.b   d0,d6
                    ext.w    d6
                    ext.l    d6
                    move.l   d6,d0
                    addq.l   #1,d0
                    bne.b    lbC02D206
                    moveq    #0,d0
                    bra      lbC02D266
lbC02D206:
                    moveq    #34,d0
                    move.l   #$10001,d1
                    EXEC     AllocMem
                    move.l   d0,a3
                    tst.l    d0
                    bne.b    lbC02D220
                    move.l   d6,d0
                    EXEC     FreeSignal
                    bra.b    lbC02D264
lbC02D220:
                    lea      (10,a3),a0
                    move.l   a5,(a0)+
                    move.b   d7,(9,a3)
                    move.b   #4,(8,a3)
                    clr.b    (a0)+
                    move.b   d6,(a0)+
                    sub.l    a1,a1
                    EXEC     FindTask
                    move.l   d0,(16,a3)
                    move.l   a5,d0
                    beq.b    lbC02D24A
                    move.l   a3,a1
                    EXEC     AddPort
                    bra.b    lbC02D264
lbC02D24A:
                    lea      (24,a3),a0
                    move.l   a0,(20,a3)
                    lea      (20,a3),a0
                    move.l   a0,(28,a3)
                    clr.l    (24,a3)
                    move.b   #2,(32,a3)
lbC02D264:
                    move.l   a3,d0
lbC02D266:
                    movem.l  (sp)+,d6/d7/a3/a5/a6
                    rts
lbC02D274:
                    movem.l  d7/a3/a5/a6,-(sp)
                    move.l   d0,d7
                    move.l   a0,a5
                    move.l   a5,d0
                    bne.b    lbC02D284
                    moveq    #0,d0
                    bra.b    lbC02D2AE
lbC02D284:
                    move.l   d7,d0
                    move.l   #$10001,d1
                    EXEC     AllocMem
                    move.l   d0,a3
                    tst.l    d0
                    beq.b    lbC02D2AC
                    move.b   #5,(8,a3)
                    clr.b    (9,a3)
                    move.l   a5,(14,a3)
                    move.w   d7,(18,a3)
lbC02D2AC:
                    move.l   a3,d0
lbC02D2AE:
                    movem.l  (sp)+,d7/a3/a5/a6
                    rts

; ===========================================================================
alloc_mem_block:
                    move.l   #$10001,d1
                    movem.l  d2/d3/a2/a6,-(sp)
                    move.l   d1,d3
                    and.l    #$FFFEFFFF,d1
                    addq.l   #4,d0
                    move.l   d0,d2
                    EXEC     AllocMem
                    tst.l    d0
                    beq.b    .error
                    move.l   d0,a2
                    btst     #16,d3
                    beq.b    .no_clear
                    move.l   a2,a0
                    move.l   d2,d0
                    bsr      clear_mem_block
.no_clear:
                    move.l   d2,(a2)+
                    move.l   a2,d0
.error:
                    movem.l  (sp)+,d2/d3/a2/a6
                    rts

; ===========================================================================
free_mem_block:
                    move.l   a0,d0
                    beq.b    .empty_param
                    subq.w   #4,a0
                    move.l   a0,a1
                    move.l   (a1),d0
                    EXEC     FreeMem
.empty_param:
                    rts

; ===========================================================================
clear_mem_block:
                    move.l   a0,d1
                    beq.b    .error
                    btst     #0,d1
                    beq      .odd_address_start
                    subq.l   #1,d0
                    bcs.b    .error
                    sf       (a0)+
.odd_address_start:
                    move.l   d2,-(sp)
                    moveq    #0,d2
                    moveq    #32,d1
.loop:
                    sub.l    d1,d0
                    bcs.b    .done
                REPT 8
                    move.l   d2,(a0)+
                ENDR
                    bra.b    .loop
.done:
                    add.l    d1,d0
                    bra.b    .go
.remaining_bytes:
                    sf       (a0)+
.go:
                    dbra     d0,.remaining_bytes
                    move.l   (sp)+,d2
.error:
                    rts

; ===========================================================================
get_current_screen_data:
                    subq.w   #4,sp
                    movem.l  d6/d7/a3/a5/a6,-(sp)
                    move.l   d1,d6
                    move.l   d0,d7
                    move.l   a1,a3
                    move.l   a0,a5
                    move.l   IntBase,a0
                    move.w   (LIB_VERSION,a0),d0
                    moveq    #37,d1
                    cmp.w    d1,d0
                    bcs.b    .old_intuition
                    moveq    #WBENCHSCREEN,d0
                    cmp.w    d0,d6
                    bne.b    .old_intuition
                    move.l   a3,d0
                    beq.b    .new_intuition
.old_intuition:
                    moveq    #0,d0
                    move.w   d7,d0
                    moveq    #0,d1
                    move.w   d6,d1
                    move.l   a5,a0
                    move.l   a3,a1
                    INT      GetScreenData
                    tst.l    d0
                    beq.b    .error
                    move.l   a5,a0
                    bra.b    .ok
.error:
                    sub.l    a0,a0
.ok:
                    move.l   a0,d0
                    bra.b    .ret
.new_intuition:
                    lea      (workbench_name,pc),a0
                    INT      LockPubScreen
                    move.l   d0,(20,sp)
                    beq.b    .ret
                    moveq    #0,d1
                    move.w   d7,d1
                    move.l   d0,a0
                    move.l   d1,d0
                    move.l   a5,a1
                    EXEC     CopyMem
                    lea      (workbench_name,pc),a0
                    move.l   (20,sp),a1
                    INT      UnlockPubScreen
                    move.l   (20,sp),d0
.ret:
                    movem.l  (sp)+,d6/d7/a3/a5/a6
                    addq.w   #4,sp
                    rts
workbench_name:
                    dc.b     'Workbench',0
                    even

; ===========================================================================
                    section  data,data
lbW01737C:
                    dc.w     11
                    dc.l     lbC0208FA
                    dc.w     2
                    dc.l     lbC01EA3E
                    dc.w     1
                    dc.l     lbC01EA32
                    dc.w     14
                    dc.l     lbC029E1A
                    dc.w     0
lbW017396:
                    dc.w     2
                    dc.l     lbW017984
                    dc.w     1
                    dc.l     ascii_MSG0
                    dc.w     3
                    dc.l     lbB017594
                    dc.w     0
                    dc.l     0,0,0
ascii_MSG0:
                    dc.b     CMD_SET_MAIN_SCREEN
                    dc.b     CMD_END
main_menu_text:
                    dc.b     CMD_CLEAR_MAIN_MENU
                    dc.b     CMD_TEXT,1,0,'Current Song:',0
                    dc.b     CMD_TEXT,1,1,'New  Pos..:',0
                    dc.b     CMD_TEXT,1,2,'Load Patt.:',0
                    dc.b     CMD_TEXT,1,3,'Save Len..:',0
                    dc.b     CMD_TEXT,1,4,'Pref Ins. Del.',0
                    dc.b     CMD_TEXT,1,5,'Exit Speed:',0
                    dc.b     CMD_TEXT,6,6,'SLen.:',0
                    dc.b     CMD_SUB_COMMAND,0
                    dc.l     wb_cli_text_ptr
                    dc.b     CMD_TEXT,16,0,'Editor:',0
                    dc.b     CMD_TEXT,16,1,'Play Song MidiMode:',0
                    dc.b     CMD_TEXT,16,2,'Play Patt Copy Cut',0
                    dc.b     CMD_TEXT,16,3,'Edit.:    Replc. Mix It',0
                    dc.b     CMD_TEXT,16,4,'Poly.:    NoteUp NoDown',0
                    dc.b     CMD_TEXT,16,5,'Quant:    OctaUp OcDown',0
                    dc.b     CMD_TEXT,16,6,'PLen.:    ChInst ChaEff',0
                    dc.b     CMD_TEXT,40,0,'Current Sample:',0
                    dc.b     CMD_TEXT,40,1,'Name: --------------------',0
                    dc.b     CMD_TEXT,40,2,'Len.:         Load  Clear',0
                    dc.b     CMD_TEXT,40,6,'Mode:',0
                    dc.b     CMD_TEXT,54,3,'Save  Clear',0
                    dc.b     CMD_TEXT,54,4,'Edit   All',0
                    dc.b     CMD_TEXT,54,5,'Copy   Mix',0
                    dc.b     CMD_TEXT,54,6,'Swap  ClrCB',0
                    dc.b     CMD_TEXT,67,0,'Memory:',0
                    dc.b     CMD_SUB_COMMAND,0
                    dc.l     lbL01FE5A
                    dc.b     CMD_SUB_COMMAND,0
                    dc.l     lbL01FEC0
                    dc.b     CMD_TEXT,71,5,'S',0
                    dc.b     CMD_TEXT,71,6,'C',0
                    dc.b     CMD_END
                    even
wb_cli_text_ptr:
                    dc.l     CLI_MSG
CLI_MSG:
                    dc.b     CMD_TEXT,1,6,'CLI',0
                    dc.b     CMD_END
WB_MSG:
                    dc.b     CMD_TEXT,1,6,'WB',0
                    dc.b     CMD_END
                    even
lbB017594:
                    dc.l     lbB0175A6
                    dc.b     0,1,1,1,4,1
                    dc.l     lbC020DCE
                    dc.l     0
lbB0175A6:
                    dc.l     lbB0175B8
                    dc.b     0,1,1,2,4,1
                    dc.l     load_song
                    dc.l     0
lbB0175B8:
                    dc.l     lbB0175CA
                    dc.b     0,1,1,3,4,1
                    dc.l     lbC02145E
                    dc.l     0
lbB0175CA:
                    dc.l     lbB0175DC
                    dc.b     0,1,1,4,4,1
                    dc.l     lbC01E0AA
                    dc.l     0
lbB0175DC:
                    dc.l     lbB0175EE
                    dc.b     0,1,1,5,4,1
                    dc.l     lbC0245D0
                    dc.l     0
lbB0175EE:
                    dc.l     lbB017600
                    dc.b     0,1,1,6,4,1
                    dc.l     go_to_cli_workbench
                    dc.l     0
lbB017600:
                    dc.l     lbB017612
                    dc.b     0,1,6,1,9,1
                    dc.l     lbC022028
                    dc.l     lbC022044
lbB017612:
                    dc.l     lbB017624
                    dc.b     0,1,6,2,9,1
                    dc.l     lbC022058
                    dc.l     lbC02207C
lbB017624:
                    dc.l     lbB017636
                    dc.b     0,1,6,3,9,1
                    dc.l     lbC0220CE
                    dc.l     lbC022098
lbB017636:
                    dc.l     lbB017648
                    dc.b     0,1,6,4,4,1
                    dc.l     lbC0220E4
                    dc.l     0
lbB017648:
                    dc.l     lbB01765A
                    dc.b     0,1,11,4,4,1
                    dc.l     lbC02210C
                    dc.l     0
lbB01765A:
                    dc.l     lbB01766C
                    dc.b     0,1,6,5,9,1
                    dc.l     lbC022000
                    dc.l     lbC022014
lbB01766C:
                    dc.l     lbB01767E
                    dc.b     0,1,6,6,9,1
                    dc.l     lbC022168
                    dc.l     lbC022136
lbB01767E:
                    dc.l     lbB017690
                    dc.b     0,1,16,1,9,1
                    dc.l     play_song
                    dc.l     0
lbB017690:
                    dc.l     lbB0176A2
                    dc.b     0,1,16,2,9,1
                    dc.l     play_pattern
                    dc.l     0
lbB0176A2:
                    dc.l     lbB0176B4
                    dc.b     16,1,16,3,9,1
                    dc.l     lbC01F96C
                    dc.l     0
lbB0176B4:
                    dc.l     lbB0176C6
                    dc.b     0,1,16,4,9,1
                    dc.l     lbC01FA4A
                    dc.l     lbC01FA4E
lbB0176C6:
                    dc.l     lbB0176D8
                    dc.b     0,1,16,5,9,1
                    dc.l     lbC01FBBC
                    dc.l     lbC01FBB8
lbB0176D8:
                    dc.l     lbB0176EA
                    dc.b     0,1,16,6,9,1
                    dc.l     lbC022170
                    dc.l     lbC02216C
lbB0176EA:
                    dc.l     lbB0176FC
                    dc.b     16,1,26,1,13,1
                    dc.l     lbC01F9BC
                    dc.l     0
lbB0176FC:
                    dc.l     lbB01770E
                    dc.b     16,1,26,2,4,1
                    dc.l     lbC01F51C
                    dc.l     0
lbB01770E:
                    dc.l     lbB017720
                    dc.b     16,1,31,2,3,1
                    dc.l     lbC01F532
                    dc.l     0
lbB017720:
                    dc.l     lbB017732
                    dc.b     16,1,35,2,4,1
                    dc.l     lbC01FA06
                    dc.l     0
lbB017732:
                    dc.l     lbB017744
                    dc.b     16,1,26,3,6,1
                    dc.l     lbC01F5C8
                    dc.l     0
lbB017744:
                    dc.l     lbB017756
                    dc.b     16,1,33,3,6,1
                    dc.l     lbC01F5D2
                    dc.l     0
lbB017756:
                    dc.l     lbB017768
                    dc.b     16,1,26,4,6,1
                    dc.l     lbC01F790
                    dc.l     lbC01F788
lbB017768:
                    dc.l     lbB01777A
                    dc.b     16,1,33,4,6,1
                    dc.l     lbC01F7BA
                    dc.l     lbC01F7B2
lbB01777A:
                    dc.l     lbB01778C
                    dc.b     16,1,26,5,6,1
                    dc.l     lbC01F7DE
                    dc.l     lbC01F7D6
lbB01778C:
                    dc.l     lbB01779E
                    dc.b     16,1,33,5,6,1
                    dc.l     lbC01F80A
                    dc.l     lbC01F802
lbB01779E:
                    dc.l     lbB0177B0
                    dc.b     0,1,26,6,6,1
                    dc.l     lbC01F88E
                    dc.l     0
lbB0177B0:
                    dc.l     lbB0177C2
                    dc.b     0,1,33,6,6,1
                    dc.l     lbC01F8E8
                    dc.l     lbC01E0B6
lbB0177C2:
                    dc.l     lbB0177D4
                    dc.b     0,1,40,1,26,1
                    dc.l     lbC021E38
                    dc.l     lbC021E54
lbB0177D4:
                    dc.l     lbB0177E6
                    dc.b     0,1,40,5,8,1
                    dc.l     lbC021E6C
                    dc.l     lbC021E88
lbB0177E6:
                    dc.l     lbB0177F8
                    dc.b     0,1,40,6,7,1
                    dc.l     lbC021EA2
                    dc.l     lbC021EF4
lbB0177F8:
                    dc.l     lbB01780A
                    dc.b     0,1,54,2,4,1
                    dc.l     lbC02191E,0
lbB01780A:
                    dc.l     lbB01781C
                    dc.b     0,1,54,3,4,1
                    dc.l     lbC021C72
                    dc.l     0
lbB01781C:
                    dc.l     lbB01782E
                    dc.b     0,1,54,4,4,1
                    dc.l     lbC01E09E
                    dc.l     0
lbB01782E:
                    dc.l     lbB017840
                    dc.b     0,1,54,5,4,1
                    dc.l     lbC0216DC
                    dc.l     0
lbB017840:
                    dc.l     lbB017852
                    dc.b     0,1,54,6,4,1
                    dc.l     lbC02189C
                    dc.l     0
lbB017852:
                    dc.l     lbB017864
                    dc.b     0,1,60,2,5,1
                    dc.l     lbC02168E
                    dc.l     0
lbB017864:
                    dc.l     lbB017876
                    dc.b     0,1,60,3,5,2
                    dc.l     lbC02163C
                    dc.l     0
lbB017876:
                    dc.l     lbB017888
                    dc.b     0,1,60,5,5,1
                    dc.l     lbC02177E
                    dc.l     0
lbB017888:
                    dc.l     lbB01789A
                    dc.b     0,1,60,6,5,1
                    dc.l     lbC01E096
                    dc.l     0
lbB01789A:
                    dc.l     lbL0178AC
                    dc.b     16,1,67,5,3,1
                    dc.l     increase_replay_type
                    dc.l     decrease_replay_type
lbL0178AC:
                    dc.l     lbB0178BE
                    dc.b     16,1,71,5,1,2
                    dc.l     lbC022202
                    dc.l     lbC02220C
lbB0178BE:
                    dc.l     lbB0178D0
                    dc.b     16,1,72,5,1,2
                    dc.l     lbC022220
                    dc.l     0
lbB0178D0:
                    dc.l     lbB0178E2
                    dc.b     16,1,73,5,1,2
                    dc.l     lbC022224
                    dc.l     0
lbB0178E2:
                    dc.l     lbB0178F4
                    dc.b     16,1,74,5,1,2
                    dc.l     lbC022228
                    dc.l     0
lbB0178F4:
                    dc.l     lbB017906
                    dc.b     16,1,75,5,1,2
                    dc.l     lbC02222C
                    dc.l     0
lbB017906:
                    dc.l     lbB017918
                    dc.b     16,1,76,5,1,2
                    dc.l     lbC022230
                    dc.l     0
lbB017918:
                    dc.l     lbB01792A
                    dc.b     16,1,77,5,1,2
                    dc.l     lbC022234
                    dc.l     0
lbB01792A:
                    dc.l     lbB01793C
                    dc.b     16,1,78,5,1,2
                    dc.l     lbC022238
                    dc.l     0
lbB01793C:
                    dc.l     lbB01794E
                    dc.b     16,1,79,5,1,2
                    dc.l     lbC02223C
                    dc.l     0
lbB01794E:
                    dc.l     lbB017960
                    dc.b     16,1,67,1,13,2
                    dc.l     lbC01FE26
                    dc.l     0
lbB017960:
                    dc.l     lbL017972
                    dc.b     16,1,67,3,13,1
                    dc.l     lbC01FE86
                    dc.l     0
lbL017972:
                    dc.l     0
                    dc.b     32,1,0,7,80,24
                    dc.l     lbC01E9DC
                    dc.l     0
lbW017984:
                    dc.w     10,0
                    dc.l     lbW0179BE
                    dc.w     10,$100
                    dc.l     lbW017A58
                    dc.w     10,$200
                    dc.l     lbW017AF2
                    dc.w     10,$400
                    dc.l     lbW017B8E
                    dc.w     10,$1000
                    dc.l     lbW017B6C
                    dc.w     10,$800
                    dc.l     lbW017BC0
                    dc.w     10,$A00
                    dc.l     lbW017BCE
                    dc.w     0
lbW0179BE:
                    dc.w     2,16
                    dc.l     lbC01F298
                    dc.w     2,17
                    dc.l     lbC01F2B2
                    dc.w     2,18
                    dc.l     lbC01F51C
                    dc.w     2,19
                    dc.l     lbC01F5C8
                    dc.w     2,20
                    dc.l     lbC01F5D2
                    dc.w     2,21
                    dc.l     lbC01F19A
                    dc.w     2,22
                    dc.l     lbC01F1A6
                    dc.w     2,23
                    dc.l     lbC01F1B2
                    dc.w     2,24
                    dc.l     lbC01F1BE
                    dc.w     2,25
                    dc.l     lbC01F1CA
                    dc.w     2,2
                    dc.l     lbC01F96C
                    dc.w     2,31
                    dc.l     lbC01FA6C
                    dc.w     2,32
                    dc.l     lbC01F42C
                    dc.w     2,5
                    dc.l     play_pattern
                    dc.w     2,96
                    dc.l     play_pattern
                    dc.w     4,15
                    dc.l     lbC01F10A
                    dc.w     4,14
                    dc.l     lbC01F142
                    dc.w     4,12
                    dc.l     previous_pattern_row
                    dc.w     4,13
                    dc.l     next_pattern_row
                    dc.w     0
lbW017A58:
                    dc.w     2,18
                    dc.l     lbC01F532
                    dc.w     2,19
                    dc.l     lbC01F6F2
                    dc.w     2,20
                    dc.l     lbC01F846
                    dc.w     2,21
                    dc.l     lbC01F7BA
                    dc.w     2,22
                    dc.l     lbC01F790
                    dc.w     2,23
                    dc.l     lbC01F80A
                    dc.w     2,24
                    dc.l     lbC01F7DE
                    dc.w     2,25
                    dc.l     lbC01F88E
                    dc.w     2,32
                    dc.l     lbC01F3DA
                    dc.w     2,66
                    dc.l     lbC01FA06
                    dc.w     2,69
                    dc.l     lbC01E09E
                    dc.w     2,76
                    dc.l     lbC02191E
                    dc.w     2,80
                    dc.l     increase_replay_type
                    dc.w     2,83
                    dc.l     lbC021C72
                    dc.w     2,31
                    dc.l     lbC01E03E
                    dc.w     4,15
                    dc.l     lbC01F378
                    dc.w     4,14
                    dc.l     lbC01F366
                    dc.w     4,12
                    dc.l     lbC01F39E
                    dc.w     4,13
                    dc.l     lbC01F38C
                    dc.w     0
lbW017AF2:
                    dc.w     2,32
                    dc.l     lbC01F40C
                    dc.w     2,20
                    dc.l     lbC01F82C
                    dc.w     2,21
                    dc.l     lbC01F7B2
                    dc.w     2,22
                    dc.l     lbC01F788
                    dc.w     2,23
                    dc.l     lbC01F802
                    dc.w     2,24
                    dc.l     lbC01F7D6
                    dc.w     2,25
                    dc.l     lbC01F8E8
                    dc.w     2,14
                    dc.l     lbC01F276
                    dc.w     2,15
                    dc.l     lbC01F262
                    dc.w     2,31
                    dc.l     lbC022398
                    dc.w     4,12
                    dc.l     lbC02216C
                    dc.w     4,13
                    dc.l     lbC022170
                    dc.w     6,'0','9',0
                    dc.l     lbC021E2A
                    dc.w     6,'a','z',10
                    dc.l     lbC021E2A
                    dc.w     0
lbW017B6C:
                    dc.w     4,12
                    dc.l     lbC021E54
                    dc.w     4,13
                    dc.l     lbC021E38
                    dc.w     4,15
                    dc.l     lbC01F122
                    dc.w     4,14
                    dc.l     lbC01F160
                    dc.w     0
lbW017B8E:
                    dc.w     2,25
                    dc.l     lbC01E0B6
                    dc.w     2,31
                    dc.l     lbC01E074
                    dc.w     4,15
                    dc.l     lbC01F2FC
                    dc.w     4,14
                    dc.l     lbC01F2D4
                    dc.w     4,13
                    dc.l     lbC01F31E
                    dc.w     4,12
                    dc.l     lbC01F344
                    dc.w     0
lbW017BC0:
                    dc.w     6,'0','9',48
                    dc.l     lbC01F21A
                    dc.w     0
lbW017BCE:
                    dc.w     6,'0','9',0
                    dc.l     lbC01FBDA
                    dc.w     0
patterns_ed_help_text_1:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,0,8,  '- Pattern Editor Help Page 1 --------------------------------------------------',0
                    dc.b     CMD_TEXT,0,10, '- Block Movement -------- - Block Operations ------ - Pattern Movement --------',0
                    dc.b     CMD_TEXT,0,12, '___SPACE  Remove Block    ___F3  Copy Block         ___CURSOR Move Cursor',0
                    dc.b     CMD_TEXT,0,13, 'SH_SPACE  Block Track     ___F4  Replace Block      ___F6-F10 Go to Predefined',0
                    dc.b     CMD_TEXT,0,14, 'AL_SPACE  Block Pattern   ___F5  Mix Block          ___HELP   Go to PolyPos',0
                    dc.b     CMD_TEXT,0,15, 'SH_CURSOR Size Block      SH_F3  Cut Block          AL_CURSOR Prv/Nxt/Size Patt',0
                    dc.b     CMD_TEXT,0,16, 'AM_CURSOR Move Block      SH_F4  Flip Block         CT_CURSLR Go to Track',0
                    dc.b     CMD_TEXT,0,17, 'SH_B      Block Mode      SH_F5  Delete Sample      BK_0-9    Move to Pattern',0
                    dc.b     CMD_TEXT,26,18,'AL_F5  Delete Sample Inst',0
                    dc.b     CMD_TEXT,0,19, '- Octave Settings ------- SH_F6  Note Down          - Misc --------------------',0
                    dc.b     CMD_TEXT,26,20,'AL_F6  Note Down Inst',0
                    dc.b     CMD_TEXT,0,21, '___F1 Set Octave 1+2      SH_F7  Note Up            ___ESC    Play Pattern',0
                    dc.b     CMD_TEXT,0,22, '___F2 Set Octave 2+3      AL_F7  Note Up Inst       ___`      Play Pattern',0
                    dc.b     CMD_TEXT,26,23,'SH_F8  Octave Down        SH_P      Change PlayRout',0
                    dc.b     CMD_TEXT,0,24, '- Samples --------------- AL_F8  Octave Down Inst   AL+BK_0-9 Set Quant',0
                    dc.b     CMD_TEXT,26,25,'SH_F9  Octave Up          SH_HELP   Here I am!',0
                    dc.b     CMD_TEXT,0,26, 'SH_L       Load Sample    AL_F9  Octave Up Inst     AL_HELP   Play Help Page',0
                    dc.b     CMD_TEXT,0,27, 'SH_S       Save Sample    SH_F10 Change Instrument  AM_HELP   Effect Help Page',0
                    dc.b     CMD_TEXT,0,28, 'SH_E       Edit Sample    AL_F10 Change Effect',0
                    dc.b     CMD_TEXT,0,29, 'AL_0-9/a-z Set  Sample    AM_F10 Effect Editor',0
                    dc.b     CMD_TEXT,0,30, 'CT_CURSUD  Add/Sub Sample',0
                    dc.b     CMD_END
patterns_ed_help_text_2:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,23,12,'- Pattern Editor Help Page 2 -----',0
                    dc.b     CMD_TEXT,23,14,'- Edit ---------------------------',0
                    dc.b     CMD_TEXT,23,16,'___TAB Change Edit Mode',0
                    dc.b     CMD_TEXT,23,17,'___BS  Delete Note + Up',0
                    dc.b     CMD_TEXT,23,18,'___RET Insert Note + Down',0
                    dc.b     CMD_TEXT,23,19,'___DEL Clear  Note + Inst',0
                    dc.b     CMD_TEXT,23,20,'SH_DEL Insert Note',0
                    dc.b     CMD_TEXT,23,21,'AL_DEL Clear  Note + Inst + Effect',0
                    dc.b     CMD_TEXT,23,22,'AM_DEL Clear  Effect',0
                    dc.b     CMD_TEXT,23,23,'CT_DEL Like ___DEL + QuantPolyMove',0
                    dc.b     CMD_END
effects_help_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,17,8, '- Effects Help Page --------------------------',0
                    dc.b     CMD_TEXT,17,10,'1 Portamento Down (4) (Period)',0
                    dc.b     CMD_TEXT,17,11,'2 Portamento Up   (4) (Period)',0
                    dc.b     CMD_TEXT,17,13,'A Arpeggio 1      (B) (down, orig,   up)',0
                    dc.b     CMD_TEXT,17,14,'B Arpeggio 2      (B) (orig,   up, orig, down)',0
                    dc.b     CMD_TEXT,17,15,'C Arpeggio 3      (B) (  up,   up, orig)',0
                    dc.b     CMD_TEXT,17,17,'D Slide Down      (B) (Notes)',0
                    dc.b     CMD_TEXT,17,18,'U Slide Up        (B) (Notes)',0
                    dc.b     CMD_TEXT,17,20,'L Slide Down Once (B) (Notes)',0
                    dc.b     CMD_TEXT,17,21,'H Slide Up   Once (B) (Notes)',0
                    dc.b     CMD_TEXT,17,23,'F Set Filter      (B) <>00:ON',0
                    dc.b     CMD_TEXT,17,24,'P Pos Jump        (B)',0
                    dc.b     CMD_TEXT,17,25,'S Speed           (B)',0
                    dc.b     CMD_TEXT,17,26,'V Volume          (B) <=40:DIRECT',0
                    dc.b     CMD_TEXT,17,27,'O Old Volume      (4)   4x:Vol Down      (VO)',0
                    dc.b     CMD_TEXT,41,28,'5x:Vol Up        (VO)',0
                    dc.b     CMD_TEXT,41,29,'6x:Vol Down Once (VO)',0
                    dc.b     CMD_TEXT,41,30,'7x:Vol Up   Once (VO)',0
                    dc.b     CMD_END
                    even
lbW018516:
                    dc.w     0,0,0,0,639,0,0,0,0
                    dc.l     lbC01E37C
fullscreen_copperlist_ntsc_struct:
                    dc.l     copperlist
                    dc.l     -1,main_menu_copper_jump
                    dc.l     -1,pattern_copper_jump
                    dc.l     0
main_copperlist_struct:
                    dc.l     copperlist
                    dc.l     main_menu_copper_jump,main_menu_copper_part,main_menu_copper_back_jump
                    dc.l     pattern_copper_jump,pattern_copper_part,pattern_copper_back_jump
                    dc.l     0
our_window_struct:
                    dc.w     0,0
                    dc.w     172,26
                    dc.b     0,1
                    dc.l     IDCMP_GADGETUP
                    dc.l     WFLG_NOCAREREFRESH|WFLG_ACTIVATE|WFLG_DEPTHGADGET|WFLG_DRAGBAR 
                    dc.l     our_gadget_struct
                    dc.l     0
                    dc.l     oktalyzer_name
                    dc.l     0
                    dc.l     0
                    dc.w     5,5
                    dc.w     -1,-1
                    dc.w     1
oktalyzer_name:
                    dc.b     'Oktalyzer',0
our_gadget_struct:
                    dc.l     0
                    dc.w     8,13
                    dc.w     157,9
                    dc.w     GFLG_GADGHCOMP
                    dc.w     GACT_RELVERIFY
                    dc.w     GTYP_BOOLGADGET
                    dc.l     our_gadget_border_struct
                    dc.l     0
                    dc.l     our_gadget_text_struct
                    dc.l     0
                    dc.l     0
                    dc.W     0
                    dc.l     0
our_gadget_border_struct:
                    dc.w     -1,-1
                    dc.b     1,0
                    dc.b     1
                    dc.b     5
                    dc.l     our_gadget_border_coords
                    dc.l     0
our_gadget_border_coords:
                    dc.w     0,0
                    dc.w     158,0
                    dc.w     158,10
                    dc.w     0,10
                    dc.w     0,0
our_gadget_text_struct:
                    dc.b     1,0
                    dc.b     1
                    dc.b     0
                    dc.w     11,1
                    dc.l     topaz_font_struct
                    dc.l     our_gadget_text
                    dc.w     0,0
our_gadget_text:
                    dc.b     'Restart Oktalyzer',0
topaz_font_struct:
                    dc.l     topaz_name
                    dc.w     8
                    dc.b     0
                    dc.b     0
topaz_name:
                    dc.b     'topaz.font',0
files_sel_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     5,1,90,38,5
                    dc.b     CMD_TEXT,2,10,'Drawer:',0
                    dc.b     CMD_TEXT,2,11,'File..:',0
                    dc.b     CMD_TEXT,2,12,'  Ok   ReRead Parent Delete Cancel',0
                    dc.b     5,63,11,16,3
                    dc.b     CMD_TEXT,63,10,'OkDir',0
                    dc.b     CMD_TEXT,64,12,'Install Delete',0
                    dc.b     5,41,9,20,5
                    dc.b     CMD_TEXT,41,8, 'Format',0
                    dc.b     CMD_TEXT,42,10,'Drive..:',0
                    dc.b     CMD_TEXT,42,11,'Verify.:      Go',0
                    dc.b     CMD_TEXT,42,12,'Clear..:',0
                    dc.b     CMD_TEXT,1,15, 'Directories',0
                    dc.b     5,1,16,38,14
                    dc.b     CMD_TEXT,41,15,'Files',0
                    dc.b     5,41,16,38,14
                    dc.b     CMD_END
                    even
lbW018706:
                    dc.l     lbW018718
                    dc.w     $2801,$110,$260E
                    dc.l     lbC026D32
                    dc.l     lbC026DA6
lbW018718:
                    dc.l     lbW01872A
                    dc.w     $2801,$2910,$260E
                    dc.l     lbC026D32
                    dc.l     lbC026D64
lbW01872A:
                    dc.l     lbW01873C
                    dc.w     $1001,$20A,$2401
                    dc.l     lbC027674
                    dc.w     0,0
lbW01873C:
                    dc.l     lbW01874E
                    dc.w     $1001,$20B,$2401
                    dc.l     lbC027698
                    dc.w     0,0
lbW01874E:
                    dc.l     lbW018760
                    dc.w     $1001,$20C,$601
                    dc.l     lbC026BBC
                    dc.l     0
lbW018760:
                    dc.l     lbW018772
                    dc.w     $1001,$90C,$601
                    dc.l     lbC026F18
                    dc.l     0
lbW018772:
                    dc.l     lbW018784
                    dc.w     $1001,$100C,$601
                    dc.l     lbC0276BC
                    dc.l     0
lbW018784:
                    dc.l     lbW018796
                    dc.w     $1001,$170C,$601
                    dc.l     lbC0276DC
                    dc.l     0
lbW018796:
                    dc.l     lbW0187A8
                    dc.w     $1001,$1E0C,$601
                    dc.l     lbC026BAC
                    dc.l     0
lbW0187A8:
                    dc.l     lbW0187BA
                    dc.w     $1001,$400C,$701
                    dc.l     lbC027CF4
                    dc.l     0
lbW0187BA:
                    dc.l     lbW0187CC
                    dc.w     $1001,$480C,$601
                    dc.l     lbC027DDA
                    dc.l     0
lbW0187CC:
                    dc.l     lbW0187DE
                    dc.b     0,1,42,10,11,1
                    dc.l     increase_trackdisk_unit_number
                    dc.l     decrease_trackdisk_unit_number
lbW0187DE:
                    dc.l     lbW0187F0
                    dc.w     $1001,$2A0B,$B01
                    dc.l     switch_verify_mode
                    dc.l     0
lbW0187F0:
                    dc.l     lbW018802
                    dc.w     $1001,$2A0C,$B01
                    dc.l     switch_clear_mode
                    dc.l     0
lbW018802:
                    dc.w     0,0,$1001,$360A,$603
                    dc.l     format_disk
                    dc.l     0
lbW018814:
                    dc.w     10,0
                    dc.l     lbW01881E
                    dc.w     0
lbW01881E:
                    dc.w     2,5
                    dc.l     lbC026BAC
                    dc.w     2,4
                    dc.l     lbC026BBC
                    dc.w     2,97
                    dc.l     lbC02756A
                    dc.w     2,99
                    dc.l     lbC027532
                    dc.w     0
samples_ed_text:
                    dc.b     12
                    dc.b     4
                    dc.b     CMD_TEXT,1,8, 'Sample Editor',0
                    dc.b     CMD_TEXT,1,10,'Sample Name:',0
                    dc.b     CMD_TEXT,38,9,'Length RepStr RepLen  Mode  BStart  BEnd',0
                    dc.b     9,0,94,13,0
                    dc.l     max_lines
                    dc.b     CMD_TEXT,1,0,'Exit  Mark  Cut    Paste   Change  Change  Delta',0
                    dc.b     CMD_TEXT,1,1,'Swap  All   Copy  Reverse  Volume  Period  Filter',0
                    dc.b     CMD_MOVE_TO_LINE
                    dc.l     max_lines
                    dc.b     CMD_TEXT,58,0,'Monitor  Rate:',0
                    dc.b     CMD_TEXT,58,1,'Sampler  Chan:',0
                    dc.b     CMD_END
                    even
lbW01892C:
                    dc.l     lbW01893E
                    dc.w     $1001,$1A01,$D01
                    dc.l     lbC01F9BC
                    dc.l     0
lbW01893E:
                    dc.l     lbW018950
                    dc.w     1,$2801,$1A01
                    dc.l     lbC028E0E
                    dc.l     lbC028E1C
lbW018950:
                    dc.l     lbW018962
                    dc.w     $1001,$2806,$701
                    dc.l     lbC028E2A
                    dc.l     lbC028E38
lbW018962:
                    dc.l     lbW018974
                    dc.w     $1001,$3602,$401
                    dc.l     lbC028E50
                    dc.l     0
lbW018974:
                    dc.l     lbW018986
                    dc.w     $1001,$3603,$401
                    dc.l     lbC028E58
                    dc.l     0
lbW018986:
                    dc.l     lbW018998
                    dc.w     $1001,$3605,$401
                    dc.l     lbC028E8E
                    dc.l     0
lbW018998:
                    dc.l     lbW0189AA
                    dc.w     $1001,$3606,$401
                    dc.l     lbC028E60
                    dc.l     0
lbW0189AA:
                    dc.l     lbW0189BC
                    dc.w     $1001,$3C02,$501
                    dc.l     lbC028E6A
                    dc.l     0
lbW0189BC:
                    dc.l     lbW0189CE
                    dc.w     $1001,$3C03,$502
                    dc.l     lbC028E74
                    dc.l     0
lbW0189CE:
                    dc.l     lbW0189E0
                    dc.w     $1001,$3C05,$501
                    dc.l     lbC028E7E
                    dc.l     0
lbW0189E0:
                    dc.l     lbW0189F2
                    dc.w     $1001,$3C06,$501
                    dc.l     lbC028E88
                    dc.l     0
lbW0189F2:
                    dc.l     lbW018A04
                    dc.w     $1001,$10A,$2201
                    dc.l     lbC02852A
                    dc.l     0
lbW018A04:
                    dc.l     lbW018A16
                    dc.w     $1001,$100,$401
                    dc.l     lbC0281FE
                    dc.l     0
lbW018A16:
                    dc.l     lbW018A28
                    dc.w     $1001,$101,$401
                    dc.l     lbC02855C
                    dc.l     0
lbW018A28:
                    dc.l     lbW018A3A
                    dc.w     $1001,$700,$402
                    dc.l     lbC02860A
                    dc.l     0
lbW018A3A:
                    dc.l     lbW018A4C
                    dc.w     $1001,$D00,$401
                    dc.l     lbC028614
                    dc.l     lbC02862C
lbW018A4C:
                    dc.l     lbW018A5E
                    dc.w     $1001,$D01,$401
                    dc.l     lbC028692
                    dc.l     0
lbW018A5E:
                    dc.l     lbW018A70
                    dc.w     $1001,$1300,$701
                    dc.l     lbC0286F4
                    dc.l     lbC02879C
lbW018A70:
                    dc.l     lbW018A82
                    dc.w     $1001,$1301,$701
                    dc.l     lbC028868
                    dc.l     0
lbW018A82:
                    dc.l     lbW018A94
                    dc.w     $1001,$1C00,$602
                    dc.l     lbC028F10
                    dc.l     lbC0290FC
lbW018A94:
                    dc.l     lbW018AA6
                    dc.w     $1001,$2400,$602
                    dc.l     lbC029330
                    dc.l     0
lbW018AA6:
                    dc.l     lbL018AB8
                    dc.w     $1001,$2C00,$602
                    dc.l     lbC02997C
                    dc.l     0
lbL018AB8:
                    dc.l     lbL018ACA,$10013A00
                    dc.w     $701
                    dc.l     lbC029AE6
                    dc.l     0
lbL018ACA:
                    dc.l     lbL018ADC,$10013A01
                    dc.w     $701
                    dc.l     lbC029B5A
                    dc.l     0
lbL018ADC:
                    dc.l     lbL018AEE,$14300
                    dc.w     $901
                    dc.l     lbC029DF2
                    dc.l     lbC029DE0
lbL018AEE:
                    dc.l     0,$10014301
                    dc.w     $901
                    dc.l     lbC029E04
                    dc.l     0
lbW018B00:
                    dc.w     10,0
                    dc.l     lbW018B22
                    dc.w     10,$800
                    dc.l     lbW018B54
                    dc.w     10,$100
                    dc.l     lbW018B66
                    dc.w     10,$200
                    dc.l     lbW018BC0
                    dc.w     0
lbW018B22:
                    dc.w     2,5
                    dc.l     lbC0281FE
                    dc.w     2,6
                    dc.l     lbC0289C4
                    dc.w     4,$F
                    dc.l     lbC028ABC
                    dc.w     4,$E
                    dc.l     lbC028AD8
                    dc.w     4,$C
                    dc.l     lbC028AF2
                    dc.w     4,$D
                    dc.l     lbC028B08
                    dc.w     0
lbW018B54:
                    dc.w     4,$30
                    dc.l     lbC0289EE
                    dc.w     4,$2E
                    dc.l     lbC028A58
                    dc.w     0
lbW018B66:
                    dc.w     2,$4C
                    dc.l     lbC028E50
                    dc.w     2,$53
                    dc.l     lbC028E58
                    dc.w     2,$43
                    dc.l     lbC028E8E
                    dc.w     2,$58
                    dc.l     lbC028E60
                    dc.w     2,$4D
                    dc.l     lbC028E7E
                    dc.w     2,$46
                    dc.l     lbC028E88
                    dc.w     4,$F
                    dc.l     lbC028AC0
                    dc.w     4,$E
                    dc.l     lbC028ADC
                    dc.w     4,$C
                    dc.l     lbC028AF6
                    dc.w     4,$D
                    dc.l     lbC028B0C
                    dc.w     2,$1F
                    dc.l     lbC028260
                    dc.w     0
lbW018BC0:
                    dc.w     4,15
                    dc.l     lbC028AC4
                    dc.w     4,14
                    dc.l     lbC028AE0
                    dc.w     4,12
                    dc.l     lbC028AFA
                    dc.w     4,13
                    dc.l     lbC028B10
                    dc.w     6,48,57,0
                    dc.l     lbC028E46
                    dc.w     6,97,122,10
                    dc.l     lbC028E46
                    dc.w     0
samples_ed_help_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,2,13,'- Sample Editor Help Page --------------------------------------------------',0
                    dc.b     CMD_TEXT,2,15,'- Samples ------------- - Repeats --------------------- - Misc -------------',0
                    dc.b     CMD_TEXT,2,17,'SH_L       Load Sample  ___DEL    Clear  Repeats        ___ESC  Exit',0
                    dc.b     CMD_TEXT,2,18,'SH_S       Save Sample  ___CURSOR Set    Repeats        SH_HELP Huhu!',0
                    dc.b     CMD_TEXT,2,19,'SH_C       Copy Sample  SH_CURSOR Set    Repeats fast   ___F1   Set Oct. 0+1',0
                    dc.b     CMD_TEXT,2,20,'SH_X       Swap Samples AL_CURSOR Set    Repeats faster ___F2   Set Oct. 1+2',0
                    dc.b     CMD_TEXT,2,21,'SH_M       Mix  Samples BK_0      Search 0 Left',0
                    dc.b     CMD_TEXT,2,22,'AL_0-9/a-z Set  Sample  BK_.      Search 0 Right',0
                    dc.b     CMD_END
prefs_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,29,8,'Oktalyzer Preferences',0
                    dc.b     CMD_TEXT,1,10,'Misc',0
                    dc.b     5,1,11,25,13
                    dc.b     CMD_TEXT,2,12,'PattFormat:',0
                    dc.b     CMD_TEXT,2,13,'Default PatternLen:',0
                    dc.b     CMD_TEXT,2,15,'Sample Load Mode..:',0
                    dc.b     CMD_TEXT,2,16,'Sample Save Format:',0
                    dc.b     CMD_TEXT,2,18,'MouseRepeat Delay.:',0
                    dc.b     CMD_TEXT,2,19,'MouseRepeat Speed.:',0
                    dc.b     CMD_TEXT,2,21,'Color Set...:',0
                    dc.b     CMD_TEXT,18,22,'RGB RGB',0
                    dc.b     CMD_TEXT,28,10,'Polyphony',0
                    dc.b     5,28,11,12,13
                    dc.b     CMD_TEXT,29,12,'<        >',0
                    dc.b     CMD_TEXT,29,13,'<        >',0
                    dc.b     CMD_TEXT,29,14,'<        >',0
                    dc.b     CMD_TEXT,29,15,'<        >',0
                    dc.b     CMD_TEXT,29,16,'<        >',0
                    dc.b     CMD_TEXT,29,17,'<        >',0
                    dc.b     CMD_TEXT,29,18,'<        >',0
                    dc.b     CMD_TEXT,29,19,'<        >',0
                    dc.b     CMD_TEXT,30,20, '12345678',0
                    dc.b     CMD_TEXT,29,22,'Left-Right',0
                    dc.b     CMD_TEXT,42,10,'IndexPos',0
                    dc.b     5,42,11,8,13
                    dc.b     CMD_TEXT,43,13,'F6:',0
                    dc.b     CMD_TEXT,43,15,'F7:',0
                    dc.b     CMD_TEXT,43,17,'F8:',0
                    dc.b     CMD_TEXT,43,19,'F9:',0
                    dc.b     CMD_TEXT,43,21,'F0:',0
                    dc.b     CMD_TEXT,52,10,'Charset Editor',0
                    dc.b     5,52,11,27,18
                    dc.b     CMD_TEXT,53,20,'Char:',0
                    dc.b     CMD_TEXT,53,22,'OutL. ',   $80,0
                    dc.b     CMD_TEXT,53,23,'UnDo ',$82,' ',$83,0
                    dc.b     CMD_TEXT,53,24,'Paste ',   $81,0
                    dc.b     CMD_TEXT,53,25,'Cut Copy',0
                    dc.b     CMD_TEXT,53,26,'Mirror X',0
                    dc.b     CMD_TEXT,53,27,'Mirror Y',0
                    dc.b     7,62,12,16,16
                    dc.B     CMD_TEXT,2,27,'Load  Save  Use  Old  Cancel',0
                    dc.b     CMD_TEXT,33,25,'ST Load Modes',0
                    dc.b     7,33,26,17,3
                    dc.b     CMD_TEXT,34,27,'Smps:   Trks:',0
                    dc.b     CMD_END
                    even
prefs_help_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,17,14,'- Preferences Help Page ---------------------',0
                    dc.b     CMD_TEXT,17,16,'- Chars ------------------ - Misc -----------',0
                    dc.b     CMD_TEXT,17,18,'___CURSOR Move  CharCursor ___ESC  Cancel',0
                    dc.b     CMD_TEXT,17,19,'SH_CURSOR Shift Char       SH_HELP Look here!',0
                    dc.b     CMD_END
                    even
lbW019080:
                    dc.l     lbW019092
                    dc.w     $1001,$E0C,$201
                    dc.l     lbC02AA68
                    dc.l     0
lbW019092:
                    dc.l     lbW0190A4
                    dc.w     $1001,$110C,$201
                    dc.l     lbC02AA6C
                    dc.l     0
lbW0190A4:
                    dc.l     lbW0190B6
                    dc.w     $1001,$140C,$201
                    dc.l     lbC02AA70
                    dc.l     0
lbW0190B6:
                    dc.l     lbW0190C8
                    dc.w     $1001,$170C,$201
                    dc.l     lbC02AA74
                    dc.l     0
lbW0190C8:
                    dc.l     lbW0190DA
                    dc.w     1,$20D,$1701
                    dc.l     lbC02AAB2
                    dc.l     lbC02AAC4
lbW0190DA:
                    dc.l     lbW0190EC
                    dc.w     1,$20F,$1701
                    dc.l     lbC02AAE6
                    dc.l     lbC02AAF8
lbW0190EC:
                    dc.l     lbW0190FE
                    dc.w     $1001,$210,$1701
                    dc.l     lbC02AB24
                    dc.l     0
lbW0190FE:
                    dc.l     lbW019110
                    dc.w     1,$212,$1701
                    dc.l     lbC02AB54
                    dc.l     lbC02AB66
lbW019110:
                    dc.l     lbW019122
                    dc.w     1,$213,$1701
                    dc.l     lbC02AB88
                    dc.l     lbC02AB9A
lbW019122:
                    dc.l     lbW019134
                    dc.w     1,$215,$F01
                    dc.l     lbC02ABBC
                    dc.l     lbC02ABCE
lbW019134:
                    dc.l     lbW019146
                    dc.w     1,$1215,$102
                    dc.l     lbC02AC42
                    dc.l     lbC02AC76
lbW019146:
                    dc.l     lbW019158
                    dc.w     1,$1315,$102
                    dc.l     lbC02AC46
                    dc.l     lbC02AC7A
lbW019158:
                    dc.l     lbW01916A
                    dc.w     1,$1415,$102
                    dc.l     lbC02AC4A
                    dc.l     lbC02AC7E
lbW01916A:
                    dc.l     lbW01917C
                    dc.w     1,$1615,$102
                    dc.l     lbC02ABDE
                    dc.l     lbC02AC12
lbW01917C:
                    dc.l     lbW01918E
                    dc.w     1,$1715,$102
                    dc.l     lbC02ABE2
                    dc.l     lbC02AC16
lbW01918E:
                    dc.l     lbW0191A0
                    dc.w     1,$1815,$102
                    dc.l     lbC02ABE6
                    dc.l     lbC02AC1A
lbW0191A0:
                    dc.l     lbW0191B2
                    dc.w     1,$1D0C,$101
                    dc.l     lbC02ACF2
                    dc.l     lbC02AD22
lbW0191B2:
                    dc.l     lbW0191C4
                    dc.w     1,$1D0D,$101
                    dc.l     lbC02ACF6
                    dc.l     lbC02AD26
lbW0191C4:
                    dc.l     lbW0191D6
                    dc.w     1,$1D0E,$101
                    dc.l     lbC02ACFA
                    dc.l     lbC02AD2A
lbW0191D6:
                    dc.l     lbW0191E8
                    dc.w     1,$1D0F,$101
                    dc.l     lbC02ACFE
                    dc.l     lbC02AD2E
lbW0191E8:
                    dc.l     lbW0191FA
                    dc.w     1,$1D10,$101
                    dc.l     lbC02AD02
                    dc.l     lbC02AD32
lbW0191FA:
                    dc.l     lbW01920C
                    dc.w     1,$1D11,$101
                    dc.l     lbC02AD06
                    dc.l     lbC02AD36
lbW01920C:
                    dc.l     lbW01921E
                    dc.w     1,$1D12,$101
                    dc.l     lbC02AD0A
                    dc.l     lbC02AD3A
lbW01921E:
                    dc.l     lbW019230
                    dc.w     1,$1D13,$101
                    dc.l     lbC02AD0E
                    dc.l     lbC02AD3E
lbW019230:
                    dc.l     lbW019242
                    dc.w     1,$260C,$101
                    dc.l     lbC02AD22
                    dc.l     lbC02ACF2
lbW019242:
                    dc.l     lbW019254
                    dc.w     1,$260D,$101
                    dc.l     lbC02AD26
                    dc.l     lbC02ACF6
lbW019254:
                    dc.l     lbW019266
                    dc.w     1,$260E,$101
                    dc.l     lbC02AD2A
                    dc.l     lbC02ACFA
lbW019266:
                    dc.l     lbW019278
                    dc.w     1,$260F,$101
                    dc.l     lbC02AD2E
                    dc.l     lbC02ACFE
lbW019278:
                    dc.l     lbW01928A
                    dc.w     1,$2610,$101
                    dc.l     lbC02AD32
                    dc.l     lbC02AD02
lbW01928A:
                    dc.l     lbW01929C
                    dc.w     1,$2611,$101
                    dc.l     lbC02AD36
                    dc.l     lbC02AD06
lbW01929C:
                    dc.l     lbW0192AE
                    dc.w     1,$2612,$101
                    dc.l     lbC02AD3A
                    dc.l     lbC02AD0A
lbW0192AE:
                    dc.l     lbW0192C0
                    dc.w     1,$2613,$101
                    dc.l     lbC02AD3E
                    dc.l     lbC02AD0E
lbW0192C0:
                    dc.l     lbW0192D2
                    dc.w     $1001,$1D16,$A01
                    dc.l     lbC02AD42
                    dc.l     lbC02AD56
lbW0192D2:
                    dc.l     lbW0192E4
                    dc.w     1,$2B0D,$601
                    dc.l     increase_f6_key_line_jump_value
                    dc.l     decrease_f6_key_line_jump_value
lbW0192E4:
                    dc.l     lbW0192F6
                    dc.w     1,$2B0F,$601
                    dc.l     increase_f7_key_line_jump_value
                    dc.l     decrease_f7_key_line_jump_value
lbW0192F6:
                    dc.l     lbW019308
                    dc.w     1,$2B11,$601
                    dc.l     increase_f8_key_line_jump_value
                    dc.l     decrease_f8_key_line_jump_value
lbW019308:
                    dc.l     lbW01931A
                    dc.w     1,$2B13,$601
                    dc.l     increase_f9_key_line_jump_value
                    dc.l     decrease_f9_key_line_jump_value
lbW01931A:
                    dc.l     lbW01932C
                    dc.w     1,$2B15,$601
                    dc.l     increase_f10_key_line_jump_value
                    dc.l     decrease_f10_key_line_jump_value
lbW01932C:
                    dc.l     lbW01933E
                    dc.w     $2001,$350C,$807
                    dc.l     lbC02B1A8
                    dc.l     lbC02B1B0
lbW01933E:
                    dc.l     lbW019350
                    dc.w     1,$3514,$801
                    dc.l     lbC02AF0C
                    dc.l     lbC02AF1E
lbW019350:
                    dc.l     lbW019362
                    dc.w     1,$3B16,$101
                    dc.l     move_char_up
                    dc.l     move_char_down
lbW019362:
                    dc.l     lbW019374
                    dc.w     1,$3A17,$101
                    dc.l     move_char_left
                    dc.l     move_char_right
lbW019374:
                    dc.l     lbW019386
                    dc.w     1,$3C17,$101
                    dc.l     move_char_right
                    dc.l     move_char_left
lbW019386:
                    dc.l     lbW019398
                    dc.w     1,$3B18,$101
                    dc.l     move_char_down
                    dc.l     move_char_up
lbW019398:
                    dc.l     lbW0193AA
                    dc.w     $1001,$3516,$501
                    dc.l     outline_char
                    dc.l     0
lbW0193AA:
                    dc.l     lbW0193BC
                    dc.w     $1001,$3517,$401
                    dc.l     lbC02AFAA
                    dc.l     lbC02AFBE
lbW0193BC:
                    dc.l     lbW0193CE
                    dc.w     $1001,$3518,$501
                    dc.l     lbC02AFD2
                    dc.l     lbC02AFE6
lbW0193CE:
                    dc.l     lbW0193E0
                    dc.w     $1001,$3519,$301
                    dc.l     lbC02B00E
                    dc.l     lbC02B02C
lbW0193E0:
                    dc.l     lbW0193F2
                    dc.w     $1001,$3919,$401
                    dc.l     lbC02AFFA,0
lbW0193F2:
                    dc.l     lbW019404
                    dc.b     16,1,53,26,8,1
                    dc.l     mirror_char_x
                    dc.l     0
lbW019404:
                    dc.l     lbW019416
                    dc.b     16,1,53,27,8,1
                    dc.l     mirror_char_y
                    dc.l     0
lbW019416:
                    dc.l     lbW019428
                    dc.w     $2001,$3E0C,$1010
                    dc.l     lbC02AF7E
                    dc.l     0
lbW019428:
                    dc.l     lbW01943A
                    dc.w     $1001,$11A,$603
                    dc.l     load_prefs
                    dc.l     0
lbW01943A:
                    dc.l     lbW01944C
                    dc.w     $1001,$71A,$603
                    dc.l     save_prefs
                    dc.l     0
lbW01944C:
                    dc.l     lbW01945E
                    dc.w     $1001,$D1A,$503
                    dc.l     lbC02A966
                    dc.l     0
lbW01945E:
                    dc.l     lbW019470
                    dc.w     $1001,$121A,$503
                    dc.l     lbC02A972
                    dc.l     0
lbW019470:
                    dc.l     lbW019482
                    dc.w     $1001,$171A,$803
                    dc.l     lbC02A97A
                    dc.l     0
lbW019482:
                    dc.l     lbW019494
                    dc.w     $1001,$221B,$701
                    dc.l     lbC02AA14
                    dc.l     0
lbW019494:
                    dc.w     0,0,$1001,$2A1B,$701
                    dc.l     lbC02AA1E
                    dc.l     0
lbW0194A6:
                    dc.w     10,0
                    dc.l     lbW0194C0
                    dc.w     10,$100
                    dc.l     lbW0194EA
                    dc.w     10,$700
                    dc.l     lbW019514
                    dc.w     0
lbW0194C0:
                    dc.w     2,5
                    dc.l     lbC02A97A
                    dc.w     4,15
                    dc.l     lbC02AF2E
                    dc.w     4,14
                    dc.l     lbC02AF40
                    dc.w     4,12
                    dc.l     lbC02AF56
                    dc.w     4,13
                    dc.l     lbC02AF6A
                    dc.w     0
lbW0194EA:
                    dc.w     4,15
                    dc.l     move_char_left
                    dc.w     4,14
                    dc.l     move_char_right
                    dc.w     4,12
                    dc.l     move_char_up
                    dc.w     4,13
                    dc.l     move_char_down
                    dc.w     2,31
                    dc.l     lbC02A7DA
                    dc.w     0
lbW019514:
                    dc.w     2,67
                    dc.l     save_font
                    dc.w     0
                    dc.w     0
effects_ed_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,1,8,'Oktalyer Effect Editor',0
                    dc.b     5,1,9,56,5
                    dc.b     CMD_TEXT,4,11,'Add  Sub  Copy  Cut  Paste  Load  Save  DO!!  Exit',0
                    dc.b     CMD_TEXT,59,8,'Status',0
                    dc.b     CMD_TEXT,78,8,'_',0
                    dc.b     CMD_TEXT,61,10,'CurrentLine.: __',0
                    dc.b     CMD_TEXT,61,11,'CurrentChan.:  _',0
                    dc.b     CMD_TEXT,61,12,'________________',0
                    dc.b     5,59,9,20,5
                    dc.b     CMD_TEXT,1,15,'Effect Conversion Filter Term Table',0
                    dc.b     5,1,16,78,14
                    dc.b     CMD_END
lbW0195F4:
                    dc.l     lbW019606
                    dc.w     1,$30A,$503
                    dc.l     lbC02B780
                    dc.l     0
lbW019606:
                    dc.l     lbW019618
                    dc.w     1,$80A,$503
                    dc.l     lbC02B7A4
                    dc.l     0
lbW019618:
                    dc.l     lbW01962A
                    dc.w     $1001,$D0A,$603
                    dc.l     lbC02B8FE
                    dc.l     0
lbW01962A:
                    dc.l     lbW01963C
                    dc.w     $1001,$130A,$503
                    dc.l     lbC02B866
                    dc.l     0
lbW01963C:
                    dc.l     lbW01964E
                    dc.w     $1001,$180A,$703
                    dc.l     lbC02B9BA
                    dc.l     0
lbW01964E:
                    dc.l     lbW019660
                    dc.w     $1001,$1F0A,$603
                    dc.l     lbC02BB16
                    dc.l     0
lbW019660:
                    dc.l     lbW019672
                    dc.w     $1001,$250A,$603
                    dc.l     lbC02BC20
                    dc.l     0
lbW019672:
                    dc.l     lbW019684
                    dc.w     $1001,$2B0A,$603
                    dc.l     lbC02C2E4
                    dc.l     0
lbW019684:
                    dc.l     lbW019696
                    dc.w     $1001,$310A,$603
                    dc.l     lbC02B7DE
                    dc.l     0
lbW019696:
                    dc.l     lbW0196A8
                    dc.w     $2001,$210,$40E
                    dc.l     lbC02B7E6
                    dc.l     lbC02B7EA
lbW0196A8:
                    dc.l     lbW0196BA
                    dc.w     $2001,$910,$50E
                    dc.l     lbC02BCE6
                    dc.l     0
lbW0196BA:
                    dc.l     lbW0196CC
                    dc.w     $2001,$E10,$50E
                    dc.l     lbC02BCFE
                    dc.l     0
lbW0196CC:
                    dc.l     lbW0196DE
                    dc.w     $2001,$1410,$190E
                    dc.l     lbC02BD16
                    dc.l     0
lbW0196DE:
                    dc.w     0,0,$2001,$3410,$190E
                    dc.l     lbC02BD2E
                    dc.l     0
lbW0196F0:
                    dc.w     10,0
                    dc.l     lbW019712
                    dc.w     10,$100
                    dc.l     lbW01972C
                    dc.w     10,$200
                    dc.l     lbW019746
                    dc.w     10,$400
                    dc.l     lbW019760
                    dc.w     0
lbW019712:
                    dc.w     2,5
                    dc.l     lbC02B7DE
                    dc.w     4,12
                    dc.l     lbC02C278
                    dc.w     4,13
                    dc.l     lbC02C21A
                    dc.w     0
lbW01972C:
                    dc.w     2,12
                    dc.l     lbC02C2CC
                    dc.w     2,13
                    dc.l     lbC02C2D8
                    dc.w     2,31
                    dc.l     lbC02B738
                    dc.w     0
lbW019746:
                    dc.w     4,12
                    dc.l     lbC02B7A4
                    dc.w     4,13
                    dc.l     lbC02B780
                    dc.w     2,31
                    dc.l     lbC02B75C
                    dc.w     0
lbW019760:
                    dc.w     2,99
                    dc.l     lbC02B8FE
                    dc.w     2,120
                    dc.l     lbC02B866
                    dc.w     2,105
                    dc.l     lbC02B9BA
                    dc.w     2,108
                    dc.l     lbC02BB16
                    dc.w     2,115
                    dc.l     lbC02BC20
                    dc.w     2,100
                    dc.l     lbC02C2E4
                    dc.w     2,113
                    dc.l     lbC02B7DE
                    dc.w     0
effects_ed_help_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,21,12,'- Effect Editor Help Page ------------',0
                    dc.b     CMD_TEXT,21,14,'- Menu ----- - Movement --------------',0
                    dc.b     CMD_TEXT,21,16,'AM_C   Copy  ___CURSOR UD Scroll',0
                    dc.b     CMD_TEXT,21,17,'AM_X   Cut   SH_CURSOR UD Scroll Page',0
                    dc.b     CMD_TEXT,21,18,'AM_I   Paste AL_CURSOR UD Sub/Add',0
                    dc.b     CMD_TEXT,21,19,'AM_L   Load',0
                    dc.b     CMD_TEXT,21,20,'AM_S   Save  - Help ------------------',0
                    dc.b     CMD_TEXT,21,21,'AM_D   Do',0
                    dc.b     CMD_TEXT,21,22,'AM_Q   Exit  SH_HELP Here you are!',0
                    dc.b     CMD_TEXT,21,23,'___ESC Exit  AL_HELP Compute Help Page',0
                    dc.b     CMD_END
compute_help_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,8,8, '- Compute Help Page --------------------------------------------',0
                    dc.b     CMD_TEXT,8,10,'- Operands - Prio -  - Variables ------------  - Signs ---------',0
                    dc.b     CMD_TEXT,8,12,'<< SHIFT LEFT     5  P  Pattern Number         ~ NOTATION',0
                    dc.b     CMD_TEXT,8,13,'>> SHIFT RIGHT    5  H  Height of Pattern      - NEGATION',0
                    dc.b     CMD_TEXT,8,15,'&  AND            4  S  TRUE if SingleTrack    - Value Types ---',0
                    dc.b     CMD_TEXT,8,16,'|  OR             4  D  TRUE if DoubleTrack',0
                    dc.b     CMD_TEXT,8,17,'!  OR             4                            0-9 DECIMAL',0
                    dc.b     CMD_TEXT,8,18,'^  EOR            4  N  Note Number            %   BINARY',0
                    dc.b     CMD_TEXT,8,19,'                     I  Instrument Number      @   OCTAL',0
                    dc.b     CMD_TEXT,8,20,'*  MULTIPLICATION 3  V  Effect Value           $   HEXADECIMAL',0
                    dc.b     CMD_TEXT,8,21,'/  DIVISION       3                            ''   STRING (''''='')',0
                    dc.b     CMD_TEXT,8,22,'                     X  XPos in Pattern (1..)  "   STRING (""=")',0
                    dc.b     CMD_TEXT,8,23,'+  ADDITION       2  Y  YPos in Pattern (0..)',0
                    dc.b     CMD_TEXT,8,24,'-  SUBTRACTION    2',0
                    dc.b     CMD_TEXT,8,25,'                     T  TRUE',0
                    dc.b     CMD_TEXT,8,26,'=  EQUAL          1  F  FALSE',0
                    dc.b     CMD_TEXT,8,27,'>= GREATER EQUAL  1',0
                    dc.b     CMD_TEXT,8,28,'<= LESS EQUAL     1',0
                    dc.b     CMD_TEXT,8,29,'<> UNEQUAL        1',0
                    dc.b     CMD_END
play_help_text:
                    dc.b     CMD_SET_SUB_SCREEN
                    dc.b     4
                    dc.b     CMD_TEXT,9,10,'- Play Song, Play Pattern Help Page -------------------------',0
                    dc.b     CMD_TEXT,9,12,'- Misc --------------------------- - Octave Settings --------',0
                    dc.b     CMD_TEXT,9,14,'___ESC       Stop                  ___F1 Set Octave 1+2',0
                    dc.b     CMD_TEXT,9,15,'___`         Stop to Act Pos       ___F2 Set Octave 2+3',0
                    dc.b     CMD_TEXT,9,17,'___TAB       Change Edit Mode      - Track Movement ---------',0
                    dc.b     CMD_TEXT,9,18,'___CURSOR UD Change Sample',0
                    dc.b     CMD_TEXT,9,19,'___F3-F10    Change Channel States ___CURSOR LR Change Track',0
                    dc.b     CMD_TEXT,44,20,'___HELP      Go to PolyPos',0
                    dc.b     CMD_TEXT,9,21,'NB_1         Sub Quant',0
                    dc.b     CMD_TEXT,9,22,'NB_2         Add Quant',0
                    dc.b     CMD_TEXT,9,24,'NB_4         Sub Poly',0
                    dc.b     CMD_TEXT,9,25,'NB_5         Add Poly',0
                    dc.b     CMD_TEXT,9,27,'NB_7         Change MidiMode',0
                    dc.b     CMD_END
our_screen_struct:
                    dc.w     0,0
                    dc.w     SCREEN_WIDTH,11
                    dc.w     1
                    dc.b     0,1
                    dc.w     V_HIRES
                    dc.w     CUSTOMSCREEN
                    dc.l     0
                    dc.l     0
                    dc.l     0
                    dc.l     0
; related to the replay
OK_PattLineBuff:
                    dcb.b    4*8,0
OK_ChannelsData:
                    dcb.b    28*4,0
; --- mixing buffers
lbB019D74:
                    dcb.b    314,0
lbB019EAE:
                    dcb.b    314,0
; ---
OK_PBuffs:
                    dcb.l    16,0
OK_PatternList:
                    dcb.l    64,0
save_stack:
                    dc.l     0
screen_mem_block:
                    dc.l     0
lbL01A130:
                    dc.l     0
lbL01A134:
                    dc.l     0
current_viewed_pattern:
                    dc.w     0
lbL01A13A:
                    dcb.b    12,0
lbL01A146:
                    dcb.l    1024,0
caret_current_positions:
                    dcb.b    40,0
                    dc.b     0
                    even
OK_SampleTab:
                    dcb.l    36*2,0
pattern_bitplane_top_pos:
                    dc.w     0
pattern_play_flag:
                    dc.b     0
                    even
lbW01B294:
                    dc.w     0
lbW01B296:
                    dc.w     0
lbW01B298:
                    dc.w     0
lbL01B29A:
                    dc.l     0
lbB01B29E:
                    dcb.b    8,0
lbB01B2A6:
                    dcb.b    2,0
lbL01B2A8:
                    dc.l     0
lbL01B2AC:
                    dc.l     0
lbW01B2B0:
                    dcb.w    3,0
lbW01B2B6:
                    dc.w     0
lbB01B2B8:
                    dc.b     0
lbB01B2B9:
                    dc.b     0
lbW01B2BA:
                    dc.w     0
trackdisk_device:
                    dcb.b    IOTD_SIZE,0
lbL01B30C:
                    dcb.l    256,0
lbW01B70C:
                    dc.w     0
lbW01B70E:
                    dc.w     0
lbL01B710:
                    dcb.l    2,0
lbL01B718:
                    dc.l     0
lbL01B71C:
                    dc.l     0
lbL01B720:
                    dc.l     0
lbL01B724:
                    dc.l     0
song_chunk_header_loaded_data:
                    dcb.b    8,0
lbW01B730:
                    dc.w     0
lbL01B732:
                    dc.l     0
lbW01B736:
                    dcb.w    41,0
lbW01B788:
                    dc.w     0
vumeters_levels:
                    dc.b     32,0
window_user_port:
                    dc.l     0
window_handle:
                    dc.l     0
lbL01B7B2:
                    dcb.l    8,0
lbL01B7D2:
                    dc.l     0
lbL01B7D6:
                    dc.l     0
lbW01B7DA:
                    dc.w     0
lbW01B7DC:
                    dc.w     0
OK_Samples:
                    dcb.b    32*36,0
lbW01BC5E:
                    dc.w     0
lbL01BC60:
                    dc.l     0
lbL01BC64:
                    dc.l     0
lbW01BC68:
                    dc.w     0
midi_mode:
                    dc.b     0
lbB01BC6B:
                    dcb.b    3,0
lbW01BC6E:
                    dc.w     0
lbL01BC70:
                    dcb.l    64,0
                    ; (must be aligned)
                    cnop     0,8
file_info_block:
                    dcb.b    fib_SIZEOF,0
disk_info_data:
                    dcb.l    9,0
; ---
curent_dir_name:
                    dcb.b    80,0
lbB01BEE8:
                    dcb.b    80,0
filename_to_load:
                    dcb.b    160,0
dir_songs:
                    dcb.b    160,0
dir_samples:
                    dcb.b    80,0
lbL01C0C8:
                    dcb.b    80,0
dir_prefs:
                    dcb.b    80,0
dir_effects:
                    dcb.b    160,0
; ---
lbL01C258:
                    dcb.l    320,0
mult_table:
                    dcb.b    512,0
emult_table:
lbL01C958:
                    dcb.l    64,0
lbL01CA58:
                    dcb.l    320,0
lbL01CF58:
                    dcb.l    64,0

; ===========================================================================
prefs_backup_data:
                    dc.l     0
OK_ChannelsModes_backup:
                    dcb.b    PREFS_FILE_LEN-4,0

; ===========================================================================
lbB01D88E:
                    dcb.b    7,0
lbB01D895:
                    dcb.b    7,0
lbL01D89C:
                    dcb.l    100,0
lbL01DA2C:
                    dcb.l    256,0

; ===========================================================================
                    section  chip_data,data_c
copperlist:
sprites_bps:
                    dc.w     SPR0PTH,0,SPR0PTL,0,SPR1PTH,0,SPR1PTL,0,SPR2PTH,0,SPR2PTL,0,SPR3PTH,0,SPR3PTL,0
                    dc.w     SPR4PTH,0,SPR4PTL,0,SPR5PTH,0,SPR5PTL,0,SPR6PTH,0,SPR6PTL,0,SPR7PTH,0,SPR7PTL,0
                    dc.w     DIWSTRT,$581,DIWSTOP,$40C1
copper_ddfstrt:
                    dc.w     DDFSTRT,$3C
copper_ddfstop:
                    dc.w     DDFSTOP,$D4
                    dc.w     FMODE,%11,BPLCON3,$C20
                    ; mouse pointer colors
                    dc.w     COLOR17,$805,COLOR18,$B06,COLOR19,$E08
                    dc.w     BPLCON1,0,BPLCON2,%111111
                    dc.w     BPL1MOD,0
; =====
main_menu_copper_jump:
                    dc.w     0,0,0,0,0,0
pattern_copper_jump:
                    dc.w     0,0,0,0,0,0
; =====
copper_start_line:
                    dc.w     $6407,$FFFE
main_back_color:
                    dc.w     COLOR00,0
main_front_color:
                    dc.w     COLOR01,0
main_bp:
                    dc.w     BPL1PTH,0,BPL1PTL,0
main_bplcon0:
                    dc.w     BPLCON0,$9200
copper_pal_line:
                    dc.w     $FFDF,$FFFE
copper_credits_line:
                    dc.w     $2407,$FFFE
copper_credits_back_color:
                    dc.w     COLOR00,0
copper_credits_front_color:
                    dc.w     COLOR01,0
credits_bp:
                    dc.w     BPL1PTH,0,BPL1PTL,0
                    dc.w     BPLCON0,$9200
copper_end_line:
                    dc.w     $2C07,$FFFE
                    dc.w     BPLCON0,$200
                    dc.w     $FFFF,$FFFE
                    dc.w     $FFFF,$FFFE
; =====
main_menu_copper_part:
                    dc.w     $2C07,$FFFE
main_menu_bp:
                    dc.w     BPL1PTH,0,BPL1PTL,0
                    dc.w     BPLCON0,$9200
                    dc.w     $3307,$FFFE
main_menu_back_color:
                    dc.w     COLOR00,0
main_menu_front_color:
                    dc.w     COLOR01,0
main_menu_copper_back_jump:
                    dc.w     0,0,0,0,0,0
; =====
pattern_copper_part:
                    dc.w     $4407,$FFFE
copper_int:
                    dc.w     BPLCON0,$9200
pattern_copper_back_jump:
                    dc.w     0,0,0,0,0,0

; ===========================================================================
mouse_pointer:
                    dc.b     0,0,0,0
                    dc.w     %1100011110000000,%1111100000000000
                    dc.w     %1000000100000000,%1001000000000000
                    dc.w     %0000001000000000,%1010000000000000
                    dc.w     %0000010000000000,%1100000000000000
                    dc.w     %0000100000000000,%1000000000000000
                    dc.w     %1001000000000000,%0000000000000000
                    dc.w     %1010000000000000,%0000000000000000
                    dc.w     %1100000000000000,%0000000000000000
                    dc.w     %1000000000000000,%0000000000000000
                    dc.w     0,0
bottom_credits_picture:
                    incbin   "pic_640x8.hi1"

; ===========================================================================
                    section  chip_blocks,bss_c
OK_MixBuff_1:
                    ds.b     MIX_BUFFERS_1*MIX_BUFFERS_LEN_1
OK_OuputBuff_2:
                    ds.b     82
OK_MixBuff_2:
                    ds.b     MIX_BUFFERS_LEN_2*2
                    ; (must be aligned for AGA)
                    cnop     0,8
main_screen:
                    ds.b     (1080*80)
dummy_sprite:
                    ds.b     4
OK_EmptyWaveForm:
                    ds.w     1
requesters_save_buffer:
                    ds.b     (24*20)

                    end
