@echo off
cls

echo "build.cmd running in directory %cd%"

start .paket/paket.bootstrapper.exe
if errorlevel 1 (
  exit /b %errorlevel%
)

start .paket/paket.exe restore --force
if errorlevel 1 (
  exit /b %errorlevel%
)