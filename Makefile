#
# Copyright (C) 2026 SCUT Router Term
# 
# -- LuCI by aidenlee (e-mail: dongdonglee1994@foxmail.com)
# -- Fixed for OpenWrt 24.10+ / 25.x compatibility
#
# This is free software, licensed under the GNU General Public License v3.0 .
#
include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for scutclient Plus (2026)
LUCI_DEPENDS:=+scutclient +luci-compat +luci-lib-nixio +PACKAGE_luci-lua-runtime:luci-lua-runtime
PKG_VERSION:=1.0
PKG_RELEASE:=3
PKG_LICENSE:=GPL-3.0

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
