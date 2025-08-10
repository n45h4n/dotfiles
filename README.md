# 🛠️ Dotfiles

Personal dotfiles for my development environment using **zsh** on **WSL (Ubuntu)** and **macOS**.  
Includes setup scripts, package installation via Homebrew, Neovim (Kickstart) configuration, and daily auto-updates.

---

## 🚀 Features
- **Cross-platform:** Works on both macOS and WSL Ubuntu.
- **Automated setup:** Installs and configures Homebrew, zsh, Neovim, dev tools, and dotfiles.
- **Package management:** OS-specific `Brewfile` for reproducible installs.
- **Neovim Kickstart fork:** Automatically installed/updated.
- **Daily auto-update:** Pulls latest changes for dotfiles and Kickstart.
- **Developer-friendly tools:** `fzf`, `zellij`, `tmux`, `lazygit`, Python/Node/Go, MySQL client, ngrok, ffmpeg, and more.

---

## 🖥️ Fresh Windows (WSL) Setup

### 1. Install WSL with Ubuntu
In **PowerShell** (run as Administrator):
```powershell
wsl --install -d Ubuntu
````

Restart your computer if prompted.

---

### 2. Update & Install Git

In **Ubuntu (WSL)**:

```bash
sudo apt update && sudo apt install -y git
```

---

### 3. Clone & Bootstrap

```bash
git clone https://github.com/n45h4n/dotfiles.git
cd dotfiles
./scripts/bootstrap-linux.sh
```

---

### 4. Restart WSL

In **PowerShell**:

```powershell
wsl --shutdown
```

Reopen Ubuntu — you’ll land in zsh with everything set up.

✅ Enjoy — zsh + Homebrew + Neovim + all your tools are ready.

---

## 🍎 Fresh Mac Setup

### 1. Clone & Bootstrap

In **Terminal**:

```bash
git clone https://github.com/n45h4n/dotfiles.git
cd dotfiles
./scripts/bootstrap-mac.sh
```

---

### 2. Restart Terminal

Close & reopen **Terminal** (or iTerm2).

✅ Done — full zsh + brew + Neovim + all tools set.

---

## 📦 Installed Tools (Highlights)

* **Shell & Core:** zsh, git, stow, curl, wget, jq, ripgrep, fd, fzf, tmux, zellij, lazygit, ranger, tree, htop, tldr.
* **Languages:** Python 3.12 (pipx, uv), Node.js, Go (Linux only by default).
* **Build Tools:** gcc, make, pkg-config, cmake, ninja.
* **Databases:** SQLite, MySQL client.
* **Cloud & Misc:** ngrok, ffmpeg, rclone.
* **Neovim LSP:** lua-language-server.

---

## 🔄 Updating

Updates run automatically **once per day** in the background when you open a shell.

Manual update:

```bash
update-all
```

This pulls the latest changes for both:

* Dotfiles repo (rebased to keep local changes)
* Kickstart.nvim (fast-forward only)

---
