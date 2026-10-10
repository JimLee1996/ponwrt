#!/bin/bash
# SPDX-License-Identifier: MIT

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
PKG_PATH="$REPO_ROOT/package"
cd "$PKG_PATH"

#移除luci-app-attendedsysupgrade
find ../feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +

#修复HomeProxy的google检测
HP_DIR=$(find ../feeds/luci/ -maxdepth 3 -type d -wholename "*/applications/luci-app-homeproxy")
if [ -d "$HP_DIR" ]; then
	echo " "

	HP_PATH="$HP_DIR/root/usr/share/rpcd/ucode/luci.homeproxy"
	sed -i 's|www.google.com|www.google.com/generate_204|g' "$HP_PATH"

	cd "$PKG_PATH" && echo "homeproxy check has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "

	sed -i '/\/files/d' "$TS_FILE"

	cd "$PKG_PATH" && echo "tailscale has been fixed!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE"

	cd "$PKG_PATH" && echo "rust has been fixed!"
fi

#修复Frpc配置文件
FRPC_DIR=$(find ../feeds/luci/ -maxdepth 3 -type d -wholename "*/applications/luci-app-frpc")
if [ -d "$FRPC_DIR" ]; then
	FRPC_PATH="$FRPC_DIR/htdocs/luci-static/resources/view/frpc.js"
	sed -i "s|'tcp', 'kcp', 'websocket'|'tcp', 'kcp', 'websocket', 'quic'|g" "$FRPC_PATH"

	cd "$PKG_PATH" && echo "luci-app-frpc has been fixed!"
fi

#修改sing-box(full变体)的GO_PKG_TAGS，避免完整编译生成过大二进制
SB_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/sing-box/Makefile")
if [ -f "$SB_FILE" ]; then
	echo " "

	SING_BOX_TAGS=${SING_BOX_TAGS:-with_clash_api,with_gvisor,with_quic,with_utls,with_wireguard}
	sed -i "/GO_PKG_TAGS:=\$(subst/! s|^[[:space:]]*GO_PKG_TAGS:=.*|  GO_PKG_TAGS:=$SING_BOX_TAGS|" "$SB_FILE"

	cd "$PKG_PATH" && echo "sing-box has been fixed!"
fi

if [ -f "$REPO_ROOT/custom/scripts/private-handles.sh" ]; then
	. "$REPO_ROOT/custom/scripts/private-handles.sh"
fi
