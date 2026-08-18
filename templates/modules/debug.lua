-- The message printed by the module whatis command
whatis("debug-compile v%VERSION%")

-- The message printed by the module help command
help([[
This module will prompt the compiler wrapper to inject debug flags
into your application builds for as long as both modules are loaded. This
functionality is intended to make building with debug flags easier when
using applications with complex build systems.

Created on:     %DATE%
]])

-- Will only work with newer versions of compiler wrapper
depends_on(atleast("compiler_wrapper", "3.0.0"))

-- These default debug flags can be overridden by other modules
setenv("HPC_MFLAGS_DEBUG", "-g")
setenv("COMPILER_WRAPPER_MFLAGS_DEBUG", "1")
