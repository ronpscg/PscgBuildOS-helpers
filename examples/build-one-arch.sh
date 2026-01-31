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
	# just helps to quickly see everything in the same place. I prefer not using these things because I prefer temp stuff to go to tmpfs (faster, better for the storage device)
	outdir=${homedir}/PscgBuildOS/out
}

set_vars() {
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
	DISTROS_TO_BUILD=pscg_alpineos		\
	DEFAULT_BUILD_TARGET=buildall		\
	DEBIAN_ARCHS=""				\
	DEBIAN_PORTS_ARCHS=""			\
	BUSYBOX_ARCHS=""			\
	ALPINE_ARCHS=x86_64			\
	$NEXT_WRAPPER_SCRIPT
}

main "$@"
