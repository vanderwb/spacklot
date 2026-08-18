-- The message printed by the module whatis command
whatis("profile-compile v%VERSION%")

-- The message printed by the module help command
help([[
This module will prompt the compiler wrapper to inject profiling flags
into your application builds for as long as both modules are loaded. This
functionality is intended to make building with profiling flags easier when
using applications with complex build systems.

Created on:     %DATE%
]])

-- Will only work with newer versions of compiler wrapper
depends_on(atleast("compiler_wrapper", "3.0.0"))

-- Profiler flags are compiler-specific and are set in compiler modules
-- Ref: https://docs.linaroforge.com/25.1.1/html/forge/map/get_started_map/prepare_a_program_for_profiling.html
setenv("COMPILER_WRAPPER_MFLAGS_PROFILE", "1")
