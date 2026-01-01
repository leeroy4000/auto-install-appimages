# AppImage Auto-Installer

This repository contains a small utility script that finds AppImage files in `~/Applications`, extracts icons and metadata, and installs desktop entries into `~/.local/share/applications`.

Files
- `auto-install-appimages.sh` — the installer script (executable).

Usage

```bash
# Run normally (skips already-installed entries):
./auto-install-appimages.sh

# Force reinstall all AppImages:
./auto-install-appimages.sh --force
```

Notes
- The script expects Bash and uses `mapfile` and `mktemp` — it is not POSIX sh.
- It will create desktop entries and copy icons to `~/.local/share/pixmaps`.

Push to a private GitHub repo

Option A: create repo on GitHub website, then push:

```bash
cd ~/auto-install-appimages
git remote add origin git@github.com:<your-username>/auto-install-appimages.git
git branch -M main
git push -u origin main
```

Option B: use GitHub CLI (`gh`):

```bash
cd ~/auto-install-appimages
# creates a private repo and pushes current branch
gh repo create auto-install-appimages --private --source=. --remote=origin --push
```

If you want, I can create the private repo for you with `gh` (requires authentication).
