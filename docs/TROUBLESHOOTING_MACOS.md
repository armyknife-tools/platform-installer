# Troubleshooting Guide - macOS

## Common Issues on macOS

### Shell Configuration Issues

#### Issue: "Oh-My-Bash not working after installation"

**Symptoms:**
- Commands like `git` aliases not working
- Theme not displaying correctly
- `.bashrc` not being sourced

**Solution:**
macOS bash doesn't automatically source `.bashrc`. You need to create/update `~/.bash_profile`:

```bash
# Create ~/.bash_profile if it doesn't exist
cat >> ~/.bash_profile << 'EOF'
# Source .bashrc if it exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF

# Restart your terminal or source it
source ~/.bash_profile
```

**Or use this automated fix:**
```bash
make -C ~/armyknife-platform -f makefiles/Makefile.Shell.mk configure-shell
```

---

#### Issue: "Command not found: starship" or similar errors

**Symptoms:**
- Starship prompt not loading
- Error messages about missing commands

**Solution:**
The PATH might not be set correctly. Check your `.bashrc`:

```bash
# Add this to ~/.bashrc if missing
export PATH="$HOME/.armyknife/bin:$PATH"

# If starship was installed via Homebrew
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Reload
source ~/.bashrc
```

---

#### Issue: "sed: command s not recognized" errors during installation

**Symptoms:**
- Installation fails with sed errors
- Theme not being set in `.bashrc`

**Solution:**
This was a bug in older versions - now fixed. macOS uses BSD sed which requires different syntax than Linux (GNU sed).

**If you're still seeing this:**
1. Update to the latest version:
   ```bash
   cd ~/armyknife-platform
   git pull
   ```

2. Or manually fix the theme:
   ```bash
   # Add to ~/.bashrc
   echo 'OSH_THEME="powerline-multiline"' >> ~/.bashrc
   source ~/.bashrc
   ```

---

### Shell Switching Issues

#### Issue: "chsh: /bin/bash: non-standard shell"

**Symptoms:**
- Can't switch to bash using `chsh -s /bin/bash`
- Error about non-standard shell

**Solution:**
This shouldn't happen with `/bin/bash` (it's the system default), but if it does:

1. Check if bash is in `/etc/shells`:
   ```bash
   grep bash /etc/shells
   ```

2. If not listed, add it:
   ```bash
   echo "/bin/bash" | sudo tee -a /etc/shells
   ```

3. Try switching again:
   ```bash
   chsh -s /bin/bash
   ```

---

#### Issue: "Still using zsh after switching to bash"

**Symptoms:**
- Ran `chsh -s /bin/bash` but still in zsh
- Prompt shows zsh features

**Solution:**
You need to restart your terminal application completely (not just open a new tab):

1. **Close all terminal windows**
2. **Quit Terminal.app or iTerm2 completely** (Cmd+Q)
3. **Reopen the terminal application**
4. Verify:
   ```bash
   echo $SHELL
   # Should show: /bin/bash
   ```

---

### Oh-My-Bash Installation Issues

#### Issue: "Oh-My-Bash installation hangs or fails"

**Symptoms:**
- Installation seems stuck
- Network timeout errors

**Solution:**

1. **Check internet connection:**
   ```bash
   curl -I https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh
   ```

2. **Install manually:**
   ```bash
   # Remove any partial installation
   rm -rf ~/.oh-my-bash

   # Install Oh-My-Bash manually
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
   ```

3. **If behind a proxy:**
   ```bash
   export https_proxy=your-proxy-url
   export http_proxy=your-proxy-url
   make -C ~/armyknife-platform -f makefiles/Makefile.Shell.mk install-oh-my-bash
   ```

---

#### Issue: "Permission denied" errors

**Symptoms:**
- Can't write to `.bashrc`
- Installation fails with permission errors

**Solution:**

1. **Check file permissions:**
   ```bash
   ls -la ~/.bashrc
   # Should be owned by your user
   ```

2. **Fix ownership if needed:**
   ```bash
   sudo chown $USER:staff ~/.bashrc
   chmod 644 ~/.bashrc
   ```

3. **Check home directory permissions:**
   ```bash
   ls -la ~ | head -n 2
   # Should show your user as owner
   ```

---

### Font and Display Issues

#### Issue: "Powerline symbols not displaying correctly"

**Symptoms:**
- Weird characters in prompt
- Boxes or question marks instead of symbols
- Broken arrows or git symbols

**Solution:**

1. **Install Nerd Fonts:**
   ```bash
   make -C ~/armyknife-platform -f makefiles/Makefile.Shell.mk install-fonts
   ```

