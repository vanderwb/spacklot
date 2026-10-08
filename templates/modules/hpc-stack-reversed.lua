require("posix")
family("env")

-- The message printed by the module whatis command
whatis("hpc-stack v%VERSION%")

-- The message printed by the module help command
help([[
This module sets up %CLUSTER% HPC environment, adding our hierarchical
module tree, convenience features and tailored performance settings

Cluster version: %VERSION%
Created on:      %DATE%
]])

-- A meta-module should be harder to remove
add_property("lmod","sticky")

-- Detect environment settings
local user      = capture("whoami"):gsub("\n$","")
local othreads  = os.getenv("OMP_NUM_THREADS")

local syspath   = os.getenv("HPC_DEFAULT_PATH")
local sysman    = os.getenv("HPC_DEFAULT_MANPATH")
local sysinfo   = os.getenv("HPC_DEFAULT_INFOPATH")

-- Base shell environment packages and utilities
local basepath      = "%BASEROOT%"
local viewpath      = pathJoin(basepath, "view")

-- System specific settings
setenv("HPC_ENV_VERSION",   "%VERSION%")
setenv("HPC_CLUSTER",       "%CLUSTER%")

-- Spack settings
local envpath = "%ENVROOT%"
setenv("HPC_ENV_CONFIG",   pathJoin(envpath, "config"))
setenv("HPC_ENV_SPACK",    pathJoin(envpath, "spack"))
setenv("HPC_ENV_REGISTRY", pathJoin(envpath, "registry"))
setenv("HPC_ENV_HASH",     "%GITHASH%")

-- Enable modules from developer trees
local mroot_vars = os.getenv("HPC_VARS_MODULEROOT")

if (mode() == "load") then
    if mroot_vars then
        setenv("__HPC_VARS_MODULEROOT", mroot_vars)

        for var in string.gmatch(mroot_vars, "[^:]+") do
            local mroot = os.getenv(var)

            if mroot then
                setenv("__" .. var, pathJoin(mroot, "%VERSION%"))
            end
        end
    else
        unsetenv("__HPC_VARS_MODULEROOT")
    end
end

-- Enable custom modules from downstreams
local is_set    = os.getenv("HPC_MODULEROOT_USER")
local was_set   = os.getenv("__HPC_ENV_MODULEROOT_USER")
local old_value = os.getenv("__HPC_MODULEROOT_USER")

if was_set or not is_set then
    mroot = pathJoin("/home", user, "spack-downstreams/%CLUSTER%/modules/%VERSION%")
    setenv("__HPC_ENV_MODULEROOT_USER", 1)
    
    -- Only unset if user has not changed value in the interim
    if (mode() == "load") or (is_set == old_value) then
        setenv("HPC_MODULEROOT_USER", mroot)
    end
else
    mroot = is_set
end

append_path("HPC_VARS_MODULEROOT", "HPC_MODULEROOT_USER")

-- We need this variable to ensure modulepaths are unset correctly at swap
if (mode() == "load") then
    setenv("__HPC_MODULEROOT_USER", mroot)
    append_path("__HPC_VARS_MODULEROOT", "HPC_MODULEROOT_USER")
end

-- Add custom Core paths
local mroot_vars = os.getenv("__HPC_VARS_MODULEROOT")

if mroot_vars then
    for var in string.gmatch(mroot_vars, "[^:]+") do
        local mroot = os.getenv("__" .. var)

        if mroot then
            append_path("MODULEPATH", pathJoin(mroot, "Core"))
        end
    end
end

-- Loading this module unlocks the Spack module tree
append_path("MODULEPATH", "%MODPATH%")

-- Add Lmod settings
pushenv("LMOD_PACKAGE_PATH", "%UTILPATH%")
pushenv("LMOD_CONFIG_DIR",   "%UTILPATH%")
pushenv("LMOD_AVAIL_STYLE",  "grouped:system")
pushenv("LMOD_SYSTEM_DEFAULT_MODULES", "%DEFMODS%")
pushenv("LMOD_MODULERCFILE", "%MODRC%")

-- Ensure modules load in subshells
setenv("ENV", "/etc/profile.d/modules.sh")

-- Default OpenMP environment
if not othreads then
    setenv("OMP_NUM_THREADS", "1")
end

setenv("OMP_STACKSIZE", "64000K")

-- Make sure localization is set
pushenv("LC_ALL",    "en_US.UTF-8")
pushenv("LANG",      "en_US.UTF-8")

-- Add base packages utilities to PATHS
prepend_path("PATH",            pathJoin(basepath, "utils/bin"))
prepend_path("PATH",            pathJoin(basepath, "wrappers/bin"))
append_path("PATH",             pathJoin(viewpath, "bin"))
append_path("MANPATH",          pathJoin(viewpath, "man"))
append_path("MANPATH",          pathJoin(viewpath, "share/man"))
append_path("INFOPATH",         pathJoin(viewpath, "share/info"))
append_path("ACLOCAL_PATH",     pathJoin(viewpath, "share/aclocal"))

setenv("WRAPPER_INC_0_COMMON",       pathJoin(viewpath, "include"))
setenv("WRAPPER_LDFLAGS_0_COMMON",   pathJoin(viewpath, "lib"))
setenv("WRAPPER_LDFLAGS_0_COMMON64", pathJoin(viewpath, "lib64"))

prepend_path("PKG_CONFIG_PATH", pathJoin(viewpath, "lib/pkgconfig"))
prepend_path("PKG_CONFIG_PATH", pathJoin(viewpath, "lib64/pkgconfig"))

-- Make sure system versions come after Spack versions (save aclocal)
append_path("PATH",             syspath)
append_path("MANPATH",          sysman)
append_path("INFOPATH",         sysinfo)
prepend_path("ACLOCAL_PATH",    "/usr/share/aclocal")

-- Add PERL library from the base
append_path("PERL5LIB", pathJoin(basepath, "perl/lib/perl5"))
