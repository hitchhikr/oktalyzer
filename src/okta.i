; ===========================================================================
; Oktalyzer v2.0 - Main program includes
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
                    include "exec/resident.i"
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
SCREEN_HEIGHT       equ     256
SCREEN_BYTES        equ     (SCREEN_WIDTH/8)
SCREEN_SIZE         equ     (SCREEN_BYTES*SCREEN_HEIGHT)

PREFS_FILE_LEN      equ     2102
TRACK_LEN           equ     (22*512)

STACK_KB            equ     8

OK                  equ     0
ERROR               equ     -1

DIR_SONGS           equ     0
DIR_SAMPLES         equ     1
DIR_PREFS           equ     2
DIR_EFFECTS         equ     3

MIDI_OFF            equ     0
MIDI_IN             equ     1
MIDI_OUT            equ     2

CMD_DONE            equ     0
CMD_TEXT            equ     2
CMD_CLEAR_MAIN_MENU equ     3
CMD_PREPARE_SUB_SCREEN equ  4
CMD_DRAW_BOX        equ     5
CMD_SUB_COMMAND     equ     6
CMD_DRAW_BOX_OUTER  equ     7
CMD_TEXT_PTR        equ     8
CMD_DRAW_FILLED_BOX_FROM_POINTER equ 9
CMD_CLEAR_CHARS     equ     10
CMD_SET_SUB_COPPERLIST equ  11
CMD_SET_MAIN_COPPERLIST equ 12
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
ERROR_LEFT_ONE_BIT  equ     ERROR_COPY_BUF_FREE+1
ERROR_BLOCK_COPIED  equ     ERROR_LEFT_ONE_BIT+1
ERROR_SMP_SHORTENED equ     ERROR_BLOCK_COPIED+1
ERROR_SMP_TOO_SHORT equ     ERROR_SMP_SHORTENED+1
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
ERROR_OKT_STRUCT    equ     ERROR_CANT_CONVERT+1
ERROR_MOD_STRUCT    equ     ERROR_OKT_STRUCT+1
ERROR_UNKNOWN_MOD   equ     ERROR_MOD_STRUCT+1
ERROR_WHAT_FILE     equ     ERROR_UNKNOWN_MOD+1
ERROR_NOT_DIR       equ     ERROR_WHAT_FILE+1
ERROR_ENDOF_ENTRIES equ     ERROR_NOT_DIR+1
ERROR_NOTHING_SEL   equ     ERROR_ENDOF_ENTRIES+1
ERROR_MULTI_SEL     equ     ERROR_NOTHING_SEL+1
ERROR_COPYBUF_EMPTY equ     ERROR_MULTI_SEL+1
ERROR_NO_ENTRIES    equ     ERROR_COPYBUF_EMPTY+1
ERROR_EF_STRUCT     equ     ERROR_NO_ENTRIES+1
ERROR_WHAT_REPEAT   equ     ERROR_EF_STRUCT+1

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

GADGET_TRAP_RMB_BIT equ     11
GADGET_NO_REPEAT_BIT equ    12
GADGET_NO_HILITE_BIT equ    13
GADGET_DISABLED_BIT equ     14
GADGET_TRAP_RMB     equ     (1<<GADGET_TRAP_RMB_BIT)
GADGET_NO_REPEAT    equ     (1<<GADGET_NO_REPEAT_BIT)
GADGET_NO_HILITE    equ     (1<<GADGET_NO_HILITE_BIT)
GADGET_DISABLED     equ     (1<<GADGET_DISABLED_BIT)

VIS_DRAW_VUMETERS   equ     0
VIS_PATT_SCROLL     equ     1
VIS_DRAW_POS        equ     2
VIS_TRIG_VUMETERS   equ     3
VIS_DRAW_SPEED      equ     4
VIS_DRAW_PATT       equ     5
VIS_DRAW_PATT_POS   equ     6

OKT_IN_TRACKER      equ     1
MAX_SAMPLES         equ     36

SMP_TYPE_8_BIT      equ     0
SMP_TYPE_16_BIT     equ     1

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
                    rs.b    1           ; 1 (padding)
