@echo off
cls

echo "build.cmd running in directory %cd%"

.paket/paket.bootstrapper.exe
if errorlevel 1 (
  exit /b %errorlevel%
)

.paket/paket.exe restore --force
if errorlevel 1 (
  exit /b %errorlevel%
)