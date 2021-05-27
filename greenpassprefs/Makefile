ARCHS = arm64 arm64e
export TARGET = iphone:clang:11.4:11.4
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = GreenPassPrefs

GreenPassPrefs_FILES = GPSRootListController.m
GreenPassPrefs_FRAMEWORKS = UIKit
GreenPassPrefs_PRIVATE_FRAMEWORKS = Preferences
GreenPassPrefs_LIBRARIES = imagepicker
GreenPassPrefs_INSTALL_PATH = /Library/PreferenceBundles
GreenPassPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GreenPassPrefs.plist$(ECHO_END)
