#
# No rebuild
#
# We *SOURCE* the next script so no need to takea care of exports. This script must be sourced
#

defaults() {
	: ${BUILD_IMAGE_VERSION=aug17-build-image-version-riscv}
	: ${ENABLE_GRAPHICS=true}
	: ${ENABLE_BROWSERS=false}
	: ${ENABLE_SOUND=true}	# although no one uses it as is

	export ENABLE_GRAPHICS ENABLE_SOUND ENABLE_BROWSERS
}

buildall() {
	: ${config_buildtasks__do_generate_qemu_scripts=true}
	: ${config_buildtasks__do_pack_images=true}
	: ${config_distro__add_oot_ota_code=true}
	: ${config_buildtasks__do_build_rootfs=true}
	: ${config_buildtasks__do_build_kernel=true}
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

. ./2025-aug-prep.sh 
