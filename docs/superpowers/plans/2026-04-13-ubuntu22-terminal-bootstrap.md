# Ubuntu 22.04 Terminal Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On this `Ubuntu 22.04` machine, install the repo-defined terminal toolchain and link the repo-managed dotfiles with proxy-aware networking and basic validation.

**Architecture:** Keep the repository’s installation logic intact by using `install/ubuntu.sh` and `bootstrap/common.sh` as the source of truth, but execute the phases separately so proxy, privilege, and download failures are easy to isolate. User-space downloads inherit `http_proxy` / `https_proxy` / `all_proxy`, while privileged apt commands use a temporary `/etc/apt/apt.conf.d/90codex-proxy` file so `run_root` can stay unchanged and user-home installs still land under `/home/xing`.

**Tech Stack:** Bash, `apt`, `sudo`, GitHub Release downloads via `curl`/`wget`, pinned git clones, WezTerm Fury apt repo, symlink-based dotfiles deployment

---

## File Map

- `install/ubuntu.sh` — canonical Ubuntu install order and package list
- `bootstrap/common.sh` — shared install functions for Neovim, Lazygit, Yazi, WezTerm repo setup, plugin clones, and config linking
- `bootstrap/plugins.lock.sh` — pinned refs for `oh-my-zsh`, `powerlevel10k`, zsh plugins, and tmux plugins
- `config/zsh/.zshrc` — user shell config linked to `~/.zshrc`
- `config/zsh/.p10k.zsh` — prompt config linked to `~/.p10k.zsh`
- `config/tmux/.tmux.conf` — tmux config linked to `~/.tmux.conf`
- `config/wezterm/wezterm.lua` — WezTerm config linked to `~/.wezterm.lua`
- `config/nvim` — Neovim config linked to `~/.config/nvim`
- `config/yazi` — Yazi config linked to `~/.config/yazi`
- `/etc/apt/apt.conf.d/90codex-proxy` — temporary root-only apt proxy config created for this rollout and removed during cleanup
- `/usr/share/keyrings/wezterm-fury.gpg` — WezTerm apt repository keyring
- `/etc/apt/sources.list.d/wezterm.list` — WezTerm apt repository definition
- `/home/xing/.local/opt/nvim` — Neovim unpack target managed by `install_neovim_linux`
- `/home/xing/.local/bin/nvim` — Neovim shim created by the repo bootstrap
- `/home/xing/.local/bin/lazygit` — Lazygit binary installed from GitHub Release
- `/home/xing/.local/bin/yazi` — Yazi binary installed from GitHub Release
- `/home/xing/.local/bin/ya` — Yazi helper binary installed from GitHub Release
- `/home/xing/.oh-my-zsh` — pinned `oh-my-zsh` clone target
- `/home/xing/.tmux/plugins` — pinned tmux plugin clone targets

### Task 1: Confirm machine state and proxy reachability

**Files:**
- Read: `install/ubuntu.sh`
- Read: `bootstrap/common.sh`
- Read: `/etc/os-release`

- [ ] **Step 1: Confirm the repo root and OS release**

Run:

```bash
cd /home/xing/project/wezterm_config
test -f install/ubuntu.sh
test -f bootstrap/common.sh
source /etc/os-release
printf '%s\n' "$PRETTY_NAME"
```

Expected: prints `Ubuntu 22.04...`

- [ ] **Step 2: Confirm `sudo` credentials are available before downloads start**

Run:

```bash
sudo -v
```

Expected: exits `0` after password entry or cached credentials refresh

- [ ] **Step 3: Export the proxy environment for the current shell**

Run:

```bash
export http_proxy=http://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10808
export all_proxy=socks5://127.0.0.1:10808
env | grep -E '^(http_proxy|https_proxy|all_proxy)='
```

Expected: prints all three proxy variables with `127.0.0.1:10808`

- [ ] **Step 4: Verify outbound HTTPS works through the proxy**

Run:

```bash
curl -I --max-time 10 https://github.com
```

Expected: response headers with `HTTP/2 200` or `HTTP/2 302`

### Task 2: Prepare apt to use the proxy and install bootstrap prerequisites

**Files:**
- Create: `/etc/apt/apt.conf.d/90codex-proxy`
- Modify: `/var/lib/apt/lists`
- Modify: `/var/lib/dpkg/status`

