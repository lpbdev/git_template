# Following GNU Make Best Practices
# ============================================================================
# Makefile for C Project - Contains two source files and their headers
# Supports: Debug/Release versions, clang-format, cppcheck, doxygen
# ============================================================================

# Compiler configuration
CC = gcc
CFLAGS_COMMON = -Wall -Wextra -std=c11 -MMD -MP
LDFLAGS = 

# Directory structure
SRC_DIR = src
INC_DIR = include
BUILD_DIR = build
DOC_DIR = doc

# Source files
SRCS = $(SRC_DIR)/main.c $(SRC_DIR)/utils.c

OBJS = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
DEPS = $(OBJS:.o=.d)

# Header files
INCS = -I$(INC_DIR)
DEPS_INC = $(INC_DIR)/utils.h $(INC_DIR)/common.h

# 头文件
VERSION_DIR = $(SRC_DIR)/version_info

INCS = -I$(INC_DIR) -I$(VERSION_DIR)
DEPS_INC = $(INC_DIR)/rtk.h $(INC_DIR)/cJSON.h  $(INC_DIR)/fft.h \
		   $(INC_DIR)/BandPassFilter.h $(INC_DIR)/logmod.h $(INC_DIR)/pos_filter.h \
		   $(INC_DIR)/version_info/version_info.h


# Target executable
TARGET = program

# ============================================================================
# Version-specific configuration
# ============================================================================

# Debug version
CFLAGS_DEBUG = -O0 -g3 -DDEBUG -D_DEBUG
BUILD_DIR_DEBUG = $(BUILD_DIR)/debug
OBJS_DEBUG = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR_DEBUG)/%.o)
DEPS_DEBUG = $(OBJS_DEBUG:.o=.d)
TARGET_DEBUG = $(BUILD_DIR_DEBUG)/$(TARGET)_debug

# Release version
CFLAGS_RELEASE = -O3 -DNDEBUG -flto
BUILD_DIR_RELEASE = $(BUILD_DIR)/release
OBJS_RELEASE = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR_RELEASE)/%.o)
DEPS_RELEASE = $(OBJS_RELEASE:.o=.d)
TARGET_RELEASE = $(BUILD_DIR_RELEASE)/$(TARGET)

# ============================================================================
# Default target
# ============================================================================

.PHONY: all
all: debug release

.PHONY: debug
debug: $(TARGET_DEBUG)

.PHONY: release
release: $(TARGET_RELEASE)

include $(SRC_DIR)/version_info/version_info.mk
# ============================================================================
# Compilation rules
# ============================================================================

# Debug version compilation rules
$(BUILD_DIR_DEBUG)/%.o: $(SRC_DIR)/%.c $(DEPS_INC)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_COMMON) $(CFLAGS_DEBUG) $(INCS) -c $< -o $@

$(TARGET_DEBUG): $(OBJS_DEBUG)
	@mkdir -p $(dir $@)
	$(CC) $(OBJS_DEBUG) -o $@ $(LDFLAGS)
	@printf ">> Debug version build complete: $@"

# Release version compilation rules
$(BUILD_DIR_RELEASE)/%.o: $(SRC_DIR)/%.c $(DEPS_INC)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_COMMON) $(CFLAGS_RELEASE) $(INCS) -c $< -o $@

$(TARGET_RELEASE): $(OBJS_RELEASE)
	@mkdir -p $(dir $@)
	$(CC) $(OBJS_RELEASE) -o $@ $(LDFLAGS)
	@printf ">> Release version build complete: $@"

# ============================================================================
# Code formatting (clang-format)
# ============================================================================

.PHONY: format
format:
	@printf "** Formatting code..."
	@clang-format -i $(SRCS) $(DEPS_INC)
	@printf ">> Code formatting complete"

.PHONY: format-check
format-check:
	@printf "** Checking code format..."
	@clang-format --dry-run --Werror $(SRCS) $(DEPS_INC) || \
		(printf "!! Code format does not meet requirements, please run 'make format'" && exit 1)
	@printf ">> Code format check passed"

# ============================================================================
# Static analysis (cppcheck)
# ============================================================================

.PHONY: cppcheck
cppcheck:
	@printf "** Running cppcheck static analysis..."
	cppcheck --enable=all \
		--inconclusive \
		--suppress=missingIncludeSystem \
		--suppress=unmatchedSuppression \
		--error-exitcode=1 \
		-I$(INC_DIR) \
		$(SRCS)
	@printf ">> cppcheck analysis complete, no issues found"

# ============================================================================
# Documentation generation (doxygen)
# ============================================================================

.PHONY: docs
docs:
	@printf "** Generating documentation..."
	@mkdir -p $(DOC_DIR)
	doxygen Doxyfile 2>/dev/null || \
		(printf "!! Doxygen configuration failed, generating with default configuration..." && \
		 doxygen -g Doxyfile && \
		 sed -i 's/^PROJECT_NAME.*/PROJECT_NAME = "My C Program"/' Doxyfile && \
		 sed -i 's/^INPUT.*/INPUT = $(SRC_DIR) $(INC_DIR)/' Doxyfile && \
		 sed -i 's/^RECURSIVE.*/RECURSIVE = YES/' Doxyfile && \
		 sed -i 's/^OUTPUT_DIRECTORY.*/OUTPUT_DIRECTORY = $(DOC_DIR)/' Doxyfile && \
		 doxygen Doxyfile)
	@printf ">> Documentation generation complete, see $(DOC_DIR)/html/index.html"

.PHONY: docs-clean
docs-clean:
	rm -rf $(DOC_DIR)

# ============================================================================
# Cleanup
# ============================================================================

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: dist-clean
dist-clean: clean docs-clean
	rm -f Doxyfile

# ============================================================================
# Execution
# ============================================================================

.PHONY: run-debug
run-debug: debug
	@printf "** Running Debug version..."
	./$(TARGET_DEBUG)

.PHONY: run-release
run-release: release
	@printf "** Running Release version..."
	./$(TARGET_RELEASE)

# ============================================================================
# Comprehensive checks
# ============================================================================

.PHONY: check
check: format-check cppcheck
	@printf ">> All checks passed"

.PHONY: all-check
all-check: check debug release docs
	@printf ">> Complete build finished"

# ============================================================================
# Help information
# ============================================================================

.PHONY: help
help:
	@printf "Available targets:"
	@printf "  all          - Build debug and release versions (default)"
	@printf "  debug        - Build debug version"
	@printf "  release      - Build release version"
	@printf "  format       - Format code"
	@printf "  format-check - Check code format"
	@printf "  cppcheck     - Run static analysis"
	@printf "  docs         - Generate documentation"
	@printf "  docs-clean   - Clean documentation"
	@printf "  clean        - Clean build files"
	@printf "  dist-clean   - Deep clean"
	@printf "  run-debug    - Run debug version"
	@printf "  run-release  - Run release version"
	@printf "  check        - Run code checks and static analysis"
	@printf "  all-check    - Complete build and checks"

# ============================================================================
# Include dependencies
# ============================================================================

-include $(DEPS_DEBUG) $(DEPS_RELEASE)
