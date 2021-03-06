MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIRNAME := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))
TOP :=$(shell dirname $(MKFILE_PATH))/../../
FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0xe0:m

# default variable values
SOURCES ?= $(wildcard *.c) $(wildcard *.cpp)
SOURCES := $(shell readlink -f $(SOURCES))
INCLUDES ?= ./
INCLUDES := $(shell readlink -f $(INCLUDES))

# generate object names
OBJECTS	 = $(patsubst %.cpp, %.o, $(SOURCES))
OBJECTS	 += $(patsubst %.c, %.o, $(SOURCES))
OBJECTS  := $(filter-out %.c, $(OBJECTS))
OBJECTS  := $(filter-out %.cpp, $(OBJECTS))

OBJ_DIR  = tmp/
OBJ_TMP  = $(addprefix $(OBJ_DIR)/, $(notdir ${OBJECTS}))

IFLAGS	 = $(foreach d, $(INCLUDES), -I$d)
CFLAGS  += -Wall -MMD -DUSB_VID=null -DUSB_PID=null -DARDUINO=106 #arduino specific
CFLAGS  += -fshort-enums -O2 -Os # more optimizing
CPPFLAGS += $(CFLAGS)

ifeq ($(filter $(FLOAT_SUPPORT), $(TRUE)),) # only turn on this if float support disabled
ifneq ($(filter $(OPTIMIZE), $(TRUE)),)
CFLAGS  += -fdata-sections -ffunction-sections -Wl,--gc-sections # garbage collection
endif
endif

# libutils support
ifneq ($(filter $(UTILS_SUPPORT), $(TRUE)),)
LIBUTILS = $(OBJ_DIR)libutils.a
UTILS_SOURCES ?= $(wildcard $(UTILS_DIR)/*.c) $(wildcard $(UTILS_DIR)/*.cpp)
endif
UTILS_DIR  ?= $(TOP)/common/utils/
UTILS_DIR := $(shell readlink -f $(UTILS_DIR))
UTILS_INCLUDEFLAGS ?= -I$(UTILS_DIR)

UTILS_OBJECTS	 = $(patsubst %.cpp, %.cpp.libo, $(UTILS_SOURCES))
UTILS_OBJECTS	 += $(patsubst %.c, %.c.libo, $(UTILS_SOURCES))
UTILS_OBJECTS  := $(filter-out %.c, $(UTILS_OBJECTS))
UTILS_OBJECTS  := $(filter-out %.cpp, $(UTILS_OBJECTS))
UTILS_OBJ_TMP  = $(addprefix $(OBJ_DIR)/, $(notdir ${UTILS_OBJECTS}))

# Fuse Low Byte = 0xe0   Fuse High Byte = 0xd9   Fuse Extended Byte = 0xff
# Bit 7: CKDIV8  = 0     Bit 7: RSTDISBL  = 1    Bit 7:
#     6: CKOUT   = 1         6: DWEN      = 1        6:
#     5: SUT1    = 1         5: SPIEN     = 0        5:
#     4: SUT0    = 0         4: WDTON     = 1        4:
#     3: CKSEL3  = 0         3: EESAVE    = 1        3:
#     2: CKSEL2  = 0         2: BOOTSIZ1  = 0        2: BODLEVEL2 = 1
#     1: CKSEL1  = 0         1: BOOTSIZ0  = 0        1: BODLEVEL1 = 1
#     0: CKSEL0  = 0         0: BOOTRST   = 1        0: BODLEVEL0 = 1
# External clock source, start-up time = 14 clks + 65ms
# Don't output clock on PORTB0, don't divide clock by 8,
# Boot reset vector disabled, boot flash size 2048 bytes,
# Preserve EEPROM disabled, watch-dog timer off
# Serial program downloading enabled, debug wire disabled,
# Reset enabled, brown-out detection disabled

# Tune the lines below only if you know what you are doing:

AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE)
COMPILE = $(CC) $(CFLAGS) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE) $(IFLAGS)
COMPILE_CPP = $(CPP) $(CPPFLAGS) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE) $(IFLAGS)
LINK_LIBUTILS = avr-ar rcs $(LIBUTILS)
UTILS_COMPILE = $(CC) $(CFLAGS) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE) $(UTILS_INCLUDEFLAGS)
UTILS_COMPILE_CPP = $(CPP) $(CPPFLAGS) -DF_CPU=$(CLOCK) -mmcu=$(DEVICE) $(UTILS_INCLUDEFLAGS)

# symbolic targets:
.default: all

all: 
	$(MAKE) $(HEX_NAME)	
	
.c.o:
	@mkdir -p $(OBJ_DIR)
	$(COMPILE) -c $< -o $(OBJ_DIR)/$(notdir $@)
	@echo ""

.cpp.o:
	@mkdir -p $(OBJ_DIR)
	$(COMPILE_CPP) -c $< -o $(OBJ_DIR)/$(notdir $@)
	@echo ""

%.c.libo: %.c
	@mkdir -p $(OBJ_DIR)
	$(UTILS_COMPILE) -c $< -o $(OBJ_DIR)/$(notdir $@)
	@echo ""

%.cpp.libo: %.cpp
	@mkdir -p $(OBJ_DIR)
	$(UTILS_COMPILE_CPP) -c $< -o $(OBJ_DIR)/$(notdir $@)
	@echo ""

flash:	all
	$(AVRDUDE) -U flash:w:$(HEX_NAME):i

fuse:
	$(AVRDUDE) $(FUSES)

# Xcode uses the Makefile targets "", "clean" and "install"
install: flash fuse

# if you use a bootloader, change the command below appropriately:
load: all
	bootloadHID $(HEX_NAME)

clean: 
	rm -f $(HEX_NAME) $(BINARY_NAME) $(LIBUTILS)
	rm -rf $(OBJ_DIR)
	rm -f $(UTILS_DIR)/*.d

# file targets:
ifeq ($(wildcard $(LIBUTILS)),) # check if libutils.a exists
$(LIBUTILS): $(UTILS_OBJECTS)
	$(foreach obj, $(UTILS_OBJ_TMP), $(LINK_LIBUTILS) $(obj) ;)
else
$(LIBUTILS):
	
endif

$(BINARY_NAME): $(OBJECTS) $(LIBUTILS)
	$(COMPILE) -o $(BINARY_NAME) $(OBJ_TMP) $(LIBUTILS)

$(HEX_NAME): $(BINARY_NAME)
	rm -f $(HEX_NAME)
	avr-objcopy -j .text -j .data -O ihex $(BINARY_NAME) $(HEX_NAME)
	avr-size -C $(BINARY_NAME) --mcu=$(DEVICE)
# If you have an EEPROM section, you must also create a hex file for the
# EEPROM and add it to the "flash" target.

# Targets for code debugging and analysis:
disasm:	$(BINARY_NAME)
	avr-objdump -d $(BINARY_NAME)
