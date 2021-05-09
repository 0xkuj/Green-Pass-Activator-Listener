ARCHS = arm64 arm64e
export TARGET = iphone:clang:14.4:14.4
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = GreenPassPrefs

GreenPassPrefs_FILES = GPSRootListController.m
GreenPassPrefs_FRAMEWORKS = UIKit
GreenPassPrefs_PRIVATE_FRAMEWORKS = Preferences
GreenPassPrefs_LIBRARIES = imagepicker
GreenPassPrefs_INSTALL_PATH = /Library/PreferenceBundles
GreenPassPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
