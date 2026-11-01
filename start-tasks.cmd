@echo off
rem Opens tasks.html of this folder in Google Chrome, also when another browser is the default one. No Neovim, no
rem install: it only starts Chrome with the file. Before that it updates the page: this folder is a clone of tasks-web,
rem and `git pull --ff-only` brings the newest tasks.html (skipped without git, outside a clone, or offline: the page as
rem it is opens). The file is then checked against SHA256SUMS; a file that does not match is not opened.
rem
rem   start-tasks.cmd              the page in a tab of Chrome
rem   start-tasks.cmd /app         the page in a window of its own (no tabs, its own button in the taskbar)
rem   start-tasks.cmd /update      pull and check only, start nothing
rem   start-tasks.cmd /shortcut    a shortcut "tasks" on the desktop and in the Start menu (runs this script with /app,
rem                                so every start updates); pin it to the taskbar from there (right click, "Pin to taskbar")
rem   start-tasks.cmd /print       print what would be started, start nothing (no pull)
rem   ... /noupdate                as second word: no pull (the check of the sums still runs)
setlocal EnableExtensions

set "page=%~dp0tasks.html"
if not exist "%page%" (
  echo tasks.html is missing next to this script: "%page%"
  exit /b 1
)

set "mode=%~1"
if /i "%mode%"=="" set "mode=/tab"
if /i not "%mode%"=="/tab" if /i not "%mode%"=="/app" if /i not "%mode%"=="/shortcut" if /i not "%mode%"=="/print" if /i not "%mode%"=="/update" (
  echo Unknown option "%~1". Use /app, /update, /shortcut or /print, or nothing.
  exit /b 2
)
if not "%~2"=="" if /i not "%~2"=="/noupdate" (
  echo Unknown option "%~2". The second word can only be /noupdate.
  exit /b 2
)

rem The update: a pull where it can be made, then the check of the file.
set "pull=1"
if /i "%~2"=="/noupdate" set "pull="
if /i "%mode%"=="/print" set "pull="
if /i "%mode%"=="/shortcut" set "pull="
if defined pull call :update
if /i not "%mode%"=="/print" (
  call :check_sum
  if errorlevel 1 exit /b 1
)
if /i "%mode%"=="/update" exit /b 0

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
rem The link runs this script with /app (minimized, it closes once Chrome is started), so every start pulls first.
set "TASKS_WEB_CHROME=%chrome%"
set "TASKS_WEB_SCRIPT=%~f0"
set "TASKS_WEB_DIR=%~dp0."
powershell -NoProfile -NonInteractive -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$shell = New-Object -ComObject WScript.Shell;" ^
  "foreach ($dir in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs')) {" ^
  "  $link = $shell.CreateShortcut((Join-Path $dir 'tasks.lnk'));" ^
  "  $link.TargetPath = $env:ComSpec;" ^
  "  $q = [char]34; $link.Arguments = '/c ' + $q + $q + $env:TASKS_WEB_SCRIPT + $q + ' /app' + $q;" ^
  "  $link.WorkingDirectory = $env:TASKS_WEB_DIR;" ^
  "  $link.WindowStyle = 7;" ^
  "  $link.IconLocation = $env:TASKS_WEB_CHROME + ',0';" ^
  "  $link.Description = 'tasks (web page in Chrome, updated at every start)';" ^
  "  $link.Save();" ^
  "  Write-Output ('Made ' + $link.FullName)" ^
  "}"
exit /b %errorlevel%

rem The pull: only in a clone and with git; a failure (offline, local changes, a branch that moved apart) is said and
rem the page as it is opens.
:update
where git >nul 2>nul
if errorlevel 1 (
  echo git was not found: the page is not updated.
  exit /b 0
)
if not exist "%~dp0.git" (
  echo This folder is not a clone of tasks-web: the page is not updated.
  exit /b 0
)
echo Updating the page ^(git pull^) ...
git -C "%~dp0." pull --ff-only --quiet
if errorlevel 1 echo The pull failed ^(offline, or local changes^): the page as it is opens.
exit /b 0

rem The check: tasks.html must match its line in SHA256SUMS. Without the file or the line it is said and not checked
rem (an old clone); a file that does not match is not opened.
:check_sum
set "TASKS_WEB_DIR=%~dp0."
powershell -NoProfile -NonInteractive -Command ^
  "$d = $env:TASKS_WEB_DIR; $sums = Join-Path $d 'SHA256SUMS';" ^
  "if (-not (Test-Path -LiteralPath $sums)) { Write-Output 'SHA256SUMS is missing: tasks.html is not checked.'; exit 0 }" ^
  "$line = @(Get-Content -LiteralPath $sums | Where-Object { $_ -match '^\s*[0-9a-fA-F]{64}\s+\*?tasks\.html\s*$' })[0];" ^
  "if (-not $line) { Write-Output 'SHA256SUMS names no tasks.html: it is not checked.'; exit 0 }" ^
  "$want = ($line.Trim() -split '\s+')[0].ToLower();" ^
  "$sha = [Security.Cryptography.SHA256]::Create();" ^
  "$have = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes((Join-Path $d 'tasks.html')))).Replace('-', '').ToLower();" ^
  "if ($have -ne $want) { Write-Output 'tasks.html does not match SHA256SUMS, so it is not opened. Look at git status in this folder.'; exit 1 }"
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
