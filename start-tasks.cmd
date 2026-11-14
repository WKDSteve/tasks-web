@echo off
rem The setup and update tool of the page tasks.html of this folder. No Neovim, no install. The everyday start does
rem not run it: the shortcut it makes points at the browser itself, so a click starts the browser and nothing else (no
rem cmd, no git, no PowerShell). Run from a terminal, it updates the page first: this folder is a clone of tasks-web,
rem and `git pull --ff-only` brings the newest tasks.html (skipped without git, outside a clone, or offline: the page as
rem it is opens). The file is then checked against SHA256SUMS; a file that does not match is not opened.
rem
rem   start-tasks.cmd /shortcut    a shortcut "tasks" on the desktop and in the Start menu that starts Chrome with the
rem                                page in a window of its own (without Chrome: the page in the default browser);
rem                                pin it to the taskbar from there (right click, "Pin to taskbar")
rem   start-tasks.cmd /update      pull and check only, start nothing: the way to update the page
rem   start-tasks.cmd              update, check, then the page in a tab of Chrome
rem   start-tasks.cmd /app         the same, in a window of its own (no tabs, its own button in the taskbar)
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
if not defined chrome if /i not "%mode%"=="/shortcut" (
  echo Chrome was not found. Opening tasks.html in the default browser; writing needs Chrome or Edge.
  if /i "%mode%"=="/print" (echo start "" "%page%") else start "" "%page%"
  exit /b 0
)

rem A tab takes the path; a window of its own (and its shortcut) takes the address.
if defined chrome if /i not "%mode%"=="/tab" (
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
rem The link starts the browser itself: Chrome with the address of the page as a window of its own, or, without
rem Chrome, the page (the default browser opens it). No script runs at a click, so a click does not update the page:
rem `start-tasks.cmd /update` does. The link holds the paths of today; make it again after moving the clone or Chrome.
rem TASKS_WEB_LINK_DIR (for a test): the one folder the link is written to, instead of the desktop and the Start menu.
set "TASKS_WEB_CHROME=%chrome%"
set "TASKS_WEB_URL=%url%"
set "TASKS_WEB_PAGE=%page%"
set "TASKS_WEB_DIR=%~dp0."
powershell -NoProfile -NonInteractive -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$shell = New-Object -ComObject WScript.Shell;" ^
  "$dirs = if ($env:TASKS_WEB_LINK_DIR) { @($env:TASKS_WEB_LINK_DIR) } else { [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs') };" ^
  "foreach ($dir in $dirs) {" ^
  "  $link = $shell.CreateShortcut((Join-Path $dir 'tasks.lnk'));" ^
  "  if ($env:TASKS_WEB_CHROME) {" ^
  "    $link.TargetPath = $env:TASKS_WEB_CHROME;" ^
  "    $q = [char]34; $link.Arguments = $q + '--app=' + $env:TASKS_WEB_URL + $q;" ^
  "    $link.Description = 'tasks (web page in a window of Chrome)'" ^
  "  } else {" ^
  "    $link.TargetPath = $env:TASKS_WEB_PAGE;" ^
  "    $link.Arguments = '';" ^
  "    $link.Description = 'tasks (web page in the default browser)'" ^
  "  };" ^
  "  $link.WorkingDirectory = $env:TASKS_WEB_DIR;" ^
  "  $link.WindowStyle = 1;" ^
  "  $ico = [IO.Path]::GetFullPath((Join-Path $env:TASKS_WEB_DIR 'assets\icons\tasks-web\tasks-web.ico'));" ^
  "  if (Test-Path -LiteralPath $ico) { $link.IconLocation = $ico + ',0' } elseif ($env:TASKS_WEB_CHROME) { $link.IconLocation = $env:TASKS_WEB_CHROME + ',0' };" ^
  "  $link.Save();" ^
  "  Write-Output ('Made ' + $link.FullName)" ^
  "}"
if errorlevel 1 exit /b 1
if not defined chrome echo Chrome was not found: the shortcut opens tasks.html in the default browser; writing needs Chrome or Edge.
echo The shortcut starts the browser and nothing else. To update the page: start-tasks.cmd /update
exit /b 0

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
