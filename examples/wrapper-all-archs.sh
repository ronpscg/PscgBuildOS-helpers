#!/bin/bash
LOCAL_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
cd $LOCAL_DIR/.. # work on the helpers main directory (cleanup example)

NEXT_WRAPPER_SCRIPT=./wip-2-wrapper.sh	# Allow easy chaining of a subsequent script

DEBIAN_ARCHS="i386 x86_64 arm arm64 riscv "
DEBIAN_PORTS_ARCHS="loongarch "
if [ "$(lsb_release -r | cut -f 2)" = "24.04" ] ; then
	# or alternatively - set the links of gcc-14
	DEBIAN_PORTS_ARCHS=""
fi


#
# This is a function demonstrating the setting of partition table sizes. It was designed to support pscg_busyboxos, and is also called from the respective
# pscg_alpineos builder in this file, so if you install too many packages on your alpineos, or too many modules/firmware on the rootfs of either, you will want
# to change the numbers here (again, it is an example, and I am leaving it here because it is useful to look at)
#
set_partition_layout_variables() {
	# NOT CALLED AT FIRST DEMONSTRATION - WILL MODIFY THE SIZE TO SHOW HOW IT AFFECTS IT
	set -a
	: ${config_imager__partition_size_system="+50M"} # +700M was OK for debos without graphics, 3000M was ok for systemd and weston, 4000M was OK for adding firefox
        : ${config_imager__partition_size_ota_state="+10M"}
        : ${config_imager__partition_size_ota_extract="+150M"}
        : ${config_imager__partition_size_config="+10M"}
        : ${config_imager__partition_size_roconfig="+10M"}
        : ${config_imager__partition_size_data="+100M"} 
        : ${config_imager__partition_size_system_overlay="+100M"}
        : ${config_imager__partition_size_recovery_tarball="+200M"}
	set +a
}	

#
# Set some common variables for the buildsystem - mostly archs etc. 
# Basically the same I just wanted to see that I avoid the tmp paths
# $1 ARCH
#
imager_variables_by_arch() {
	return 0 # Demonstration that we can remove this function alltogether BUT THEN logs etc. go to tmp

	local arch=$1

	# TMP_TOP is used in the main script, and is defined here to avoid set -u errors.  TMP_BUT_PERSISTENT_TOP is an example. One can remove this function altogheter.
	: ${TMP_TOP=${outdir}/tmp/PscgBuildOS}
	: ${TMP_BUT_PERSISTENT_TOP=${outdir}/tmp-but-persistent/PscgBuildOS}
	export TMP_TOP TMP_BUT_PERSISTENT_TOP 


	export preferred_tmp_top=${TMP_BUT_PERSISTENT_TOP} # When the images are huge, TMP_TOP might not be the best choice

	export config_bsp__qemu_removable_media_path=$TMP_BUT_PERSISTENT_TOP/removable_media-${arch}.img
	export config_imager__workdir_ext_partition_images=${TMP_TOP}/staging-${arch}/wip-images

	export config_imager__workdir=${preferred_tmp_top}/staging-${arch}/installer_fs_workdir # The file system contents of the installation media and the OTA tarball will be populated in the following directory
	export config_imager__installer_workdir="${preferred_tmp_top}/staging-${arch}/installer-workdir" # This is a folder used only to mount the installer image

	#
	# These are explanations. Perhaps they will find themselves into one of the README files
	#
	# Your installer image ${config_imager__installer_image_file} needs to be packed. For that, an image file is created, and loop mounted onto ${config_imager__installer_workdir}. 
	# The populated contents will be what you expect to see in your installer media, e.g.:
	# autoflash  bzImage  initramfs.cpio  installables  installer.digest  installer.manifest  kernel.config
	#
	# That is as opposed to ${config_imager__workdir} (e.g. ./tmp-but-persistent/PscgBuildOS/staging-i386/installer_fs_workdir/) that would have:
	# autoflash  bzImage  initramfs.cpio  installables  kernel.config

	#
	# In the previously recorded video the exaple would be:
	# /home/ron/aug19-pscgbuildos/artifacts/aug19_busyboxos_image_2308-i386-installer.img  <-> /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging-i386/installer-workdir
	# However, you will not see "installer-workdir" nominally, as it is removed when either there is an error, or all is done, in the cleanup_loopback_devices_and_mounts() function
}

