# mac-agentic-dev-setup

A practical guide to preparing a Mac for terminal-based development, AI coding tools, multiple language runtimes, containers, and local Kubernetes.

The setup described here combines Homebrew, Ghostty and zsh, Starship, tmux, direnv, Git and GitHub CLI, mise, uv, Corepack, VS Code, Cursor, ChatGPT, Claude Code, Codex CLI, OrbStack, and development quality tools.

**Current prerequisite:** The script uses a Bash associative array but does not install or require-check modern Bash. macOS’s bundled Bash 3.2 cannot run that section. Use the modern-Bash quick start below. The script is interactive and does not provide automatic rollback or configuration backups.

## Quick start

1. Finish macOS setup, install pending macOS updates, and restart if required. Use your normal administrator account and a native terminal on Apple silicon.
2. Install Apple's Command Line Tools if missing:

   ```sh
   xcode-select -p
   # If the command above reports that developer tools are missing:
   xcode-select --install
   ```

   Complete the installation dialog before continuing. Verify with `xcrun --find clang`.

3. Obtain this repository. Replace `YOUR_GITHUB_USERNAME` below with its actual owner. If you already downloaded it, open its directory instead.

   ```sh
   git clone https://github.com/YOUR_GITHUB_USERNAME/mac-agentic-dev-setup.git
   cd mac-agentic-dev-setup
   less setup.sh
   ```

4. **Install the required interpreter before running.** The script uses `declare -A`, which requires Bash 4 or newer. macOS's `/bin/bash` is Bash 3.2, and the script does not install newer Bash itself. If Homebrew is missing, install it using its [official instructions](https://docs.brew.sh/Installation), load the `brew shellenv` command printed by the installer, and run:

   ```sh
   brew install bash
   "$(brew --prefix)/bin/bash" --version
   "$(brew --prefix)/bin/bash" -n setup.sh
   "$(brew --prefix)/bin/bash" ./setup.sh
   ```

   Its `#!/usr/bin/env bash` shebang selects Bash through PATH. You may use `chmod +x setup.sh` and `./setup.sh` only after confirming that `bash --version` resolves to modern Bash. Explicit invocation above is the least ambiguous route. Do not run the entire script with `sudo`, `sh setup.sh`, or `zsh setup.sh`.

   During the run, choose whether to update Git identity (default **No**) and, if not already authenticated, whether to sign in to GitHub (default **Yes**). Stay available for installer and OrbStack dialogs.

5. Open a fresh Ghostty window, or run `exec zsh -l` after setup has finished. Sign in to GitHub and the AI applications, and launch OrbStack once to complete its onboarding.

   ```sh
   gh auth login --hostname github.com --git-protocol https --web
   gh auth setup-git
   gh auth status
   open -a OrbStack
   ```

