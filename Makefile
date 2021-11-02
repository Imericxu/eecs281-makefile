ifndef build_dir
########################################
# Build type preprocessing and clean   #
########################################

# Disable unnecessary Make implicity rules
MAKEFLAGS += --no-builtin-rules

# Vars that don't depend on build type
export uniqname := imericxu
export identifier := EECS281IDENTIFIEREECS280IDENTIFIER
export build_dir = build
export executable := executable
export full_submit_file = fullsubmit.tar.gz
export partial_submit_file = partialsubmit.tar.gz
export ungraded_submit_file = ungraded.tar.gz

.SUFFIXES:

.PHONY: all
all: release

.PHONY: clean
clean:
	rm -rf $(build_dir)_release $(build_dir)_debug
	rm -rf *.dSYM
	rm -f $(full_submit_file) $(partial_submit_file) $(ungraded_submit_file)
	rm -f $(executable) $(executable)_debug

.PHONY: release
release: export build_dir := $(build_dir)_release
release: export CXXFLAGS += -O3 -DNDEBUG

.PHONY: debug
debug: export build_dir := $(build_dir)_debug
debug: export CXXFLAGS += -g3 -DDEBUG
debug: export executable := $(executable)_debug

release debug:
	@$(MAKE)

else
##############################
# Main Makefile starts       #
##############################

CXX ?= g++
warnings := -Wall -Werror -Wextra -Wconversion
CXXFLAGS += -std=c++17 $(warnings) -pedantic

# enables c++17 on CAEN or 281 autograder
PATH := /usr/um/gcc-6.2.0/bin:$(PATH)
LD_LIBRARY_PATH := /usr/um/gcc-6.2.0/lib64
LD_RUN_PATH := /usr/um/gcc-6.2.0/lib64

src_dir := src
src := $(wildcard $(src_dir)/*.cpp)

include_dir := include
obj = $(patsubst $(src_dir)/%.cpp,$(build_dir)/%.o,$(src))
deps = $(patsubst $(src_dir)/%.cpp,$(build_dir)/%.d,$(src))

##############################
# Targets                    #
##############################

.PHONY: all
all: identifier $(executable)

.PHONY: identifier
identifier:
	@grep_result=(grep --include=\*.{h,hpp,c,cpp} -rL "$(identifier)" \
            $(include_dir) $(src_dir))
	@if [ ! -z "$$grep_result" ]; then \
		@echo "Missing project identifier in file(s): "; \
		echo $$grep_result; \
		rm -f $(full_submit_file) $(partial_submit_file) \
                $(ungraded_submit_file); \
		exit 1; \
	fi

$(executable): $(obj)
	$(CXX) $(CXXFLAGS) $(obj) -o $(executable)

.PHONY: static
static:
	cppcheck --enable=all --suppress=missingIncludeSystem \
            -I$(include_dir) $(src)

-include $(deps)

$(build_dir)/%.o: $(src_dir)/%.cpp Makefile | $(build_dir)
	$(CXX) $(CXXFLAGS) -I$(include_dir) -MMD -c -o $(build_dir)/$*.o $<

$(build_dir):
	mkdir -p $@

endif #build_dir