CHAN_SMP_REP_START: rs.l    1           ; 2
CHAN_SMP_REP_LEN_S: rs.w    1           ; 6
CHAN_NOTE_S:        rs.w    1           ; 8
CHAN_PERIOD_S:      rs.w    1           ; 10
CHAN_NOTE_D:        rs.w    1           ; 12
CHAN_BASE_NOTE_D:   rs.w    1           ; 14
CHAN_SMP_REP_LEN_D: rs.l    1           ; 16
CHAN_SMP_PROC_D:    rs.l    1           ; 18
CHAN_SMP_PROC_LEN_D:rs.l    1           ; 20
CHAN_LEN:           rs.b    0           ; 24

		            rsreset
OKT_SCALING_CODE:   rs.b    74800
OKT_CODE_POINTERS:  rs.l    36
OKT_LENGTHS:        rs.w    36*2
OKT_CODE_LENGTH:    rs.b    0

OKT_SCALING_LINES   equ     19552
OKT_BUFFERS_LENGTH  equ     312

OKT_SAMPLE_BOOST    equ     0
OKT_SAMPLE_FILTER   equ     1*2
OKT_SAMPLE_XFADE    equ     2*2
OKT_SAMPLE_NORM     equ     3*2

GAD_DONE            equ     0
GAD_NEXT            equ     1

KEY_MOD_NONE_BIT    equ     0
KEY_MOD_SHIFT_BIT   equ     8
KEY_MOD_ALT_BIT     equ     9
KEY_MOD_AMIGA_BIT   equ     10
KEY_MOD_NUMPAD_BIT  equ     11
KEY_MOD_CTRL_BIT    equ     12
KEY_MOD_REPEAT_BIT  equ     15

KEY_MOD_NONE        equ     (0)                         ;$0
KEY_MOD_SHIFT       equ     (1<<KEY_MOD_SHIFT_BIT)      ;$100
KEY_MOD_ALT         equ     (1<<KEY_MOD_ALT_BIT)        ;$200
KEY_MOD_AMIGA       equ     (1<<KEY_MOD_AMIGA_BIT)      ;$400
KEY_MOD_NUMPAD      equ     (1<<KEY_MOD_NUMPAD_BIT)     ;$800
KEY_MOD_CTRL        equ     (1<<KEY_MOD_CTRL_BIT)       ;$1000
KEY_MOD_REPEAT      equ     (1<<KEY_MOD_REPEAT_BIT)     ;$8000

KL_ENTRY_DONE       equ     0
KL_ENTRY_HEAD       equ     10
KEY_NO_REPEAT       equ     2
KEY_REPEAT          equ     4
KEY_RANGE_NO_REPEAT equ     6
KEY_RANGE_REPEAT    equ     8

KEY_TAB             equ     $42-$40
KEY_RETURN          equ     $44-$40
KEY_ESC             equ     $45-$40
KEY_DEL             equ     $46-$40
KEY_UP              equ     $4C-$40
KEY_DOWN            equ     $4D-$40
KEY_RIGHT           equ     $4E-$40
KEY_LEFT            equ     $4F-$40
KEY_F1              equ     $50-$40
KEY_F2              equ     $51-$40
KEY_F3              equ     $52-$40
KEY_F4              equ     $53-$40
KEY_F5              equ     $54-$40
KEY_F6              equ     $55-$40
KEY_F7              equ     $56-$40
KEY_F8              equ     $57-$40
KEY_F9              equ     $58-$40
KEY_F10             equ     $59-$40
KEY_HELP            equ     $5F-$40

; ===========================================================================
                IFD OKT_AUDIO_VAMPIRE
OKT_AUDIO_BASE      equ     $440
OKT_AUDIO_DMA       equ     $296
INTREQ2             equ     $29C
OKT_AUDIO_ADR       equ     0
OKT_AUDIO_LEN       equ     4
OKT_AUDIO_VOL       equ     8
OKT_AUDIO_CTRL      equ     $A
OKT_AUDIO_PER       equ     $C
OKT_AUDIO_SIZE      equ     $10
OKT_AUDIO_HW_CHANS  equ     8
V_AUD0VOL           equ     $8
V_AUD1VOL           equ     $18
V_AUD2VOL           equ     $28
V_AUD3VOL           equ     $38
V_AUD4VOL           equ     $48
V_AUD5VOL           equ     $58
V_AUD6VOL           equ     $68
V_AUD7VOL           equ     $78
V_AUD8VOL           equ     $88
V_AUD9VOL           equ     $98
V_AUD10VOL          equ     $A8
V_AUD11VOL          equ     $B8
V_AUD12VOL          equ     $C8
V_AUD13VOL          equ     $D8
V_AUD14VOL          equ     $E8
V_AUD15VOL          equ     $F8
                ELSE
