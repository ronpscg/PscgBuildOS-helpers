#!/bin/bash
DEBIAN_ARCHS="i386 x86_64 arm arm64 riscv "
DEBIAN_PORTS_ARCHS="loongarch "



set_partition_layout_variables() {
	# NOT CALLED AT FIRST DEMONSTRATION - WILL MODIFY THE SIZE TO SHOW HOW IT AFFECTS IT
	set -a
	: ${config_imager__partition_size_system="+50M"} # +700M was OK for debos without graphics, 3000M was ok for systemd and weston, 4000M was OK for adding firefox
        : ${config_imager__partition_size_ota_state="+10M"}
        : ${config_imager__partition_size_ota_extract="+150M"}
        : ${config_imager__partition_size_config="+10M"}
        : ${config_imager__partition_size_roconfig="+10M"}
        : ${config_imager__partition_size_data="+100M"} # this is a placeholder - for when data gets its own partition
        : ${config_imager__partition_size_system_overlay="+100M"} # this now includes data  (reduced it from 2600)
        : ${config_imager__partition_size_recovery_tarball="+200M"} #
	set +a
}	

#
# $1 ARCH (in busyboxos we don't play too much with the different variants - which makes it easier to follow, cf. debos)
#
busyboxos_imager_variables_by_arch() {
	local arch=$1
	# Implicitly sets the installer image full path
	# (just showing the definition: ${config_imager__installer_image_file="$config_toplevel__shared_artifacts/$BUILD_IMAGE_VERSION-installer.img"} )
	export BUILD_IMAGE_VERSION=sep03_busyboxos_0309-${arch}
	# Sets the storage image
	export config_bsp__qemu_storage_device_path=$config_toplevel__shared_artifacts/pscgbuildos_storage-${arch}.img
	# Sets the livecd by copying $config_imager__workdir_ext_partition_images/system.img to $config_bsp__qemu_livecd_storage_device_path
	export config_bsp__qemu_livecd_storage_device_path=$config_toplevel__shared_artifacts/pscgbuildos_storage_livecd-${arch}.img

	# More examples that are exaggerated (using ARCH=i386, as it is just faster to run the target itself for)
	# Copies to removable media <if...>
	# Adds: ./tmp-but-persistent/PscgBuildOS/removable_media-i386.img
	export config_bsp__qemu_removable_media_path=$TMP_BUT_PERSISTENT_TOP/removable_media-${arch}.img

	# from the code:
	# The system partition will be packed into this ext image
	
	export config_imager__workdir_ext_partition_images=${TMP_TOP}/staging-${arch}/wip-images

	export preferred_tmp_top=${TMP_BUT_PERSISTENT_TOP} # When the images are huge, TMP_TOP might not be the best choice


	# The file system contents of the installation media and the OTA tarball will be populated in the following directory
	export config_imager__workdir=${preferred_tmp_top}/staging-${arch}/installer_fs_workdir

	# This is a folder used only to mount the installer image
	export config_imager__installer_workdir="${preferred_tmp_top}/staging-${arch}/installer-workdir"

	#
	# Your installer image ${config_imager__installer_image_file} needs to be packed. For that, an image file is created, and loop mounted onto ${config_imager__installer_workdir}. 
	# The populated contents willbe what you expect to see in your installer media, e.g.:
	# autoflash  bzImage  initramfs.cpio  installables  installer.digest  installer.manifest  kernel.config
	#
	# That is as opposed to ./tmp-but-persistent/PscgBuildOS/staging-i386/installer_fs_workdir/ that would have:
	# autoflash  bzImage  initramfs.cpio  installables  kernel.config

	# autoflash  bzImage  initramfs.cpio  installables  installer.digest  installer.manifest  kernel.config
	#
	# In the previously recorded video the exaple would be:
	# /home/ron/aug19-pscgbuildos/artifacts/aug19_busyboxos_image_2308-i386-installer.img  <-> /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging-i386/installer-workdir
	# However, the "installer-workdir" is removed when either there is an error, or all is done, in the cleanup_loopback_devices_and_mounts() function
	


	# Since I keep the previous materials at the end - I cleanup. Could alternatively, on heavy reuse, avoid that as well
	: ${config_imager__workdir_start_from_scratch=true}		# Cleanup previous working directory
	: ${config_imager__installer_workdir_start_from_scratch=true}	# Cleanup previous installer working directory
	set +a
	
	# First demonstration: commented out to show defaults
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
		export ARCH=$ARCH config_distro=pscg_debos config_pscgdebos__debian_or_ubuntu=debian config_pscgdebos__debian_codename=$1
		echo y | ./aug18-wrapper.sh $build_tasks
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
		./aug18-wrapper.sh $build_tasks
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
		./aug18-wrapper.sh $build_tasks
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
	outdir=${homedir}/aug19-pscgbuildos
}

set_homedir
set_outdir
set -euo pipefail # must be done after checking for SUDO_HOME (or otherwise remove -u)

set -a
	: ${TMP_TOP=${outdir}/tmp/PscgBuildOS}
	: ${TMP_BUT_PERSISTENT_TOP=${outdir}/tmp-but-persistent/PscgBuildOS}
	: ${BUILD_OUT=${outdir}/build}
	: ${config_toplevel__shared_artifacts=${outdir}/artifacts}

        : ${config_buildtasks__do_generate_qemu_scripts=true}
        : ${config_buildtasks__do_pack_images=true}
set +a	

START=$(date)

export config_ramdisk__kexectools_include=false
#build_debian trixie buildall "$DEBIAN_ARCHS"
#build_debian trixie buildall "$DEBIAN_PORTS_ARCHS"
#build_debian trixie buildall "s390"

#build_busyboxos buildall "$DEBIAN_ARCHS $DEBIAN_PORTS_ARCHS"
#build_busyboxos buildall i386
#build_busyboxos buildall s390
#build_busyboxos buildall sparc64

demo_materials_reusing_loongarch() {
	set -a
	config_distro__prebuilt_image_materials_workdir=/tmp/whatever-stam-foo-bar
	config_buildtasks__do_build_rootfs=false
	config_buildtasks__do_build_kernel=false
	config_buildtasks__do_build_kernel_modules=false
	config_buildtasks__do_build_ramdisk=false
	config_buildtasks__do_build_bootloader=false

	config_kernel__edu_do_modules_prepare=false
	config_examples__common_linux_add_hello_module=false

	# demo: the default without setting it is 500. You can uncomment it
	#config_bsp__qemu_storage_device_size_mib=2000 # Just because I am reusing something where 
	# or, you can copy from wherever we built the ramdisk materials, as partitions-emmc.config will match what is there
	distro__prebuilt_partitions_emmc_config_file_for_imager_estimation=/tmp/pscg_alpineos/build-loongarch/ramdisk/initramfs/flasher/config/partitions-emmc.config
	set +a
}
demo_materials_reusing_loongarch
build_alpineos buildall loongarch

END=$(date)
echo "Done."
echo "$START"
echo "$END"
