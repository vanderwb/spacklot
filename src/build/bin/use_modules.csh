#!/bin/csh
#
#   This script allows you to easily switch to this software stack's
#   build (default) or public modules
#
#   Author:         Brian Vanderwende
#   Last Revised:   09:27, 10 Nov 2026
#   

set sourced = ($_)

if ("$sourced" == "") then
    echo "Error: I need to be sourced, not executed" > /dev/stderr
    exit 1
endif

# Perform script setup
set my_bin = `ls -l /proc/$$/fd | sed -e 's/^[^/]*//' | grep "/use_modules.csh"`
set my_dir = `dirname $my_bin`

# Hacky way to get bourne-style variables from config file
eval `bash -x $my_dir/../main.cfg |& grep --color=never 'SPACKLOT[^\[]*=' | sed 's/^+/set/'`

if ( $#argv == 0 || $1 == "build" ) then
    echo "Loading build module tree:"
    set mod_init = $SPACKLOT_ENV_BUILD/util/localinit.csh
else
    echo "Loading public module tree:"
    set mod_init = $SPACKLOT_ENV_PUBLIC/util/localinit.csh
endif

if ( ! -f $mod_init ) then
    echo "Error: localinit.csh does not exist. No changes will be made.\n" > /dev/stderr
    exit 1
endif

# If we have already had a modules change, let's revert that
if ( `alias reset_modules` != "" ) then
    echo "  (existing non-default modules detected; resetting to default first...)"
    reset_modules
endif

# Store initial environment in case we need it
set reset_tmpdir = `mktemp -d`
env > $reset_tmpdir/pre

# If SPACKLOT_MODULE_ENVIRONMENT_TYPE is set to isolated, we assume we can
# cleanly instantiate the module environment here
set env_type = "isolated"

if ( $?SPACKLOT_MODULE_ENVIRONMENT_TYPE ) then
    set env_type = $SPACKLOT_MODULE_ENVIRONMENT_TYPE
endif

if ( $env_type == "isolated" ) then
    # Check that system matches what we are loading if possible
    if ( $?HPC_SYSTEM ) then
        if ( $HPC_SYSTEM != $SPACKLOT_CLUSTER ) then
            echo "Error: Module stack ($SPACKLOT_CLUSTER) does not match identified host ($HPC_SYSTEM)." > /dev/stderr
            echo "       No changes will be made.\n" > /dev/stderr
            exit 1
        endif
    else
        echo "Warning: System is not known (HPC_SYSTEM not set). Cannot verify stack compatibility." > /dev/stderr
    endif

    # Store old odule tree for reversal
    if ( $?LMOD_CONFIG_DIR ) then
        set spacklot_reset_script = `echo $LMOD_CONFIG_DIR | sed 's|\(.*envs/\).*|\1build/bin/use_modules.csh|'`
        set spacklot_reset_type = `echo $LMOD_CONFIG_DIR | sed 's|.*/\([^/]*\)/util|\1|'`
    endif

    # First, let's sanitize the module environment
    if ( `alias module` != "" ) then
        module --force purge

        if ( `alias clearMT` != "" ) then
            clearMT
        else
            foreach lmod_var ( `env | grep -e ^LMOD -e ^__LMOD -e ^_ModuleTable | cut -d= -f1` )
                unsetenv $lmod_var
            end

            unsetenv MODULEPATH MODULEPATH_ROOT
        endif
    endif
else if ( `alias clearMT` != "" ) then
    module --force purge
    clearMT
endif

# Init the new modules into your environment
source $mod_init
env > $reset_tmpdir/post

echo " -> $MODULEPATH_ROOT\n"
echo 'Type "reset_modules" to return to system module stack\n'

set reset_script_exists = 0

if ( $?spacklot_reset_script ) then
    if ( -e $spacklot_reset_script ) then
        set reset_script_exists = 1
    endif
endif

# Define alias to return to default
if ( $reset_script_exists ) then
    alias reset_modules "echo 'Resetting modules to system default ...'; source $spacklot_reset_script $spacklot_reset_type"
    unset spacklot_reset_type
else
    set spacklot_reset_script = "$home/.spacklot_reset.$$"
    \diff "$reset_tmpdir/pre" "$reset_tmpdir/post" > "$reset_tmpdir/diff"

    sed -n 's/^> \([^=]*\)=.*/unsetenv \1/p' $reset_tmpdir/diff >! $spacklot_reset_script
    sed -n 's/^< \([^=]*\)=\(.*\)/setenv \1 "\2"/p' $reset_tmpdir/diff >> $spacklot_reset_script

    alias reset_modules "echo 'Resetting modules to system default ...'; source $spacklot_reset_script; rm -f $spacklot_reset_script; unalias reset_modules"
    rm -rf $reset_tmpdir
endif

unset sourced my_bin my_dir reset_tmpdir env_type spacklot_reset_script reset_script_exists
