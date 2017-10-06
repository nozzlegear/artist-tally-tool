@echo off
cls

.paket\paket.exe restore --force
if errorlevel 1 (
  exit /b %errorlevel%
)