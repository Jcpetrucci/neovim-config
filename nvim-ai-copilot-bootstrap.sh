#!/usr/bin/env bash
set -euo pipefail

PACK_ROOT="${HOME}/.config/nvim/pack/vendor/start"

mkdir -p "${PACK_ROOT}"

# --- prereqs ---
# Intentionally do NOT install neovim here, because distro packages may lag
# behind upstream and you already upgraded manually.
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y nodejs npm curl git ripgrep make
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y nodejs npm curl git ripgrep make
elif command -v brew >/dev/null 2>&1; then
  brew install node ripgrep make git curl
else
  echo "Install manually: nodejs, npm, git, curl, make, ripgrep(optional)"
fi

clone_or_update() {
  local repo_url="$1"
  local dest="$2"
  local ref="${3:-}"

  if [ -d "${dest}/.git" ]; then
    git -C "${dest}" fetch --tags --force
  else
    git clone --depth=1 "${repo_url}" "${dest}"
  fi

  if [ -n "${ref}" ]; then
    git -C "${dest}" fetch --depth=1 origin "${ref}" || true
    git -C "${dest}" checkout "${ref}"
  fi
}

# Pin to refs your team approves internally.
clone_or_update https://github.com/github/copilot.vim.git \
  "${PACK_ROOT}/copilot.vim" \
  "v1.59.0"

clone_or_update https://github.com/nvim-lua/plenary.nvim.git \
  "${PACK_ROOT}/plenary.nvim" \
  "master"

clone_or_update https://github.com/CopilotC-Nvim/CopilotChat.nvim.git \
  "${PACK_ROOT}/CopilotChat.nvim" \
  "main"

# Optional token counting support for CopilotChat.nvim
if [ -d "${PACK_ROOT}/CopilotChat.nvim" ]; then
  (cd "${PACK_ROOT}/CopilotChat.nvim" && make tiktoken) || true
fi

echo
echo "Bootstrap complete."
echo "Next:"
echo "  1. Launch nvim"
echo "  2. Run: :Copilot setup"
echo "  3. Complete GitHub device login"
echo "  4. Verify inline completion, :CopilotChatOpen, and <leader>ap / <leader>aP"

