@echo off
setlocal EnableDelayedExpansion

REM ===== Parse arguments =====
if "%~1" neq "-i" (
    echo Usage: ssh-copy-id.bat -i keyfile user host
    exit /b 1
)

set KEYFILE=%~2
set RUSER=%~3
set RHOST=%~4

if "!RHOST!"=="" (
    for /f "tokens=1,2 delims=@" %%A in ("!RUSER!") do (
        set RUSER=%%A
        set RHOST=%%B
    )
)

if "!RHOST!"=="" (
    echo Usage: ssh-copy-id.bat -i keyfile user host
    echo    or: ssh-copy-id.bat -i keyfile user@host
    exit /b 1
)

REM ===== Determine public/private key files =====
if "%KEYFILE:~-4%"==".pub" (
    set PUBKEY=%KEYFILE%
    set PRIVKEY=%KEYFILE:~0,-4%
) else (
    set PRIVKEY=%KEYFILE%
    set PUBKEY=%KEYFILE%.pub
)

if not exist "%PUBKEY%" (
    echo Public key not found: %PUBKEY%
    exit /b 1
)

if not exist "%PRIVKEY%" (
    echo Private key not found: %PRIVKEY%
    exit /b 1
)

REM ===== Execute =====
echo Copying key using:
echo   Private: %PRIVKEY%
echo   Public : %PUBKEY%
echo   Target : !RUSER!@!RHOST!
echo.

REM Detect remote OS (Linux/macOS returns "Linux"/"Darwin"; Windows returns an error message)
set REMOTE_OS=
for /f "delims=" %%O in ('ssh -i "%PRIVKEY%" !RUSER!@!RHOST! "uname -s 2>&1"') do set REMOTE_OS=%%O

if /i "!REMOTE_OS!"=="Linux" (
    echo   Remote OS: Linux
    type "%PUBKEY%" | ssh -i "%PRIVKEY%" !RUSER!@!RHOST! "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
) else if /i "!REMOTE_OS!"=="Darwin" (
    echo   Remote OS: macOS
    type "%PUBKEY%" | ssh -i "%PRIVKEY%" !RUSER!@!RHOST! "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
) else (
    echo   Remote OS: Windows
    type "%PUBKEY%" | ssh -i "%PRIVKEY%" !RUSER!@!RHOST! "$k=[Console]::In.ReadLine(); $admin=(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); if($admin){$f='C:\ProgramData\ssh\administrators_authorized_keys'; if($k){Add-Content $f $k}; icacls $f /inheritance:r | Out-Null; icacls $f /grant 'SYSTEM:F' | Out-Null; icacls $f /grant 'Administrators:F' | Out-Null} else {$d=Join-Path $env:USERPROFILE '.ssh'; if(-not(Test-Path $d)){New-Item -ItemType Directory $d | Out-Null}; if($k){Add-Content (Join-Path $d 'authorized_keys') $k}}"
)

echo Done.
endlocal
