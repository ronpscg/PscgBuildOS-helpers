#!/bin/bash
#
# This is a last-line wrapper script for the PscgBuildOS builder.
#
# It contains some default values, and if they do not exist, 
# default values will be used from within build fragments, inside the build system. The build system is the project referred to as $BUILD_TOP,
# which is likely publicly accessible at https://github.com/ronpscg/PscgBuildOS . If you have access to private builds, they may be under ronubo, other private Bitbuckets,
# other other private repos. Since this file is on those projects as well, the documentation for the highly documented scripts is identical.
# 
# It is meant to be used as the "last-line" before the build system entry, i.e $BUILD_TOP/build-image.sh
# Given that, it aims to be as standard, useful, and correct as one would need, meaning that it does not choose the optimization routes when it can on the one hand,
# and does not generate things that are not absolutely necessary on the other hand.
#
# A reasonable usage would be adding a wrapper script to this script, for each one of your configurations, or
# just set the respective environment variables before **sourcing** this script, or running the external script.
# You can see the *wrapper-1-example.sh* script, for excellent, highly documented example of sourcing this script (the -1 means the distance from this script)
#
# You could alternatively, add a simple line that sources a config file, but adding a wrapper script (or specifying a couple of parameters from command line)
# is easier to follow
#
# Some tradeoffs of paths/speeds:
# Ideally, with a lot of memory, this would go under /tmp, or your own created and mounted tmpfs.
# HOWEVER, in the graphics builds, /tmp/PscgBuildOS/staging will easily take more than 10GB (system img, compressed image, working directories, etc..), so for a 32GB RAM machine, the memory will be exhausted. For this reason, the build system variable TMP_BUT_PERSISTENT_TOP has been introduced
# Using tmpfs is much faster than using storage
# on the other hand, using storage can have an advantage of persisting after reboot (if you want to get back to your development or experimentation, just to see your tmp files gone...)
#

#------------------------------------------------------------------------------------------
# You must at a minimum set your build environment. Modify the variables here to control:
# 1. Where your build system is located (BUILD_TOP)
# 2. Where your temporary files are located (TMP_TOP)
# [3. Where your temporary files are located should you want to support huge temporary files that you may want to keep (TMP_BUT_PERSISTENT_TOP)]
# [4. Where additional layers and components are located (you are expected to provide them externally - we can't know ahead of time what you want to include) ]
#
# The build system itself would set BUILD_TOP and TMP_TOP by default under at $HOME/PscgBuildOS/out/... . However, if you want to redefine some variables,
# you should define them as well even if they are completely identical, so we define them, as well as a log file name, here explicitly.
#
# TMP_BUT_PERSISTENT_TOP is useful to use to signal "yourself" that the files are temporary, but you may want to use them (e.g. the intermediate build materials etc.)
# We use at some points the term "preferred_tmp_top" - which would be an easy switch to what we think we would want to have under TMP_BUT_PERSISTENT_TOP,
# and is switched easily into TMP_TOP. Out of those three, only TMP_TOP is recognized in the build system directly, and the others are use to override variables
# known by the build system (i.e. config_...__...)
#
# It is safe in general to get rid of everything under TMP_TOP and TMP_BUT_PERSISTENT_TOP, and again, let us emphasize: you do not even need to override anything.
# You can build perfectly, directly from $BUILD_TOP/build-image.sh, and there is plenty of feedback from the build-system to tell you when you do things wrong.
# There is also plenty of documentation
#------------------------------------------------------------------------------------------
init_main_builder_env() {
	: ${config_toplevel__include_date_in_build_version=false} # Set to false to replace the image files after each build - this can be very useful and save a lot of storage space

	### base dirs
	if [ -n "$SUDO_HOME" ] ; then
		: ${homedir=$SUDO_HOME}
	elif [ -n "$SUDO_USER" ] ; then
		: ${homedir=/home/$SUDO_USER}
	else
		: ${homedir=$HOME}
	fi
	# outdir is used here for defining TMP_TOP (which is defined in the same way in the build system, but we want to set the log file prior to sourcing commonEnv) and TMP_BUT_PERSISTENT_TOP
	# it only affects variables that could be overridden, and is used to give them default values, so there is no point in making it modifable or exporting it
	outdir=${homedir}/PscgBuildOS/out 
	
	### build system source directory, distro type, and version setting	
	: ${BUILD_TOP=${homedir}/dev/otaworkshop/PscgBuildOS}
	: ${TMP_TOP=${outdir}/tmp/PscgBuildOS}
	: ${TMP_BUT_PERSISTENT_TOP=${outdir}/tmp-but-persistent/PscgBuildOS}
        
	export logFile=${logFile-${TMP_TOP}/$(basename -s .sh $0).log}
	mkdir -p $TMP_TOP || { echo "Cannot create $TMP_TOP" ; exit 1 ; }	
	. $BUILD_TOP/builder/commonEnv.sh || { echo "Cannot source common environment file" ; exit 1 ; }
}
	
