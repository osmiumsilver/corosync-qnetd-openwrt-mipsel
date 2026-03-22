include $(TOPDIR)/rules.mk

PKG_NAME:=libknet
PKG_VERSION:=1.28
PKG_RELEASE:=1

PKG_SOURCE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/kronosnet/kronosnet/archive/refs/tags/
PKG_SOURCE_SUBDIR:=kronosnet-$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/kronosnet-$(PKG_VERSION)
PKG_HASH:=skip
PKG_FIXUP:=autoreconf
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

# kronosnet sets its own -D_FORTIFY_SOURCE=2; remove OpenWrt's to avoid redefinition error
TARGET_CFLAGS := $(filter-out -D_FORTIFY_SOURCE=%,$(TARGET_CFLAGS))

CONFIGURE_VARS += \
	PKG_CONFIG_PATH="$(STAGING_DIR)/usr/lib/pkgconfig" \
	nss_CFLAGS="-I$(STAGING_DIR)/usr/include/nss -I$(STAGING_DIR)/usr/include/nspr" \
	nss_LIBS="-L$(STAGING_DIR)/usr/lib -lnss3 -lssl3 -lsmime3 -lnssutil3"

CONFIGURE_ARGS += \
	--disable-crypto-openssl \
	--disable-compress-zlib \
	--disable-compress-lz4 \
	--disable-compress-lzo2 \
	--disable-compress-zstd \
	--disable-compress-bzip2 \
	--disable-compress-lzma \
	--disable-libknet-sctp \
	--disable-libnozzle \
	--disable-man

define Package/libknet
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=libknet
  DEPENDS:=+libqb +libnss
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include $(1)/usr/lib/pkgconfig
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/include/libknet.h $(1)/usr/include/
	cp -a $(PKG_INSTALL_DIR)/usr/lib/libknet.so* $(1)/usr/lib/
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libknet.pc $(1)/usr/lib/pkgconfig/
endef

define Package/libknet/install
	$(INSTALL_DIR) $(1)/usr/lib
	cp -a $(PKG_INSTALL_DIR)/usr/lib/libknet.so* $(1)/usr/lib/
	rm -f $(1)/usr/lib/*.a $(1)/usr/lib/*.la
endef

$(eval $(call BuildPackage,libknet))
