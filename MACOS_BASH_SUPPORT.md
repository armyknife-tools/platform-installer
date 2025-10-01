# macOS Bash Support

## Overview

The ArmyknifeLabs Platform Installer now fully supports both bash and zsh on macOS. The installer will automatically detect your current shell and offer to switch to bash if you're currently using zsh.

## Changes Made

### 1. Shell Detection and User Prompting

#### [install.sh](install.sh)
- Added `USER_SHELL` variable to track the current shell
- Added interactive prompt for macOS users to switch to bash
- Updated to call `chsh -s /bin/bash` when user opts to switch
- Enhanced post-install message to show correct shell RC file
- Added warning for bash users to restart their terminal

#### [scripts/interactive-install.sh](scripts/interactive-install.sh)
- Added "Shell Configuration" section to `detect_system()` function
- Prompts macOS users to choose between bash and zsh
- Explains that zsh → Oh-My-Zsh and bash → Oh-My-Bash
- Automatically detects if already using bash

### 2. Oh-My-Bash Support on macOS

#### [makefiles/Makefile.Shell.mk](makefiles/Makefile.Shell.mk)
- Updated `install-oh-my-shell` target to detect bash vs zsh on macOS
- Modified `install-oh-my-bash` to support both Linux and macOS:
  - Changed installer invocation from `sh` to `bash`
  - Added macOS-specific `sed` syntax handling (BSD vs GNU)
  - Updated comments to reflect macOS support

### 3. Documentation Updates

#### [README.md](README.md)
- Updated "Shell Environment" section to clarify bash/zsh support
- Added note about automatic shell detection on macOS
- Updated installation profile table
- Added user note after Quick Install section

## User Experience

### Interactive Installation Flow on macOS

1. **System Detection**
   ```
   System Information:
   OS: macOS 14.6.0
   Current shell: zsh

   Shell Configuration
   Current shell: zsh

   macOS uses zsh by default, but bash is also supported.
   Zsh → Oh-My-Zsh will be installed
   Bash → Oh-My-Bash will be installed

   Switch to /bin/bash for better compatibility? (y/N):
   ```

2. **Shell Installation**
   - If zsh: Installs Oh-My-Zsh with agnoster theme
   - If bash: Installs Oh-My-Bash with powerline-multiline theme

3. **Post-Installation**
   ```
   📝 Next Steps:

   1. Restart your shell or run:
      source ~/.bashrc

      Note: You've switched to bash. Please restart your terminal
            for the shell change to take full effect.
   ```

### Non-Interactive Mode

When using `--yes` or in CI/CD environments:
- The installer will automatically detect the current shell
- No prompts will be shown
- Oh-My-Bash will be installed if bash is detected
- Oh-My-Zsh will be installed if zsh is detected

## Testing

### Test on macOS with zsh (default)
```bash
# Should prompt to switch to bash
./install.sh --profile minimal
```

### Test on macOS with bash (already switched)
```bash
# Should detect bash and install Oh-My-Bash automatically
chsh -s /bin/bash
exec bash
./install.sh --profile minimal
```

### Test non-interactive mode
```bash
# Should auto-detect without prompting
./install.sh --yes --profile minimal
```

## Compatibility

- ✅ macOS 13+ (Ventura and later)
- ✅ Both Intel and Apple Silicon
- ✅ bash 3.2+ (macOS default) and 5.x (Homebrew)
- ✅ zsh 5.8+ (macOS default)

## Known Issues

### bash on macOS
- macOS ships with bash 3.2 (due to GPL licensing)
- Most features work fine, but consider installing bash 5.x via Homebrew for modern features:
  ```bash
  brew install bash
  ```

### Oh-My-Bash vs Oh-My-Zsh
- Oh-My-Bash has fewer plugins/themes than Oh-My-Zsh
- Both integrate fully with ArmyknifeLabs functions
- Starship prompt works identically on both

## Migration Guide

### Switching from zsh to bash
```bash
# 1. Switch shell
chsh -s /bin/bash

# 2. Restart terminal
exec bash

# 3. Reinstall or run shell setup
make -C ~/armyknife-platform -f makefiles/Makefile.Shell.mk install-oh-my-bash
```

### Switching from bash to zsh
```bash
# 1. Switch shell
chsh -s /bin/zsh

# 2. Restart terminal
exec zsh

# 3. Reinstall or run shell setup
make -C ~/armyknife-platform -f makefiles/Makefile.Shell.mk install-oh-my-zsh
```

## Related Files

- [install.sh](install.sh) - Main installer with shell detection
- [scripts/interactive-install.sh](scripts/interactive-install.sh) - Interactive installer UI
- [makefiles/Makefile.Shell.mk](makefiles/Makefile.Shell.mk) - Shell configuration logic
- [README.md](README.md) - User-facing documentation

## Future Enhancements

- [ ] Add fish shell support
- [ ] Create automated tests for shell switching
- [ ] Add shell performance comparison guide
- [ ] Create video tutorial for macOS users
