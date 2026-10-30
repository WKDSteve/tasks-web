@echo off
rem Opens tasks.html of this folder in Google Chrome, also when another browser is the default one. No Neovim, no
rem install: it only starts Chrome with the file.
rem
rem   start-tasks.cmd              the page in a tab of Chrome
rem   start-tasks.cmd /app         the page in a window of its own (no tabs, its own button in the taskbar)
rem   start-tasks.cmd /shortcut    a shortcut "tasks" on the desktop and in the Start menu (opens like /app); pin it to
rem                                the taskbar from there (right click, "Pin to taskbar")
rem   start-tasks.cmd /print       print what would be started, start nothing
setlocal EnableExtensions

set "page=%~dp0tasks.html"
if not exist "%page%" (
  echo tasks.html is missing next to this script: "%page%"
  exit /b 1
)

set "mode=%~1"
if /i "%mode%"=="" set "mode=/tab"
if /i not "%mode%"=="/tab" if /i not "%mode%"=="/app" if /i not "%mode%"=="/shortcut" if /i not "%mode%"=="/print" (
  echo Unknown option "%~1". Use /app, /shortcut or /print, or nothing.
  exit /b 2
)

call :find_chrome
if not defined chrome (
  if /i "%mode%"=="/shortcut" (
    echo Chrome was not found, so no shortcut was made.
    exit /b 1
  )
  echo Chrome was not found. Opening tasks.html in the default browser; writing needs Chrome or Edge.
  if /i "%mode%"=="/print" (echo start "" "%page%") else start "" "%page%"
  exit /b 0
)

rem A tab takes the path; a window of its own (and its shortcut) takes the address.
if /i not "%mode%"=="/tab" (
  call :make_url
  if errorlevel 1 exit /b 1
)

if /i "%mode%"=="/print" (
  echo Chrome:   "%chrome%"
  echo Tab:      "%chrome%" "%page%"
  echo Window:   "%chrome%" "--app=%url%"
  exit /b 0
)
if /i "%mode%"=="/tab" (
  start "" "%chrome%" "%page%"
  exit /b 0
)
if /i "%mode%"=="/app" (
  start "" "%chrome%" "--app=%url%"
  exit /b 0
)

rem /shortcut: WScript.Shell writes the .lnk files; the paths go in through the environment, not through the command line.
set "TASKS_WEB_CHROME=%chrome%"
set "TASKS_WEB_ARGS="--app=%url%""
powershell -NoProfile -NonInteractive -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$shell = New-Object -ComObject WScript.Shell;" ^
  "foreach ($dir in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs')) {" ^
  "  $link = $shell.CreateShortcut((Join-Path $dir 'tasks.lnk'));" ^
  "  $link.TargetPath = $env:TASKS_WEB_CHROME;" ^
  "  $link.Arguments = $env:TASKS_WEB_ARGS;" ^
  "  $link.IconLocation = $env:TASKS_WEB_CHROME + ',0';" ^
  "  $link.Description = 'tasks (web page in Chrome)';" ^
  "  $link.Save();" ^
  "  Write-Output ('Made ' + $link.FullName)" ^
  "}"
exit /b %errorlevel%

rem The address of the page as a browser writes it: [Uri] escapes a space, # and % of a folder name, which in a raw
rem file:/// address would cut it off (#) or be read as an escape (%).
:make_url
set "url="
set "TASKS_WEB_PAGE=%page%"
for /f "usebackq delims=" %%u in (`powershell -NoProfile -NonInteractive -Command "[Uri]::new($env:TASKS_WEB_PAGE).AbsoluteUri"`) do set "url=%%u"
if not defined url (
  echo The address of tasks.html could not be made.
  exit /b 1
)
exit /b 0

rem Chrome registers itself under App Paths (per machine or per user); the usual folders are the fallback.
:find_chrome
set "chrome="
for %%k in (HKLM HKCU) do (
  if not defined chrome for /f "tokens=2,*" %%a in ('reg query "%%k\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" /ve 2^>nul ^| find "REG_SZ"') do set "chrome=%%~b"
)
if defined chrome if not exist "%chrome%" set "chrome="
for %%p in ("%ProgramFiles%" "%ProgramFiles(x86)%" "%LocalAppData%") do (
  if not defined chrome if exist "%%~p\Google\Chrome\Application\chrome.exe" set "chrome=%%~p\Google\Chrome\Application\chrome.exe"
)
exit /b 0
