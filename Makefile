DEBUG = 0
# FINALPACKAGE = 1

ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:11.0
INSTALL_TARGET_PROCESSES = WeChat


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WePay

WePay_FILES = Tweak.x
WePay_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
