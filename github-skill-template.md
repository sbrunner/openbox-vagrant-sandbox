---
name: github-token
description: Provides GitHub tokens and safe `gh` execution patterns. Use when a task needs GitHub API access, when default `gh auth` does not have enough permissions, or when commands must avoid exposing tokens in logs/output.
---

# GitHub Token

## Quick start

1. Select the token from the owner map below.
2. Run `gh` only through the wrapper script.
3. If you also need `git push` over HTTPS, run `gh auth setup-git` through the wrapper before pushing.
4. Always clone all branches.
5. Ensure `origin` uses tokenized HTTPS (`https://x-access-token:<token>@github.com/<owner>/<repo>.git`). If clone creates another URL format, convert it immediately.

## Token owner map

- `camptocamp` repositories:
  - Definition: https://github.com/settings/personal-access-tokens/<id>
  - Script: `scripts/camptocamp-token`
- Classic token (notifications and other organizations/users):
  - Definition: https://github.com/settings/tokens/<id>
  - Script: `scripts/classic-token`

## Wrapper script (required)

Use a wrapper script to keep tokens out of logged command lines.

The scripts are bundled in the skill directory:

```
~/.config/opencode/skills/github-token/scripts/classic-token
~/.config/opencode/skills/github-token/scripts/camptocamp-token
```

Run commands through the wrapper:

```bash
~/.config/opencode/skills/github-token/scripts/classic-token gh api notifications
```

Configure Git credential flow for token-based push (per session):

```bash
~/.config/opencode/skills/github-token/scripts/camptocamp-token gh auth setup-git
git push origin HEAD
```

Ensure tokenized HTTPS origin after clone:

```bash
git remote set-url origin https://x-access-token:<token>@github.com/<owner>/<repo>.git
git remote -v
```

Practical mode (persistent in current repository): embed token in `origin` URL without printing it in logs:

```bash
python3 - <<'PY'
import re
import subprocess
from pathlib import Path

wrapper = Path('~/.config/opencode/skills/github-token/scripts/camptocamp-token').read_text()
token = re.search(r"GH_TOKEN='([^']+)'", wrapper).group(1)
url = f"https://x-access-token:{token}@github.com/camptocamp/<repo>.git"
subprocess.run(['git', 'remote', 'set-url', 'origin', url], check=True)
PY
```

## Hard safety rules

- Never put token literals directly in logged commands (for example `GH_TOKEN=... gh ...`).
- Never print token values in output, reports, or user-facing messages.
- If token-in-remote mode is used, do it only in local clones and avoid sharing `.git/config`.
- If a token is exposed, revoke and rotate it immediately.

## Troubleshooting

- `HTTP 403 Resource not accessible by personal access token`: use another token from the owner map (or classic), then retry.
- `fatal: could not read Username for 'https://github.com'`: setup the remote URL through the correct wrapper, then retry `git push`.
- If an operation still fails, report it as manual intervention required.
