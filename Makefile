ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
export TARGET = iphone:clang:11.4:11.4

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GreenPass

GreenPass_FILES = $(wildcard G*.*m)  UIImage+Gif.m
GreenPass_LIBRARIES = imagepicker 
GreenPass_FRAMEWORKS = UIKit Photos MobileCoreServices
GreenPass_LDFLAGS = -lactivator
GreenPass_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += greenpassprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
