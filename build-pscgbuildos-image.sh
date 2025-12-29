#!/bin/bash
#
# This is a wrapper script for the PscgBuildOS builder.
# It contains some default values, and if they do not exist, 
# default values will be used from within build fragments, inside the build system
# 
# A reasonable usage would be adding a wrapper script to this script, for each one of your configurations, or
# just set the respective environment variables before running it.
# You could alternatively, add a simple line that sources a config file, but adding a wrapper script (or specifying a couple of parameters from command line)
# is easier to follow
#
# Some tradeoffs of paths/speeds:
# Ideally, with a lot of memory, this would go under /tmp, or your own created and mounted tmpfs.
# HOWEVER, in the graphics builds, /tmp/PscgBuildOS/staging will easily take more than 10GB (system img, compressed image, working directories, etc..), so for a 32GB RAM machine, the memory will be exhausted. For this reason, the build system variable TMP_BUT_PERSISTENT_TOP has been introduced
# Using tmpfs is much faster than using storage
# on the other hand, using storage can have an advantage of persisting after reboot (if you want to get back to your development or experimentation, just to see your tmp files gone...)
#

#
# You must at a minimum set your build environment. Modify the variables here to control:
# 1. Where your build system is located (BUILD_TOP)
# 2. Where your temporary files are located (TMP_TOP)
# 3. Where your temporary files are located should you want to support huge temporary files (TMP_BUT_PERSISTENT_TOP)
# [4. Where additional layers and components are located (you are expected to provide them externally - we can't know ahead of time what you want to include) ]
#
init_main_builder_env() {
	if [ -n "$SUDO_HOME" ] ; then
		: ${homedir=$SUDO_HOME}
	elif [ -n "$SUDO_USER" ] ; then
		: ${homedir=/home/$SUDO_USER}
	else
		: ${homedir=$HOME}
	fi
	
	### build system source directory, distro type, and version setting	
	: ${BUILD_TOP=${homedir}/dev/otaworkshop/PscgBuildOS}
	: ${TMP_TOP=/tmp/PscgBuildOS}	
	: ${TMP_BUT_PERSISTENT_TOP=${homedir}/tmp-but-persistent/PscgBuildOS}

	export logFile=${logFile-${TMP_TOP}/$(basename -s .sh $0).log}
	mkdir -p $TMP_TOP || { echo "Cannot create $TMP_TOP" ; exit 1 ; }	
	. $BUILD_TOP/builder/commonEnv.sh || { echo "Cannot source common environment file" ; exit 1 ; }
}
	
export_variables() {
	### Essential variables for initializing the build system itself
	export BUILD_OUT
	export TMP_TOP
	export logFile

	###
	export BUILD_IMAGE_VERSION 	
	export config_distro 	
	export config_toplevel__arch 
	export config_toplevel__arch_subarch

	export config_toplevel__shared_artifacts
	export config_imager__workdir_compressed
	export config_imager__compress_installer_image 
	export config_imager__installer_image_file 
	export config_imager__installer_image_file_tarball

	export config_bsp__qemu_storage_device_path
	export config_bsp__qemu_removable_media_path
	export config_bsp__qemu_storage_device_size_mib
	export config_bsp__qemu_recreate_storage_device
	export config_bsp__qemu_copy_installer_image_to_removable_media
	export config_bsp__qemu_livecd_storage_device_path
}

