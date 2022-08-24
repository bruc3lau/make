# blah: blah.o
# 	cc blah.o -o blah # Runs third

# blah.o: blah.c
# 	cc -c blah.c -o blah.o # Runs second

# blah.c:
# 	echo "int main() { return 0; }" > blah.c # Runs first

# some_file:
# 	echo "This line will always print"

# some_file:
# 	echo "This line will only print once"
# 	touch some_file

# some_file: other_file
# 	echo "This will run second, because it depends on other_file"
# 	touch some_file

# other_file:
# 	echo "This will run first"
# 	touch other_file

# some_file: other_file
# 	touch some_file

# other_file:
# 	echo "nothing"

# some_file: 
# 	touch some_file

# clean:
# 	rm -f some_file

# files := file1 file2
# some_file: $(files)
# 	echo "Look at this variable: " $(files)
# 	touch some_file

# file1:
# 	touch file1
# file2:
# 	touch file2

# clean:
# 	rm -f file1 file2 some_file

# x := dude

# all:
# 	echo $(x)
# 	echo ${x}

# 	# Bad practice, but works
# 	echo $x 


# all: one two three clean

# one:
# 	touch one
# two:
# 	touch two
# three:
# 	touch three

# clean:
# 	rm -f one two three

# all: f1.o f2.o

# f1.o f2.o:
# 	echo ${@}
# Equivalent to:
# f1.o:
# 	 echo f1.o
# f2.o:
# 	 echo f2.o

# Print out file information about every .c file
# print: $(wildcard *.c)
# 	ls -la  $?

# thing_wrong := *.o # Don't do this! '*' will not get expanded
# thing_right := $(wildcard *.o)

# all: one two three four

# # Fails, because $(thing_wrong) is the string "*.o"
# one: $(thing_wrong)

# # Stays as *.o if there are no files that match this pattern :(
# two: *.o 

# # Works as you would expect! In this case, it does nothing.
# three: $(thing_right)

# # Same as rule three
# four: $(wildcard *.o)

# hey: one two
# 	# Outputs "hey", since this is the first target
# 	echo $@

# 	# Outputs all prerequisites newer than the target
# 	echo $?

# 	# Outputs all prerequisites
# 	echo $^

# 	touch hey

# one:
# 	touch one

# two:
# 	touch two

# clean:
# 	rm -f hey one two

# CC = gcc # Flag for implicit rules
# CFLAGS = -g # Flag for implicit rules. Turn on debug info

# # Implicit rule #1: blah is built via the C linker implicit rule
# # Implicit rule #2: blah.o is built via the C compilation implicit rule, because blah.c exists
# blah: blah.o

# blah.c:
# 	echo "int main() { return 0; }" > blah.c

# clean:
# 	rm -f blah*

# objects = foo.o bar.o all.o
# all: $(objects)

# # These files compile via implicit rules
# foo.o: foo.c
# bar.o: bar.c
# all.o: all.c

# all.c:
# 	echo "int main() { return 0; }" > all.c

# %.c:
# 	touch $@

# clean:
# 	rm -f *.c *.o all

# objects = foo.o bar.o all.o
# all: $(objects)

# # These files compile via implicit rules
# # Syntax - targets ...: target-pattern: prereq-patterns ...
# # In the case of the first target, foo.o, the target-pattern matches foo.o and sets the "stem" to be "foo".
# # It then replaces the '%' in prereq-patterns with that stem
# $(objects): %.o: %.c

# all.c:
# 	echo "int main() { return 0; }" > all.c

# %.c:
# 	touch $@

# clean:
# 	rm -f *.c *.o all

# obj_files = foo.result bar.o lose.o
# src_files = foo.raw bar.c lose.c

# .PHONY: all
# all: $(obj_files)

# $(filter %.o,$(obj_files)): %.o: %.c
# 	echo "target: $@ prereq: $<"
# $(filter %.result,$(obj_files)): %.result: %.raw
# 	echo "target: $@ prereq: $<" 

# %.c %.raw:
# 	touch $@

# clean:
# 	rm -f $(src_files)

# Thanks to Job Vranish (https://spin.atomicobject.com/2016/08/26/makefile-c-projects/)
TARGET_EXEC := final_program

BUILD_DIR := ./build
SRC_DIRS := ./src

# Find all the C and C++ files we want to compile
# Note the single quotes around the * expressions. Make will incorrectly expand these otherwise.
SRCS := $(shell find $(SRC_DIRS) -name '*.cpp' -or -name '*.c' -or -name '*.s')

# String substitution for every C/C++ file.
# As an example, hello.cpp turns into ./build/hello.cpp.o
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

# String substitution (suffix version without %).
# As an example, ./build/hello.cpp.o turns into ./build/hello.cpp.d
DEPS := $(OBJS:.o=.d)

# Every folder in ./src will need to be passed to GCC so that it can find header files
INC_DIRS := $(shell find $(SRC_DIRS) -type d)
# Add a prefix to INC_DIRS. So moduleA would become -ImoduleA. GCC understands this -I flag
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

# The -MMD and -MP flags together generate Makefiles for us!
# These files will have .d instead of .o as the output.
CPPFLAGS := $(INC_FLAGS) -MMD -MP

# The final build step.
$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS)
	$(CC) $(OBJS) -o $@ $(LDFLAGS)

# Build step for C source
$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Build step for C++ source
$(BUILD_DIR)/%.cpp.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@


.PHONY: clean
clean:
	rm -r $(BUILD_DIR)

# Include the .d makefiles. The - at the front suppresses the errors of missing
# Makefiles. Initially, all the .d files will be missing, and we don't want those
# errors to show up.
-include $(DEPS)