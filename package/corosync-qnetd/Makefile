include $(TOPDIR)/rules.mk

PKG_NAME:=corosync-qdevice
PKG_VERSION:=3.0.4
PKG_RELEASE:=2

PKG_SOURCE:=corosync-qdevice-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/corosync/corosync-qdevice/archive/refs/tags/v$(PKG_VERSION)/
PKG_HASH:=skip
PKG_BUILD_DIR:=$(BUILD_DIR)/corosync-qdevice-$(PKG_VERSION)
PKG_FIXUP:=autoreconf
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

PKG_BUILD_DEPENDS:=nss-qnetd

include $(INCLUDE_DIR)/package.mk

# Bypass unconditional PKG_CHECK_MODULES for corosync libs (only used by qdevice, not qnetd)
CONFIGURE_VARS += \
	PKG_CONFIG_PATH="$(STAGING_DIR)/usr/lib/pkgconfig" \
	nss_CFLAGS="-I$(STAGING_DIR)/usr/include/nss -I$(STAGING_DIR)/usr/include/nspr" \
	nss_LIBS="-L$(STAGING_DIR)/usr/lib -lnss3 -lssl3 -lsmime3 -lnssutil3 -lnspr4 -lplc4 -lplds4" \
	corosync_common_CFLAGS=" " \
	corosync_common_LIBS=" " \
	cmap_CFLAGS=" " \
	cmap_LIBS=" " \
	votequorum_CFLAGS=" " \
	votequorum_LIBS=" "

CONFIGURE_ARGS += \
	--disable-qdevices \
	--enable-install-qnetd-in-sbin \
	--disable-systemd \
	--with-initddir=/etc/init.d

define Package/corosync-qnetd
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Corosync QNetd
  DEPENDS:=+libnss +nspr +nss-utils +openssl-util +bash +coreutils-chown +coreutils-sha1sum +coreutils-stat +openssh-sftp-server +procps-ng
endef

define Package/corosync-qnetd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/corosync-qnetd $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/corosync-qnetd-tool $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/corosync-qnetd-certutil $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/qnetd.init $(1)/etc/init.d/corosync-qnetd
	$(SED) '1s|#!.*/bash|#!/bin/bash|' $(1)/usr/sbin/corosync-qnetd-certutil
endef

$(eval $(call BuildPackage,corosync-qnetd))