2. **Configure your terminal to use a Nerd Font:**

   **Terminal.app:**
   - Preferences → Profiles → Font
   - Choose "FiraCode Nerd Font" or "JetBrains Mono Nerd Font"

   **iTerm2:**
   - Preferences → Profiles → Text → Font
   - Choose "FiraCode Nerd Font" or "JetBrains Mono Nerd Font"
   - Enable "Use ligatures" if using FiraCode

3. **Verify font installation:**
   ```bash
   ls ~/Library/Fonts/ | grep -i nerd
   # Or for system-wide
   brew list --cask | grep nerd-font
   ```

---

### Compatibility Issues

#### Issue: "bash version 3.2 - features not working"

**Symptoms:**
- Modern bash features don't work
- Array operations fail
- Some Oh-My-Bash plugins broken

**Solution:**

macOS ships with bash 3.2 (from 2007!) due to licensing. Install a modern bash:

```bash
# Install bash 5.x via Homebrew
brew install bash

# Add to /etc/shells
echo "/opt/homebrew/bin/bash" | sudo tee -a /etc/shells

# Switch to new bash
chsh -s /opt/homebrew/bin/bash

# Restart terminal
exec /opt/homebrew/bin/bash

# Verify version
bash --version
# Should show 5.x
```

---

### Integration Issues

#### Issue: "ArmyknifeLabs functions not available"

**Symptoms:**
- `ak_*` functions return "command not found"
- Custom aliases not working

**Solution:**

1. **Check if bashlib is sourced:**
   ```bash
   grep -r "armyknife" ~/.bashrc
   ```

2. **If missing, add integration:**
   ```bash
   make -C ~/armyknife-platform -f makefiles/Makefile.Shell.mk integrate-armyknife
   ```

3. **Manually verify library location:**
   ```bash
   ls -la ~/.armyknife/lib/
   # Should show core.sh, ui.sh, etc.
   ```

4. **Test sourcing manually:**
   ```bash
   source ~/.armyknife/lib/core.sh
   ak_detect_os
   # Should display OS info
   ```

---

## Diagnostic Commands

Run these commands to diagnose issues:

```bash
# Check shell
echo "Current shell: $SHELL"
echo "Shell version: $BASH_VERSION"

# Check Oh-My-Bash
[ -d ~/.oh-my-bash ] && echo "Oh-My-Bash: Installed" || echo "Oh-My-Bash: Not installed"

# Check bashrc
[ -f ~/.bashrc ] && echo "~/.bashrc: Exists" || echo "~/.bashrc: Missing"
[ -f ~/.bash_profile ] && echo "~/.bash_profile: Exists" || echo "~/.bash_profile: Missing"

# Check Oh-My-Bash config
grep "OSH_THEME" ~/.bashrc

# Check ArmyknifeLabs integration
grep "armyknife" ~/.bashrc

# Check fonts
ls ~/Library/Fonts/ | grep -i nerd

# Check starship
command -v starship && starship --version

# Run platform doctor
make -C ~/armyknife-platform doctor
```

---

## Getting Help

If you're still having issues:

1. **Run the doctor script:**
   ```bash
   make -C ~/armyknife-platform doctor --fix
   ```

2. **Check logs:**
   ```bash
   ls -lt ~/.armyknife/logs/ | head
   tail -n 50 ~/.armyknife/logs/install-*.log
   ```

3. **File an issue:**
   - Include output from diagnostic commands above
   - Include relevant log files
   - Specify macOS version: `sw_vers`
   - Specify architecture: `uname -m`

4. **Community support:**
   - GitHub Issues: https://github.com/armyknife-tools/platform-installer/issues
   - Discussions: https://github.com/armyknife-tools/platform-installer/discussions

---

## Quick Fixes Reference

| Problem | Quick Fix |
|---------|-----------|
| bashrc not loading | Create `~/.bash_profile` that sources `~/.bashrc` |
| Commands not found | Add to PATH in `~/.bashrc` |
| Fonts broken | Install Nerd Fonts and configure terminal |
| sed errors | Update to latest version (bug fixed) |
| Still in zsh | Quit terminal app completely (Cmd+Q) and reopen |
| Old bash version | Install bash 5.x via Homebrew |
| Functions missing | Run `integrate-armyknife` target |

---

## Prevention Tips

- Always restart terminal completely after shell changes (Cmd+Q, not just new tab)
- Keep Homebrew updated: `brew update && brew upgrade`
- Keep platform updated: `make -C ~/armyknife-platform update`
- Use `.bash_profile` to source `.bashrc` on macOS
- Install modern bash (5.x) via Homebrew for best experience
