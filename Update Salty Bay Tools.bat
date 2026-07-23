@echo off
setlocal enabledelayedexpansion
title Salty Bay Tools - Updater / Installer
color 0B
cd /d "%~dp0"

echo.
echo  ============================================================
echo   Salty Bay Tools - Updater
echo.
echo   This finds every Salty Bay tool already on this computer,
echo   updates each one to the latest shared version, and offers
echo   to add any tools you don't have yet.
echo.
echo   Your saved work and logins are NOT touched (comps in the
echo   Deals folder, the court login, downloaded county data, etc).
echo  ============================================================
echo.

REM -- Make sure Git is available (the updater needs it) --
where git >nul 2>&1
if errorlevel 1 (
    echo  [..] Git isn't installed yet - installing it one time, please wait...
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    set "PATH=%PATH%;C:\Program Files\Git\cmd;C:\Program Files\Git\bin"
)
where git >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Git could not be installed automatically.
    echo          Please send KG a screenshot of this window.
    echo.
    pause
    exit /b 1
)

REM A per-tool failure is recorded to this file rather than a variable, because
REM :process_tool runs inside setlocal and anything set in there is discarded.
REM Without it the final banner said "Everything is up to date" even when a
REM download had failed - the kind of quiet lie that cost us 7/23.
set "FAILFLAG=%TEMP%\_salty_bay_update_failures.txt"
if exist "%FAILFLAG%" del "%FAILFLAG%" >nul 2>&1

echo  Scanning your Desktop, Downloads and Documents ^(this can take a minute^)...

REM ================= THE TOOL LIST =================
REM  To add a future tool, copy one CALL line and fill in the four values:
REM   CALL :process_tool "<Friendly Name>" "<launcher file name>" "<repo url>" "<install folder name>"
call :process_tool "Comp Tool"     "Salty Bay Comp Tool.bat"  "https://github.com/saltybayflips-AI-Empire/salty-bay-comp-tool.git"  "Salty Bay Comp Tool"
call :process_tool "E&F Lead Pull" "Salty Bay E&F Pull.bat"   "https://github.com/saltybayflips-AI-Empire/salty-bay-ef-pull.git"     "Salty Bay E&F Pull"
REM ================================================

echo.
if exist "%FAILFLAG%" goto :some_failed
echo  ============================================================
echo   [DONE] Everything is up to date. You can close this window
echo   and open your tools the normal way.
echo  ============================================================
echo.
pause
exit /b 0

:some_failed
echo  ============================================================
echo   [PARTLY DONE] These did NOT get the update:
echo.
type "%FAILFLAG%"
echo.
echo   Everything else is current, and the tools still open on the
echo   copy already on this computer.
echo.
echo   Send this to KG: open the tool's folder and double-click
echo   "Send Logs to KG.bat", then paste the result into Slack.
echo  ============================================================
echo.
del "%FAILFLAG%" >nul 2>&1
pause
exit /b 1


REM =====================================================================
REM  :process_tool  %1 name  %2 launcher-file  %3 repo url  %4 folder name
REM =====================================================================
:process_tool
setlocal enabledelayedexpansion
set "TOOL_NAME=%~1"
set "SIG=%~2"
set "REPO=%~3"
set "FOLDER=%~4"
set "FOUND=0"

echo.
echo  ------------------------------------------------------------
echo   !TOOL_NAME!
echo  ------------------------------------------------------------

REM  Scan roots include "%USERPROFILE%\Salty Bay Tools" - the folder the Comp
REM  Tool README suggests - which the first version of this updater MISSED.
REM  A copy there was never found -> never git-linked -> silently frozen on an
REM  old version until it broke (Red, 7/23/26).
for %%R in (
    "%USERPROFILE%\Desktop"
    "%USERPROFILE%\OneDrive\Desktop"
    "%USERPROFILE%\Downloads"
    "%USERPROFILE%\OneDrive\Downloads"
    "%USERPROFILE%\Documents"
    "%USERPROFILE%\OneDrive\Documents"
    "%USERPROFILE%\Salty Bay Tools"
    "%USERPROFILE%\OneDrive\Salty Bay Tools"
    "C:\Salty Bay Tools"
) do (
    if exist "%%~R" (
        for /f "delims=" %%F in ('dir /b /s /a-d "%%~R\%SIG%" 2^>nul') do (
            set "FOUND=1"
            call :update_one "%%~dpF"
        )
    )
)

if "!FOUND!"=="0" (
    echo   You don't have the !TOOL_NAME! on this computer yet.
    set "ANS=N"
    set /p "ANS=  Install it now? Type Y then Enter, or just press Enter to skip: "
    if /i "!ANS!"=="Y" (
        echo   Downloading !TOOL_NAME! to your Desktop...
        git clone "%REPO%" "%USERPROFILE%\Desktop\%FOLDER%"
        if errorlevel 1 (
            echo   [X] Couldn't download !TOOL_NAME!. You may not have GitHub access
            echo       to it yet - tell KG and he'll grant you access, then re-run this.
        ) else (
            if exist "%USERPROFILE%\Desktop\%FOLDER%\install.bat" (
                pushd "%USERPROFILE%\Desktop\%FOLDER%"
                call "install.bat"
                popd
            )
            echo   [OK] !TOOL_NAME! installed on your Desktop.
        )
    ) else (
        echo   Skipped !TOOL_NAME!.
    )
)
endlocal
exit /b 0


REM =====================================================================
REM  :update_one  %1 = folder path of an existing install (trailing slash)
REM  Runs inside :process_tool's scope, so %REPO% is available here.
REM =====================================================================
:update_one
set "D=%~1"
echo   Found a copy at: !D!
pushd "%D%"
if not exist ".git" (
    git init -b main >nul 2>nul
)
git remote remove origin >nul 2>nul
git remote add origin "%REPO%" >nul 2>nul
git fetch origin main
if errorlevel 1 (
    echo   [X] Could not download the update - a GitHub sign-in may be needed.
    echo       Left this copy as-is.
    echo   !TOOL_NAME! at !D!>> "%FAILFLAG%"
) else (
    git reset --hard origin/main
    git branch --set-upstream-to=origin/main main >nul 2>nul
    echo   [OK] Updated to the latest version.
)
popd
exit /b 0