#---------------------------------------------------------------------------------------------
# You can export variables here. Do note that since the file sources $BUILD_TOP/build-image.sh
# you don't really need to do anything here, not even what is said to be essential.
# It is meant for good and clear order.
#---------------------------------------------------------------------------------------------
export_variables() {
	### Essential variables for initializing the build system itself
	export BUILD_OUT
	export TMP_TOP
	export logFile
}


#----------------------------------------------------------------------------------------------
# This is the function where we will set some important values that for the most part, you
# would want to be defalut. However, as mentioned above, with the exception of sharing 
# same architecture kernel (and other components) builds, and sharing some project source files,
# what is set in this script chooses correction over optimization. 
#
# Once you modify the build system, or build multiple products, you will already have the experience to 
# write a wrapper script, and  select your preferred development workflow 
# (e.g. - save tons of time by not creating OTA image, not  reusing a storage device, even skipping levels and reusing intermediates 
# in order to change them in place (e.g rootfs) etc. 
# This file intentionally does not do these things, only what is specifically mentioned in the previous paragraph.
#----------------------------------------------------------------------------------------------
set_variables_conditionally() {
	#
	# Very simple optimization examples. (Starts from 1 and not from 0 to highlight that it is not something I would do in a code)
	# The optimizations will affect conditional variables, that have been set outside of the script - they are grouped to help you learn
	# Therefore, you will see setting of more values that are perhaps affected by the optimization related example clauses - these are intentional
	# and account for the general behavior. Remember, the goal in this script is to set reasonable defaults, the examples are bonuses, because it is
	# the last-line script. In time everything set by the examples - you will set yourself on your respective wrapper scripts.
	#
	local simple_dev_optimization_1=false	# if set to true - don't copy the installer to the removable media. Instead, let the user do it themselves
	local simple_dev_optimization_2=true	# if set to true - don't create the storage device (i.e. the "hard disk") - Instead, let the user to it themselves
	local simple_dev_optimization_3=false	# if set to true - don't create the live cd. The user can reuse system.img themselves, but won't enjoy the overlays, etc.
	local simple_dev_optimization_4=true	# if set to true - don't create OTA tarball and recovery. The user cannot do it themselves. This is one of the most agressive optimizations.
	#
	# Otherwise, we set most of build system config_...__... values by default to true, in order to have the easier and richer behavior - not the optimized one
	# The build system itself would usually opt for less optimizations - but if it's not sure it will not decide, and you may have to be specific, or the build system
	# will tell you to be specific.
	#

	# In the build-system there are more complex setting, with arch and subarch. Here we will settle for simplicity
	# If you find yourself building with multiple compiler flavors and flags, you will need to dive deepr into the arch/subarch mechanism
	local arch=$ARCH 

	# The OTA optimization comes first because it can affect other default values. This shows you that the order is important.
	if [ "$simple_dev_optimization_4" = "true" ] ; then
		# If you don't create an OTA image - you cannot create an installer image, as the installer installs the OTA tarball
		: ${config_imager__create_ota_image=false}
		: ${config_bsp__qemu_copy_installer_image_to_removable_media=false}

		#
		# The next line is commented out to show you something important - you can skip the installer - but you can still pack images, 
		# and then enjoy your livecd. The build-system's generate-qemu-scripts.sh would run by default (you can disable the task as well),
		# so you can take advantage of it if you for example skipped building the rootfs, or the kernel, or something and want to iterate on 
		# testing very quickly just the things you care about. AGAIN - THIS IS A USE CASE EXAMPLE - SUPER USEFUL - AND IT IS COMMENTED OUT
		# because it is meant to serve only those who use the system actively and understand the consequences of what they do to save time.
		#
		#: ${config_buildtasks__do_pack_images=false}
	fi

	if [ "$simple_dev_optimization_1" = "true" ] ; then
		# Don't copy installer - saves time. Copying it - prevents direct modification of the installer image, which is useful for debugging without ruining an already built image
		# It is confusing. It is qemu - and not imager, because the imager is done once it created the image.
		# The thing here is that when we generate qemu images and artifacts, we may opt to also copy the installer image
		# and create the disk image etc. This is the clean thing to do - but it both takes time and space.
		: ${config_bsp__qemu_copy_installer_image_to_removable_media=false}
	else
		# Alternatively if you want to create it set it to true, and later on, we will set a default path to copy it into
		: ${config_bsp__qemu_copy_installer_image_to_removable_media=true}
	fi


	if [ "$simple_dev_optimization_2" = "true" ] ; then
		: ${config_bsp__qemu_recreate_storage_device=false}
	else
		# if both are set true the build system will automatically deicde the path 	
		: ${config_bsp__qemu_recreate_storage_device=true}
		: ${config_bsp__qemu_create_storage_device_with_default_path_if_need_be=true} 	
	fi

	if [ "$simple_dev_optimization_3" = "true" ] ; then
		:
	else
		: ${config_bsp__qemu_create_livecd_with_default_path_if_need_be=true}		# if set to true, the build system will automatically decide the path
	fi

	# We set some paths here - they are done outside of the optimization options anyhow, as these options can be selected
	if [ "$config_bsp__qemu_copy_installer_image_to_removable_media" = "true" ] ; then
		: ${config_bsp__qemu_removable_media_path=${TMP_BUT_PERSISTENT_TOP}/removable_media-${arch}.img}
	else
		# The removable media is strictly for QEMU running. If you want to keep your installer file in tact - set this
		# value to another value.  (as demonstrated below)
		# Otherwise, the default in the build-system's generate-qemu-scripts.sh is to use your installer as the removable media.
		# Hence, if you want to change things in the removable_media after insterting it, you should copy it somewhere else.
		# Otherwise, if you don't care and want to avoid the copy, make sure that config_bsp__qemu_copy_installer_image_to_removable_media=false in the first place
		:
	fi

	# Some sizing examples
	if [ "$config_distro" = "pscg_buildos" ] ; then
		# The size must depend on the features, and for this, we will let a caller script / cmdline environment variables / config file decide some of the parameters
		:
	else # definitely enough for busybox. could be enough for alpineos 
		: ${config_bsp__qemu_storage_device_size_mib=$((500))} # for busyboxos you can work just fine with 6 for example...
	fi
	#
	# Note: there is automatic calculation, but if you build a debian like distro, you will likely
	# want to calculate config_imager__ext_partition_system_minimum_size_bytes yourself. Don't do it here,
	# as it is an excellent example of file system tuning parameters and considerations, and such a failure is 
	# an excellent example
	# e.g.: You can run with:
	# config_imager__ext_partition_system_minimum_size_bytes=$((500*1024*1024)) ./build-debos-image.sh
}	#


main() {
	#----tmp
	cd $(realpath $(dirname ${BASH_SOURCE[0]}))
	. ./staging-base.sh
	set_standard_default_values_distro_reuse
	distro_reuse_exports
	set_standard_default_values_wip
	#eotmp
	init_main_builder_env			# Initialize the main builder environment
	export_variables			# Export important variables


	set_variables_conditionally		# Set variables conditionally, unless they are already set by the environment

	cd $BUILD_TOP || fatalError "Cannot access $BUILD_TOP"
	. ./build-image.sh $@			# Build image
	hardInfo "🥰 DONE 🥰"			# Enjoy!
}

# Check if the script is being sourced or executed and do things differently according to that
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
	# We could run main() in a subshell, but if someone makes a script, and sources it, we want them to not
	# worry about exports, and just source and run main() 
	echo "Script is being sourced. Please run main() to execute the build process."
	echo "Careful if you are sourcing this script from a terminal, as it will exit upon errors"
else
	echo "Script is being executed directly."
	main "$@"
fi
