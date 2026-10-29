# tasks-web

The page of [tasks-desktop](https://github.com/WKDSteve/tasks-desktop) as a single HTML file that Chrome opens
from disk (`file://`). No install, no server, no host: the file makes no network request (its CSP forbids it), and
the vault comes from a local folder you pick in the browser.

This repository holds only built files. The sources live in tasks-desktop; its build writes here. Do not edit
the files by hand.

## Now: the probe

`probe.html` checks whether this works on a machine at all, before the real page is built. It reads nothing but
the folder you pick.

```
git clone https://github.com/WKDSteve/tasks-web.git
```

1. Check the file: `Get-FileHash probe.html` must match the line in `SHA256SUMS`.
2. Open `file:///C:/repos/tasks-web/probe.html` in Chrome (adjust the path).
3. Create an **empty** test folder. Never pick a real vault.
4. Press button 1 and pick the test folder. The page writes, renames and deletes one file in it, called
   `tasks-web-probe.txt`.
5. Reload the page, then close and reopen Chrome, and each time press button 2. After the restart, the line
   "Marker of the previous visit" shows whether Chrome kept the page's storage at all (a time in both
   places) or wiped it (`none`).
6. Press "Copy result" and paste the text into the notes of the task
   `ALL/probe-seite-web-variante-workstation` in tasks-vault.
7. In `chrome://policy`, filter for `FileSystem` and for `URL` and note what is set.

Update later with `git pull`.

## Now: the engine check

`engine-check.html` starts the tasks.nvim engine in the browser, on a small synthetic test vault that is part
of the file (it reads no folder of this machine). Open it like the probe, wait until every line is there, press
"Copy result" and paste the text into the notes of `tasks-desktop/web-variante-ohne-installation-pilot`.

## Now: the page (read only)

`tasks.html` is the full page of tasks-desktop with the tasks.nvim engine running in the browser. For now it only
reads; write as before with `tasks.lua` in Neovim and commit with git.

1. `git pull`, then check the file: `Get-FileHash tasks.html` must match the line in `SHA256SUMS`.
2. Open `file:///C:/repos/tasks-web/tasks.html` in Chrome (adjust the path).
3. Press "Choose folder ..." (German: "Ordner wählen ...") and pick the vault (the folder that holds the areas). The page reads the `*.md`
   files, `areas.json` and `vault.json` into memory; `.git` and other hidden folders are skipped.
4. After a restart of Chrome the page shows the vault used last: press "Allow access" ("Zugriff erlauben") once (no picker).
5. Changes on disk show up when the tab gets focus again, or within 30 seconds.

Missing compared to the app: writing (create, `set`, `done`), tray, autostart, notifications, "show in Explorer",
"open in editor", several vaults at once. Plan: `tasks-desktop/web-variante-ohne-installation-pilot` in
tasks-vault.
