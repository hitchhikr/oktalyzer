; link 
; This is only for my Rexx® Macro
*************************************************************************
*									*
*		      Oktalyzer PlayRoutine 1 Example			*
*									*
*************************************************************************

		oldsyntax

; All Coding by A.Sander

; Warning: No Audio Channels will be allocated. Any other Audio access 
; could be dangerous!

; In case of any implementation Problems call Germany 08106/5729 (after 6 p.m.).

; xLINK example1.o okplay1.o to example1

		xref	OK_Init
		xref	OK_Play
		xref	OK_Stop

; Definition of External Buffers ----------------------------------------

		rsreset
P1_Routines:	rs.b	$a81c			;   Constant !
P1_Pointers:	rs.l	36
P1_Lengths:	rs.w	36
P1_Len:		rs.b	0

		section	c,code

Play1:		lea	Music,a0		;   Init
		lea	Play1RoutBuff,a1
		jsr	OK_Init

		move.l	(4).w,a6		;   Get ExecBase

		sub.l	a1,a1
		jsr	-294(a6)		;   (FindTask)
		move.l	d0,MyTask

		moveq	#-1,d0
		jsr	-330(a6)		;   (AllocSignal)
		move.w	d0,SigBit
		moveq	#0,d1
		bset	d0,d1
		move.l	d1,SigMask

		moveq	#5,d0		;   Add a vertical blank int
		lea	VBIInt(pc),a1
		move.l	#VBICode,18(a1)
		jsr	-168(a6)	;   (AddIntServer)

		move.l	SigMask(pc),d0	;   Wait for Signal
		jsr	-318(a6)	;   (Wait)

		lea	VBIInt(pc),a1
		moveq	#5,d0
		jsr	-174(a6)	;   (RemIntServer)

		move.w	SigBit(pc),d0
		jsr	-336(a6)	;   (FreeSignal)

		jsr	OK_Stop

		moveq	#0,d0		;==>Return Code OK
		rts

; Data ------------------------------------------------------------------

SigBit:		ds.w	1
SigMask:	ds.l	1
MyTask:		ds.l	1

; My vertical Blank Interrupt Structure ---------------------------------

VBIInt:		ds.l	2
		dc.b	2,127			;   Should be at begin of List
		ds.l	3

; My vertical Blank Interrupt -------------------------------------------

VBICode:	movem.l	d0-d7/a0-a6,-(sp)	;   Save All

		jsr	OK_Play

		btst	#6,$bfe001
		bne.s	.cont
		btst	#2,$dff016
		bne.s	.cont

		move.l	MyTask(pc),a1
		move.l	SigMask(pc),d0
		move.l	(4).w,a6		;   Get ExecBase
		jsr	-324(a6)		;   (Signal)

.cont:		movem.l	(sp)+,d0-d7/a0-a6
		lea	$dff000,a0		;--> Shitty GFXBASE BUG!
		moveq	#0,d0
		rts

; Routine-Buffer for PlayRout 1 - (build up in OK_Init) -----------------

		section	b,bss

Play1RoutBuff:	ds.b	P1_Len

		section	dc,data,chip	;   data_c in Devpac

Music:		incbin	OKTALYZER:OK-SONGS/tar-demo-song1

		end
