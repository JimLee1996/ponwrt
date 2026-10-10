#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
PACKAGE_DIR="$REPO_ROOT/package"
TMP_DIR="${TMPDIR:-/tmp}/ponwrt-custom-packages"

mkdir -p "$PACKAGE_DIR" "$TMP_DIR"
cd "$PACKAGE_DIR"

update_package() {
	local package_name="$1"
	local package_repo="$2"
	local package_branch="$3"
	local package_mode="${4:-}"
	local package_aliases="${5:-}"
	local repo_name="${package_repo#*/}"
	local clone_dir="$TMP_DIR/$repo_name"

	echo
	echo "Updating package: $package_name from $package_repo ($package_branch)"

	for name in $package_name $package_aliases; do
		find "$REPO_ROOT/feeds/luci" "$REPO_ROOT/feeds/packages" "$PACKAGE_DIR" \
			-maxdepth 3 -type d -iname "*$name*" -prune -print 2>/dev/null |
			while IFS= read -r dir; do
				rm -rf "$dir"
				echo "Deleted existing package directory: $dir"
			done
	done

	rm -rf "$clone_dir"
	git clone --depth=1 --single-branch --branch "$package_branch" \
		"https://github.com/$package_repo.git" "$clone_dir"

	case "$package_mode" in
		pkg)
			find "$clone_dir" -mindepth 1 -maxdepth 4 -type d -iname "*$package_name*" -prune \
				-exec cp -rf {} "$PACKAGE_DIR/" \;
			rm -rf "$clone_dir"
			;;
		name)
			rm -rf "$PACKAGE_DIR/$package_name"
			mv -f "$clone_dir" "$PACKAGE_DIR/$package_name"
			;;
		*)
			rm -rf "$PACKAGE_DIR/$repo_name"
			mv -f "$clone_dir" "$PACKAGE_DIR/$repo_name"
			;;
	esac
}

# Packages that are selected by custom/config/general.config but are not
# expected to be reliably present in upstream feeds.
update_package "easytier" "EasyTier/luci-app-easytier" "main"

if [ -f "$REPO_ROOT/custom/scripts/private-packages.sh" ]; then
	# shellcheck source=/dev/null
	. "$REPO_ROOT/custom/scripts/private-packages.sh"
fi
