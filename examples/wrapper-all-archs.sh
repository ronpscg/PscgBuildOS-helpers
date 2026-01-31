#!/bin/bash
LOCAL_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
cd $LOCAL_DIR/.. # work on the helpers main directory (cleanup example)

NEXT_WRAPPER_SCRIPT=./qemu-2-wrapper.sh	# Allow easy chaining of a subsequent script

ALL_DEBIAN_ARCHS="i386 x86_64 arm arm64 riscv s390"
ALL_DEBIAN_PORTS_ARCHS="loongarch sparc64"
# BusyboxOS supports everything
ALL_BUSYBOX_ARCHS="$DEBIAN_ARCHS $DEBIAN_PORTS_ARCHS"
# You can look at the different projects and also set a "subarch", e.g. to build both for armv7 and armhf in Alpine etc.
ALL_ALPINE_ARCHS="i386 x86_64 arm arm64 riscv s390 loongarch" 

# Enable setting the architectures from a wrapper script
: ${DEBIAN_ARCHS=$ALL_DEBIAN_ARCHS}
: ${DEBIAN_PORTS_ARCHS=$ALL_DEBIAN_PORTS_ARCHS}
: ${BUSYBOX_ARCHS=$ALL_BUSYBOX_ARCHS}
: ${ALPINE_ARCHS=$ALL_ALPINE_ARCHS}

# Enable setting the build commands externally. We will provide defaults to keep it short
# And avoid declaring arrays or adding more sourcing. 
: ${DISTROS_TO_BUILD="busybox alpineos debian"}

: ${DEFAULT_BUILD_TARGET=buildall} # e.g. buildall|ramdisk-only|ramdisk-kernel etc.


if [ "$(lsb_release -r | cut -f 2)" = "24.04" ] ; then
	# or alternatively - set the links of gcc-14, and remove this if clause altogether
	DEBIAN_PORTS_ARCHS="sparc64"
fi

: ${CONTINUE_ON_ERROR="true"}	# if true, continue after a (per arch/product) build error. Can be useful to try and build a lot of things together.

#
# $1 message
#
report_success() {
	local msg=$(printf "%3d: $@" "$((REPORT_COUNT))")
	: $((REPORT_COUNT++)) # done separately and not inline because of the subshell in the previous line
	REPORT_SUCCEEDED+="$msg\n"
	if [ -f "$LOCAL_LOG_FILE" ] ; then
		echo -e "$(date): \e[32m$msg\e[0m SUCCESS" | tee -a $LOCAL_LOG_FILE
	fi
}

#
# $1 message
#
report_fail() {
	local msg=$(printf "%3d: $@" "$((REPORT_COUNT))")
	: $((REPORT_COUNT++)) # done separately and not inline because of the subshell in the previous line
	REPORT_FAILED+="$msg\n"
	if [ -f "$LOCAL_LOG_FILE" ] ; then
		echo -e "$(date): \e[31m$msg\e[0m FAIL" | tee -a $LOCAL_LOG_FILE
	fi
}
#
# $1 message
#
report() {
	local msg=$(printf "%3d: $@" "$((REPORT_COUNT))")
	if [ -f "$LOCAL_LOG_FILE" ] ; then
		echo -e "$(date): $msg" | tee -a $LOCAL_LOG_FILE
	fi
}
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
# This is mostly intended to initialize a log files to see reports of this script, regardless of the build system itself.
# We also initialize some of the global directories (that the build systemd doesn't really need, but see the comment in imager_variables_by_arch
#
init_env() {
	# TMP_TOP is used in the main script, and is defined here to avoid set -u errors. It is set here to the default folder the build-system would set
	# but it is controllable from outside the script should you want to
	: ${TMP_TOP=${outdir}/tmp/PscgBuildOS}
	# TMP_BUT_PERSISTENT_TOP is an example. One can remove this function altogheter. By design no one needs it
	# therefore it does not need to be exported, but there is the possibility
	: ${TMP_BUT_PERSISTENT_TOP=${outdir}/tmp-but-persistent/PscgBuildOS}
	export TMP_TOP TMP_BUT_PERSISTENT_TOP

	# This is exported only for subsequent scripts to use should they want to - it is none of the concern of the build system
	# When the images are huge, TMP_TOP might not be the best choice
	export preferred_tmp_top=${TMP_BUT_PERSISTENT_TOP} 

	REPORT_SUCCEEDED=""		# set list of successful target (if CONTINUE_ON_ERROR=true. Otherwise, either everything succeeded, or the last one failed)
	REPORT_FAILED=""		# set list of failed targets (if CONTINUE_ON_ERROR=true. Otherwise, either everything succeeded, or the last one failed)
	REPORT_COUNT="0"		# Increase for every built image

	LOCAL_LOG_FILE=${preferred_tmp_top}/$(basename $0).log
	mkdir -p $(dirname $LOCAL_LOG_FILE) || { echo "Faild to create the logflie containing directory" ; exit 1 ; }
	echo >> $LOCAL_LOG_FILE || { echo "Failed to create logfile" ; exit 1 ; }
}

