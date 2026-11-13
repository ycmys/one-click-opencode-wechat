# one-click-opencode-wechat

A one-click GitHub Codespaces setup that runs [OpenCode](https://opencode.ai) behind a
WeChat bridge, so you can talk to a coding agent from WeChat.

## Quick Start

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ycmys/one-click-opencode-wechat)

Creating the Codespace automatically:

- installs the Node.js LTS toolchain, Git and the GitHub CLI
- installs the OpenCode CLI
- installs [weclaw](https://github.com/fastclaw-ai/weclaw) and writes `~/.weclaw/config.json`
- creates `~/.weclaw/workspace` as the agent working directory

When it finishes, start OpenCode in the terminal:

```bash
opencode
```

## Change the model

The default model is `opencode/minimax-m2.5-free`. Override it with `OPENCODE_MODEL`
and re-run the setup script:

```bash
OPENCODE_MODEL=opencode/big-pickle bash .devcontainer/post-create.sh
```

Then restart the bridge. Use `/models` inside OpenCode to see the models available
to your account.

## Manual setup

```bash
curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://raw.githubusercontent.com/fastclaw-ai/weclaw/main/install.sh | sh
bash .devcontainer/post-create.sh
opencode
```

## GitHub permissions

In a Codespace, `GITHUB_TOKEN` is injected automatically and is scoped to the
repositories you can access, so the agent can usually read and push without extra
setup. Check what it can do with:

```bash
curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO | grep -A6 '"permissions"'
```

If the agent needs write access to another repository, create a fine-grained
personal access token with **Contents: Read and write** for that repository, store
it as a Codespaces secret (for example `GH_TOKEN`), and restart the Codespace.
Never paste tokens into chat or commit them to the repository.

## Requirements

- A GitHub account with Codespaces enabled
- A WeChat account and the ability to receive messages from the bridge
- An OpenCode provider/model you are allowed to use

## Notes

- The install scripts are fetched from their official URLs at create time, so a
  rebuild always gets the current version.
- Rebuilding the Codespace re-runs the setup and overwrites `~/.weclaw/config.json`.
- The OpenCode VS Code extension is optional; install **OpenCode** from the
  Marketplace if you want IDE integration.
