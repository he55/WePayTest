DEBUG = 0
# FINALPACKAGE = 1

ARCHS = arm64
TARGET := iphone:clang:latest:11.0
INSTALL_TARGET_PROCESSES = WeChat


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WePay

WePay_FILES = $(wildcard src/fmdb/*.m src/*.m src/*.x)
WePay_CFLAGS = -fobjc-arc
WePay_LIBRARIES = sqlite3
WePay_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