#
# Set some common variables for the buildsystem - mostly archs etc. 
# $1 ARCH
#
# NOTE: the current content is just an example of modifying paths - it is not needed because of the defaults in the build system itself, and in the last-line script.
#       everything is exported here because this particular script calls and not sources the next script in line (made this way to allow continuing on errors if someone wants to do that)
#
imager_variables_by_arch() {
	local arch=$1


	export config_bsp__qemu_removable_media_path=$TMP_BUT_PERSISTENT_TOP/removable_media-${arch}.img
	export config_imager__workdir_ext_partition_images=${TMP_TOP}/staging-${arch}/wip-images
	
	# The filesystem contents of the installation media and the OTA tarball will be populated in the following directory
	export config_imager__workdir=${preferred_tmp_top}/staging-${arch}/installer_fs_workdir 
	# A folder used only to mount the installer image
	export config_imager__installer_workdir="${preferred_tmp_top}/staging-${arch}/installer-workdir"

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
	# In the previously recorded video the example would be:
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
	: ${config_imager__ext_partition_system_size_scale_factor=1.30} # This is an exaggeration - it is useful for 32 bit architectures with tiny rootfs where the overhead is significant and tarballs are installed into the livecd
	export config_imager__ext_partition_system_size_scale_factor
}

#
# $1 ARCH
#
debian_imager_variables_by_arch() {
	imager_variables_by_arch $@
	: ${config_imager__ext_partition_system_size_scale_factor=1.35} # This is a wild exaggeration
	export config_imager__ext_partition_system_size_scale_factor
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
		debian_imager_variables_by_arch $ARCH	# Concentrate in one function so that it is easy to demonstrate and to comment out
		export ARCH=$ARCH config_distro=pscg_debos config_pscgdebos__debian_or_ubuntu=debian config_pscgdebos__debian_codename=$1
		local msg="$config_distro-$ARCH ($codename) - $build_tasks"
		report "$msg - STARTING "
		if echo y | $NEXT_WRAPPER_SCRIPT $build_tasks ; then
			report_success "$msg"
		else
			report_fail "$msg"
		fi
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
		local msg="$config_distro-$ARCH - $build_tasks"
		report "$msg - STARTING "
		if echo y | $NEXT_WRAPPER_SCRIPT $build_tasks ; then
			report_success "$msg"
		else
			report_fail "$msg"
		fi
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
		local msg="$config_distro-$ARCH - $build_tasks"
		report "$msg - STARTING "
		if echo y | $NEXT_WRAPPER_SCRIPT $build_tasks ; then
			report_success "$msg"
		else
			report_fail "$msg"
		fi
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
	if [ "$CONTINUE_ON_ERROR" = "true" ] ; then
		echo -e "\e[33$mNOTE: $0: CONTINUE_ON_ERROR=true (<build> -k like behavior)\e[0m"
	else
		set -euo pipefail # must be done after checking for SUDO_HOME (or otherwise remove -u)
	fi

	init_env


	export config_ramdisk__kexectools_include=false # The reason to put it here is that not all architectures support kexec, and we (potentially) want to show the building of everything

	# The next exported block is done like this as it is very significant - if you remove it / set the conditional variables to false, you will be able to build
	# and test the initramfs, and a livecd rootfs much faster, and save time and space on creating a storage device for the EMMC/Disk storage. You will then
	# need to create it on your own. It is easy and possible to do the switches, as it is an example, I am explaining the exact rationale - to be faster, remove this block, to test
	# everything keep it, to test everything but also keep the storage device, per product - modify the last variable to true
	# If you don't create the OTA image - there is no point for you to have an installer either.
	set -a
	: ${config_imager__create_ota_image=true}
        # We are creating a livecd where we just copy the system.img and pack it in the resulting image - and we don't want qemu to recreate it.
        # If we decide to create both a livecd and and installer image - we will use other variables
        # The reason for separating the livecd is that I wanted to avoid the time it takes to compress the image, which is (re)used for the OTA update.
        # Otherwise, I would make the livecd and the installer the same image (and I might do it again - I used to have this mode in the past but it was not popular with customers)
        # This is what simple_dev_optimization_2 in the last-line script does if enabled
        : ${config_bsp__qemu_recreate_storage_device=true}
	config_bsp__qemu_recreate_storage_device=false # for now - to avoid excessive extra storage - fill free to remove this line if you have "infinite" disk space!
	set +a

	START=$(date)
	for d in $DISTROS_TO_BUILD ; do
		case $d in 
			busyboxos|busybox|pscg_busyboxos)
				build_busyboxos "$DEFAULT_BUILD_TARGET" "$BUSYBOX_ARCHS"
				;;
			alpineos|alpine|pscg_alpineos)
				build_alpineos "$DEFAULT_BUILD_TARGET" "$ALPINE_ARCHS"
				;;
			debos|debian|pscg_debos)
				build_debian trixie "$DEFAULT_BUILD_TARGET" "$DEBIAN_ARCHS"
				# Note: as per the post release of Debian Trixie, all Debian ports next-sid are broken. Some day they will work, but it is not the day of this commit.
				#       prior to the release of Trixie the loongarch has been tested extensively, and worked well. I think the sparc64 also worked well, 
				#       but I mostly tested loongarch and I think riscv64 then, because if I am not wrong it was also on Debian ports before Trixie became the new stable
				#build_debian sid "$DEFAULT_BUILD_TARGET" "$DEBIAN_PORTS_ARCHS"
				;;
			*)
				echo invalid DISTROS_TO_BUILD option $d. continuing
				continue
				;;
		esac
	done

	END=$(date)
	report "Done."
	report "$START"
	report "$END"
	echo -e "Successful builds:\n\e[32m$REPORT_SUCCEEDED\e[0m"
	echo -e "Failed builds:\n\e[31m$REPORT_FAILED\e[0m"

	local suc=$(echo -en "$REPORT_SUCCEEDED" | wc -l)
	local fai=$(echo -en "$REPORT_FAILED" | wc -l)
	report "Ran $((suc+fai)) builds. \e[32m$suc succeeded\e[0m, \e[31m$fai failed\e[0m\n"
}

main "$@"
