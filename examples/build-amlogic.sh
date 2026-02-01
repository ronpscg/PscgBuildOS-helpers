#!/bin/bash
#
# This script is a very concise and very obvious wrapper around wrapper-all-archs.sh
# It uses the latter as is, aiming to build just one architecture/or product
#

set_homedir() {
	if [ -n "$SUDO_HOME" ] ; then
		: ${homedir=$SUDO_HOME}
	elif [ -n "$SUDO_USER" ] ; then
		: ${homedir=/home/$SUDO_USER}
	else
		: ${homedir=$HOME}
	fi
}

set_outdir() {
	# We want to share code between the different distros, not between the different BSPs when they are actually different and the kernel configs are very different
	# It is however possible to use the same output directory, and just understand that sharing architectures may affect the build time,
	# or alterntively set: config_distro__reuse_shared_arch_kernel=false  config_distro__reuse_shared_arch_ramdisk=false
	outdir=${homedir}/PscgBuildOS/out-amlogic
	echo "$BUILD_OUT"
	: ${BUILD_OUT=${outdir}/build}
	export BUILD_OUT
}


set_vars() {
	export config_bsp_layer=layers/bsp/recipes/linux/bsp-amlogic-s905w-p281

	# Uncomment if you already built a first build, no longer care about the kernel or images, and just want to work on the bootloaders and installations
	export config_buildtasks__do_build_kernel_dtbs=true
	export config_buildtasks__do_build_kernel=true
	export config_buildtasks__do_build_ramdisk=true
	export config_buildtasks__do_build_rootfs=true
	export config_buildtasks__do_build_bootloaders=true
	export config_buildtasks__do_build_boot_firmware=true
	export config_kernel__rebuild_kernel=false

	export config_buildtasks__do_generate_qemu_scripts=false

	export config_uboot__fetch_git_or_tarball=git

	export config_distro__url_ota_server_base="http://192.168.1.106:8000"
	export config_pscg_alpineos__inittab_skip_console_login=false

	# This will make your subsequent builds smaller, but your images sizes also smaller. Mind your tradeoffs.
	# You could reuse materials from a previous build, while still cleaning the caches, and it will make your build time much faster.
	: ${config_pscg_alpineos__postbuild_clean_apk_caches=true}
	: ${config_pscgdebos__postbuild_clean_apt_caches=true}
	export config_pscg_alpineos__postbuild_clean_apk_caches config_pscgdebos__postbuild_clean_apt_caches
}

main() {
	LOCAL_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
	NEXT_WRAPPER_SCRIPT=$LOCAL_DIR/wrapper-all-archs.sh
	cd $LOCAL_DIR/.. # work on the helpers main direct

	set_homedir
	set_outdir
	set_vars



	# We do not export anything directly related to this and the wrapper-all-arch.sh script to keep it clean. One could export more things

	# To keep things simple when using this script:
	# Pay attention if you select an architecture to keep all of the others empty and select only one distro
	
	#
	# Do one build loop for the smaller distros
	# 
	export config_imager__installer_media_size_sectors=$((200*1024*1024/512))
	DISTROS_TO_BUILD="pscg_busyboxos pscg_alpineos"			\
	DEFAULT_BUILD_TARGET=buildall					\
	DEBIAN_ARCHS="arm64"						\
	DEBIAN_PORTS_ARCHS=""						\
	BUSYBOX_ARCHS="arm64"						\
	ALPINE_ARCHS=arm64						\
	$NEXT_WRAPPER_SCRIPT


	#
	# Do another call for PscgDeboOS to override the installer media size so we don't need to wait too much when flashing it
	#

	# We set the size to installer image size 1500 MiB as per the time of build. It may not be enough in the future, so you may want to change it if you find it so.
	# The smaller the size is the faster it is to flash the installer image onto an sdcard or USB stick
	export config_imager__installer_media_size_sectors=$((1500*1024*1024/512))

	# To keep things simple when using this script:
	# Pay attention if you select an architecture to keep all of the others empty and select only one distro
	DISTROS_TO_BUILD="pscg_debos"	\
	DEFAULT_BUILD_TARGET=buildall					\
	DEBIAN_ARCHS="arm64"						\
	DEBIAN_PORTS_ARCHS=""						\
	BUSYBOX_ARCHS="arm64"						\
	ALPINE_ARCHS=arm64						\
	$NEXT_WRAPPER_SCRIPT



}

main "$@"
