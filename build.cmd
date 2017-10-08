@echo off
cls

echo "build.cmd running in directory %cd%"

dotnet restore std-artist-tally-tool
dotnet build -c Release std-artist-tally-tool

REM .paket\paket.bootstrapper.exe
REM if errorlevel 1 (
REM   exit /b %errorlevel%
REM )

REM .paket\paket.exe restore --force
REM if errorlevel 1 (
REM   exit /b %errorlevel%
REM )

call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_TEMP%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
IF !ERRORLEVEL! NEQ 0 goto error