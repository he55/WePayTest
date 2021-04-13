DEBUG = 0
# FINALPACKAGE = 1

ARCHS = armv7 arm64
TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Filza


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppInfoForFilza

AppInfoForFilza_FILES = Tweak.x
AppInfoForFilza_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
