ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
export TARGET = iphone:clang:14.4:14.4

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GreenPass

GreenPass_FILES = Tweak.xm
GreenPass_LIBRARIES = imagepicker
GreenPass_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += greenpassprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
