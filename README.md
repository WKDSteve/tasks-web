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

## Later: the page

`tasks.html`, the full page with the tasks.nvim engine running in the browser. Plan:
`tasks-desktop/web-variante-ohne-installation-pilot` in tasks-vault.
