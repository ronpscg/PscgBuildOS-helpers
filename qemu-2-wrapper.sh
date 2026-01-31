#
# No rebuild
#
# We *SOURCE* the next script so no need to takea care of exports. This script must be sourced
#

defaults() {
	# These defaults can be overridden. However do note that since the ENABLE_GRAPHICS feature is sanity tested for the potential inclusion of huge libraries,
	# only trivial things are tested so our current behavior for this feature is to mean we only add it on PscgDebOS.
	# There are exercises in the PSCG courses that tackle exactly that (graphics withotu systemd, weston, light display managers etc.) but for now they are left out of the open sourced published project
	if [ "$config_distro" = "pscg_debos" ] ; then
		: ${ENABLE_GRAPHICS=true}
		: ${config_imager__installer_media_size_sectors=$((6*1024*1024*1024/512))}
		# We could also add another example (of a browser kiosk device at the time of writing it)
		#config_pscgdebos__extra_layers_file=$PWD/more-layers/more-pscg_debos-layers.txt
		#: ${ENABLE_BROWSERS=true}
	else
		: ${ENABLE_GRAPHICS=true}							# It's fine to enable the grpahics
		: ${config_imager__installer_media_size_sectors=$((200*1024*1024/512))}		# The image sizes will liklely not exceed 200MB for pscg_busyboxos (definitely) and pscg_alpineos (unless you add much more packages and then it is up to you to increase the size in a wrapping script)
	fi
	: ${ENABLE_BROWSERS=false}
	: ${ENABLE_SOUND=true}	# although no one uses it as is

	export ENABLE_GRAPHICS ENABLE_SOUND ENABLE_BROWSERS

	: ${config_pscg_alpineos__postbuild_clean_apk_caches=false} 
	: ${config_pscgdebos__postbuild_clean_apt_caches=false}
	export config_pscg_alpineos__postbuild_clean_apk_caches config_pscgdebos__postbuild_clean_apt_caches

}

buildall() {
	: ${config_buildtasks__do_generate_qemu_scripts=true}
	: ${config_buildtasks__do_pack_images=true}
	: ${config_distro__add_oot_ota_code=true}
	: ${config_buildtasks__do_build_rootfs=true}
	: ${config_buildtasks__do_build_kernel=true}
	: ${config_buildtasks__do_build_kernel_dtbs=true}
	: ${config_pscgdebos__extra_layers_file=$PWD/more-layers.txt} # since the file does not exist, we will not source it. This is an example - you can set if you want what is inside $PWD/more-layers/...
	: ${config_distro=pscg_debos}
	: ${config_pscgdebos__debian_or_ubuntu=debian}
	: ${config_pscgdebos__debian_codename=sid}
}


ramdisk-only() {
	: ${config_buildtasks__do_generate_qemu_scripts=false}
	: ${config_buildtasks__do_pack_images=false}
	: ${config_distro__add_oot_ota_code=false}
	: ${config_buildtasks__do_build_rootfs=false}
	: ${config_buildtasks__do_build_kernel=false}
	: ${config_buildtasks__do_build_kernel_dtbs=false}
	: ${config_pscgdebos__extra_layers_file=$PWD/more-layers.txt}
	: ${config_distro=pscg_debos}
	: ${config_pscgdebos__debian_or_ubuntu=debian}
	: ${config_pscgdebos__debian_codename=sid}
}


ramdisk-kernel() {
	: ${config_buildtasks__do_generate_qemu_scripts=false}
	: ${config_buildtasks__do_pack_images=false}
	: ${config_distro__add_oot_ota_code=false}
	: ${config_buildtasks__do_build_rootfs=false}
	: ${config_buildtasks__do_build_kernel=true}
	: ${config_buildtasks__do_build_kernel_dtbs=true}
	: ${config_pscgdebos__extra_layers_file=$PWD/more-layers.txt}
	: ${config_distro=pscg_debos}
	: ${config_pscgdebos__debian_or_ubuntu=debian}
	: ${config_pscgdebos__debian_codename=sid}
}

verify_essentials() {
	[ -z "$ARCH" ] && { echo "Please provide ARCH" ; exit 1 ; }
	[ -z "$config_distro" ] && { echo "Please provide config_distro" ; exit 1 ; }
	if [ "$config_distro" = "pscg_debos" ] ; then
		[ -z "$config_pscgdebos__debian_or_ubuntu" ] && { echo "Please provide config_pscgdebos__debian_or_ubuntu" ; exit 1 ; }
		[ -z "$config_pscgdebos__debian_codename" ] && { echo "Please provide config_pscgdebos__codename" ; exit 1 ; }
		[ -z "$ARCH" ] && { echo "Please provide ARCH" ; exit 1 ; }
	fi
}


defaults # better not set them, but helps to save typing
verify_essentials

if [ -z "$1" ] || ! type -t $1 >/dev/null ; then 
	echo "$1 is not a function"
	exit 1
fi

$1

NEXT_WRAPPER_SCRIPT=./qemu-1-wrapper.sh  # Allow easy chaining of a subsequent script
. $NEXT_WRAPPER_SCRIPT
