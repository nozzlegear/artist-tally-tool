@echo off
cls

echo "build.cmd running in directory %cd%"

dotnet restore std-artist-tally-tool

REM .paket\paket.bootstrapper.exe
REM if errorlevel 1 (
REM   exit /b %errorlevel%
REM )

REM .paket\paket.exe restore --force
REM if errorlevel 1 (
REM   exit /b %errorlevel%
REM )