6. Work through [post-install verification](#post-install-verification). A successful script exit alone does not prove that accounts are authenticated, Docker is running, or every cask is Homebrew-managed.

## Contents

- [Prerequisites and new-Mac preparation](#prerequisites-and-new-mac-preparation)
- [Installation and configuration inventory](#installation-and-configuration-inventory)
- [Homebrew and existing desktop applications](#homebrew-and-existing-desktop-applications)
- [Terminal and shell configuration](#terminal-and-shell-configuration)
- [Git, GitHub, and secret exclusions](#git-github-and-secret-exclusions)
- [Language runtimes, uv, and Corepack](#language-runtimes-uv-and-corepack)
- [Editors and AI tools](#editors-and-ai-tools)
- [Containers and Kubernetes](#containers-and-kubernetes)
- [Quality tools and repository checks](#quality-tools-and-repository-checks)
- [FileVault and security](#filevault-and-security)
- [Authentication checklist](#authentication-checklist)
- [Post-install verification](#post-install-verification)
- [Rerunning and idempotency](#rerunning-and-idempotency)
- [Updating and maintenance](#updating-and-maintenance)
- [Create and push the GitHub repository](#create-and-push-the-github-repository)
- [Uninstall considerations](#uninstall-considerations)
- [Symptom-based troubleshooting](#symptom-based-troubleshooting)

## Prerequisites and new-Mac preparation

Use a macOS release supported by the current versions of Homebrew and each desktop app. Apple silicon is the target for this Mac setup. Do not assume an Intel Mac can install the entire GUI inventory; inspect each cask's current requirements first with `brew info --cask NAME`.

You will need:

- A local account permitted to install applications and approve required administrator prompts.
- A reliable internet connection for package downloads, language runtimes, app installers, and sign-in.
- Adequate free storage for apps, several language runtimes, caches, container images, and cluster data. Container storage can become the largest consumer; inspect free space with `df -h /`.
- A GitHub account for remote repositories, and appropriate accounts or organizational access for the AI tools you intend to use. Installation does not confer paid service access.
- A backup of existing configuration and important data before using the script on an established Mac.

Before installation:

1. Finish Setup Assistant and configure your keyboard, network, login, and account recovery.
2. Apply macOS updates and complete restarts.
3. Enable a backup method such as Time Machine.
4. Review FileVault in System Settings → Privacy & Security → FileVault.
5. On a managed Mac, follow your organization's software, proxy, certificate, and account policies.
6. Quit desktop apps before installing or adopting them.
7. Inspect existing shell and Git settings locally. They may contain private values; do not paste them wholesale into support requests.

Useful baseline checks:

```sh
sw_vers
uname -m
arch
df -h /
xcode-select -p
/bin/bash --version
printf '%s\n' "$SHELL"
command -v brew
```

On Apple silicon, a native terminal normally reports `arm64`. If it reports `x86_64`, check whether the terminal is running under Rosetta before installing a second Homebrew tree.

### Apple Command Line Tools

The Command Line Tools provide Apple's compiler, SDK tooling, and developer utilities. Full Xcode is not necessary for the general toolchain described here; projects that build Apple-platform apps may require it separately.

```sh
xcode-select --install
# Wait for Apple's installer to finish, then:
xcode-select -p
xcrun --find clang
clang --version
git --version
```

An “already installed” message is fine if the verification commands succeed. A typical selected directory is `/Library/Developer/CommandLineTools`; a full Xcode developer directory is also valid. See [Apple's Command Line Tools documentation](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools/).

## Installation and configuration inventory

The following inventory reflects the supplied script. Homebrew can install additional dependencies automatically; exact dependency versions vary over time. The script runs `brew update`, then skips formulae and casks it already considers installed rather than explicitly upgrading them.

| Area | Intended components / typical package identifiers | What they provide | What still requires attention |
| --- | --- | --- | --- |
| Apple tooling | Command Line Tools | Compiler, SDK utilities, initial Git | Finish Apple's installer and verify selected tools |
| Package management | Homebrew | CLI packages and GUI casks | Correct architecture and shell PATH |
| Script interpreter prerequisite | Modern `bash`, installed manually | Bash 4+ language support | Not in the script’s formula list; use the quick start |
| Terminal | `ghostty` cask; macOS zsh | Terminal emulator and interactive shell | Confirm selected shell and terminal settings |
| Shell tools | `starship`, `tmux`, `direnv` | Prompt, terminal sessions, directory environment loading | Shell hooks; review each `.envrc` before allowing it |
| Source control | `git`, `gh` | Git and GitHub CLI | Identity, authentication, chosen credential method |
| Runtime management | `mise` | Per-user runtime selection | Node LTS, Python 3.13, Java 21, Go |
| Python tooling | `uv` | Python dependency, environment, and tool management | Choose the intended interpreter for each environment |
| JS package managers | Corepack | Yarn/pnpm dispatch and version selection | Enable shims; install Corepack separately when absent |
| Editors | `visual-studio-code`, `cursor` casks | GUI development environments | Verify `code` and `cursor` commands; sign in as needed |
| Chat application | `chatgpt` cask | ChatGPT desktop | Sign in and review permissions |
| AI coding CLIs | Claude Code and Codex native installers; conditional `cursor-cli` cask | Terminal coding assistants | Existing `claude`/`codex` commands are retained; Cursor cask can be skipped |
| Containers | `orbstack` cask and its Docker integration | Local Docker-compatible engine and tools | First launch, runtime startup, Docker context |
| Kubernetes | `kubectl`, `helm`, `k9s`, `kind` | Kubernetes CLI, package manager, terminal UI, local clusters | `kubectl` is the literal formula name in the script (Homebrew may canonicalize it); no cluster is created |
| Quality checks | `shellcheck`, `shfmt`, `pre-commit`, `gitleaks`, `actionlint`, `hadolint` | Shell, secrets, workflow, and Dockerfile checks | Run checks; configure hooks in each applicable repository |
| Security configuration | FileVault status and global Git exclusions | Encryption awareness and accidental-commit protection | Verify encryption; review actual exclusion patterns |

### Exact Homebrew formula list

The script's `BREW_FORMULAE` array contains these 28 entries, in this order:

```text
git gh jq yq ripgrep fd fzf bat eza tree wget curl htop tmux direnv
starship mise uv kubectl helm k9s kind shellcheck shfmt pre-commit
gitleaks actionlint hadolint
```

The tools beyond the core development stack are:

| Formula / command | Purpose |
| --- | --- |
| `jq` | Query and transform JSON |
| `yq` | Query and transform YAML and related structured data |
| `ripgrep` / `rg` | Fast text searching |
| `fd` | File searching |
| `fzf` | Interactive fuzzy selection |
| `bat` | File viewing with syntax highlighting |
| `eza` | Enhanced directory listings |
| `tree` | Directory-tree listings |
| `wget`, `curl` | Command-line downloads and HTTP requests |
| `htop` | Interactive process inspection |

Installing these binaries does not enable extra aliases, fuzzy-completion bindings, or shell plugins. In particular, Homebrew's curl may not be the first `curl` in PATH; inspect `type -a curl`.

### Execution order and boundaries

The script uses `set -Eeuo pipefail` and proceeds in this order:

1. Require Darwin/macOS; report architecture and macOS version. Non-arm64 receives an Intel-target warning rather than an immediate rejection.
2. Check FileVault status; warn rather than enable encryption.
3. Check `xcode-select -p`. If unavailable, launch the Command Line Tools installer and **exit with status 0**, instructing you to rerun after installation. This is an early exit, not a finished setup.
4. Install Homebrew only if `brew` is absent from PATH. Initialize `/opt/homebrew` if present, otherwise `/usr/local`, and append the matching shell-environment line to `.zprofile`.
5. Run `brew update`; install missing formulae in the listed order.
6. Install/adopt the five desktop casks, with nonfatal failed-adoption warnings.
7. Check `brew info --cask cursor-cli`. Install that cask if available and not already registered; otherwise warn and skip. No vendor-installer fallback is implemented.
8. Append four exact zsh initialization lines, then activate mise for the current Bash process.
9. Run `mise use --global` separately for `node@lts`, `python@3.13`, `java@21`, and `go@latest`.
10. Run `corepack enable` only if the command exists; otherwise warn. The script does not install missing Corepack or explicitly select pnpm/Yarn versions.
11. Write the Git preferences below; optionally prompt for identity; append six global ignore patterns; set five Git aliases.
12. Install Codex and Claude Code via native installers only when their commands are absent from the current PATH. An existing installation from another manager is kept.
13. Add `~/.local/bin` to this process's PATH. Attempt to launch OrbStack; launch failure is tolerated.
14. Check GitHub authentication; prompt to run `gh auth login` if needed.
15. Run Homebrew diagnostics, command-path checks, runtime version reporting, and Claude diagnostics.
16. Poll `docker info` up to 15 times, sleeping one second after unsuccessful attempts. Individual calls can make total waiting time longer. If Docker is reachable, run `docker run --rm hello-world`.
17. Print Git/GitHub status and the final setup summary.

It does not configure Ghostty appearance, tmux bindings, a Starship theme, editor extensions, a default login shell, standalone Docker formulae, Kubernetes clusters, repository hooks, or application account logins other than the optional GitHub flow. It does not create configuration backups. The script accepts no implemented dry-run, unattended, rollback, or uninstall options; passing an invented flag will not make it safe or noninteractive.

### Configuration locations to inspect

The script directly creates/updates `~/.zprofile`, `~/.zshrc`, global Git configuration (usually `~/.gitconfig`, through Git), and `~/.gitignore_global`; mise and the native installers manage their own user files. It does not write Ghostty, Starship, or tmux customization files. Common inspection locations are:

| Location | Purpose |
| --- | --- |
| `~/.zprofile` | Login-shell environment, commonly Homebrew initialization |
| `~/.zshrc` | Interactive shell hooks and PATH additions |
| `~/.config/starship.toml` | Optional Starship customizations |
| `~/.tmux.conf` or the tool's XDG configuration | Optional tmux settings |
| `~/.config/ghostty/config` | Common Ghostty configuration path |
| `~/Library/Application Support/com.mitchellh.ghostty/config` | Another supported macOS Ghostty configuration location |
| `~/.config/mise/config.toml` | Common user-level mise runtime selections |
| `~/.gitconfig` | Global Git identity, preferences, and exclusions-file reference |
| `~/.gitignore_global` | Global Git ignore file selected by this script |
| `~/.local/bin` | Common location for user-installed CLI launchers |

Back up existing files before running setup or making manual changes; this script does not create automatic backups.

## Homebrew and existing desktop applications

Homebrew manages command-line packages as **formulae** and applications as **casks**. Its standard prefix is `/opt/homebrew` on Apple silicon and `/usr/local` on Intel. Use the prefix returned by `brew --prefix` when constructing paths. Follow the installer's shell-environment instructions. See [Homebrew installation](https://docs.brew.sh/Installation).

The confirmed desktop block maps these five casks to these app bundles:

| Cask | Application checked by the script |
| --- | --- |
| `ghostty` | `/Applications/Ghostty.app` |
| `visual-studio-code` | `/Applications/Visual Studio Code.app` |
| `cursor` | `/Applications/Cursor.app` |
| `chatgpt` | `/Applications/ChatGPT.app` |
| `orbstack` | `/Applications/OrbStack.app` |

### Exact behavior of the supplied cask block

For each entry:

1. Run `brew list --cask "$cask"`. If it succeeds, report that Homebrew already manages the cask and skip it.
2. Otherwise check whether the mapped application directory exists in `/Applications`.
3. If it exists, attempt `brew install --cask --adopt "$cask"`.
4. If adoption succeeds, report success. If it fails, warn that adoption failed and leave the existing app in place. In either case, continue to the next entry.
5. If the app directory does not exist, run a normal `brew install --cask "$cask"`.

The mapping is a Bash associative array, so iteration order is not guaranteed. The script defines its own status-printing helpers. An unguarded fresh-install failure stops this script under `set -e`; adoption failure is explicitly handled by the `if` statement.

This block does not upgrade an already-managed cask or prove that its app bundle is healthy. It does not look in `~/Applications`, custom cask directories, or renamed app bundles. Those cases need manual inspection.

### What adoption means

Homebrew's `--adopt` option accepts an existing artifact only when it is identical to the artifact being installed. A different app version may therefore fail adoption. Do not combine it with `--force`. See [Homebrew's command reference](https://docs.brew.sh/Manpage).

For the reported ChatGPT case:

```sh
brew install --cask --adopt chatgpt
brew list --cask chatgpt
open -a ChatGPT
```

If adoption fails, the app may still work normally. Record it as “installed manually; not managed by Homebrew.” Update it through the app, then retry adoption if desired. Alternatively, deliberately move the closed app bundle aside and install the cask, after preserving anything you need. See the detailed troubleshooting entry below.

## Terminal and shell configuration

Ghostty hosts the terminal; zsh interprets interactive commands; Starship renders the prompt; tmux manages persistent terminal sessions; direnv loads reviewed directory-specific environment settings. Installing any of these does not automatically prove that shell integration is active.

### PATH and zsh initialization

After setup, start a new terminal. These examples describe the intended integration and can be used to repair missing configuration. Inspect existing settings before adding lines, and keep only one effective copy of each hook.

For an Apple-silicon Homebrew installation, the login-shell initialization commonly includes:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
```

On Intel, use `/usr/local/bin/brew` instead. Do not add both unconditionally.

The script appends these exact lines to `~/.zshrc`, in this order, when each exact line is missing:

```sh
eval "$(starship init zsh)"
eval "$(mise activate zsh)"
eval "$(direnv hook zsh)"
export PATH="$HOME/.local/bin:$PATH"
```

Homebrew must already be available when these hooks run. The helper uses exact-line matching; equivalent pre-existing lines with different spacing or quoting can still produce duplicate hooks. Existing conflicting initialization is not removed. When repairing manually, merge these lines rather than replacing your entire shell configuration. Sources: [mise setup](https://mise.jdx.dev/getting-started.html), [Starship setup](https://starship.rs/guide/), and [direnv hooks](https://direnv.net/docs/hook.html).

Check both a fresh Ghostty window and editor-integrated terminals. GUI programs may inherit a different environment from a login shell.

### Ghostty

Launch with `open -a Ghostty`. Use its settings interface to locate the active configuration. A readable prompt and a working shell are sufficient for an initial check; this README does not assume a specific font, theme, key mapping, or window layout. See [Ghostty configuration](https://ghostty.org/docs/config).

### tmux

```sh
tmux -V
tmux new-session -s setup-check
```

With default bindings, press `Ctrl-b`, release, then `d` to detach. Reattach with `tmux attach-session -t setup-check`. Type `exit` in the test session when finished. Custom key bindings may differ. Sessions survive a terminal window closing while the tmux server remains running; they do not automatically survive reboot.

### direnv

```sh
direnv version
direnv status
```

An unapproved `.envrc` is intentionally blocked. Read it before running `direnv allow` in its directory: it can execute shell commands. A global shell hook is not permission to trust every repository. Avoid having both direnv and a second runtime manager fight mise for PATH ordering.

## Git, GitHub, and secret exclusions

### Identity and preferences

Git identity and GitHub authentication are separate. The former labels commits; the latter permits remote access.

If your identity is missing, set it manually using your actual name and a verified GitHub email or your GitHub-provided no-reply address:

```sh
git config --global user.name "Your Name"
git config --global user.email "YOUR_VERIFIED_OR_NOREPLY_EMAIL"
git config --global init.defaultBranch main
```

The values above are placeholders. Do not commit them unchanged. Repository-local Git settings can override global settings. Inspect relevant effective values with:

```sh
git config --show-origin --get user.name
git config --show-origin --get user.email
git config --show-origin --get init.defaultBranch
git config --show-origin --get core.excludesfile
git config --show-origin --get-all credential.helper
```

A missing optional setting can return exit status 1 without indicating an installation failure. The script writes the following global preferences on **every run**, replacing different existing values for these keys:

| Git key | Value | Effect |
| --- | --- | --- |
| `init.defaultBranch` | `main` | Default branch for newly initialized repositories |
| `pull.rebase` | `true` | Rebase local commits by default during pull |
| `fetch.prune` | `true` | Remove stale remote-tracking references during fetch |
| `rerere.enabled` | `true` | Remember and reuse conflict resolutions |
| `rerere.autoupdate` | `true` | Allow reused resolutions to update the index; inspect staged results |
| `push.autoSetupRemote` | `true` | Set upstream automatically for applicable default pushes |
| `worktree.guessRemote` | `true` | Permit worktree commands to infer matching remote branches |
| `diff.algorithm` | `histogram` | Select histogram diffing |
| `merge.conflictstyle` | `zdiff3` | Show base-aware conflict markers |
| `color.ui` | `auto` | Use color when appropriate |
| `core.excludesfile` | Absolute path to `~/.gitignore_global` | Select this global exclusions file |

The script also sets `git st` → `status --short --branch`, `git co` → `checkout`, `git br` → `branch`, `git ci` → `commit`, and `git lg` → `log --graph --decorate --oneline --all`.

The identity prompt defaults to No. Choosing `y` or `Y` prompts for name and email; a blank response preserves that field. Declining preserves existing identity but does not create a missing one. The script does not configure commit signing or a Git editor. Review rebase and rerere behavior before relying on these defaults in shared work.

### GitHub CLI

For browser-based HTTPS authentication:

```sh
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
gh auth status
gh api user --jq .login
```

Select the intended account in the browser. Organization access may require additional approval or SSO authorization. The CLI attempts to use system credential storage; review any warning about fallback storage. Do not use `gh auth token` as a verification command because it prints a credential. See [GitHub CLI authentication](https://cli.github.com/manual/gh_auth_login).

SSH is optional. If you choose it, use a passphrase-protected key, add only its public key to GitHub, verify GitHub's host key, and test `ssh -T git@github.com`. GitHub's successful greeting can still return status 1 because it does not offer shell access. Never upload a private key to the repository.

### Global ignore file

Find the configured file first:

```sh
git config --global --get core.excludesfile
```

The script creates `~/.gitignore_global` if necessary, adds each missing exact pattern, and points global `core.excludesfile` at it on every run. Its exact additions are:

```gitignore
.DS_Store
.env
.env.local
.env.*.local
*.pem
*.key
```

These are **six patterns**. Existing contents of this file remain. However, a previously selected different global exclusions file is no longer selected by `core.excludesfile`; review and merge any needed rules from that old file.

The coverage is intentionally limited: `.env.production`, `.env.development`, `.envrc`, `.p12`/`.pfx` files, extensionless private keys, cloud credential files, and kubeconfigs are not excluded by these additions alone. Add reviewed repository-specific or global rules when those files may occur in a working tree. Never rely on file naming alone to protect secrets.

Broad patterns such as `*.key` may hide legitimate fixtures. An `.env.example` is not excluded by these six patterns, but must contain fake values only. Global exclusions are local to this Mac and are not automatically shared with collaborators. Repository-level rules remain useful.

Inside a Git repository, check matching rules without creating real secrets:

```sh
git check-ignore -v --no-index .env .env.local local-private.pem
git check-ignore -v --no-index .env.example
git status --short --ignored
```

The example file should normally be unignored; `git check-ignore` returning 1 for an unignored path is expected. Ignore rules do not remove already-tracked files or erase history. See [Git's ignore documentation](https://git-scm.com/docs/gitignore).

## Language runtimes, uv, and Corepack

### mise owns the requested runtimes

The target selections are Node LTS, Python 3.13, Java 21, and Go. “LTS,” a major/minor selector, and “latest” are moving selectors; they are not exact reproducibility guarantees. The precise Node LTS release and Go version installed depend on when the selectors are resolved.

Check the result:

```sh
mise --version
mise doctor
mise ls
mise current
mise which node
mise which python
mise which java
mise which go
```

The script runs four separate `mise use --global` commands with these selectors. If selections are missing, this combined **manual repair command** requests the same targets:

```sh
mise use --global node@lts python@3.13 java@21 go@latest
```

This installs/selects runtimes and changes user-level mise configuration. Run it outside a repository when verifying global defaults; local configuration can override them. Check the resulting Java distribution rather than assuming a particular vendor. See [mise getting started](https://mise.jdx.dev/getting-started.html) and [mise Java support](https://mise.jdx.dev/lang/java.html).

Do not remove or replace Apple's system Python. Avoid layering another Node/Python version manager over mise unless you intentionally manage the precedence. For project reproducibility, use reviewed exact versions rather than assuming the global workstation default will remain constant.

### Python and uv

uv manages Python environments and dependencies; it can also obtain its own Python runtimes. In this setup, explicitly select the mise-managed Python when you want to verify that installation rather than accidentally testing a different interpreter.

```sh
uv --version
python --version
python -c 'import sys; print(sys.executable)'
```

For an isolated test without modifying the repository:

```sh
uv_check_dir="$(mktemp -d "${TMPDIR:-/tmp}/uv-check.XXXXXX")"
uv venv --python "$(mise which python)" "$uv_check_dir/venv"
"$uv_check_dir/venv/bin/python" -c 'import sys; print(sys.version); print(sys.executable)'
printf 'Temporary verification environment: %s\n' "$uv_check_dir"
```

Remove that specific temporary directory when finished. Do not use `sudo pip` or install project dependencies into Apple's Python. See [uv's Python management guide](https://docs.astral.sh/uv/guides/install-python/).

### Node and Corepack

The script enables Corepack if found, but only warns if it is absent. The installation command below is a manual completion step in that case.

Corepack supplies package-manager shims and selects compatible Yarn/pnpm versions. It is not guaranteed to be bundled with every Node version: upstream bundled it starting with Node 14.19 and stopped before Node 25. Check before enabling it.

```sh
node --version
npm --version
command -v corepack
corepack --version
```

If absent, install it into the active mise-managed Node environment, then enable shims:

```sh
npm install --global corepack
corepack enable
pnpm --version
yarn --version
```

The last two commands may download package-manager versions. They do not require you to use both managers in a project. Respect the project's chosen package manager and lockfile. A Node upgrade can require enabling Corepack again in the new runtime. See [Corepack's upstream documentation](https://github.com/nodejs/corepack).

### Java and Go

```sh
java -version
javac -version
printf 'JAVA_HOME=%s\n' "$JAVA_HOME"
go version
go env GOROOT GOPATH
```

Java should report major version 21, and `javac` should be available. An IDE may need its JDK set separately. `/usr/libexec/java_home` may not discover a mise-managed JDK unless it has been explicitly registered; use `mise where java` to locate the selected installation. Avoid an old hard-coded `JAVA_HOME` overriding it.

## Editors and AI tools

### VS Code and Cursor desktop

```sh
open -a "Visual Studio Code"
open -a Cursor
code --version
cursor --version
```

Homebrew casks can expose editor launchers, but verify them. If `code` is missing, open VS Code's Command Palette and run **Shell Command: Install 'code' command in PATH**, then reopen the terminal. For Cursor, use its corresponding shell-command installation action. `code .` and `cursor .` open the current directory in their respective editors. See [VS Code's macOS setup](https://code.visualstudio.com/docs/setup/mac).

The script does not install editor extensions or explicitly repair launcher symlinks. Inspect installed extensions with `code --list-extensions` or `cursor --list-extensions`; configure desired language and AI support separately.

### ChatGPT desktop

Open ChatGPT from Applications, sign in with the intended account, and verify normal operation. Its GUI sign-in does not prove that Codex CLI or any other CLI is authenticated. Review permissions when enabling optional desktop integrations.

### Native CLI installers

For a missing `claude` or `codex` command, the script uses the native/standalone installer. If either command already exists on PATH, the script retains it regardless of installation method. Cursor CLI is attempted through a separate Homebrew cask. The first two commands below match the script; the third is an **optional manual fallback** if the Cursor cask is unavailable:

```sh
# Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# OpenAI Codex CLI
curl -fsSL https://chatgpt.com/codex/install.sh | sh

# Optional manual Cursor CLI fallback (not run by setup.sh)
curl -fsS https://cursor.com/install | bash
```

Run only the installer you need, as your normal user. Each command downloads and executes remote code. For a reviewable installation, download the script to a temporary file, inspect it, then invoke the documented interpreter; the installer may itself download additional components. Do not substitute unofficial mirrors or disable TLS verification to bypass an error.

Verify and sign in:

```sh
claude --version
claude doctor
claude

codex --version
codex
```

Follow each tool's interactive sign-in flow. Start from a directory you intend the tool to access. Account entitlements and organization policies are independent of whether the binary launches. Sources: [Claude Code setup](https://code.claude.com/docs/en/setup) and [Codex CLI setup](https://learn.chatgpt.com/docs/codex/cli).

### Cursor launcher versus Cursor CLI

`cursor` launches the editor. Current Cursor documentation names the terminal assistant command `agent`; some installations also expose `cursor-agent`. Check the installed version instead of assuming these commands are interchangeable:

```sh
command -v cursor
command -v agent
command -v cursor-agent
agent --version
agent --help
```

Run `agent` and follow its authentication flow. If your installed release only exposes `cursor-agent`, use its `--help` to identify the supported commands. Confirm the executable is actually Cursor's before using a generic command named `agent`. See [Cursor CLI installation](https://cursor.com/docs/cli/installation).

## Containers and Kubernetes

### OrbStack and Docker

OrbStack supplies the local container runtime in this setup. Launch it, finish onboarding, and wait for the engine to become ready. A Homebrew installation finishing does not mean the engine has started.

```sh
open -a OrbStack
docker --version
docker context ls
docker context show
docker version
docker info
docker compose version
```

`docker --version` proves only that the client exists. `docker version` should show both client and server. `docker info` should connect to the intended engine. Select the OrbStack context only if it is present and is the engine you want to use:

```sh
docker context use orbstack
```

Do not install or switch to a second container engine merely to repair a missing client command. First inspect OrbStack's integration and PATH. See [OrbStack Docker documentation](https://docs.orbstack.dev/docker/).

### Kubernetes clients and local clusters

- `kubectl` talks to the cluster selected in kubeconfig.
- Helm manages Kubernetes releases.
- k9s provides an interactive cluster interface.
- kind creates Kubernetes nodes as containers for local testing.

Installing these programs does not create a cluster or grant access to a remote one. Before using commands that query or change a cluster, check the context:

```sh
kubectl version --client
helm version --short
k9s version
kind version
kubectl config get-contexts
kubectl config current-context
kind get clusters
```

An empty kubeconfig or no current context is normal before creating or connecting a cluster. OrbStack's optional Kubernetes feature and a kind cluster are separate choices; enabling one is not required to use the other.

## Quality tools and repository checks

| Tool | Purpose | Example |
| --- | --- | --- |
| ShellCheck | Static analysis of shell scripts | `shellcheck setup.sh` |
| shfmt | Shell formatting checks | `shfmt -d setup.sh` |
| pre-commit | Runs configured repository hooks | `pre-commit run --all-files` |
| Gitleaks | Detects likely committed or local secrets | `gitleaks git --redact .` |
| actionlint | Checks GitHub Actions workflow files | `actionlint` |
| hadolint | Checks a Dockerfile | `hadolint Dockerfile` |

Run examples only where the relevant files exist. `shfmt -d` reports differences without writing changes. A formatter disagreement is not proof that a script is functionally broken. ShellCheck warnings deserve review; do not silence the entire checker to bypass one finding.

Installing pre-commit does not activate hooks in every repository. If a repository already has a reviewed `.pre-commit-config.yaml`, run `pre-commit install`, then `pre-commit run --all-files`. First use may download hook environments. Hooks execute code; review their sources and revisions. See [pre-commit documentation](https://pre-commit.com/).

For Gitleaks, use `gitleaks git --redact .` to scan Git history and `gitleaks dir --redact .` to scan the working directory, including files not yet committed. Findings normally produce a nonzero result. A clean scan lowers risk but is not proof that all secrets are absent. See [Gitleaks documentation](https://github.com/gitleaks/gitleaks).

## FileVault and security

Check encryption status:

```sh
fdesetup status
```

The target is `FileVault is On.` The script checks for this text case-insensitively. Any other output, including an in-progress or unavailable status, produces its “not enabled” warning; inspect the actual state in System Settings. It does not enable encryption or block installation. If `fdesetup` is absent, that check is skipped.

If FileVault is off, enable it through System Settings → Privacy & Security → FileVault and safely retain your recovery method. Keep recovery information separate from this repository. Apple silicon's built-in storage encryption does not make the FileVault login protection irrelevant. See [Apple's FileVault guide](https://support.apple.com/guide/mac-help/protect-data-on-your-mac-with-filevault-mh11785/mac).

### No-secrets rules

- Never commit API keys, tokens, recovery keys, private SSH keys, real `.env` values, cloud credentials, kubeconfig credentials, or authentication caches.
- Do not place tokens in clone URLs or command arguments that will remain in shell history.
- Keep real credentials out of shell configuration committed to Git. Use the tool's supported login and credential storage mechanisms.
- Do not upload complete home-directory settings, full environment dumps, or unsanitized diagnostic logs.
- A private repository is still not a secrets store. Accounts, collaborators, integrations, and backups can expose its contents.
- A Git ignore file controls Git's handling of untracked files. It does not prevent an AI tool or other process from reading those files.
- Review coding-assistant permissions, changes, and commands before approving sensitive operations. Use the intended repository as the working directory rather than your home directory.
- Do not globally disable Gatekeeper, certificate checking, or security controls to get an installer working.

If a secret was committed, revoke or rotate it first. Removing the file from the latest commit is insufficient because history and remote copies can retain it. Then remove it from tracking, add exclusions, and assess whether coordinated history cleanup is needed.

## Authentication checklist

| Service | Action | Verification |
| --- | --- | --- |
| Git | Set commit identity | Inspect `user.name` and `user.email` |
| GitHub | `gh auth login`, then HTTPS credential setup if used | `gh auth status`; confirm intended account |
| VS Code | Optional Settings Sync / extension accounts | Check account menu and only required extensions |
| Cursor desktop | Sign in through app | Check intended account and workspace |
| ChatGPT desktop | Sign in through app | Open a normal conversation |
| Claude Code | Run `claude` and complete sign-in | CLI reaches authenticated interface |
| Codex CLI | Run `codex` and complete sign-in | CLI reaches authenticated interface |
| Cursor CLI | Run the installed Cursor assistant CLI | Complete its own login flow |
| OrbStack | Complete onboarding and applicable license steps | Docker client reaches server |
| Container registry | Only if private image access is needed | Authenticate to that specific registry |
| Kubernetes | Obtain access through your cluster's approved process | Verify context before querying it |

Do not assume signing in to a desktop app signs in to its CLI. For registries, interactive `docker login REGISTRY` is preferable to placing a password directly in an argument. Do not authenticate to production services just to prove a local tool was installed.

## Post-install verification

Run checks in a fresh terminal, section by section. Commands here are diagnostics unless explicitly labeled as creating resources. Do not run the entire section under `set -e`; a missing optional setting or an empty cluster list can legitimately return nonzero.

### 1. macOS, Homebrew, and shell

```sh
sw_vers
uname -m
xcode-select -p
xcrun --find clang
clang --version
brew --version
brew --prefix
brew doctor
zsh --version
starship --version
tmux -V
direnv version
direnv status
fdesetup status
```

For the additional command-line utilities installed by the script:

```sh
jq --version
yq --version
rg --version
fd --version
fzf --version
bat --version
eza --version
tree --version
wget --version
curl --version
htop --version
```

Expected: developer tools resolve, Homebrew matches the intended architecture, commands print versions, and FileVault has the intended state. Review `brew doctor` warnings individually; unrelated pre-existing warnings do not automatically mean setup failed.

### 2. Executable availability and provenance

```sh
for tool in brew git gh jq yq rg fd fzf bat eza tree wget curl htop starship tmux direnv mise uv node npm corepack python java javac go code cursor claude codex docker kubectl helm k9s kind shellcheck shfmt pre-commit gitleaks actionlint hadolint; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%-14s %s\n' "$tool" "$(command -v "$tool")"
  else
    printf 'MISSING: %s\n' "$tool"
  fi
done
command -v agent
command -v cursor-agent
```

If Cursor CLI was installed, at least its intended assistant command should resolve. A skipped cask leaves this as a manual completion item. Use `type -a TOOL` when a version or location is unexpected. A system Git path can be valid but does not verify that the Homebrew Git is being selected.

### 3. Desktop application presence and Homebrew registration

```sh
for app in Ghostty "Visual Studio Code" Cursor ChatGPT OrbStack; do
  if test -d "/Applications/$app.app"; then
    printf 'APP PRESENT: %s\n' "$app"
  else
    printf 'APP MISSING FROM /Applications: %s\n' "$app"
  fi
done

for cask in ghostty visual-studio-code cursor chatgpt orbstack; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    printf 'BREW MANAGED: %s\n' "$cask"
  else
    printf 'NOT BREW MANAGED: %s\n' "$cask"
  fi
done
```

App presence and Homebrew registration are separate checks. A failed adoption can yield a usable app with no cask registration. Launch each GUI app once to catch first-run or compatibility issues.

### 4. Git and account state

```sh
git --version
gh --version
git config --show-origin --get user.name
git config --show-origin --get user.email
git config --show-origin --get core.excludesfile
gh auth status
```

Expected: correct identity, a real exclusions file with reviewed patterns, and authentication to the intended GitHub host/account. In a repository, repeat the ignore checks from the earlier section.

To inspect every Git setting written by the script:

```sh
for key in init.defaultBranch pull.rebase fetch.prune rerere.enabled rerere.autoupdate push.autoSetupRemote worktree.guessRemote diff.algorithm merge.conflictstyle color.ui core.excludesfile alias.st alias.co alias.br alias.ci alias.lg; do
  printf '%s: ' "$key"
  git config --global --get "$key"
done
```

Compare the results with the Git-settings table. Run without `--global` and with `--show-origin` inside a repository when investigating overrides.

### 5. Runtimes and package managers

```sh
mise --version
mise doctor
mise current
node --version
npm --version
corepack --version
python --version
python -c 'import sys; print(sys.executable); print(sys.version_info[:2])'
uv --version
java -version
javac -version
go version
```

Expected: the selected Node LTS release, Python `(3, 13)`, Java/Javac 21, and a working Go installation. Run `pnpm --version` and `yarn --version` separately if you want to test Corepack downloads. Test uv's environment creation using the temporary-directory procedure above.

### 6. Editors and coding CLIs

```sh
code --version
cursor --version
claude --version
claude doctor
codex --version
```

Then check the installed Cursor assistant (`agent --version` or the documented command for your release). Version output establishes launchability, not authentication or permission to use a particular model. Complete interactive login separately.

### 7. Docker end-to-end test

Start OrbStack first. The final command downloads and runs a public test image, leaves the image cached, and removes its test container on exit:

```sh
docker context show
docker version
docker info
docker compose version
docker run --rm hello-world
```

Expected: both client and server information, a functioning Compose plugin, and the test image's success message. A download failure can be a network or registry issue even when the local engine works.

### 8. Kubernetes client checks and optional local cluster test

```sh
kubectl version --client
helm version --short
k9s version
kind version
kind get clusters
kubectl config get-contexts
```

**Optional resource-creating test:** This downloads a node image and creates a local kind cluster. Confirm that `setup-verification` is not already in use. Cluster creation can change the current kubectl context, so note it first.

```sh
kubectl config current-context
kind get clusters
kind create cluster --name setup-verification --wait 120s
kubectl --context kind-setup-verification get nodes
kubectl --context kind-setup-verification get pods -A
helm --kube-context kind-setup-verification list --all-namespaces
```

Expected: the node becomes `Ready`, and system pods become healthy after startup settles. Open `k9s --context kind-setup-verification` if you want to verify its interactive connection; quit with `:q`.

Only if this run created the disposable cluster, remove it afterward:

```sh
kind delete cluster --name setup-verification
```

Restore the previous context explicitly if you had one. Deleting this cluster destroys workloads and data inside it. See [kind's quick start](https://kind.sigs.k8s.io/docs/user/quick-start/).

### 9. Quality-tool versions and applicable checks

```sh
shellcheck --version
shfmt --version
pre-commit --version
gitleaks version
actionlint -version
hadolint --version
```

From the setup repository:

```sh
shellcheck setup.sh
shfmt -d setup.sh
gitleaks dir --redact .
```

If it already has Git history, also run `gitleaks git --redact .`. Run pre-commit, actionlint, and hadolint only where their required configuration or target files exist.

### Acceptance checklist

- [ ] A fresh Ghostty shell resolves the required commands without startup errors.
- [ ] Apple tools and Homebrew use the intended architecture and paths.
- [ ] Each desktop app launches; unmanaged apps are recorded rather than mistaken for adopted casks.
- [ ] mise selects Node LTS, Python 3.13, Java 21, and Go.
- [ ] uv can create an environment with the intended Python; Corepack can launch the chosen JS package manager.
- [ ] Git identity, GitHub authentication, and global exclusions are verified.
- [ ] Editor launchers and AI CLIs work; needed account sign-ins are complete.
- [ ] Docker reaches OrbStack and runs the test image.
- [ ] Kubernetes clients work; optional cluster testing succeeds if performed.
- [ ] Quality tools launch and relevant repository checks have been reviewed.
- [ ] FileVault status and recovery arrangements are understood.

## Rerunning and idempotency

“Safe to rerun” should mean that setup converges on the intended state while preserving intentional user configuration. It does not mean every action is a no-op or that exact package versions remain fixed.

The confirmed cask block has these rerun outcomes:

| Existing state | Next run |
| --- | --- |
| Cask already registered | Skip, without an explicit upgrade or repair |
| App exists but cask is not registered | Retry adoption |
| Adoption fails | Warn, retain existing app, continue |
| App absent and cask unregistered | Attempt installation |

The rest of this script behaves as follows:

| Component | Rerun behavior |
| --- | --- |
| Homebrew metadata | `brew update` runs again |
| Formulae | Registered formulae are skipped; no explicit `brew upgrade` |
| Shell files | Missing exact lines are appended; existing content remains, without backup or conflict resolution |
| mise | All four global selection commands run again; moving selectors can resolve newer releases |
| Corepack | Re-enabled if present; missing command is still only a warning |
| Git preferences and aliases | Listed values are overwritten on each run |
| Git identity | Prompt appears again; default No retains values |
| Global exclusions | Six exact patterns are appended if missing; exclusions-file selection is reset |
| Codex / Claude | Any command already on PATH causes installation to be skipped |
| Cursor CLI | Availability check repeats; available cask is installed only if unregistered |
| OrbStack | Launch is attempted again |
| GitHub | Authentication is checked; interactive login is offered only if check fails |
| Docker smoke test | Runs again when a server is reachable; image can stay cached |

Native installers and app auto-updaters may change versions independently. Existing CLI detection occurs before the script's explicit late PATH refresh, so a tool installed under `~/.local/bin` but absent from the inherited PATH can be installed again. Restart your shell before rerunning.

Before rerunning on an established Mac:

1. Read changes to the script and save any local edits.
2. Back up shell, Git, terminal, and runtime configuration that matters to you.
3. Close applications being changed and stop any concurrent installation.
4. Use the same verified interpreter as the first run.
5. Review warnings, then repeat the relevant verification sections.

A failed run is not a transaction: previously completed installations remain. Correct the first meaningful error, then rerun. Do not uninstall everything merely because a later phase failed. There is no argument parser implementing dry-run, resume, unattended, or uninstall behavior.

## Updating and maintenance

Use each component's installation method consistently. Inspect provenance before removing duplicate installations or deciding which updater applies.

### Homebrew-managed tools

```sh
brew update
brew outdated
```

Review the list, then upgrade selected tools, for example `brew upgrade git gh mise uv`. Use `brew upgrade --cask CASK_NAME` for a selected registered cask when appropriate. Desktop apps with their own updater may follow different update behavior; inspect `brew info --cask CASK_NAME` and the app's settings. See [Homebrew's FAQ](https://docs.brew.sh/FAQ).

Do not expect a setup rerun to upgrade casks: the confirmed cask block skips registered entries. Check app-managed updates separately when an app was left unmanaged after failed adoption.

### Runtime updates

Inspect `mise ls` and `mise current` first. Deliberately reselect the desired runtime line when updating, then rerun language verification. Preserve Python 3.13 and Java 21 if those are compatibility requirements rather than silently moving to new major releases.

Check `mise upgrade --help` for the installed version before using an upgrade workflow. Keep older runtime versions until dependent work has been tested. Existing Python virtual environments do not automatically switch interpreter, and npm-global tools may be tied to an older Node installation.

If uv was installed by Homebrew, update it through Homebrew. Avoid mixing that with a standalone uv self-update workflow.

### Native coding tools

- Claude Code native installs support automatic updates; `claude update` performs a manual check/update. Use `claude doctor` afterward. See [Claude Code setup](https://code.claude.com/docs/en/setup).
- Update standalone Codex using the same official installer: `curl -fsSL https://chatgpt.com/codex/install.sh | sh`. See [Codex CLI](https://learn.chatgpt.com/docs/codex/cli).
- Cursor CLI supports `agent update` in the currently documented CLI and also attempts automatic updates. Use the equivalent help for your installed release if its command differs. See [Cursor CLI installation](https://cursor.com/docs/cli/installation).

After changes, start a new terminal and verify command paths and versions. Update native applications through their chosen management method.

### Storage and regular review

```sh
brew cleanup --dry-run
docker system df
kind get clusters
```

Review before cleanup. Docker volumes may contain databases or other irreplaceable work; do not run broad prune commands with volume deletion as routine maintenance. Periodically review unused credentials, app permissions, old runtimes, backup health, FileVault, and secret-scanning findings.

## Create and push the GitHub repository

These steps publish your setup files. Run them from the directory containing the actual `setup.sh` and this `README.md`, not from your home directory. Repository creation and pushing are deliberate publishing actions.

### New local repository

First ensure you are not inside an unrelated parent repository:

```sh
pwd
git rev-parse --show-toplevel
```

If the second command reports a different existing repository root, stop and move to the intended independent repository location. If it reports that this is not a Git repository, initialize it:

```sh
git init -b main
chmod +x setup.sh
git status --short
shellcheck setup.sh
shfmt -d setup.sh
gitleaks dir --redact .
```

Review or resolve findings, then stage only intended files. If you have a reviewed repository `.gitignore`, add it explicitly as well.

```sh
git add README.md setup.sh
git diff --cached --stat
git diff --cached
git status --short
```

Read the staged diff for secrets, accidental personal values, and unsupported claims before committing:

```sh
git commit -m "Document and add Mac development setup"
gitleaks git --redact .
gh auth status
```

Create a private repository and push the reviewed commit:

```sh
gh repo create mac-agentic-dev-setup --private --source=. --remote=origin --push
gh repo view --web
git remote -v
git status --short
```

Use `OWNER/mac-agentic-dev-setup` for an explicit user or organization owner you are authorized to publish under. Change `--private` to `--public` only if you intend to publish everything in the history. See [GitHub CLI repository creation](https://cli.github.com/manual/gh_repo_create).

### Existing remote or cloned repository

Do not create another repository or overwrite `origin` blindly:

```sh
git remote -v
git status
git branch --show-current
```

For an existing local repository with no remote, add the correct URL after verifying ownership:

```sh
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/mac-agentic-dev-setup.git
git push -u origin main
```

For a clone that already has `origin`, stage and commit the intended changes, then use `git push`. If the remote already has commits you lack, fetch and reconcile the histories before pushing. Do not force-push to bypass a non-fast-forward error.

## Uninstall considerations

The script implements no automatic rollback or uninstall. Removing this repository does not uninstall applications or undo home-directory settings.

Work component by component:

1. Back up data and export anything needed, especially containers, volumes, and local cluster workloads.
2. Record which applications were present before setup and which are now Homebrew-managed.
3. Quit affected applications and services.
4. Remove a selected formula with `brew uninstall FORMULA_NAME` or a managed application with `brew uninstall --cask CASK_NAME`, after reviewing dependencies and app data needs.
5. Use each native CLI's documented uninstall procedure after confirming the installation path. Preserve needed account/session data or sign out intentionally.
6. Remove only the setup-related shell hooks or settings you can identify. Keep unrelated user configuration.
7. Restore specific Git settings from your backup where appropriate. Do not delete all of `.gitconfig` to remove one setting.
8. Remove individual mise runtimes only after checking for dependent work. Keep system runtimes and Apple tools intact.

An app successfully adopted into Homebrew is now managed by Homebrew, even if it was originally installed manually; uninstalling that cask can remove the app bundle. App preferences and data may remain. Broad `--zap` cleanup can remove additional data and should be reviewed carefully.

Do not erase `~/.config`, `~/.local`, all of Homebrew, or OrbStack's data store as a shortcut. Uninstalling setup tools does not require turning off FileVault or weakening macOS security.

## Symptom-based troubleshooting

### “It seems there is already an App at '/Applications/ChatGPT.app'”

**Meaning:** the app bundle exists, but Homebrew does not consider that cask installed. It is a cask ownership conflict, not proof that ChatGPT is broken. The original unguarded installation can still abort the script, so it should not be dismissed as a successful setup.

1. Quit ChatGPT and verify the two states separately:

   ```sh
   test -d /Applications/ChatGPT.app && printf 'App exists\n'
   brew list --cask chatgpt
   ```

2. Attempt adoption:

   ```sh
   brew install --cask --adopt chatgpt
   ```

3. Verify registration and launch the app:

   ```sh
   brew list --cask chatgpt
   open -a ChatGPT
   ```

4. If adoption reports a mismatch, the existing app may be a different version. Update the app through its own updater and retry, or keep the manual installation. The revised block warns and continues in this situation.
5. If you explicitly want a fresh Homebrew-managed bundle, quit the app, preserve its data, and move only the existing `.app` to a safe location outside `/Applications` using Finder. Then run `brew install --cask chatgpt` and test the newly installed app before disposing of the saved bundle. Do not delete its Library data just to resolve bundle ownership.
6. Ensure your actual script contains the revised adoption logic and uses a compatible Bash; otherwise the next rerun may encounter the original error again.

The same diagnosis applies to the other mapped GUI apps. Avoid automatic `--force` replacement.

### `declare: -A: invalid option`, array errors, or unexpected “bad substitution”

The script does not install Bash or validate its major version. The associative-array code is running with an incompatible interpreter. `/bin/bash` on macOS is too old for `declare -A`; invoking a Bash script as `sh` or zsh is also incorrect.

```sh
head -n 1 setup.sh
/bin/bash --version
brew install bash
"$(brew --prefix)/bin/bash" --version
"$(brew --prefix)/bin/bash" -n setup.sh
"$(brew --prefix)/bin/bash" ./setup.sh
```

This script uses `#!/usr/bin/env bash`, so executable launch depends on PATH. Explicit invocation avoids that ambiguity; it also avoids older Bash in an existing shell command cache. You do not need to change your login shell from zsh. A longer-term script fix is either a Bash-3.2-compatible cask implementation or an explicit bootstrap/re-execution requirement for modern Bash.

### `permission denied: ./setup.sh`

Confirm you are in the repository, then run `chmod +x setup.sh`. Alternatively, use the explicitly selected Bash interpreter. If the file was saved with Windows line endings, convert it to Unix LF in your editor. `bash^M` in an error commonly indicates CRLF line endings. Do not run it as root to fix an executable-bit issue.

### Apple developer tools missing or “invalid active developer path”

Run `xcode-select -p` and `xcrun --find clang`. Install the tools with `xcode-select --install`, complete the dialog, then retry. After a macOS upgrade, Software Update may offer newer tools.

If the standalone tools exist but the selected path is wrong, this is a targeted repair:

```sh
sudo xcode-select --switch /Library/Developer/CommandLineTools
```

Use that only when this directory is the intended installation. A Mac using full Xcode may need its own developer directory instead. Do not delete the entire tools directory as the first response.

### `brew: command not found` immediately after installation

Load the correct environment for the current shell:

```sh
# Apple silicon:
eval "$(/opt/homebrew/bin/brew shellenv)"
# Intel: use /usr/local/bin/brew instead.
brew --prefix
```

Persist the matching initialization once in your login-shell configuration and open a new terminal. Verify that your shell actually reads that configuration.

### Two Homebrew installations or architecture mismatch

Compare `uname -m`, `arch`, `type -a brew`, and `brew --prefix`. A Rosetta terminal can select an Intel install even on Apple silicon. Reopen a native terminal, choose the intended Homebrew prefix, and inspect dependent tools before removing anything. Do not recursively change ownership or delete an entire prefix to resolve PATH ordering.

### Downloads fail, TLS errors, or proxy failures

Check connectivity, available storage, system date/time, and your organization's proxy/certificate requirements. Retry the specific failing installer after correcting the cause. Do not use `curl -k`, disable certificate validation, or bypass organizational controls. A transient failure in one download does not mean completed installations must be removed.

### A native CLI is installed but cannot be found

Inspect `command -v TOOL`, `type -a TOOL`, and the installer's reported destination. Common user launchers require `~/.local/bin` in PATH. Open a new terminal after correcting it. For editor commands, use the editor's shell-command installation action. Repeatedly reinstalling without checking PATH can leave duplicate versions.

### Wrong CLI version or tool reverts after an update

Use `type -a claude`, `type -a codex`, or the relevant command to find duplicate native, Homebrew, or npm installations. Identify the active executable before uninstalling the unwanted installation through its own package manager. Do not delete a launcher until you know which installation owns it.

### `agent` is missing but `cursor` works

The editor launcher and terminal assistant are separate. Verify the Cursor CLI installer completed, `~/.local/bin` is on PATH, and whether your release provides `agent` or `cursor-agent`. A working `cursor --version` proves only that the editor launcher works.

### Starship is missing, prompt appears twice, or shell startup is slow

Check `starship --version`, then review `.zshrc` for missing or duplicate initialization. Inspect old prompt frameworks and repeated runtime hooks. Test a clean zsh with `zsh -f` to distinguish startup configuration problems from binary installation problems. This clean shell intentionally will not load your normal hooks.

### Commands work in one terminal but not in VS Code, Cursor, or tmux

Open a fresh terminal in the app and compare `command -v` results. Restart the app if it inherited an older environment. Existing tmux sessions may retain old environment values; create a fresh test session after correcting initialization. Do not kill a tmux server containing work just to refresh PATH.

### `direnv: ... is blocked`

Read the `.envrc`, including any scripts it sources. If it is trusted, run `direnv allow` in that directory. If it is not trusted, leave it blocked. Reapproval after edits is intentional. `direnv status` helps identify which file is active.

### mise installed, but Node/Python/Java/Go is missing or wrong

Run `mise doctor`, `mise current`, and `type -a` for the affected executable. Confirm the zsh activation hook loads after Homebrew. A local runtime selection, active Python virtual environment, or another version manager can override your global defaults. Test outside repositories and deactivate an old virtual environment before concluding the global installation is wrong.

If mise reports an untrusted configuration, inspect the file before trusting it. Configuration can influence downloads and executable tasks.

### Python reports an externally managed environment

Use a virtual environment or uv rather than installing into the protected interpreter. Select the intended mise Python explicitly when creating the environment. Do not use `sudo pip` or bypass interpreter protections to make a workstation setup check pass.

### Corepack missing, permission denied, or package-manager signature errors

Check `node --version`, `command -v node`, and `command -v corepack`. Install/update Corepack under the active user-owned Node runtime, then run `corepack enable`. If enabling tries to write into a system directory, fix which Node installation is selected instead of adding `sudo`. For signature-related failures, verify the supported current Corepack release; do not disable integrity checks.

### Java works in Terminal but the IDE cannot find the JDK

Compare `mise where java`, `command -v java`, and `JAVA_HOME`. Point the IDE at the selected JDK installation through its settings, then restart its terminal or language service. A system Java discovery utility may not enumerate mise's private installation.

### Docker says “Cannot connect to the Docker daemon”

Start OrbStack, finish onboarding, and wait for it to be ready. Inspect `docker context ls` and `docker context show`. A leftover `DOCKER_HOST` can override context selection; inspect it locally and unset it in the current shell only if it is stale and you intend local OrbStack access. Retry `docker version` and look for server output.

### Docker works but `docker compose` is missing

Verify OrbStack's CLI integration and the active `docker` executable. An older standalone Docker CLI earlier in PATH can miss the expected plugin integration. Follow OrbStack's integration guidance rather than installing another engine.

### `kubectl` connects to localhost or the wrong cluster

Inspect `kubectl config get-contexts` and `kubectl config current-context`. No kubeconfig means installation has succeeded but cluster access is not configured. Use an explicit `--context` for the local verification cluster. Do not run corrective commands against an unexpected production context.

### kind creation hangs or nodes never become Ready

First verify Docker's server is reachable. Check storage, OrbStack resource limits, image download access, and whether the cluster name already exists. Run `kind get clusters`. If a failed test cluster exists, inspect it before recreating it; exporting logs can help:

```sh
kind export logs --name setup-verification ./kind-diagnostics
```

This writes diagnostic files. Review and sanitize them before sharing, and do not accidentally commit them. Delete only the disposable cluster you created after gathering the information you need.

### Git says “Author identity unknown” or commits use the wrong email

Set `user.name` and `user.email`, then check their origins. Repository-local settings can override global values. Authentication success does not set commit identity automatically. Avoid rewriting published history just to correct future commit metadata.

### GitHub push fails with authentication or permission errors

Check `gh auth status`, `git remote -v`, the repository owner, and organization SSO requirements. For HTTPS, run `gh auth setup-git` after signing in. For SSH, verify the selected public key has access. Do not paste a token into the remote URL. A non-fast-forward rejection concerns remote history, not credentials.

### An ignored secret still appears in Git

It may already be tracked. Inspect `git ls-files -- PATH` and `git check-ignore -v --no-index PATH`. To retain a local file while removing it from tracking, use `git rm --cached -- PATH` only after reviewing the target, then commit the change. Rotate exposed credentials; this does not erase previous commits.

### pre-commit reports no configuration, or checks do not run on commit

Tool installation alone does not supply repository hook configuration. In a repository with a reviewed existing configuration, run `pre-commit install`. If hooks fail while downloading their environments, diagnose network/runtime access. Do not manufacture a passing result by disabling secret checks.

### actionlint or hadolint fails during verification

Verify the target files exist. `actionlint` requires applicable workflow files; `hadolint Dockerfile` requires that Dockerfile. A repository that has neither can still have both tools correctly installed. Use their version commands for installation checks.

### An app is reported as damaged, incompatible, or blocked

Confirm you downloaded the official app for the right architecture and supported macOS release. Update macOS if appropriate, or reinstall through the official source. Review System Settings security messages. Do not globally remove quarantine attributes or disable Gatekeeper as a routine fix.

### The script stopped halfway through or says success despite warnings

Find the first substantive failure, not just the final summary. Confirm the interpreter, tools, and network prerequisites. Completed installations persist after failure.

The final banner is not an all-checks-passed assertion. In this script:

- Missing Command Line Tools trigger an intentional early exit with status 0.
- Failed cask adoption, missing Cursor CLI cask, and missing Corepack are nonfatal.
- `brew doctor`, runtime version reporting, `claude doctor`, the final `gh auth status`, and the Docker hello-world result tolerate failure.
- The command verifier prints `NOT FOUND` but does not fail the script.
- Its command list omits `htop`, Corepack, `javac`, Docker, Compose, and the Cursor assistant command; this README checks those separately.
- With no terminal input, a `read` prompt can fail and terminate the script under `set -e`. This is not an unattended bootstrap.

Use the acceptance checklist to determine readiness. If a download or an unguarded installation fails, fix that phase and rerun with modern Bash.

When requesting help, provide the relevant error, macOS version, architecture, script revision, affected tool version/path, and what you already tried. Redact usernames where appropriate, tokens, credential URLs, and private repository details. Avoid `bash -x` around authentication or secret-bearing commands because it can print sensitive values.