#
# $1 ARCH
#
busyboxos_imager_variables_by_arch() {
	imager_variables_by_arch $@
	# Demonstration of partition layout. Comment it out to use defaults. (the published videos showed both with and without it)
	set_partition_layout_variables	
}

#
# $1: codename
# $2: build_tasks
# $3: "<arch1> <arch2>" - enclosed with "" (otherwise just do shift2 and use this as the last argument...)
#
build_debian() {
	codename=$1
	build_tasks=$2
	ARCHS=$3
	for ARCH in $ARCHS ; do
		imager_variables_by_arch $ARCH	# Concentrate in one function so that it is easy to demonstrate and to comment out
		export ARCH=$ARCH config_distro=pscg_debos config_pscgdebos__debian_or_ubuntu=debian config_pscgdebos__debian_codename=$1
		echo y | $NEXT_WRAPPER_SCRIPT $build_tasks
	done
}


#
# $2: build_tasks
# $3: "<arch1> <arch2>" - enclosed with "" (otherwise just do shift2 and use this as the last argument...)
#
build_busyboxos() {
	build_tasks=$1
	ARCHS=$2
	for ARCH in $ARCHS ; do
		busyboxos_imager_variables_by_arch $ARCH	# Concentrate in one function so that it is easy to demonstrate and to comment out
		export ARCH=$ARCH config_distro=pscg_busyboxos		
		echo y | $NEXT_WRAPPER_SCRIPT $build_tasks
	done
}

#
# $2: build_tasks
# $3: "<arch1> <arch2>" - enclosed with "" (otherwise just do shift2 and use this as the last argument...)
#
build_alpineos() {
	build_tasks=$1
	ARCHS=$2
	for ARCH in $ARCHS ; do
		busyboxos_imager_variables_by_arch $ARCH	# Concentrate in one function so that it is easy to demonstrate and to comment out
		export ARCH=$ARCH config_distro=pscg_alpineos
		echo y | $NEXT_WRAPPER_SCRIPT $build_tasks
	done
}

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

main() {
	set_homedir
	set_outdir
	set -euo pipefail # must be done after checking for SUDO_HOME (or otherwise remove -u)

	export config_ramdisk__kexectools_include=false # The reason to put it here is that not all architectures support kexec, and we (potentially) want to show the building of everything

	START=$(date)

	#build_debian trixie buildall "$DEBIAN_ARCHS" # Seems to be OK - when I tested i386 I had to install firefox from the local cache on the system, I am not sure why. not sure about riscv - maybe something is wrong with the initramfs but it's strange because alpineos build works there. all of these used to work flawlessly
	#build_debian sid buildall "$DEBIAN_PORTS_ARCHS" # Dec 25 25 - loongarch does not build seemlesly. It used to work for when Trixie was sid. 
	#build_debian trixie buildall "s390"

	#build_busyboxos buildall "$DEBIAN_ARCHS $DEBIAN_PORTS_ARCHS"
	#build_alpineos buildall "$DEBIAN_ARCHS $DEBIAN_PORTS_ARCHS"
	#build_busyboxos buildall i386
	#build_busyboxos buildall s390 # either console doesn't work or block device
	#build_busyboxos buildall sparc64 # qemu-system-sparc64: -device virtio-blk-pci,drive=emmcdisk: PCI: no slot/function available for virtio-blk-pci, all in use or reserved
	#build_debian trixie buildall riscv # There is a specific issue with RISC-V on this build, kernel panics with the ramdisk, not sure why. 6.17-rc2. 6.19-rc2 is fine.

	#build_busyboxos ramdisk-kernel x86_64
	#build_alpineos buildall x86_64
	#build_debian trixie buildall x86_64
	build_debian trixie buildall i386

	END=$(date)
	echo "Done."
	echo "$START"
	echo "$END"
}

main "$@"
