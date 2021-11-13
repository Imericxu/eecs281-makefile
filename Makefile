ifndef build_dir
##############################
# Build type processing and  #
# non-dependent targets      #
##############################

# Disable unnecessary Make implicity rules
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

# TODO: Edit Uniqname and identifier
uniqname := johndoe
identifier := EECS281IDENTIFIEREECS281IDENTIFIER

export CXX ?= g++
export warnings := -Wall -Wextra -Wconversion -Wpedantic
export CXXFLAGS += -std=c++17

# enables c++17 on CAEN or 281 autograder
export PATH := /usr/um/gcc-6.2.0/bin:$(PATH)
export LD_LIBRARY_PATH := /usr/um/gcc-6.2.0/lib64
export LD_RUN_PATH := /usr/um/gcc-6.2.0/lib64

# Name of the executable
export executable := executable

export src_dir := src
export src := $(wildcard $(src_dir)/*.cpp)

export include_dir := include
export build_dir = build

full_submit_file = fullsubmit.tar.gz
full_submit_files := Makefile $(src) $(wildcard $(include_dir)/*.h \
		$(include_dir)/*.hpp test*.txt)
partial_submit_file = partialsubmit.tar.gz
partial_submit_files := $(filter-out $(wildcard test*.txt), $(full_submit_file))
ungraded_submit_file = ungraded.tar.gz
ungraded_submit_files := $(filter-out Makefile, $(partial_submit_files))

all: release
.PHONY: all

clean:
	rm -rf $(build_dir)_release $(build_dir)_debug
	rm -rf *.dSYM
	rm -f $(full_submit_file) $(partial_submit_file) $(ungraded_submit_file)
	rm -f $(executable) $(executable)_debug
.PHONY: clean

release: export build_dir := $(build_dir)_release
release: export CXXFLAGS += -O3 -DNDEBUG
.PHONY: release

debug: export build_dir := $(build_dir)_debug
debug: export CXXFLAGS += -g3 -DDEBUG
debug: export executable := $(executable)_debug
.PHONY: debug

release debug: identifier
	@$(MAKE)

identifier:
	$(eval grep_result=$(shell grep --include=\*.{h,hpp,c,cpp} -rL $(identifier) $(include_dir) \
			$(src_dir)))
	@if [ ! -z "$(grep_result)" ]; then \
		echo "Missing project identifier in file(s):"; \
		echo $(grep_result); \
		rm -rf $(full_submit_file) $(partial_submit_file) \
				$(ungraded_submit_file); \
		exit 1; \
	fi;
.PHONY: identifier

static:
	cppcheck --enable=all --suppress=missingIncludeSystem \
			$(src) $(include_dir)/*.h
.PHONY: static

fullsubmit: $(full_submit_file)
$(full_submit_file): identifier $(full_submit_files)
	COPYFILE_DISABLE=true tar -vczf $(full_submit_file) $(full_submit_files)
	@echo !!! Final submission prepared, test files included... \
			READY FOR GRADING !!!
.PHONY: fullsubmit

partialsubmit: $(partial_submit_file)
$(partial_submit_file): identifier $(partial_submit_files)
	COPYFILE_DISABLE=true tar -vczf $(partial_submit_file) \
			$(partial_submit_files)
	@echo !!! WARNING: No test files included. Use 'make fullsubmit' to include \
			test files. !!!
.PHONY: partialsubmit

ungraded: $(ungraded_submit_file)
$(ungraded_submit_file): identifier $(ungraded_submit_files)
	@touch __ungraded
	COPYFILE_DISABLE=true tar -vczf $(ungraded_submit_file) \
			$(ungraded_submit_files) __ungraded
	@rm -f __ungraded
	@echo !!! WARNING: This submission will not be graded. !!!
.PHONY: ungraded

else
##############################
# Compile targets            #
##############################

# C++ compiled object files
obj := $(patsubst $(src_dir)/%.cpp,$(build_dir)/%.o,$(src))
# C++ generated depency files (tracks header changes)
deps := $(patsubst $(src_dir)/%.cpp,$(build_dir)/%.d,$(src))

all: $(executable)
.PHONY: all

$(executable): $(obj)
	$(CXX) $(CXXFLAGS) $(obj) -o $(executable)

# Read any existing dependency file
-include $(deps)

# The "-MMD" flag generates .d files of non-system headers
$(build_dir)/%.o: $(src_dir)/%.cpp Makefile | $(build_dir)
	$(CXX) $(CXXFLAGS) $(warnings) -I$(include_dir) -MMD -c -o $(build_dir)/$*.o $<

$(build_dir):
	mkdir -p $@

endif #build_dir
