@echo off
tools\vasm -nomsg=2050 -nomsg=2054 -nosym -nomsg=2052 -quiet -kick1hunks -D__VASM__ -Igfx -Iinclude -Fhunk -o src\okta.o src\okta.asm
if errorlevel 1 goto error
tools\vlink -bamigahunk -kick1 -o oa src\okta.o
del src\okta.o
:error
