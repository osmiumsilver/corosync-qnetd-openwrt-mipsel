include $(TOPDIR)/rules.mk

PKG_NAME:=nss
PKG_VERSION:=3.98
PKG_RELEASE:=8

PKG_SOURCE:=nss-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://archive.mozilla.org/pub/security/nss/releases/NSS_3_98_RTM/src/
PKG_HASH:=skip

PKG_BUILD_DEPENDS:=nspr

include $(INCLUDE_DIR)/package.mk

define Package/libnss
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Mozilla NSS
  DEPENDS:=+libnspr +zlib
endef

define Build/Configure
endef

# --- Why this differs from the original aarch64 version ---
#
# The original repo uses OS_ARCH=aarch64 + USE_64=1.  This works because
# NSS's coreconf has fallback logic that loads Linux.mk for unknown 64-bit
# arches.  For mipsel (32-bit), there is no such fallback — NSS can't find
# coreconf/mipsel.mk, falls back to auto-detecting the host, and then
# compiles everything with the host's "cc" instead of the cross-compiler.
#
# The fix:
#   OS_ARCH=Linux    → loads coreconf/Linux.mk (the platform config)
#   OS_TARGET=Linux  → the variable NSS actually checks in most places
#   OS_TEST=mipsel   → tells NSS the target CPU (equivalent to uname -m)
#   CPU_ARCH=mipsel  → target CPU architecture
#   No USE_64        → mipsel_24kc is 32-bit
#
# We also stage NSPR headers/libs into NSS's dist/ tree because NSS
# sub-makefiles hard-code include paths like dist/<OBJDIR>/include and
# dist/public/nspr — setting NSPR_INCLUDE_DIR alone is insufficient.

define Build/Compile
	# ---- 1. Host tool (nsinstall for the build machine) ----
	$(MAKE) -j$(nproc) -C $(PKG_BUILD_DIR)/nss/coreconf/nsinstall \
		CC="$(HOSTCC)" \
		OBJDIR_NAME=host \
		BUILD_OPT=1

	# ---- 2. Stage NSPR into dist/ so NSS's hard-coded paths find it ----
	mkdir -p $(PKG_BUILD_DIR)/dist/target.OBJ/include
	cp -fpRL $(STAGING_DIR)/usr/include/nspr/. \
		$(PKG_BUILD_DIR)/dist/target.OBJ/include/
	mkdir -p $(PKG_BUILD_DIR)/dist/public/nspr
	cp -fpRL $(STAGING_DIR)/usr/include/nspr/. \
		$(PKG_BUILD_DIR)/dist/public/nspr/
	mkdir -p $(PKG_BUILD_DIR)/dist/target.OBJ/lib
	for lib in libnspr4.so libplc4.so libplds4.so; do \
		cp -fpL $(STAGING_DIR)/usr/lib/$$lib \
			$(PKG_BUILD_DIR)/dist/target.OBJ/lib/ 2>/dev/null || true; \
	done

	# ---- 3. Target build ----
	$(MAKE) -j$(nproc) -C $(PKG_BUILD_DIR)/nss \
		BUILD_OPT=1 \
		CROSS_COMPILE=1 \
		NATIVE_CC="$(HOSTCC)" \
		OS_TARGET=Linux \
		OS_ARCH=Linux \
		OS_TEST=mipsel \
		CPU_ARCH=mipsel \
		KERNEL=Linux \
		OBJDIR_NAME=target.OBJ \
		FREEBL_LOWHASH=1 \
		FREEBL_NO_DEPEND=1 \
		NSS_USE_64=0 \
		NSINSTALL="$(PKG_BUILD_DIR)/nss/coreconf/nsinstall/host/nsinstall" \
		CC="$(TARGET_CC)" \
		CCC="$(TARGET_CXX)" \
		RANLIB="$(TARGET_CROSS)ranlib" \
		RC= \
		NSS_DISABLE_DBM=1 \
		NSS_DISABLE_LIBPKIX=1 \
		NSS_DISABLE_GTESTS=1 \
		USE_SYSTEM_NSPR=1 \
		NSPR_INCLUDE_DIR="$(PKG_BUILD_DIR)/dist/target.OBJ/include" \
		NSPR_LIB_DIR="$(PKG_BUILD_DIR)/dist/target.OBJ/lib" \
		OS_REL_CFLAGS="" \
		ARCHFLAG="" \
		DSO_LDOPTS="-shared" \
		LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib" \
		NSS_ENABLE_TESTS=0 \
		XCFLAGS="$(filter-out -Wl%,$(TARGET_CFLAGS)) $(TARGET_CPPFLAGS) \
			-I$(STAGING_DIR)/usr/include \
			-I$(STAGING_DIR)/usr/include/nspr \
			-I$(PKG_BUILD_DIR)/dist/public/nspr \
			-D_GNU_SOURCE \
			-fno-lto -Wno-error" \
		DANGEROUS_CRT_PATH_OK=1
endef

# Only install headers and libs into staging_dir for other packages to compile against.
# No ipk is generated for the router — use official libnss from opkg instead.

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/nss
	cp -fpRL $(PKG_BUILD_DIR)/dist/public/nss/. $(1)/usr/include/nss/
	$(INSTALL_DIR) $(1)/usr/lib
	cp -fpL $(PKG_BUILD_DIR)/dist/target.OBJ/lib/libnss3.so     $(1)/usr/lib/
	cp -fpL $(PKG_BUILD_DIR)/dist/target.OBJ/lib/libssl3.so     $(1)/usr/lib/
	cp -fpL $(PKG_BUILD_DIR)/dist/target.OBJ/lib/libsmime3.so   $(1)/usr/lib/
	cp -fpL $(PKG_BUILD_DIR)/dist/target.OBJ/lib/libsoftokn3.so $(1)/usr/lib/
	cp -fpL $(PKG_BUILD_DIR)/dist/target.OBJ/lib/libnssutil3.so $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(INSTALL_DATA) ./files/nss.pc $(1)/usr/lib/pkgconfig/nss.pc
endef

$(eval $(call BuildPackage,libnss))
