# Name of the project
PROJECT = template

BUILD_DIR = ./build

CC = arm-none-eabi-gcc
AS = arm-none-eabi-as
GDB = arm-none-eabi-gdb
OBJCOPY = arm-none-eabi-objcopy
SIZE = arm-none-eabi-size

ASFLAGS += -mthumb
CFLAGS += -O0 -mthumb -mcpu=cortex-m0 -DCORTEX_M0 -DUSE_STDPERIPH_DRIVER

LDFLAGS = -mcpu=cortex-m0 -mthumb -nostartfiles -Wl,-Map=$(BUILD_DIR)/$(PROJECT).map,--cref
LIBS =

ASFLAGS += -g -gdwarf-2
CFLAGS += -g -gdwarf-2

LIBRARIES_DIR = ./W7500/W7500x_Library_Examples/Libraries
CMSIS_DIR = $(LIBRARIES_DIR)/CMSIS

LOCAL_SOURCE_DIR = ./src
LOCAL_INCLUDES_DIR = ./src/include

# Add source files here. Could also use
# LOCAL_SOURCES = $(wildcard $(LOCAL_SOURCE_DIR)/*.c)
LOCAL_SOURCES = \
	$(LOCAL_SOURCE_DIR)/main.c \
	$(LOCAL_SOURCE_DIR)/W7500x_it.c

DEVICE_SOURCE_DIR = $(CMSIS_DIR)/Device/WIZnet/W7500/Source
DEVICE_INCLUDES_DIR = $(CMSIS_DIR)/Device/WIZnet/W7500/Include
DEVICE_SOURCES = $(DEVICE_SOURCE_DIR)/system_W7500x.c

STDPERIPH_DIR = $(LIBRARIES_DIR)/W7500x_stdPeriph_Driver
STDPERIPH_SOURCE_DIR = $(STDPERIPH_DIR)/src
STDPERIPH_INCLUDES_DIR = $(STDPERIPH_DIR)/inc

# Add peripheral driver source files here
STDPERIPH_SOURCES = $(STDPERIPH_SOURCE_DIR)/W7500x_gpio.c

STARTUP_SOURCE_DIR = $(DEVICE_SOURCE_DIR)/GCC
STARTUP_SOURCES = $(STARTUP_SOURCE_DIR)/startup_W7500.S

CORE_INCLUDES_DIR = $(CMSIS_DIR)/Include

LD_SCRIPT = $(STARTUP_SOURCE_DIR)/gcc_W7500.ld
LDFLAGS += -T$(LD_SCRIPT)

LOCAL_OBJS = $(patsubst $(LOCAL_SOURCE_DIR)/%.c, $(BUILD_DIR)/%.o, $(LOCAL_SOURCES))
STARTUP_OBJS = $(patsubst $(STARTUP_SOURCE_DIR)/%.S, $(BUILD_DIR)/%.o, $(STARTUP_SOURCES))
DEVICE_OBJS = $(patsubst $(DEVICE_SOURCE_DIR)/%.c, $(BUILD_DIR)/%.o, $(DEVICE_SOURCES))
STDPERIPH_OBJS = $(patsubst $(STDPERIPH_SOURCE_DIR)/%.c, $(BUILD_DIR)/%.o, $(STDPERIPH_SOURCES))

INCLUDES = $(LOCAL_INCLUDES_DIR) $(DEVICE_INCLUDES_DIR) $(CORE_INCLUDES_DIR) $(STDPERIPH_INCLUDES_DIR)
IFLAGS = $(foreach i, $(INCLUDES), -I$i)

OBJS = $(STARTUP_OBJS) $(LOCAL_OBJS) $(DEVICE_OBJS) $(STDPERIPH_OBJS)

.DEFAULT_GOAL = all

$(STARTUP_OBJS): $(BUILD_DIR)/%.o : $(STARTUP_SOURCE_DIR)/%.S
	$(AS) $(ASFLAGS) $^ -c -o $@

$(LOCAL_OBJS): $(BUILD_DIR)/%.o : $(LOCAL_SOURCE_DIR)/%.c
	$(CC) $(CFLAGS) $(IFLAGS) $^ -c -o $@

$(DEVICE_OBJS): $(BUILD_DIR)/%.o : $(DEVICE_SOURCE_DIR)/%.c
	$(CC) $(CFLAGS) $(IFLAGS) $^ -c -o $@

$(STDPERIPH_OBJS): $(BUILD_DIR)/%.o : $(STDPERIPH_SOURCE_DIR)/%.c
	$(CC) $(CFLAGS) $(IFLAGS) $^ -c -o $@

%elf: $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) $(LIBS) -o $@
	
%bin: %elf
	$(OBJCOPY) -O binary -S $< $@	

$(BUILD_DIR):
	if [ ! -d "$(BUILD_DIR)" ]; then mkdir "$(BUILD_DIR)"; fi
	
all: $(BUILD_DIR) $(OBJS) $(BUILD_DIR)/$(PROJECT).elf $(BUILD_DIR)/$(PROJECT).bin
	$(SIZE) $(BUILD_DIR)/$(PROJECT).elf

clean:
	rm -f $(BUILD_DIR)/*