- [ ] **Step 1: Write a temporary apt proxy config for privileged package operations**

Run:

```bash
printf 'Acquire::http::Proxy "http://127.0.0.1:10808";\nAcquire::https::Proxy "http://127.0.0.1:10808";\n' | sudo tee /etc/apt/apt.conf.d/90codex-proxy >/dev/null
sudo cat /etc/apt/apt.conf.d/90codex-proxy
```

Expected: prints two `Acquire::...::Proxy` lines pointing at `127.0.0.1:10808`

- [ ] **Step 2: Refresh apt package indexes with the temporary proxy enabled**

Run:

```bash
sudo apt-get update
```

Expected: `Reading package lists... Done`

- [ ] **Step 3: Install the minimum commands required before using repo bootstrap functions**

Run:

```bash
sudo apt-get install -y ca-certificates curl git gnupg python3 unzip wget
```

Expected: apt reports packages are installed or already the newest version

- [ ] **Step 4: Confirm the bootstrap prerequisites are now executable**

Run:

```bash
command -v git
command -v curl
command -v python3
```

Expected: prints absolute paths for all three commands

### Task 3: Install the Ubuntu package set defined by the repo

**Files:**
- Read: `install/ubuntu.sh`
- Modify: `/var/lib/dpkg/status`

- [ ] **Step 1: Install the required Ubuntu packages from `install/ubuntu.sh`**

Run:

```bash
cd /home/xing/project/wezterm_config
bash -lc 'set -euo pipefail; source bootstrap/common.sh; run_root apt-get install -y build-essential ca-certificates curl file fzf fd-find git gnupg jq ripgrep tmux unzip wget zsh'
```

Expected: apt completes without errors and installs or confirms the required packages

- [ ] **Step 2: Install `bat` when the current Ubuntu sources provide it**

Run:

```bash
cd /home/xing/project/wezterm_config
bash -lc 'set -euo pipefail; source bootstrap/common.sh; if run_root apt-cache show bat >/dev/null 2>&1; then run_root apt-get install -y bat; else echo "skip bat"; fi'
```

Expected: either apt installs `bat` or prints `skip bat`

- [ ] **Step 3: Install `eza` when the current Ubuntu sources provide it**

Run:

```bash
cd /home/xing/project/wezterm_config
bash -lc 'set -euo pipefail; source bootstrap/common.sh; if run_root apt-cache show eza >/dev/null 2>&1; then run_root apt-get install -y eza; else echo "skip eza"; fi'
```

Expected: either apt installs `eza` or prints `skip eza`

- [ ] **Step 4: Install `direnv` when the current Ubuntu sources provide it**

Run:

```bash
cd /home/xing/project/wezterm_config
bash -lc 'set -euo pipefail; source bootstrap/common.sh; if run_root apt-cache show direnv >/dev/null 2>&1; then run_root apt-get install -y direnv; else echo "skip direnv"; fi'
```

Expected: either apt installs `direnv` or prints `skip direnv`

- [ ] **Step 5: Confirm the core apt-installed tools are visible in `PATH`**

Run:

```bash
command -v zsh
command -v tmux
command -v rg
command -v fzf
command -v fdfind
```

Expected: prints absolute paths for each installed command

### Task 4: Install Neovim, Lazygit, and Yazi with the repo bootstrap functions

**Files:**
- Read: `bootstrap/common.sh`
- Create: `/home/xing/.local/opt/nvim`
- Create: `/home/xing/.local/bin/nvim`
- Create: `/home/xing/.local/bin/lazygit`
- Create: `/home/xing/.local/bin/yazi`
- Create: `/home/xing/.local/bin/ya`
- Create: `/home/xing/.local/bin/bat`
- Create: `/home/xing/.local/bin/fd`

- [ ] **Step 1: Install Neovim using the repo’s `install_neovim_linux` function**

Run:

```bash
cd /home/xing/project/wezterm_config
env http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 all_proxy=socks5://127.0.0.1:10808 bash -lc 'set -euo pipefail; source bootstrap/common.sh; install_neovim_linux'
```

Expected: logs `Installing Neovim from ...` and leaves `/home/xing/.local/bin/nvim` executable

