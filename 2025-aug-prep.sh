#!/bin/bash
#
# The objective of this function is to be very clear on what is exported, before setting default variables
#



kernel_exports() {
	export config_kernel__list_of_config_overrides	# set specific overrides from the command line. Useful for quickly trying out additional kernel features
}


# TODO: busybox the examples we set here put it to be true. Otherwise we don't need it at all.
# NOTE: in busybox.buildconfig everything is exported with set -a. May export things more specifically
override_busybox_variables() {
	: ${config_busybox__do_config_if_already_built=true}	
}
busybox_exports() {
	export config_busybox__do_config_if_already_built
}


override_imager_variables() {
	# tmp is faster and easier on your storage whereas persistent is bigger. using tmpfs with huge stuff is a bad idea, so only use it if you have A LOT of RAM on your host
	# decide where you want your files to go, and be consistent. What matters to the build system is the config_imager__... files themselves, so there is no need
	# to have it exported or so.
	: ${preferred_tmp_top=${TMP_BUT_PERSISTENT_TOP}} # When the images are huge, TMP_TOP might not be the best choice

	: ${config_imager__installer_workdir=${preferred_tmp_top}/installer-workdir}
	# Don't copy installer - saves time. Copying it - prevents direct modification of the installer image, which is useful for debugging without ruining an already built image
	# It is confusing. It is qemu - and not imager, because the imager is done once it created the image.
	# The thing here is that when we generate qemu images and artifacts, we may opt to also copy the installer image
	# and create the disk image etc. This is the clean thing to do - but it both takes time and space.
	#: ${config_bsp__qemu_copy_installer_image_to_removable_media=false} # TODAY
	: ${config_bsp__qemu_copy_installer_image_to_removable_media=true}	 # TODAY

	: ${config_imager__workdir_ext_partition_images=${TMP_TOP}/staging/wip-images}
	
	: ${BUILD_IMAGE_VERSION=aug16-build-image-version}	# the dependent (in next lines) will be overridden
	: ${config_imager__version=$BUILD_IMAGE_VERSION}	# identical to BUILD_IMAGE_VERSION
	: ${config_imager__workdir=${preferred_tmp_top}/staging/installer_fs_workdir}	# The file system contents of the installation media and the OTA tarball will be populated here
	: ${config_imager__workdir_compressed=${preferred_tmp_top}/staging/${BUILD_IMAGE_VERSION}.tar.xz} # this is overridden
	: ${config_imager__recovery_tarball=$config_imager__workdir_compressed}
	: ${config_imager__installer_workdir="${preferred_tmp_top}/staging/installer-workdir"}

	# Useful for staging while working on more installer features. So far, all we need is in the main image so delete them most probably
	# : ${config_imager__staging_list_of_image_creation_scripts_to_run="make-noninstaller-storage.sh"} # scripts to run under the staging/ dir
	#: ${config_imager__staging_do_non_staging_stuff="false"} # true if you want to run the $config_imager__list_of_image_creation_scripts_to_run
	#: ${config_imager__list_of_image_creation_scripts_to_run=""} # staging - for now either installer or bootable storage, mutually exclusive	

	: ${config_imager__installer_media_size_sectors=$((6*$SECTORS_PER_GIB))}

}

#-----------------------------------------------------------------------------
# This can be useful in a wrapper as it can help saving a lot of time for some tasks. 
# It also contains the template example for only building rootfs caches 
# (without anything else. TODO: could make a similar mechanism for the rest of the projects. For kernel/busybox/U-Boot/EDK2 it's relatively simple. For some projects it's a bit more complex 
#-----------------------------------------------------------------------------
override_buildtasks_variables() {
	: ${config_buildtasks__do_build_ramdisk=true} # without it there is no size estimate for the live installer	
	: ${config_buildtasks__do_build_kernel_modules=true}
	: ${config_buildtasks__do_build_kernel=true}
	: ${config_buildtasks__do_build_rootfs=true}
	: ${config_buildtasks__do_build_rootfs_caches_and_quit=false}
	: ${config_buildtasks__do_pack_images=true}

	# Note that this build task has also been defined in the build system - but that is not the best thing to do. may be cleaned up in time
	if [ "${config_buildtasks__do_build_rootfs_caches_and_quit}" = "true" ] ; then
		if [ ! "${config_distro}" = "pscg_debos" ] ; then
			fatalError "config_buildtasks__do_build_rootfs_caches_and_quit is set to true, but the distro is not pscg_debos. Exiting."
		fi
		# This is a special case where we just want to build the rootfs caches, and not the kernel or modules
		config_buildtasks__do_build_rootfs=true # will actually only do the prepass
		config_buildtasks__do_build_kernel=false
		config_buildtasks__do_build_kernel_modules=false
		config_buildtasks__do_build_ramdisk=false
		config_buildtasks__do_pack_images=false
	fi

}


