#!/bin/csh
#
#   This script allows you to easily switch to this software stack's
#   build (default) or public modules

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

# If SPACKLOT_DEFAULT_MODULES is set, we assume this is a stand-alone stack
# Otherwise, we assume this is an add-on set of modules we can simply add to the module path
if ( $?SPACKLOT_DEFAULT_MODULES ) then
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

    # Store old module tree for reversal
    setenv SPACKLOT_RESET_SCRIPT `echo $LMOD_CONFIG_DIR | sed 's|\(.*envs/\).*|\1build/bin/use_modules.csh|'`
    setenv SPACKLOT_RESET_TYPE `echo $LMOD_CONFIG_DIR | sed 's|.*/\([^/]*\)/util|\1|'`

    if ( $#argv == 0 || $1 == "build" ) then
        echo "Switching to build module tree:"
        set mod_init = $SPACKLOT_ENV_BUILD/util/localinit.csh
    else
        echo "Switching to public module tree:"
        set mod_init = $SPACKLOT_ENV_PUBLIC/util/localinit.csh
    endif

    if ( -e $mod_init ) then
        # First we clean the current instance
        if ( `alias module` != "" ) then
            module --force purge

            foreach lmod_var ( `env | grep -e ^LMOD -e ^__LMOD -e ^_ModuleTable | cut -d= -f1` )
                unsetenv $lmod_var
            end

            unsetenv MODULEPATH MODULEPATH_ROOT
        else
            exit 1
        endif

        # Now we use the new modules
        source $mod_init
        echo " -> $MODULEPATH_ROOT\n"
    else
        echo "Error: localinit.csh does not exist. No changes will be made.\n" > /dev/stderr
        exit 1
    endif

    # Define alias to return to default
    if ( `alias reset_modules` == "" ) then
        if ( -e $SPACKLOT_RESET_SCRIPT ) then
            alias reset_modules "source $SPACKLOT_RESET_SCRIPT $SPACKLOT_RESET_TYPE"
            echo 'Type "reset_modules" to return to system module stack\n'
        else
            unsetenv SPACKLOT_RESET_SCRIPT SPACKLOT_RESET_TYPE
        endif
    else
        unsetenv SPACKLOT_RESET_SCRIPT SPACKLOT_RESET_TYPE
        unalias reset_modules
    endif
else
    # Lmod must exist within the current environment
    if ( ! $?LMOD_ROOT ) then
        echo "Error: Module stack ($SPACKLOT_CLUSTER) requires existing Lmod. None found in environment." > /dev/stderr
        echo "       No changes will be made.\n" > /dev/stderr
        exit 1
    endif

    if ( `alias reset_modules` == "" ) then
        if ( $#argv == 0 || $1 == "build" ) then
            echo "Adding modules from build module tree:"
            setenv SPACKLOT_RESET_MODULES $SPACKLOT_ENV_BUILD/modules/environment
        else
            echo "Adding modules from public module tree:"
            setenv SPACKLOT_RESET_MODULES $SPACKLOT_ENV_PUBLIC/modules/environment
        endif
        
        module use -a $SPACKLOT_RESET_MODULES
        echo " -> $SPACKLOT_RESET_MODULES\n"
        
        setenv SPACKLOT_RESET_SCRIPT $my_bin
        alias reset_modules "source $SPACKLOT_RESET_SCRIPT"
        echo 'Type "reset_modules" to remove added modules\n'
    else
        module unuse $SPACKLOT_RESET_MODULES
        unsetenv SPACKLOT_RESET_SCRIPT SPACKLOT_RESET_MODULES
        unalias reset_modules
    endif
endif