- [ ] **Step 2: Install Lazygit using the repo’s `install_lazygit_linux` function**

Run:

```bash
cd /home/xing/project/wezterm_config
env http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 all_proxy=socks5://127.0.0.1:10808 bash -lc 'set -euo pipefail; source bootstrap/common.sh; install_lazygit_linux'
```

Expected: logs `Installing Lazygit from ...` and leaves `/home/xing/.local/bin/lazygit` executable

- [ ] **Step 3: Install Yazi using the repo’s `install_yazi_linux` function**

Run:

```bash
cd /home/xing/project/wezterm_config
env http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 all_proxy=socks5://127.0.0.1:10808 bash -lc 'set -euo pipefail; source bootstrap/common.sh; install_yazi_linux'
```

Expected: logs `Installing Yazi from ...` and leaves `/home/xing/.local/bin/yazi` and `/home/xing/.local/bin/ya` executable

- [ ] **Step 4: Create the Ubuntu compatibility symlinks for `bat` and `fd` when needed**

Run:

```bash
mkdir -p /home/xing/.local/bin
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  ln -sf "$(command -v batcat)" /home/xing/.local/bin/bat
fi
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" /home/xing/.local/bin/fd
fi
ls -l /home/xing/.local/bin | grep -E ' (bat|fd)$' || true
```

Expected: `bat` and `fd` symlinks appear when only `batcat` / `fdfind` exist

- [ ] **Step 5: Confirm the user-space binaries are installed before moving on**

Run:

```bash
/home/xing/.local/bin/nvim --version | head -n 1
/home/xing/.local/bin/lazygit --version
/home/xing/.local/bin/yazi --version
```

Expected: each command prints a version string and exits `0`

### Task 5: Install WezTerm and the pinned shell/tmux plugin stack

**Files:**
- Read: `bootstrap/common.sh`
- Create: `/usr/share/keyrings/wezterm-fury.gpg`
- Create: `/etc/apt/sources.list.d/wezterm.list`
- Create: `/home/xing/.oh-my-zsh`
- Create: `/home/xing/.oh-my-zsh/custom/themes/powerlevel10k`
- Create: `/home/xing/.oh-my-zsh/custom/plugins/zsh-autosuggestions`
- Create: `/home/xing/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting`
- Create: `/home/xing/.tmux/plugins/tpm`
- Create: `/home/xing/.tmux/plugins/tmux-sensible`
- Create: `/home/xing/.tmux/plugins/tmux-yank`
- Create: `/home/xing/.tmux/plugins/tmux-resurrect`
- Create: `/home/xing/.tmux/plugins/tmux-continuum`
- Create: `/home/xing/.tmux/plugins/tmux-powerline`

- [ ] **Step 1: Add the WezTerm apt repository using the repo’s helper**

Run:

```bash
cd /home/xing/project/wezterm_config
env http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 all_proxy=socks5://127.0.0.1:10808 bash -lc 'set -euo pipefail; source bootstrap/common.sh; ensure_wezterm_apt_repo'
```

Expected: creates `/usr/share/keyrings/wezterm-fury.gpg` and `/etc/apt/sources.list.d/wezterm.list`

- [ ] **Step 2: Refresh apt and install `wezterm`**

Run:

```bash
sudo apt-get update
sudo apt-get install -y wezterm
```

Expected: apt installs `wezterm` without repository signature errors

- [ ] **Step 3: Install the pinned oh-my-zsh stack from `bootstrap/plugins.lock.sh`**

Run:

```bash
cd /home/xing/project/wezterm_config
env http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 all_proxy=socks5://127.0.0.1:10808 bash -lc 'set -euo pipefail; source bootstrap/common.sh; install_oh_my_zsh_stack'
```

Expected: creates `/home/xing/.oh-my-zsh` and the pinned custom theme/plugin directories

- [ ] **Step 4: Install the pinned tmux plugin set from `bootstrap/plugins.lock.sh`**

Run:

```bash
cd /home/xing/project/wezterm_config
env http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 all_proxy=socks5://127.0.0.1:10808 bash -lc 'set -euo pipefail; source bootstrap/common.sh; install_tmux_plugins'
```

