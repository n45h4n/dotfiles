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
./scripts/bootstrap.sh
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
./scripts/bootstrap.sh
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

## Zellij config
```bash
zellij setup --dump-config > ~/.config/zellij/config.kdl
```

Then open it:

```bash
nvim ~/.config/zellij/config.kdl
```

📂 How to see your layout directory

```bash
zellij setup --check
```

Look for:
```bash
LAYOUT DIR: /home/nasri/.config/zellij/layouts
```

Create it if it doesn't exist
```bash
mkdir ~/.config/zellij/layouts
```

📜 Listing available layouts

```bash
ls ~/.config/zellij/layouts
```

If it’s empty, you can create your own layout files there.

ide.kdl

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

▶ Using a layout

```bash
zellij -l name_of_file
```
---
## SSH key for GitHub

1️⃣ Check for existing keys

```bash
ls -al ~/.ssh
```

If you see files like id_ed25519 and id_ed25519.pub, you might already have a key.
If not, continue.

2️⃣ Generate a new SSH key
GitHub recommends ed25519:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Replace your_email@example.com with your GitHub email.

When prompted for a file location, press Enter to accept the default (~/.ssh/id_ed25519).

When prompted for a passphrase, you can press Enter for none (or set one for extra security).

3️⃣ Start the SSH agent

```bash
eval "$(ssh-agent -s)"
```

4️⃣ Add your key to the agent

```bash
ssh-add ~/.ssh/id_ed25519
```

5️⃣ Copy the public key
```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the whole output (starts with ssh-ed25519).

6️⃣ Add it to GitHub
1. Go to GitHub → Settings → SSH and GPG keys → New SSH key.
2. Title: anything (e.g., “WSL ThinkPad”).
3. Paste the key.
4. Save.

7️⃣ Test connection

```bash
ssh -T git@github.com
```

If successful, you’ll see:

```txt
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```
---
## Google Cloud

1️⃣ Authenticate
```bash
gcloud auth login
```

1. This will open your Windows default browser.
2. Log in with the Google account that owns your project.
3. Approve the permissions.

2️⃣ Set your default project
```bash
gcloud config set project YOUR_PROJECT_ID
```

You can find YOUR_PROJECT_ID in the Google Cloud Console → Dashboard.

3️⃣ (Optional) Set default region & service account

```bash
gcloud config set run/region us-central1
```

4️⃣ Verify

```bash
gcloud auth list
```

```bash
gcloud projects list
```
---
