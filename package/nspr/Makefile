include $(TOPDIR)/rules.mk

PKG_NAME:=nspr
PKG_VERSION:=4.35
PKG_RELEASE:=1

PKG_SOURCE:=nspr-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://archive.mozilla.org/pub/nspr/releases/v$(PKG_VERSION)/src/
PKG_HASH:=skip
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/libnspr
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=NSPR
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR)/nspr; \
	 $(CONFIGURE_VARS) \
	 ./configure $(CONFIGURE_ARGS) \
		--enable-pthreads \
		--with-pthreads \
		--target=mipsel-linux \
		--enable-optimize \
		--disable-debug \
		--enable-strip)
endef

define Build/Compile
	# Pre-build host tools with native gcc so they execute on x86_64
	(cd $(PKG_BUILD_DIR)/nspr/config && \
	 gcc -o now.o -c -DXP_UNIX now.c && \
	 gcc -o now now.o && \
	 gcc -o nsinstall.o -c -DXP_UNIX nsinstall.c && \
	 gcc -o nsinstall nsinstall.o && \
	 touch now.o now nsinstall.o nsinstall)
	$(MAKE_VARS) $(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR)/nspr $(MAKE_FLAGS)
endef

define Build/Install
	$(MAKE) -C $(PKG_BUILD_DIR)/nspr install DESTDIR=$(PKG_INSTALL_DIR)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/nspr
	$(CP) $(PKG_INSTALL_DIR)/usr/include/nspr/. $(1)/usr/include/nspr/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libnspr4.so* $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libplds4.so* $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libplc4.so* $(1)/usr/lib/
endef

define Package/libnspr/install
	$(INSTALL_DIR) $(1)/usr/lib
	cp -a $(PKG_INSTALL_DIR)/usr/lib/libnspr4.so* $(1)/usr/lib/
	cp -a $(PKG_INSTALL_DIR)/usr/lib/libplds4.so* $(1)/usr/lib/
	cp -a $(PKG_INSTALL_DIR)/usr/lib/libplc4.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libnspr))
