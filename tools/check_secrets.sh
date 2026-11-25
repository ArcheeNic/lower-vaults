#!/usr/bin/env bash
# Fails when EOS client credentials reach the git index.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

status=0
if git ls-files --cached --error-unmatch network/eos.cfg >/dev/null 2>&1; then
	echo "network/eos.cfg is staged or tracked; it must stay local." >&2
	status=1
fi
if git grep --cached -lIE 'client_secret[[:space:]]*=[[:space:]]*"[^"]+"' >&2; then
	echo "A filled client_secret is staged or tracked." >&2
	status=1
fi
if [[ -f network/eos.cfg ]]; then
	secret=$(sed -nE 's/^client_secret[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' network/eos.cfg)
	if [[ -n "$secret" ]] && git grep --cached -qIF -e "$secret"; then
		echo "The EOS client secret appears in a staged or tracked file." >&2
		status=1
	fi
fi
exit "$status"
