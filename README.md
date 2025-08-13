# 🛠️ Dotfiles (SSH-only)

Personal dotfiles for **zsh** on **WSL (Ubuntu)** and **macOS**.

> **Important:** This repo is **personal** and assumes **SSH access to GitHub**. Submodules are SSH-only. Cloning with HTTPS **will fail**.

---

## ✨ What you get

* **Automated setup**: zsh + Homebrew + dev tools + configs
* **Kickstart Neovim** (fork) auto-installed via submodule
* **Oh My Zsh** vendored as a submodule (no curl pipes)
* **Brewfile-based** packages (common + OS-specific)
* **Shell niceties**: `fzf`, improved completion, aliases
* **Daily auto-update** on first shell of the day (`update-all`)
* **Idempotent** bootstrap: safe to re-run

---

## ⚙️ Requirements

* **GitHub SSH key added** to your account (instructions below)
* WSL: **Ubuntu** (22.04/24.04) or macOS 13+
* Internet and Git

---

## 🚀 TL;DR (once SSH is ready)

```bash
# Clone (SSH + submodules)
git clone --recurse-submodules git@github.com:n45h4n/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Bootstrap (installs brew, tools, zsh config, etc.)
./scripts/bootstrap.sh
```

Then restart your shell:

* **WSL**: `wsl --shutdown` (from PowerShell), reopen Ubuntu
* **macOS**: close & reopen Terminal/iTerm2

You’ll land in **zsh** with everything ready.

---

## 🔑 Set up SSH for GitHub (once per machine)

1. **Check for keys**

```bash
ls -al ~/.ssh
```

If `id_ed25519` and `id_ed25519.pub` exist, you can skip generate.

2. **Generate key (ed25519)**

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Press **Enter** for default path. Optionally set a passphrase.

3. **Start agent & add key**

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

4. **Add to GitHub**

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy → GitHub → **Settings → SSH and GPG keys → New SSH key** → Paste → Save.

5. **Test**

```bash
ssh -T git@github.com
# Expect: "Hi <username>! You've successfully authenticated..."
```

> ✅ Optional safety: force SSH for GitHub to avoid HTTPS mix-ups

```bash
git config --global url."ssh://git@github.com/".insteadOf https://github.com/
```

---

## 🖥️ Fresh Windows (WSL) Install

1. **Install WSL + Ubuntu** (PowerShell as Admin):

```powershell
wsl --install -d Ubuntu
```

Reboot if asked.

2. **Install Git in WSL**

```bash
sudo apt update && sudo apt install -y git
```

3. **SSH setup** → follow **Set up SSH** above.

4. **Clone + Bootstrap**

```bash
git clone --recurse-submodules git@github.com:n45h4n/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh
```

5. **Restart WSL**

```powershell
wsl --shutdown
```

Open Ubuntu again → you’re in zsh.

---

## 🍎 Fresh macOS Install

1. **SSH setup** → follow **Set up SSH** above.

2. **Clone + Bootstrap**

```bash
git clone --recurse-submodules git@github.com:n45h4n/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh
```

3. **Restart Terminal/iTerm2** → done.

---

## 🧰 What the bootstrap does

* Installs **Homebrew** (Linuxbrew on WSL) if missing
* Installs **common** packages via `brew/Brewfile.common`
* Installs **OS-specific** packages via `brew/Brewfile.{mac,linux}`
* Sets up **zsh** with **Oh My Zsh** (vendored submodule) + completions
* Installs/enables **fzf** keybindings (no rc file spam)
* Installs/updates **Kickstart.nvim** (vendored submodule)
* Adds an `update-all` function:

  * `git pull --rebase --autostash` on dotfiles
  * `git submodule sync && git submodule update --init --recursive`
  * Re-runs Brew bundles as needed
* Enables **daily auto-update** the first time you open a shell each day

> You can safely re-run `./scripts/bootstrap.sh` anytime.

---

## 📦 Installed Tools (highlights)

**Shell & Core**: zsh, git, stow, curl, wget, jq, ripgrep, fd, fzf, tmux, zellij, lazygit, ranger, tree, htop, tldr
**Languages**: Python 3.12 (+pipx/uv), Node.js, Go *(Linux default)*
**Build**: gcc, make, pkg-config, cmake, ninja
**DB/CLI**: SQLite, MySQL client
**Misc**: ngrok, ffmpeg, rclone
**Neovim**: Kickstart fork + `lua-language-server`

> Exact set is defined in `brew/Brewfile.common` plus `brew/Brewfile.{mac,linux}`.

---

## 🔄 Updates

* **Automatic**: runs once/day when you open a shell
* **Manual**: run anytime

```bash
update-all
```

---

## 🧪 Common commands

```bash
# Reload your shell config (aliases, PATH, etc.)
reload

# Update everything now
update-all
```

---

## 🧱 Zellij quickstart

Dump a default config:

```bash
zellij setup --dump-config > ~/.config/zellij/config.kdl
nvim ~/.config/zellij/config.kdl
```

Check layout dir:

```bash
zellij setup --check
# Look for: LAYOUT DIR: /home/nasri/.config/zellij/layouts
mkdir -p ~/.config/zellij/layouts
```

**Sample layout** (`~/.config/zellij/layouts/ide.kdl`)

```kdl
layout {
  default_tab_template {
    pane size=1 borderless=true {
      plugin location="zellij:tab-bar"
    }
    children
    pane size=1 borderless=true {
      plugin location="zellij:status-bar"
    }
  }

  tab name="dev" {
    pane command="ranger"
  }

  tab name="test" split_direction="vertical" {
    pane                               // LEFT column

    pane split_direction="horizontal" {  // RIGHT column split top & bottom
      pane                              // top-right
      pane                              // bottom-right
    }
  }
}

```

Use it:

```bash
zellij -l ide
```

---

## ☁️ Google Cloud (optional)

Authenticate:

```bash
gcloud auth login
```

Set defaults:

```bash
gcloud config set project YOUR_PROJECT_ID
gcloud config set run/region us-central1   # optional
```

Verify:

```bash
gcloud auth list
gcloud projects list
```

---

## 🧯 Troubleshooting

**`Permission denied (publickey)` when cloning or updating submodules**

```bash
# Ensure your SSH key is loaded
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Test SSH to GitHub
ssh -T git@github.com

# If repo was cloned via HTTPS, switch to SSH and resync submodules
git remote set-url origin git@github.com:n45h4n/dotfiles.git
git submodule sync --recursive
git submodule update --init --recursive
```

**fzf keybindings not working**

```bash
# Re-run the post-bundle script or update-all
update-all
# Then restart your shell
reload
```

**Homebrew not found after bootstrap (WSL)**

```bash
# Ensure brew is on PATH (bootstrap should do this)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
reload
```

---

## 📜 Notes

* This repo is **built for me** and assumes **SSH-only** GitHub access.
* Submodules live in `vendor/` and are managed via `git submodule`.
* If you change Brewfiles, run `update-all` to apply.