# NOTE: for lxqt with install recommends (without it's ~600-700MB, but does not have x11-dbus, and quite a few other things), even 400GB --> factor of 10.15 --> ~3.7GB is not enough.
#   	    lxqt warns it requires:
#   	    	Need to get 691 MB/696 MB of archives.
#	     	After this operation, 2545 MB of additional disk space will be used.
#	    and indeed, after installation you see:
#	    	after-installing-lxqt.df:/dev/sda        5.6G  3.7G  1.9G  67% /
# 		before-installing-lxqt.df:/dev/sda       5.6G  399M  5.2G   8% /
#	Obviously, that is a lot.
#	If you don't do it non-interactively, it will ask you for your language settings for kbd etc.
#
#	Without it, you need to struggle with qt and X.
#	
#
#



override_storage_and_installer_variables_for_some_dev_speedup() {
	# If not set explicitly, for the live image part (I checked now for non staging parts)  you will see that it complains on the default which is 500.
	# A huge, graphics image, takes much more
	#: ${config_bsp__qemu_storage_device_size_mib=8000}	

	# We are creating a livecd where we just copy the system.img and pack it in the resulting image - and we don't want qemu to recreate it.
	# If we decide to create both a livecd and and installer image - we will use other variables
	# The reason for separating the livecd is that I wanted to avoid the time it takes to compress the image, which is (re)used for the OTA update.
	# Otherwise, I would make the livecd and the installer the same image (and I might do it again - I used to have this mode in the past but it was not popular with customers)
	if false ; then
	: ${config_bsp__qemu_recreate_storage_device=false}
	: ${config_bsp__qemu_storage_device_path=$config_toplevel__shared_artifacts/pscgbuildos_storage_livecd.img}
	fi

	# Ideally, with a lot of memory, this would go under /tmp. HOWEVER, in the graphics builds, /tmp/staging is 10GB, and for a 32GB RAM machine, it will be exhausted
	# using tmpfs is much faster than using storage
	# on the other hand, using storage can have an advantage of persisting after reboot (if you want to get back to your development or games, just to see your tmp files gone...)
	#: ${config_bsp__qemu_storage_device_path=${homedir}/pscgbuildos-builds/pscgbuildos_storage.img}

	# TODO:
	: '
	I think I ran from the command line (i.e NOT inside the build system)
		touch config_toplevel__shared_artifacts/$BUILD_IMAGE_VERSION
	Definitely to run the harddrive, or to only run the livecd - I will need to see about that in the runqemu!	
	$ ls -larth ~/shared_artifacts-jul/
	total 7.6M
	-rw-rw-r--  1 ron ron    0 Jul 27 19:54 todo-this-is-overridden-jul25-1-installer.img
	drwxrwxr-x  3 ron ron 4.0K Jul 27 19:54 .
	drwxrwxr-x 31 ron ron 4.0K Aug  3 19:34 runqemus
	drwxr-x--- 64 ron ron 4.0K Aug  3 22:47 ..
	-rw-rw-r--  1 ron ron 9.2M Aug  3 23:15 pscgbuildos_storage_livecd.img
	'
}




