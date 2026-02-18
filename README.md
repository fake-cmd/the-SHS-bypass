 Vortex

A complete fresh rebuild of this repository as a local web portal.

## Highlights

- New Node.js static server (`index.js`)
- New frontend app in `static/` with tabs for Home, Games, Movies, and Settings
- Default search engine is DuckDuckGo
- Settings page includes a save-data manager for export/import of localStorage + cookies
- Ad toggle is safe and **does not break app behavior** when disabled
- **Made by colt**

## Run locally

```bash
npm start
```

Open `http://127.0.0.1:3000`.

## Publish to GitHub main

Target repo:

- `https://github.com/fake-cmd/the-SHS-bypass.git`

After publish, files should appear at:

- `https://github.com/fake-cmd/the-SHS-bypass/tree/main`

### Windows PowerShell (from anywhere, including `C:\Windows\System32`)

If you are **not in this repo folder**, use this one-liner first. It downloads the publisher script to your temp folder and runs it:

```powershell
$tmp = Join-Path $env:TEMP "publish-main.ps1"; Invoke-WebRequest "https://raw.githubusercontent.com/fake-cmd/the-SHS-bypass/main/scripts/publish-main.ps1" -OutFile $tmp; powershell -ExecutionPolicy Bypass -File $tmp
```

What this does:

1. Detects `git`; if missing, installs portable **MinGit** into your user profile (no admin).
2. If you are not inside a git repo, clones to `C:\Users\<you>\the-SHS-bypass`.
3. Checks out `main` and pushes to `origin`.

### Windows PowerShell (when already inside the repo)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-main.ps1
```

### Bash / npm options

```bash
npm run publish:main
# or
bash scripts/publish-to-github.sh
```

If needed, provide another remote URL:

```bash
bash scripts/publish-to-github.sh https://github.com/<owner>/<repo>.git
```
