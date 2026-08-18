#!/usr/bin/env bash
# 启用仓库内置 git hooks（每人 clone 后执行一次）
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
echo "git hooks 已启用：.githooks/pre-commit"