override_qemu_cmdline_variables() {
	: ${ENABLE_NETWORK=true}	# local to the helper script. At least for now. Affects runqemu parameters
	: ${ENABLE_GRAPHICS=false}	# local to the helper script. At least for now. Affects runqemu parameters

	# TODO: ran with:  config_buildtasks__do_pack_images=false config_distro__add_oot_ota_code=true config_buildtasks__do_build_rootfs=false config_pscgdebos__extra_layers_file=$PWD/more-layers.txt   ENABLE_GRAPHICS=true ENABLE_BROWSERS=true config_distro=pscg_debos config_pscgdebos__debian_or_ubuntu=debian config_pscgdebos__debian_codename=sid ARCH=i386   ./2025-aug-prep.sh 
	: ${ENABLE_SOUND=false}		# local to the helper script. At least for now. Affects runqemu parameters
	if [ "$ENABLE_GRAPHICS" = "true" ] ; then
		# set some defaults
		: ${config_bsp_qemu__devices_graphics_params="-display gtk,gl=on -device virtio-gpu -vga none"} 		# e.g.: -display gtk,gl=on -device virtio-gpu -vga none		
		# TODO: input devices don't work on the same architectures. -usbdevice tablet only works on x86_64 and i386
		# usb-mouse just doesn't work, so we use usb-tablet instead
		#: ${config_bsp_qemu__devices_input_params="-usbdevice tablet"} 	 		# e.g.: -usbdevice tablet"
		: ${config_bsp_qemu__devices_input_params="-device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0,port=1 -device usb-kbd,bus=xhci.0,port=2"} # only the x86 devices have -usbdevice tablet
		: ${config_bsp_qemu__devices_network_params_0=""}	# placeholder for more devices
		: ${config_bsp_qemu__devices_more_devices_params_0=""}	# placeholder for more devices
		: ${config_bsp_qemu__devices_more_devices_params_1=""}	# placeholder for more devices
		: ${config_bsp_qemu__kernel_cmdline=""}					# default command line - some more defaults will be appended to it unless COMPLETE_COMMAND_LINE_OVERRIDE=true
	else
		# set some defaults
		: ${config_bsp_qemu__devices_graphics_params="-display none"}
		: ${config_bsp_qemu__devices_input_params=""} 
		: ${config_bsp_qemu__devices_network_params_0=""}
		: ${config_bsp_qemu__devices_more_devices_params_0=""}
		: ${config_bsp_qemu__devices_more_devices_params_1=""}
		: ${config_bsp_qemu__kernel_cmdline=""}
	fi

	ENABLE_SOUND=true
	if [ "$ENABLE_SOUND" = "true" ] ; then
		# Intel SND device
		if [ $ARCH = "x86_64" ] || [ $ARCH = "i386" ] ; then
			# has more requirements in RISCV, and since virtio works, we don't need that
			# It does work, and it should work on all architectures. Commenting it out just because I prefer to use virtio eitherway
			# : ${config_bsp_qemu__devices_audio_params=" -device intel-hda -audio pipewire,id=snd0 -device hda-duplex"}
			config_kernel__list_of_config_overrides+=" SND_HDA_GENERIC=y"
			:
		fi

		# Virtio SND device
		config_bsp_qemu__devices_audio_params="-device virtio-sound-pci -audio pipewire,id=snd0"
		config_kernel__list_of_config_overrides+=" SND_VIRTIO=y"
		# These are the virtio sound modules that are built (we go deeper into them and some of the intel-hda modules in some of our courses)
		#  CC      sound/virtio/virtio_card.o
		#  CC      sound/virtio/virtio_chmap.o
		#  CC      sound/virtio/virtio_ctl_msg.o
		#  CC      sound/virtio/virtio_jack.o
		#  CC      sound/virtio/virtio_kctl.o
		#  CC      sound/virtio/virtio_pcm.o
		#  CC      sound/virtio/virtio_pcm_msg.o
		#  CC      sound/virtio/virtio_pcm_ops.o
	fi

	if [ "$ENABLE_NETWORK" = "true" ] ; then
		# this is an example of a common configuration. 
		# requires virtio, so if you want to have a very minimal configuration, e.g. without PCI you may want to not use it 
		# and if you want to use a tap device, you should specify other parameters and prepare your host (as we do in the PSCG 
		# Embedded Linux training when we work on the steps of building the virtual boards
		: ${config_bsp_qemu__devices_network_params_0="-netdev user,id=unet -device virtio-net,netdev=unet"}
	else
		: ${config_bsp_qemu__devices_network_params_0=""}	# placeholder for more devices
	fi

	: ${config_bsp_qemu__complete_command_line_override="false"}
	
	# Graphics definitely requires more memory than QEMU defaults. smp is nice to have
	: ${config_bsp__qemu_num_cpus="-smp 2"}					# to specify: -smp <count>
	: ${config_bsp__qemu_memory="-m 4g"}					# to specify -m <size, e.g. 4G etc.>
	#: ${config_bsp_qemu__devices_console_params="-serial mon:stdio"}		# to speficy -nographic , -serial mon:stdio etc.

	# the reason to set the following to false would be significant buildtime speedup 
	# if you just want to have a livecd but not an installer/OTA/recovery image
	: ${config_imager__create_ota_image=false}
}

