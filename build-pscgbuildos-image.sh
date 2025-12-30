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
	# TODO main project: in this is temporarily set in override_imager_variables() both there and in 2025-aug-wrapper.sh I commented it out delibertely now
	#                    there was nothing commented out in this function, except for the last lines which are a multicomment that also happen to have a variable example
	### toplevel
	#: ${config_toplevel__rebuild_from_scratch_product=false}	# Delete the entire product build folder (BUILD_DIR)
	#: ${config_toplevel__rebuild_from_scratch_all=false} 		# Delete the entire BUILD_OUT product


	### imager
	
	#: ${config_imager__workdir_compressed=$config_toplevel__shared_artifacts/${BUILD_IMAGE_VERSION}.tar.xz}

	#: ${config_imager__workdir_start_from_scratch=true}
	#: ${config_imager__installer_workdir_start_from_scratch=true}

	#: ${config_imager__create_installer_image=true}
	#: ${config_imager__compress_installer_image=false} # Unless you plan to push it somewhere or back it up, set to false by default
	#: ${config_imager__installer_image_file="$config_toplevel__shared_artifacts/$BUILD_IMAGE_VERSION-installer.img"} # path of the output file of the installer
	
	#: ${config_imager__installer_image_file_tarball="${config_imager__installer_image_file}.tar.xz"} # installer file, compressed (in case you want to send it to someone). It is defined in imager.buildconfig and this line should be removed

	#**Everything above was already in the files of the main project

	### qemu
	#: ${config_bsp__qemu_storage_device_path=$config_toplevel__shared_artifacts/pscgbuildos_storage.img}
#TODO: THIS IS WHERE THE PROBLEMS ARE TONIGHT - commented out the next line to check didn't check yet
#	: ${config_bsp__qemu_removable_media_path=$config_imager__installer_image_file}						# If you want to change things in the removable_media after insterting it, you should copy it somewhere else 
	: ${config_bsp__qemu_storage_device_size_mib=$((500))} # for busyboxos you can work just fine with 6 for example...
	: ${config_bsp__qemu_recreate_storage_device=true}
	: ${config_bsp__qemu_copy_installer_image_to_removable_media=true}
	#: ${config_bsp__qemu_livecd_storage_device_path=$config_toplevel__shared_artifacts/pscgbuildos_storage_livecd.img}	# it's not exactly livecd - it's using system.img as the storage

	# Note: there is automatic calculation, but if you build a debian like distro, you will likely
	# want to calculate config_imager__ext_partition_system_minimum_size_bytes yourself. Don't do it here,
	# as it is an excellent example of file system tuning parameters and considerations, and such a failure is 
	# an excellent example
	# e.g.: You can run with:
	# config_imager__ext_partition_system_minimum_size_bytes=$((500*1024*1024)) ./build-debos-image.sh
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
