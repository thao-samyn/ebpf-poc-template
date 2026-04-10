CLANG := clang
CC    := gcc
ARCH  := $(shell uname -m | sed 's/x86_64/x86/' | sed 's/aarch64/arm64/')

TARGET ?= 

INCLUDES    := -Iinclude -Ibuild
BPF_CFLAGS  := -g -O2 -target bpf -D__TARGET_ARCH_$(ARCH)
USER_CFLAGS := -Wall -Wextra -g $(INCLUDES)
USER_LIBS   := -lbpf -lelf -lz

BUILD_DIR := build
SRC_DIR   := src

BPF_OBJ  := $(BUILD_DIR)/$(TARGET).bpf.o
SKEL_H   := $(BUILD_DIR)/$(TARGET).skel.h
USER_BIN := $(BUILD_DIR)/$(TARGET)

.PHONY: all
all: $(USER_BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/vmlinux.h: | $(BUILD_DIR)
	bpftool btf dump file /sys/kernel/btf/vmlinux format c > $@

$(BPF_OBJ): $(SRC_DIR)/$(TARGET).bpf.c $(BUILD_DIR)/vmlinux.h | $(BUILD_DIR)
	$(CLANG) $(BPF_CFLAGS) $(INCLUDES) -I$(BUILD_DIR) -c $< -o $@

$(SKEL_H): $(BPF_OBJ)
	bpftool gen skeleton $< > $@

$(USER_BIN): $(SRC_DIR)/$(TARGET).c $(SKEL_H) | $(BUILD_DIR)
	$(CC) $(USER_CFLAGS) -I$(BUILD_DIR) $< -o $@ $(USER_LIBS)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: compile_commands
compile_commands:
	bear -- make clean all

.PHONY: install
install: $(USER_BIN)
	install -m 755 $(USER_BIN) /usr/local/bin/

.PHONY: help
help:
	@echo "Usage: make [TARGET=name] [target]"
	@echo ""
	@echo "  all              - Build everything (default)"
	@echo "  clean            - Remove build artifacts"
	@echo "  install          - Install binary to /usr/local/bin"
	@echo "  compile_commands - Generate compile_commands.json"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Example: make TARGET=mon-poc"