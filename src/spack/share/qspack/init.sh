# If TMPDIR is unset, this script seems to trigger infinite recursion
# Here is a hacky workaround until root cause can be determined.
if [[ -z $TMPDIR ]]; then
    tmpdir_user=$(whoami)
    export TMPDIR=/tmp/$tmpdir_user
fi

# Make sure module environment is consistent regardless of whether
# we are working on a clean system or not!
module --force purge >& /dev/null

# If left set, will contaminate Spack child shells
unset BASH_ENV

# Config to use non-system core compiler
CORE_GCC_ROOT=

if [[ -n $CORE_GCC_ROOT ]]; then
    export PATH=$CORE_GCC_ROOT/bin:$PATH
    export LIBRARY_PATH=$CORE_GCC_ROOT/lib64${LIBRARY_PATH:+:$LIBRARY_PATH}
    export LD_LIBRARY_PATH=$CORE_GCC_ROOT/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
fi

# Config to use specific Python with Spack
SPACKLOT_PYTHON_ROOT=

if [[ -e $SPACKLOT_PYTHON_ROOT/bin/python ]]; then
    export SPACK_PYTHON=$SPACKLOT_PYTHON_ROOT/bin/python
fi

# Initialize Bash Spack shell integration
. $SPACKLOT_STARTUP
