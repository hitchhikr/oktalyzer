; ===========================================================================
; Oktalyzer v1.57
; ===========================================================================
; Original code by Armin 'TIP' Sander.
; Disassembled by Franck 'hitchhikr' Charlet.
; ===========================================================================

; ===========================================================================
                    include "exec/execbase.i"
                    include "exec/memory.i"
                    include "dos/dos.i"
                    include "dos/dosextens.i"
                    include "graphics/gfxbase.i"
                    include "graphics/view.i"
                    include "intuition/screens.i"
                    include "resources/disk.i"
                    include "workbench/startup.i"
                    include "devices/trackdisk.i"
                    include "devices/bootblock.i"
                    include "devices/input.i"
                    include "devices/inputevent.i"
                    include "exec/io.i"
                    include "lvo/exec_lib.i"
                    include "lvo/dos_lib.i"
                    include "lvo/graphics_lib.i"
                    include "lvo/intuition_lib.i"
                    include "lvo/disk_lib.i"
                    include "hardware/custom.i"
                    include "hardware/dmabits.i"
                    include "hardware/intbits.i"
                    include "hardware/cia.i"
                    include "hardware/blit.i"

; ===========================================================================
SCREEN_WIDTH        equ     640
SCREEN_BYTES        equ     (SCREEN_WIDTH/8)

PREFS_FILE_LEN      equ     2102
TRACK_LEN           equ     (22*512)

STACK_KB            equ     8

OK                  equ     0
ERROR               equ     -1

DIR_SONGS           equ     0
DIR_SAMPLES         equ     1
DIR_PREFS           equ     2
DIR_EFFECTS         equ     3

MIX_BUFFERS_1       equ     4
MIX_BUFFERS_LEN_1   equ     626

MIX_BUFFERS_2       equ     2
MIX_BUFFERS_LEN_2   equ     2240

MIDI_OFF            equ     0
MIDI_IN             equ     1
MIDI_OUT            equ     2

CMD_END             equ     0
CMD_TEXT            equ     2
CMD_CLEAR_MAIN_MENU equ     3
CMD_SUB_COMMAND     equ     6
CMD_TEXT_PTR        equ     8
CMD_CLEAR_CHARS     equ     10
CMD_SET_SUB_SCREEN  equ     11
CMD_SET_MAIN_SCREEN equ     12
CMD_MOVE_TO_LINE    equ     13

ERROR_NO_MEM        equ     0
ERROR_WHAT_BLOCK    equ     ERROR_NO_MEM+1
ERROR_WHAT_POS      equ     ERROR_WHAT_BLOCK+1
ERROR_SMP_TOO_LONG  equ     ERROR_WHAT_POS+1
ERROR_WHAT_SMP      equ     ERROR_SMP_TOO_LONG+1
ERROR_SMP_CLEARED   equ     ERROR_WHAT_SMP+1
ERROR_NO_MORE_PATT  equ     ERROR_SMP_CLEARED+1
ERROR_NO_MORE_POS   equ     ERROR_NO_MORE_PATT+1
ERROR_PATT_IN_USE   equ     ERROR_NO_MORE_POS+1
ERROR_COPY_BUF_FREE equ     ERROR_PATT_IN_USE+1
ERROR_NO_MORE_SMP   equ     ERROR_COPY_BUF_FREE+1
ERROR_ONLY_4B_MODE  equ     ERROR_NO_MORE_SMP+1
ERROR_LEFT_ONE_BIT  equ     ERROR_ONLY_4B_MODE+1
ERROR_BLOCK_COPIED  equ     ERROR_LEFT_ONE_BIT+1
ERROR_SMP_CLIPPED   equ     ERROR_BLOCK_COPIED+1
ERROR_SMP_TOO_SHORT equ     ERROR_SMP_CLIPPED+1
ERROR_IFF_ERROR     equ     ERROR_SMP_TOO_SHORT+1
ERROR_SAME_SMP      equ     ERROR_IFF_ERROR+1
ERROR_DIFF_MODES    equ     ERROR_SAME_SMP+1
ERROR_Z_NOT_FOUND   equ     ERROR_DIFF_MODES+1
ERROR_CANT_INST     equ     ERROR_Z_NOT_FOUND+1
ERROR_ALREADY_INST  equ     ERROR_CANT_INST+1
ERROR_NO_OKDIR      equ     ERROR_ALREADY_INST+1
ERROR_OPEN_DEVICE   equ     ERROR_NO_OKDIR+1
ERROR_VERIFY        equ     ERROR_OPEN_DEVICE+1
ERROR_WHAT_SMPS     equ     ERROR_VERIFY+1
ERROR_CANT_CONVERT  equ     ERROR_WHAT_SMPS+1
ERROR_OK_STRUCT     equ     ERROR_CANT_CONVERT+1
ERROR_ST_STRUCT     equ     ERROR_OK_STRUCT+1
ERROR_WHAT_FILE     equ     ERROR_ST_STRUCT+1
ERROR_NOT_DIR       equ     ERROR_WHAT_FILE+1
ERROR_ENDOF_ENTRIES equ     ERROR_NOT_DIR+1
ERROR_NOTHING_SEL   equ     ERROR_ENDOF_ENTRIES+1
ERROR_MULTI_SEL     equ     ERROR_NOTHING_SEL+1
ERROR_COPYBUF_EMPTY equ     ERROR_MULTI_SEL+1
ERROR_NO_ENTRIES    equ     ERROR_COPYBUF_EMPTY+1
ERROR_EF_STRUCT     equ     ERROR_NO_ENTRIES+1
ERROR_ONLY_IN_PAL   equ     ERROR_EF_STRUCT+1

EVT_LIST_END        equ     0
EVT_KEY_PRESSED     equ     1
EVT_BYTE_FROM_SER   equ     2
EVT_MOUSE_MOVED     equ     3
EVT_LEFT_PRESSED    equ     4
EVT_LEFT_RELEASED   equ     5
EVT_MOUSE_DELAY_L   equ     6
EVT_RIGHT_PRESSED   equ     7
EVT_RIGHT_RELEASED  equ     8
EVT_MOUSE_DELAY_R   equ     9
EVT_VBI             equ     10
EVT_MORE_EVENTS     equ     11
EVT_MOUSE_MOVED_HID equ     12
EVT_DISK_CHANGE     equ     13
EVT_KEY_RELEASED    equ     14

RESP_EVT_ROUT_1     equ     10
RESP_EVT_ROUT_2     equ     14

; ===========================================================================
EXEC                MACRO
                    move.l  a6,-(a7)
                    move.l  (4).w,a6
                    jsr     (_LVO\1,a6)
                    move.l  (a7)+,a6
                    ENDM

DOS                 MACRO
                    move.l  a6,-(a7)
                    move.l  DOSBase,a6
                    jsr     (_LVO\1,a6)
                    move.l  (a7)+,a6
                    ENDM

INT                 MACRO
                    move.l  a6,-(a7)
                    move.l  IntBase,a6
                    jsr     (_LVO\1,a6)
                    move.l  (a7)+,a6
                    ENDM

GFX                 MACRO
                    move.l  a6,-(a7)
                    move.l  GFXBase,a6
                    jsr     (_LVO\1,a6)
                    move.l  (a7)+,a6
                    ENDM

DISK                MACRO
                    move.l  a6,-(a7)
                    move.l  DiskBase,a6
                    jsr     (_LVO\1,a6)
                    move.l  (a7)+,a6
                    ENDM