set_variables_conditionally() {
	### toplevel paths 
	: ${BUILD_OUT=$(readlink -f $BUILD_TOP/../..)/out-june}

	: ${config_toplevel__rebuild_from_scratch_product=false}	# Delete the entire product build folder (BUILD_DIR)
	: ${config_toplevel__rebuild_from_scratch_all=false} 		# Delete the entire BUILD_OUT product

	: ${config_toplevel__downloads_base_path=${homedir}/dev/otaworkshop/downloads_dir}
	: ${config_toplevel__caches_base_path=${homedir}/dev/otaworkshop/caches_dir}
	: ${config_toplevel__caches_workdir_base_path=${homedir}/dev/otaworkshop/caches_workdir}

	# The idea is to put in shared_artifacts something you may want to share with other hosts/people, such as images, running scripts etc.
	: ${config_toplevel__shared_artifacts=${homedir}/shared_artifacts/}


	### imager
	: ${config_imager__workdir_compressed=$config_toplevel__shared_artifacts/${BUILD_IMAGE_VERSION}.tar.xz}

	: ${config_imager__workdir_start_from_scratch=true}
	: ${config_imager__installer_workdir_start_from_scratch=true}

	: ${config_imager__create_installer_image=true}
	: ${config_imager__compress_installer_image=false} # Unless you plan to push it somewhere or back it up, set to false by default
	: ${config_imager__installer_image_file="$config_toplevel__shared_artifacts/$BUILD_IMAGE_VERSION-installer.img"} # path of the output file of the installer
	
	: ${config_imager__installer_image_file_tarball="${config_imager__installer_image_file}.tar.xz"} # installer file, compressed (in case you want to send it to someone). It is defined in imager.buildconfig and this line should be removed



	### qemu
	: ${config_bsp__qemu_storage_device_path=$config_toplevel__shared_artifacts/pscgbuildos_storage.img}

	: ${config_bsp__qemu_removable_media_path=$config_imager__installer_image_file}						# If you want to change things in the removable_media after insterting it, you should copy it somewhere else 
	: ${config_bsp__qemu_storage_device_size_mib=$((500))} # for busyboxos you can work just fine with 6 for example...
	: ${config_bsp__qemu_recreate_storage_device=true}
	: ${config_bsp__qemu_copy_installer_image_to_removable_media=true}
	: ${config_bsp__qemu_livecd_storage_device_path=$config_toplevel__shared_artifacts/pscgbuildos_storage_livecd.img}	# it's not exactly livecd - it's using system.img as the storage

	# Note: there is automatic calculation, but if you build a debian like distro, you will likely
	# want to calculate config_imager__ext_partition_system_minimum_size_bytes yourself. Don't do it here,
	# as it is an excellent example of file system tuning parameters and considerations, and such a failure is 
	# an excellent example
	# e.g.: You can run with:
	# config_imager__ext_partition_system_minimum_size_bytes=$((500*1024*1024)) ./build-debos-image.sh
}


# I think this should go to the build system itself
toplevel__set_build_image_version() {
	: ${BUILD_IMAGE_VERSION_EXTRA=""}

	# Make things more readable for arch/subarch deciding etc.
	if [ -z "$config_toplevel__arch" ] ; then
		: ${BUILD_IMAGE_VERSION="${config_distro}-${ARCH:-$(uname -m)}${BUILD_IMAGE_VERSION_EXTRA}"}
	else
		# consider subarch only if config_toplevel_arch is explicitly stated
		if [ -z "$ARCH" ] ; then
			archsubarch=$config_toplevel__arch
		else
			if [ ! "$ARCH" = "$config_toplevel__arch" ] ; then
				fatalError "ARCH and  config_toplevel__arch don't agree"
			fi
			archsubarch=$ARCH
		fi
		
		if [ -n "$config_toplevel__arch_subarch" ] ; then
			archsubarch="${archsubarch}-$config_toplevel__arch_subarch"
		fi
		: ${BUILD_IMAGE_VERSION="${config_distro}-${archsubarch}${BUILD_IMAGE_VERSION_EXTRA}"}
	fi
}

main() {
	#----tmp
	. ./staging-base.sh
	set_standard_default_values_distro_reuse
	distro_reuse_exports
	set_standard_default_values_wip
	#eotmp
	init_main_builder_env			# Initialize the main builder environment
	export_variables			# Export important variables

	toplevel__set_build_image_version	# (will likely move to the build system) # Set the build image version based on the configuration and environment variables

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
