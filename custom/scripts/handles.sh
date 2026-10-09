#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)

find_first_dir() {
	find "$@" -type d -print -quit 2>/dev/null || true
}

find_first_file() {
	find "$@" -type f -print -quit 2>/dev/null || true
}

patch_file_if_present() {
	local file="$1"
	local expression="$2"
	local label="$3"

	if [ -f "$file" ]; then
		sed -i "$expression" "$file"
		echo "$label has been patched."
	fi
}

LUCI_FEED="$REPO_ROOT/feeds/luci"
PACKAGES_FEED="$REPO_ROOT/feeds/packages"
PACKAGE_DIR="$REPO_ROOT/package"

# Remove attendedsysupgrade from LuCI collections when it is pulled by default.
if [ -d "$LUCI_FEED/collections" ]; then
	find "$LUCI_FEED/collections" -type f -name Makefile -print0 |
		xargs -0 -r sed -i '/attendedsysupgrade/d'
	echo "attendedsysupgrade defaults have been removed from LuCI collections."
fi

# Fix HomeProxy connectivity check URL.
homeproxy_dir=$(find_first_dir "$LUCI_FEED/applications" "$PACKAGE_DIR" -maxdepth 3 -wholename "*/luci-app-homeproxy")
if [ -n "$homeproxy_dir" ]; then
	patch_file_if_present \
		"$homeproxy_dir/root/usr/share/rpcd/ucode/luci.homeproxy" \
		's|www.google.com|www.google.com/generate_204|g' \
		"homeproxy check"
fi

# Add QUIC as an optional frpc protocol if luci-app-frpc is present.
frpc_dir=$(find_first_dir "$LUCI_FEED/applications" "$PACKAGE_DIR" -maxdepth 3 -wholename "*/luci-app-frpc")
if [ -n "$frpc_dir" ]; then
	patch_file_if_present \
		"$frpc_dir/htdocs/luci-static/resources/view/frpc.js" \
		"s|'tcp', 'kcp', 'websocket'|'tcp', 'kcp', 'websocket', 'quic'|g" \
		"luci-app-frpc"
fi

# Avoid tailscale packaging conflicts caused by duplicated files directories.
tailscale_makefile=$(find_first_file "$PACKAGES_FEED/net" "$PACKAGES_FEED" -maxdepth 4 -wholename "*/tailscale/Makefile")
patch_file_if_present "$tailscale_makefile" '/\/files/d' "tailscale"

# Disable Rust's CI LLVM mode, which is fragile on GitHub-hosted builders.
rust_makefile=$(find_first_file "$PACKAGES_FEED/lang" "$PACKAGES_FEED" -maxdepth 4 -wholename "*/rust/Makefile")
patch_file_if_present "$rust_makefile" 's/ci-llvm=true/ci-llvm=false/g' "rust"

# Keep the full sing-box variant from producing an oversized binary by default.
sing_box_makefile=$(find_first_file "$PACKAGES_FEED/net" "$PACKAGES_FEED" -maxdepth 4 -wholename "*/sing-box/Makefile")
if [ -f "$sing_box_makefile" ]; then
	sing_box_tags="${SING_BOX_TAGS:-with_clash_api,with_gvisor,with_quic,with_utls,with_wireguard}"
	sed -i "/GO_PKG_TAGS:=\$(subst/! s|^[[:space:]]*GO_PKG_TAGS:=.*|  GO_PKG_TAGS:=$sing_box_tags|" "$sing_box_makefile"
	echo "sing-box has been patched."
fi

if [ -f "$REPO_ROOT/custom/scripts/private-handles.sh" ]; then
	# shellcheck source=/dev/null
	. "$REPO_ROOT/custom/scripts/private-handles.sh"
fi