override_ramdisk_variables_for_kexec_example() {
	## Commented as an example
	# export config_ramdisk__kexectools_include=true
	# src/dst - one could use, if it is QEMU, 9p mounts or attach more drives. Our solution is generic though
	#
	if [ -z "$ARCH" -a "$(uname -m)" = "x86_64" ] ; then
		config_ramdisk__more_files_to_copy_src="\
		/tmp/vmlinuz-6.14.0-15-generic /tmp/initrd.img-6.14.0-15-generic \
		/home/ron/pscgbuildos-builds/target/product/pscg_debos/build-x86_64/image_materials_workdir/installables/bootfat/bzImage \
			/home/ron/pscgbuildos-builds/target/product/pscg_debos/build-x86_64/image_materials_workdir/installables/bootfat/initramfs.cpio  \
		/home/ron/pscgbuildos-builds/target/product/pscg_debos/build-x86_64/image_materials_workdir/installables/bootfat/kernel.config	 \
		" # designed mostly to ilustrate kexec - this is a place to copy a capture kernel from

	# NOTE TO SELF: ARCH=riscv64 is broken on the kernel, because it was not adjusted to riscv.

	# The next elif's are good after a first build - because in the first one, the ramdisk does not exist there yet... 
	elif [ "$ARCH" = "riscv" ] ; then
		config_ramdisk__more_files_to_copy_src=/home/ron/pscgbuildos-builds/target/product/pscg_busyboxos/build-riscv/image_materials_workdir/installables/bootfat/
	elif [ "$ARCH" = "arm64" ] ; then
		config_ramdisk__more_files_to_copy_src=/home/ron/pscgbuildos-builds/target/product/pscg_busyboxos/build-arm64/image_materials_workdir/installables/bootfat/
	fi

	config_ramdisk__more_files_to_copy_dst="/more-kernels" # designed mostly to ilustrate kexec - this is a place to copy a capture kernel to (in the target)
	config_ramdisk__directories_to_create="/more-kernels"
}
ramdisk_exports_kexec_example() {
	# The folowing are used to copy files to the ramdisk during the course of the build, without affecting the build system
	# If things work to your satisfaction, you can generate organized reicpes or update the respective files in the build system
	export config_ramdisk__directories_to_create	# create additional directories in the ramdisk as part of a particular build
	export config_ramdisk__more_files_to_copy_src	# copy files from these locations to the ramdisk
	export config_ramdisk__more_files_to_copy_dst   # copy to this particula locatin designed mostly to ilustrate kexec - this is a place to copy a capture kernel to (in the target)
}

# essentially they set IKCONFIG IKCONFIG_PROC and CONFIG_MODULES and have comments that explain why they are needed
# I will do another kernel config pass at another time.
# I think that I made this when I used more minimal configs that build much faster, but I don't remember when and how I did it
kernel_config_demonstrations_and_i_dont_know_what_but_i_will_check() {
	config_kernel__list_of_config_overrides+="
	IKCONFIG=y
	IKCONFIG_PROC=y
	"

	# For the module examples:
	: '
	es/examples/hello-module ( 0s )
	make: Entering directory '/home/ron/pscgbuildos-builds/target/shared/src/linux-kernel-src'
	make[1]: Entering directory '/home/ron/dev/otaworkshop/PscgBuildOS/layers/common/recipes/examples/hello-module'
	***
	*** The present kernel disabled CONFIG_MODULES.
	*** You cannot build or install external modules.
	***
	'

	config_kernel__list_of_config_overrides+=" MODULES=y"


	# THESE COULD BE USEFUL FOR OTHER THINGS LATER
	bla="
	NET=y
	INET=y
	NETDEVICES=y
	VIRTIO_NET=y
	"

	#export config_kernel__list_of_config_overrides_3+="
	#VIRTUALIZATION=y
	#KVM=y
	#PARAVIRT=y
	#"

	# ARCH=aarch64 fails on the kernel build
	# so does ARCH=i686
	# --> Need to modify that properly
	# # ARCH=aarch64 fails on the kernel build
	# so does ARCH=i686
	# --> Need to modify that properly


	# PACKET solves udhcpc: socket: Address family not supported by protocol. One can live without it. UNIX is for UDS - and also, one could live without i
	#PACKET=y
	#UNIX=y
}
/
example_more_kernel_qemu_graphics_related_and_notes_about_virtiogpu() {
	config_kernel__list_of_config_overrides+=" FB=y FB_VESA=y FRAMEBUFFER_CONSOLE=y  LOGO=y  LOGO_LINUX_CLUT224=y"

	# At first I did this only for non-x86, but it's fine for all
	# Builds on i386, x86_64, arm64
	# Works on x86_64, i386, loongarch
	# With DRM=y explicitly, works also on riscv64
	#	device for loongarch:  -device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0,port=1 -device usb-kbd,bus=xhci.0,port=2
	#   # note that ports are important, otherwise only one device will work
	#   # the systemd service needs to be modified as --tty is not supported by weston 14 on loongarch64
	#   # on bookworm, e.g. for x86, they have weston 10 - and you run it with the --backend=drm-backend.so --tty 7 flags for example
	#   # One can instead revert to the terminal and run   weston -Bdrm  to veritfy that it works
	#
	# Does not build (erros like below): riscv, arm64
	# config_kernel__list_of_config_overrides+=" FB_CIRRUS=y DRM_VIRTIO_GPU=y"

	# TODO: on non x86, usb tablet on qemu doesn't wok so  we'll need to change the input params
	# I think the conig was alreay in
	config_kernel__list_of_config_overrides+=" INPUT_EVDEV=y" # required for input in weston
	:
	# doesn't help in riscv, needs more config stuff to avoid missing linkage etc.
	config_kernel__list_of_config_overrides+=" FB_CIRRUS=y DRM_VIRTIO_GPU=y"
	config_kernel__list_of_config_overrides+=" DRM=y" # Without this you will have linkage probems as stated above!
	config_kernel__list_of_config_overrides+=" DRM_FBDEV_EMULATION=y" #  This is not necessary - just for the VTs...
	#
	# 
	# iscv64-linux-gnu-ld: drivers/gpu/drm/virtio/virtgpu_drv.o: in function `virtio_gpu_remove':
	# virtgpu_drv.c:(.text+0x10): undefined reference to `drm_dev_unplug'
}

