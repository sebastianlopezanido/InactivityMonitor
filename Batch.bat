@echo off
:: path to you program 
start C:\ProgramFiles\path\to\yourProgram.exe
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "Monitor.ps1"
