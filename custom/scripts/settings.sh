#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
CONFIG_FILE="${1:-$REPO_ROOT/.config}"

if [ ! -f "$CONFIG_FILE" ]; then
	echo "Config file not found: $CONFIG_FILE" >&2
	exit 1
fi

if [ -f "$REPO_ROOT/custom/config/private.config" ]; then
	echo "Applying custom/config/private.config"
	{
		echo
		cat "$REPO_ROOT/custom/config/private.config"
	} >> "$CONFIG_FILE"
fi

if [ -n "${CUSTOM_PACKAGE_SELECTIONS:-}" ]; then
	echo "Applying manual package selections"
	{
		echo
		printf '%s\n' "$CUSTOM_PACKAGE_SELECTIONS"
	} >> "$CONFIG_FILE"
fi

if [ -f "$REPO_ROOT/custom/scripts/private-settings.sh" ]; then
	# shellcheck source=/dev/null
	. "$REPO_ROOT/custom/scripts/private-settings.sh" "$CONFIG_FILE"
fi
