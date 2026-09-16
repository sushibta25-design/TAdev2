ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = MainPart

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TAdev2
TAdev2_FILES = Tweak.xm
TAdev2_CFLAGS = -fobjc-arc
TAdev2_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
