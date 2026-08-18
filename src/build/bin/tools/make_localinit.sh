# This script should be sourced by other bin scripts

if [[ $1 == build ]]; then
    pkg_root=$SPACK_ENV/opt
    module_root=$SPACK_ENV/modules
else
    pkg_root=$SPACKLOT_ROOT_PUBLIC/default/spack/opt/spack
    module_root=$SPACKLOT_ROOT_PUBLIC/modules
fi

util_path=$SPACK_ENV/util

if [[ ${SPACKLOT_LMOD_VERSION:-latest} != latest ]]; then
    lmod_location=$(spack location -i lmod@$SPACKLOT_LMOD_VERSION 2> /dev/null || true)
else
    lmod_latest=$(spack find --format '{hash}' lmod 2> /dev/null | tail -n 1)

    if [[ -n $lmod_latest ]]; then
        lmod_location=$(spack location -i /$lmod_latest 2> /dev/null || true)
    fi
fi

if [[ -z $lmod_location ]]; then
tsecho "lmod (${SPACKLOT_LMOD_VERSION:-latest}) not installed; skipping module generation"
else
mkdir -p $util_path
tsecho "Generating localinit.sh and localinit.csh"
tm_file=$SPACK_ENV/.tempinit

cat > $tm_file << EOF
# Location variables
export INSTALLPATH_ROOT=$pkg_root
export MODULEPATH_ROOT=$module_root

# Lmod configuration
export LMOD_SYSTEM_NAME=$SPACKLOT_CLUSTER
export LMOD_SYSTEM_DEFAULT_MODULES="$SPACKLOT_DEFAULT_MODULES"

case "\$MODULEPATH" in
    *"\${MODULEPATH_ROOT}"*)
        ;;
    *)
        export MODULEPATH=\$MODULEPATH_ROOT/environment
        ;;
esac

# Set defaults for Lmod behavior configuration
export LMOD_PACKAGE_PATH=$util_path
export LMOD_CONFIG_DIR=$util_path
export LMOD_AVAIL_STYLE=grouped:system

# Location of Lmod initialization scripts
export LMOD_ROOT=$lmod_location

# Use shell-specific init
comm=\`/bin/ps -p \$$ -o cmd= |awk '{print \$1}'|sed -e 's/-sh/csh/' -e 's/-csh/tcsh/' -e 's/-//g'\`
shell=\`/bin/basename \$comm\`

if [ -f \$LMOD_ROOT/lmod/lmod/init/\$shell ]; then
    . \$LMOD_ROOT/lmod/lmod/init/\$shell
else
    . \$LMOD_ROOT/lmod/lmod/init/sh
fi

unset comm shell

# Set system default stuff
export HPC_DEFAULT_PATH=/usr/local/bin:/usr/bin:/sbin:/bin
export HPC_DEFAULT_MANPATH=/usr/local/share/man:/usr/share/man
export HPC_DEFAULT_INFOPATH=/usr/local/share/info:/usr/share/info

export PATH=\${PATH}:\$HPC_DEFAULT_PATH
export MANPATH=\${MANPATH}:\$HPC_DEFAULT_MANPATH
export INFOPATH=\${INFOPATH}:\$HPC_DEFAULT_INFOPATH

# Load default modules
if [ -z "\$__Init_Default_Modules" -o -z "\$LD_LIBRARY_PATH" ]; then
  __Init_Default_Modules=1; export __Init_Default_Modules;
  module -q restore 
fi

# Hide specified modules
export LMOD_MODULERCFILE=$util_path/hidden-modules
EOF

mv $tm_file $util_path/localinit.sh

cat > $tm_file << EOF
# Location variables
setenv INSTALLPATH_ROOT $pkg_root
setenv MODULEPATH_ROOT $module_root

# Lmod configuration
setenv LMOD_SYSTEM_NAME $SPACKLOT_CLUSTER
setenv LMOD_SYSTEM_DEFAULT_MODULES "$SPACKLOT_DEFAULT_MODULES"

if ( ! \$?MODULEPATH ) then
    setenv MODULEPATH \$MODULEPATH_ROOT/environment
else if ( \$MODULEPATH !~ *\${MODULEPATH_ROOT}* ) then
    setenv MODULEPATH \$MODULEPATH_ROOT/environment
endif

# Set defaults for Lmod behavior configuration
setenv LMOD_PACKAGE_PATH $util_path
setenv LMOD_CONFIG_DIR $util_path
setenv LMOD_AVAIL_STYLE grouped:system

# Get location of Lmod initialization scripts
setenv LMOD_ROOT $lmod_location

# Add shell settings so Lmod can be used in bash scripts
setenv PROFILEREAD true
setenv BASH_ENV \${LMOD_ROOT}/lmod/lmod/init/bash 

# Use shell-specific init
set comm = \`/bin/ps -p \$$ -o cmd= |awk '{print \$1}'|sed -e 's/-sh/csh/' -e 's/-csh/tcsh/' -e 's/-//g'\`
set shell = \`/bin/basename \$comm\`

source \$LMOD_ROOT/lmod/lmod/init/\$shell
unset comm shell

# Set system default stuff
setenv HPC_DEFAULT_PATH /usr/local/bin:/usr/bin:/sbin:/bin
setenv HPC_DEFAULT_MANPATH /usr/local/share/man:/usr/share/man
setenv HPC_DEFAULT_INFOPATH /usr/local/share/info:/usr/share/info

setenv PATH \${PATH}:\$HPC_DEFAULT_PATH

if ( ! \$?MANPATH ) then
    setenv MANPATH \$HPC_DEFAULT_MANPATH
else
    setenv MANPATH \${MANPATH}:\$HPC_DEFAULT_MANPATH
endif

if ( ! \$?INFOPATH ) then
    setenv INFOPATH \$HPC_DEFAULT_INFOPATH
else
    setenv INFOPATH \${INFOPATH}:\$HPC_DEFAULT_INFOPATH
endif

# Load default modules
if ( ! \$?__Init_Default_Modules || ! \$?LD_LIBRARY_PATH ) then
  setenv __Init_Default_Modules 1
  module -q restore
endif

# Hide specified modules
setenv LMOD_MODULERCFILE $util_path/hidden-modules
EOF

mv $tm_file $util_path/localinit.csh
fi
