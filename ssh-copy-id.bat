@echo off
setlocal EnableDelayedExpansion

REM ===== 引数解析 =====
if "%~1" neq "-i" (
    echo Usage: ssh-copy-id.bat -i keyfile user host
    exit /b 1
)

set KEYFILE=%~2
set USER=%~3
set HOST=%~4

if "%HOST%"=="" (
    for /f "tokens=1,2 delims=@" %%A in ("%USER%") do (
        set USER=%%A
        set HOST=%%B
    )
)

if "%HOST%"=="" (
    echo Usage: ssh-copy-id.bat -i keyfile user host
    echo    or: ssh-copy-id.bat -i keyfile user@host
    exit /b 1
)

REM ===== 公開鍵 / 秘密鍵決定 =====
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

REM ===== 実行 =====
echo Copying key using:
echo   Private: %PRIVKEY%
echo   Public : %PUBKEY%
echo   Target : %USER%@%HOST%
echo.

type "%PUBKEY%" | ssh -i "%PRIVKEY%" %USER%@%HOST% ^
 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

echo Done.
endlocal

