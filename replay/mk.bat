@echo off
..\tools\vasm -nomsg=2050 -nomsg=2054 -nomsg=2052 -nosym -quiet -kick1hunks -D__VASM__ -Fhunk -o amiga.o test_amiga.asm
if errorlevel 1 goto error
..\tools\vlink -bamigahunk -s -kick1 -o am amiga.o
if errorlevel 1 goto error
del amiga.o
..\tools\vasm -nomsg=2050 -nomsg=2054 -nomsg=2052 -nosym -quiet -kick1hunks -D__VASM__ -Fhunk -o vampire.o test_vampire.asm
if errorlevel 1 goto error
..\tools\vlink -bamigahunk -s -kick1 -o va vampire.o
if errorlevel 1 goto error
del vampire.o
:error