Expected: creates the tmux plugin directories under `/home/xing/.tmux/plugins`

- [ ] **Step 5: Confirm the shell and terminal plugin directories now exist**

Run:

```bash
test -d /home/xing/.oh-my-zsh
test -d /home/xing/.oh-my-zsh/custom/themes/powerlevel10k
test -d /home/xing/.tmux/plugins/tpm
test -d /home/xing/.tmux/plugins/tmux-resurrect
wezterm -V
```

Expected: all directory checks exit `0` and `wezterm -V` prints a version string

### Task 6: Link the repo-managed configs into the user profile

**Files:**
- Modify: `/home/xing/.zshrc`
- Modify: `/home/xing/.p10k.zsh`
- Modify: `/home/xing/.tmux.conf`
- Modify: `/home/xing/.wezterm.lua`
- Modify: `/home/xing/.config/nvim`
- Modify: `/home/xing/.config/yazi`

- [ ] **Step 1: Link the dotfiles using the repo’s `install_config_payload` helper**

Run:

```bash
cd /home/xing/project/wezterm_config
env DOTFILES_LINK_MODE=symlink http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 all_proxy=socks5://127.0.0.1:10808 bash -lc 'set -euo pipefail; source bootstrap/common.sh; install_config_payload'
```

Expected: creates or refreshes symlinks from the user profile back to the repository config files

- [ ] **Step 2: Verify the top-level dotfiles point at the repo**

Run:

```bash
readlink -f /home/xing/.zshrc
readlink -f /home/xing/.p10k.zsh
readlink -f /home/xing/.tmux.conf
readlink -f /home/xing/.wezterm.lua
```

Expected: outputs repo-backed paths under `/home/xing/project/wezterm_config/config/...`

- [ ] **Step 3: Verify the config directories point at the repo**

Run:

```bash
readlink -f /home/xing/.config/nvim
readlink -f /home/xing/.config/yazi
```

Expected: outputs `/home/xing/project/wezterm_config/config/nvim` and `/home/xing/project/wezterm_config/config/yazi`

- [ ] **Step 4: Check whether any backups were created during linking**

Run:

```bash
find /home/xing -maxdepth 2 \( -name '.zshrc.bak.*' -o -name '.p10k.zsh.bak.*' -o -name '.tmux.conf.bak.*' -o -name '.wezterm.lua.bak.*' \) | sort
```

Expected: prints backup paths only when pre-existing files were replaced

### Task 7: Run validation, set the default shell, and remove temporary proxy state

**Files:**
- Modify: `/etc/apt/apt.conf.d/90codex-proxy`
- Read: `/home/xing/.zshrc`
- Read: `/home/xing/.tmux.conf`
- Read: `/home/xing/.wezterm.lua`

- [ ] **Step 1: Validate the interactive shell can start with the linked config**

Run:

```bash
zsh -i -c exit
```

Expected: exits `0` without a shell startup error

- [ ] **Step 2: Validate tmux can load the linked configuration**

Run:

```bash
tmux source-file /home/xing/.tmux.conf
```

Expected: exits `0` without a tmux parse error

- [ ] **Step 3: Validate the core binaries report healthy versions**

Run:

```bash
nvim --version | head -n 1
yazi --version
lazygit --version
wezterm -V
```

Expected: each command prints a version string and exits `0`

- [ ] **Step 4: Set `zsh` as the login shell if it is not already the default**

Run:

```bash
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  chsh -s "$(command -v zsh)"
fi
getent passwd "$USER" | cut -d: -f7
```

Expected: prints the absolute `zsh` path, typically `/usr/bin/zsh`

- [ ] **Step 5: Remove the temporary apt proxy file after installation is complete**

Run:

```bash
sudo rm -f /etc/apt/apt.conf.d/90codex-proxy
test ! -f /etc/apt/apt.conf.d/90codex-proxy
```

Expected: exits `0` and leaves no `90codex-proxy` file behind

- [ ] **Step 6: Record the two post-install reminders for the user**

Run:

```bash
printf '%s\n' \
  '1. Open a new terminal or run exec zsh to enter the new login shell.' \
  '2. Keep the proxy available for the first interactive nvim launch so LazyVim can fetch plugins.'
```

Expected: prints the two follow-up reminders verbatim