OKT_AUDIO_BASE      equ     $A0
OKT_AUDIO_DMA       equ     $96
OKT_AUDIO_ADR       equ     0
OKT_AUDIO_LEN       equ     4
OKT_AUDIO_PER       equ     6
OKT_AUDIO_VOL       equ     8
OKT_AUDIO_SIZE      equ     $10
OKT_AUDIO_HW_CHANS  equ     4
                ENDC

; ===========================================================================
                    ; next gadget.l
                    ; flags.w
                    ; x.b,y.b,w.b,h.b
                    ; left mouse button action.l,right mouse button action.l
GADGET              MACRO
                IF \1==GAD_NEXT
                    dc.l    next\@
                ELSE
                    dc.l    0
                ENDC
                    dc.w    \2
                    dc.b    \3,\4,\5,\6
                    dc.l    \7,\8
next\@:
                    ENDM

                    ; modifier.w
                    ; associated function.l
KL_HEAD             MACRO
                    dc.w    KL_ENTRY_HEAD,\1
                    dc.l    \2
                    ENDM

                    ; type.w,code.w
                    ; associated function.l
                    ; or
                    ; type.w,low code.w,hi code.w,added value.w passed to function
                    ; associated function.l
KEY                 MACRO
            IF \1=KEY_RANGE_NO_REPEAT
                    dc.w    \1,\2,\3,\4
                    dc.l    \5
            ELSE
                IF \1=KEY_RANGE_REPEAT
                    dc.w    \1,\2,\3,\4
                    dc.l    \5
                ELSE
                    dc.w    \1,\2
                    dc.l    \3
                ENDC
            ENDC
                    ENDM

KL_DONE             MACRO
                    dc.w    KL_ENTRY_DONE
                    ENDM

                    ; layout list.l
                    ; keyboard shortcuts list.l
                    ; gadgets list.l
SCREEN              MACRO
                    dc.w    1
                    dc.l    \1
                    dc.w    2
                    dc.l    \2
                    dc.w    3
                    dc.l    \3
                    dc.w    0
                    dc.l    0,0,0
                    ENDM

CHUNK               MACRO
            IF \1==0
                    dc.l    0
            ELSE
                    dc.b    \1
                    dc.l    \2,\3
                IF NARG==4
                    dc.l    \4
                ENDC
            ENDC
                    ENDM

; ===========================================================================
OKT_SET_AUDIO_ADR   MACRO
                    move.l  \1,(OKT_AUDIO_ADR,\2)
                    ENDM

OKT_SET_AUDIO_LEN   MACRO
                IFD OKT_AUDIO_VAMPIRE
                    move.l  \1,(OKT_AUDIO_LEN,\2)
                ELSE
                    move.w  \1,(OKT_AUDIO_LEN,\2)
                ENDC
                    ENDM

OKT_SET_AUDIO_PER   MACRO
                    move.w  \1,(OKT_AUDIO_PER,\2)
                    ENDM

OKT_SET_AUDIO_VOL   MACRO
                IFD OKT_AUDIO_VAMPIRE
                    ; set channel panning
                    ; a4 = panning table
                    move.w  \1,d1
                    mc68020
                    mulu    (a4,d3.w*4),\1
                    lsr.w   #6,\1
                    lsl.w   #8,\1
                    mulu    2(a4,d3.w*4),d1
                    mc68000
                    lsr.w   #6,d1
                    or.w    d1,\1
                ENDC
                    move.w  \1,(OKT_AUDIO_VOL,\2)
                    ENDM

OKT_SET_AUDIO_CTRL  MACRO
                IFD OKT_AUDIO_VAMPIRE
                    move.w  \1,(OKT_AUDIO_CTRL,\2)
                ENDC
                    ENDM

OKT_SET_AUDIO_DMA   MACRO
                    move.w  \1,_CUSTOM|OKT_AUDIO_DMA
                    ENDM

OKT_SET_AUDIO_PAN   MACRO
                    ENDM

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

WAIT_BLITTER        MACRO
                IFD OKT_AUDIO_VAMPIRE
                    btst    #6,(DMACONR,a6)
.wait_blit\@:
                    btst    #6,(DMACONR,a6)
                    bne     .wait_blit\@
                ELSE
                    GFX     WaitBlit
                ENDC
                    ENDM