#-----------------------------------------------------------------------------
# This should not be needed anymore, as the logic is to always source, and 
# the build system itself exports everything it needs (otherwise, it is a bug and the build system should fix it. 
# it may happen, due to years of using wrappers, and never the build system directly, but I worked quite hard to prevent that, and I think I have)
#-----------------------------------------------------------------------------
wrapper_exports() {
	#REMOVEDtoplevel_exports
	#REMOVEDqemu_exports
	#REMOVEDimager_exports	
	#REMOVEDramdisk_exports		# This remains only to have a non-verbose cpio, and to not compress the cpio archive (both are intentionally not the default build system behavior)
	ramdisk_exports_kexec_example	# specific to the Kexec example at my kexec talk, May 2025
	#REMOVEDpscgdebos_exports
	busybox_exports			# This remains because the example set override_busybox_variables=true - which is the opposite of the default. It will be reomved
	kernel_exports			# This remains because this file sets config_kernel__list_of_config_overrides - it will be packaged in a specific example
	#REMOVEDdistro_reuse_exports
}

#-----------------------------------------------------------------------------
# This is where you would want to override the environment variables if you want to wrap the build-image.sh (main project) or build-pscgbuildos-image.sh (the last-line wrapper)
#-----------------------------------------------------------------------------
wrapper_override_environment_variables() {
	#REMOVEDoverride_toplevel_variables
	override_imager_variables	# this can be useful in a wrapper as it can help saving a lot of time for some tasks
	#REMOVEDoverride_ramdisk_variables
	#REMOVEDoverride_pscgdebos_variables_init_frameworks
		
	override_buildtasks_variables	# This can be useful in a wrapper as it can help saving a lot of time for some tasks. 

	: ${config_bsp__qemu_removable_media_path=$TMP_BUT_PERSISTENT_TOP/removable_media.img}


	
	override_storage_and_installer_variables_for_some_dev_speedup
	
	override_qemu_cmdline_variables

	#override_ramdisk_variables_for_kexec_example

	override_busybox_variables
	kernel_config_demonstrations_and_i_dont_know_what_but_i_will_check

	config_imager__ext_partition_system_size_scale_factor=1.35 # TODO check in other places, add export	
	
	#REMOVEDset_standard_default_values_wip
	example_more_kernel_qemu_graphics_related_and_notes_about_virtiogpu

	
	#REMOVEDset_standard_default_values_distro_reuse

	# one could select to set the partition sizes or scale factors by the distro - we'll look at it later
	if [ "$distro" = "pscg_debos" ] ; then
		:  # export config_imager__ext_partition_system_size_scale_factor=1.15 
	fi

	# just for now while testing, to stop. easily removed, will be removed
	# [ -t 0 ] && [ "$AUTO_CONFIRM_BUILD" = "true" ] && read -p "Press enter to continue with the build-debos-image.sh script"
}

#-------------------------------------------------------------------
# A template example of a wrapper, should you want to use it
#-------------------------------------------------------------------
wrapper_main() {
	MAIN_HELPER_SCRIPT=./build-pscgbuildos-image.sh
	. $MAIN_HELPER_SCRIPT || { echo "Failed to source $MAIN_HELPER_SCRIPT"; exit 1; }
	init_main_builder_env
	
	wrapper_override_environment_variables "$@"
	wrapper_exports		# this should not be called as all exports should be done in the build system itself but we still need to organize that and that will be a lot of changes

	# Call the main function of the main helper script
	main "$@"
}

wrapper_main "$@"
