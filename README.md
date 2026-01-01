# AppImage Auto-Installer

A Bash utility that automatically installs AppImage files from your `~/Applications` directory by creating desktop entries and extracting icons.

## What It Does

This script scans `~/Applications` for AppImage files and: 
- Extracts application icons and metadata from each AppImage
- Creates desktop entries in `~/.local/share/applications`
- Copies icons to `~/.local/share/pixmaps`
- Skips AppImages that are already installed (unless forced)

## Requirements

- Bash shell (uses `mapfile` and `mktemp`)
- AppImage files in `~/Applications`

## Usage

```bash
# Install all new AppImages
./auto-install-appimages.sh

# Force reinstall all AppImages (overwrites existing entries)
./auto-install-appimages.sh --force
```

## Installation

1. Clone this repository or download `auto-install-appimages. sh`
2. Make the script executable: 
   ```bash
   chmod +x auto-install-appimages.sh
   ```
3. Run the script whenever you add new AppImages to `~/Applications`

## Notes

- Desktop entries will appear in your application menu after installation
- The script is idempotent—running it multiple times won't create duplicates unless you use `--force`
- If an AppImage is updated, use `--force` to refresh its desktop entry
