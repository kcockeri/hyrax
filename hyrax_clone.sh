#!/bin/sh
#
# Clone all of Hyrax from the OpenDAP organization page on GitHub
# This is fairly rough...

function help {
    echo "Usage: $0 [options] where options are:"
    echo "-h: help; this message"
    echo "-v: verbose"
    echo "-n: print what would be done"
    echo "-2: get the DAP2 libdap and switch to the DAP2 BES and handlers brnaches"
    echo "-D: do not get the hyrax-dependencies repo (defult is to get it)"
}

args=`getopt hvn2D $*`
if [ $? != 0 ]
then
    help
    exit 2
fi

set -- $args

# Set verbose and do_nothing to false
verbose="";
dry_run="no"
dap2="no"
get_deps="yes"

for i in $*
do
    case "$i"
	in
	-h)
	    help
	    exit 0;;
        -v)
            verbose="--verbose"
            shift;;
        -n)
            dry_run="yes"
            shift;;
	-2)
	    dap2="yes"
	    shift;;
        -D)
            get_deps="no"
            shift;;
        --)
            shift; break;;
    esac
done

function verbose {
    if test -n "$verbose"
    then
        echo "$*"
    fi
}

function do_command {
    if test "$dry_run" = "yes"
    then
	echo "$*"
    else
	# if test -n "$verbose"; then echo "$*"; fi
	verbose "$*"
	$*
    fi
}

repo_root=https://github.com/opendap

# On CentOS the fileout_netcdf tests fail when the RPM netcdf and
# hyrax-dependencies netcdf libraries are mixed. jhrg 1/2/15
if test "$get_deps" = "yes"
then

    if test ! -d hyrax-dependencies
    then 
	do_command "git clone $repo_root/hyrax-dependencies.git $verbose"
    else
	(
	cd hyrax-dependencies
	verbose "In hyrax-dependencies..."
	do_command "git pull $verbose"
	)
    fi

fi

if test "$dap2" == "yes"
then
    libdap="libdap"
    bes_module_branch="dap2"
else
    libdap="libdap4"
    bes_module_branch="master"
fi

if test ! -d $libdap
then 
    do_command "git clone ${repo_root}/${libdap}.git $verbose"
else
    (
    cd $libdap
    verbose "In ${libdap}..."
    do_command "git pull $verbose"
    )
fi

if test ! -d bes
then
    do_command "git clone $repo_root/bes.git $verbose"
    do_command "git branch $bes_module_branch"
else
    (
    cd bes
    verbose "In bes..."
    do_command "git branch $bes_module_branch"
    do_command "git pull $verbose"
    )
fi

if test ! -d olfs
then
    do_command "git clone $repo_root/olfs.git $verbose"    
else
    (
    cd olfs
    verbose "In olfs..."
    do_command "git pull $verbose"
    )
fi

# Do the submodule init/update in a sub-shell
(
if cd bes 2> /dev/null
then
    verbose "In bes updatig modules..."

    if test ! -f configure.ac
    then
	do_command "ln -s configure_modules.ac configure.ac"
    fi

    # Kludge: Use csv_handler as a sentinel; if it's code is present
    # assume this all has been run and just run 'pull' for all of the
    # submodules.
    if test ! -f modules/csv_handler/configure.ac
    then
	do_command "git submodule init"
	do_command "git submodule update"
	do_command "git submodule foreach" 'git checkout' $bes_module_branch
    else
	do_command "git submodule foreach" 'git checkout' $bes_module_branch
	do_command "git submodule foreach" 'git pull' $verbose
    fi
else
    verbose "No bes repo; cannot update submodules"
fi
) # pop out of the 'cd bes' sub-shell
