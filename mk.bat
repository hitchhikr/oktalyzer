@echo off
tools\vasm -nomsg=2050 -nomsg=2054 -nosym -nomsg=2052 -quiet -kick1hunks -Igfx -Iinclude -Fhunk -o src\oa.o src\okta.asm
if errorlevel 1 goto error
tools\vlink -bamigahunk -kick1 -o oa src\oa.o
if errorlevel 1 goto error
tools\vasm -nomsg=2050 -nomsg=2054 -nosym -nomsg=2052 -quiet -kick1hunks -DOKT_AUDIO_VAMPIRE -Igfx -Iinclude -Fhunk -o src\ov.o src\okta.asm
if errorlevel 1 goto error
tools\vlink -bamigahunk -kick1 -o ov src\ov.o
if errorlevel 1 goto error
del src\oa.o
del src\ov.o
:error
