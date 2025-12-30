#!/bin/bash

override_buildtasks_variables() {
	:
}


#-------------------------------------------------------------
# This should be optional, and give you ideas. Do not enable
# the things here before you have had experience with the 
# build system
#-------------------------------------------------------------
override_storage_and_installer_variables_for_some_dev_speedup() {
	# the reason to set the following to false would be significant buildtime speedup 
	# if you just want to have a livecd but not an installer/OTA/recovery image
	# This is what simple_dev_optimization_4 in the last-line script does if enabled
	: ${config_imager__create_ota_image=false}

	# We are creating a livecd where we just copy the system.img and pack it in the resulting image - and we don't want qemu to recreate it.
	# If we decide to create both a livecd and and installer image - we will use other variables
	# The reason for separating the livecd is that I wanted to avoid the time it takes to compress the image, which is (re)used for the OTA update.
	# Otherwise, I would make the livecd and the installer the same image (and I might do it again - I used to have this mode in the past but it was not popular with customers)
	# This is what simple_dev_optimization_2 in the last-line script does if enabled
	: ${config_bsp__qemu_recreate_storage_device=false}
	
	# Ideally, with a lot of memory, this would go under /tmp. HOWEVER, in the graphics builds, /tmp/staging is 10GB, and for a 32GB RAM machine, it will be exhausted
	# using tmpfs is much faster than using storage
	# on the other hand, using storage can have an advantage of persisting after reboot (if you want to get back to your development or games, just to see your tmp files gone...)
	#: ${config_bsp__qemu_storage_device_path=${homedir}/pscgbuildos-builds/pscgbuildos_storage.img}

	# The next comments are relevant, but perhaps better left out of this section
	# Image size can also affect the build time, if we allocate a huge disk (for some systems that do not behave nicely with sparse files)
	# If not set explicitly, for the live image part (I checked now for non staging parts)  you will see that it complains on the default which is 500.
	# A huge, graphics image, takes much more
	#: ${config_bsp__qemu_storage_device_size_mib=8000}	

}

#---------------------------------------------------------------------------------------------------------
# Features may affect your packages, kernel and QEMU command line, obviously image sizes, and more
# In this example, all of the listed variables have effect in QEMU in all distros (all with default
# sets of parameters that you can change, this is an example), because:
# 1. ENABLE_NETWORK enables network devices in QEMU
# 2. ENABLE_GRAPHICS enables a display and DRM (and in pscg_debos can affect selecting display managers...)
# 3. ENABLE_SOUND enables sound devices in QEMU, which are noticable in the initramfs (ramdisk) as well.
#---------------------------------------------------------------------------------------------------------
override_default_features() {
	: ${ENABLE_NETWORK=true}
	: ${ENABLE_GRAPHICS=true}
	: ${ENABLE_SOUND=true}
}


#----------------------------------------------------------------------------------------------------------
# Decide set of QEMU command line parameters, according to the selected features
#----------------------------------------------------------------------------------------------------------
override_qemu_cmdline_variables() {
	if [ "$ENABLE_GRAPHICS" = "true" ] ; then
		# set some defaults
		: ${config_bsp_qemu__devices_graphics_params="-display gtk,gl=on -device virtio-gpu -vga none"}
		# note that some input devices don't work on some architectures in some versions
		: ${config_bsp_qemu__devices_input_params="-device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0,port=1 -device usb-kbd,bus=xhci.0,port=2"}
		: ${config_bsp_qemu__devices_network_params_0=""}	# placeholder for more devices
		: ${config_bsp_qemu__devices_more_devices_params_0=""}	# placeholder for more devices
		: ${config_bsp_qemu__devices_more_devices_params_1=""}	# placeholder for more devices
		: ${config_bsp_qemu__kernel_cmdline=""}			# default command line - some more defaults will be appended to it unless config_bsp_qemu__complete_command_line_override=true
	else
		# set some defaults
		: ${config_bsp_qemu__devices_graphics_params="-display none"}
		: ${config_bsp_qemu__devices_input_params=""} 
		: ${config_bsp_qemu__devices_network_params_0=""}
		: ${config_bsp_qemu__devices_more_devices_params_0=""}
		: ${config_bsp_qemu__devices_more_devices_params_1=""}
		: ${config_bsp_qemu__kernel_cmdline=""}
	fi

	if [ "$ENABLE_SOUND" = "true" ] ; then
		# Intel SND device
		if [ $ARCH = "x86_64" ] || [ $ARCH = "i386" ] ; then
			# has more requirements in RISCV, and since virtio works, we don't need that
			# It does work, and it should work on all architectures. Commenting it out just because I prefer to use virtio eitherway
			# : ${config_bsp_qemu__devices_audio_params=" -device intel-hda -audio pipewire,id=snd0 -device hda-duplex"}
			:
		fi

		# Virtio SND device
		config_bsp_qemu__devices_audio_params="-device virtio-sound-pci -audio pipewire,id=snd0"
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

	
	# Graphics definitely requires more memory than QEMU defaults. smp is nice to have
	: ${config_bsp__qemu_num_cpus="-smp 2"}					# to specify: -smp <count>
	: ${config_bsp__qemu_memory="-m 4g"}					# to specify -m <size, e.g. 4G etc.>
	#: ${config_bsp_qemu__devices_console_params="-serial mon:stdio"}	# to speficy -nographic , -serial mon:stdio etc.
}

kernel_config_basic_demonstrations() {
	config_kernel__list_of_config_overrides+=" IKCONFIG=y IKCONFIG_PROC=y"
	config_kernel__list_of_config_overrides+=" MODULES=y"
	: ${config_bsp_qemu__complete_command_line_override="false"}
}


#----------------------------------------------------------------------------------------------------------
# Decide set of Linux kernel command line parameters, according to the selected features
#----------------------------------------------------------------------------------------------------------
kernel_config_qemu_graphics_audio_and_peripherals_demonstrations() {
	if [ "$ENABLE_GRAPHICS" = "true" ] ; then
		config_kernel__list_of_config_overrides+=" FB=y FB_VESA=y FRAMEBUFFER_CONSOLE=y  LOGO=y  LOGO_LINUX_CLUT224=y"
		config_kernel__list_of_config_overrides+=" INPUT_EVDEV=y" # required for input in weston
	
		config_kernel__list_of_config_overrides+=" FB_CIRRUS=y DRM_VIRTIO_GPU=y"
		config_kernel__list_of_config_overrides+=" DRM=y"
		config_kernel__list_of_config_overrides+=" DRM_FBDEV_EMULATION=y" #  This is not necessary - just for the VTs...
	fi

	if [ "$ENABLE_SOUND" = "true" ] ; then
		# Intel SND device
		if [ $ARCH = "x86_64" ] || [ $ARCH = "i386" ] ; then
			# We don't need this if we use virtio, but it's a small addition, doesn't hurt, and if virtio doesn't work on some kernels (< v5.13), this should still work
			config_kernel__list_of_config_overrides+=" SND_HDA_GENERIC=y"
		fi

		# Virtio SND device
		config_kernel__list_of_config_overrides+=" SND_VIRTIO=y"
	fi

}

override_kernel_configs() {
	kernel_config_basic_demonstrations
	kernel_config_qemu_graphics_audio_and_peripherals_demonstrations
}

#-----------------------------------------------------------------------------
# This is not needed anymore, as the logic is to always source, and 
# the build system itself exports everything it needs (otherwise, it is a bug and the build system should fix it
# it may happen, due to years of using wrappers, and never the build system directly, but I worked quite hard to prevent that, and I think I have)
#-----------------------------------------------------------------------------
wrapper_exports() {
	:
}

#-----------------------------------------------------------------------------
# This is where you would want to override the environment variables if you want to wrap the build-image.sh (main project) or build-pscgbuildos-image.sh (the last-line wrapper)
#-----------------------------------------------------------------------------
wrapper_override_environment_variables() {
	override_default_features					# This can be used to control some features that the built device has or doesn't
	override_buildtasks_variables					# This can be useful in a wrapper as it can help saving a lot of time for some tasks. 
	override_qemu_cmdline_variables					# Examples of useful QEMU command line modifications
	override_kernel_configs 					# Examples of useful Linux kernel command line modifications
	#override_storage_and_installer_variables_for_some_dev_speedup	# NOTE: even if this is completely commented out - the comments there are useful. You have more of those in the example in build-pscgbuildos-image.sh
	
	if [ "$distro" = "pscg_debos" ] ; then
		# one could select to set the disk image size, partition sizes or scale factors by the distro
		# This example will not set anything by default, just show an example. Another exapmle that sources this file (directly or indirectly) will be provided
		# : ${config_imager__ext_partition_system_size_scale_factor=1.35}
		# : ${config_bsp__qemu_storage_device_size_mib=8000}
		:
	fi

	# just for now while testing, to stop. easily removed, will be removed
	# [ -t 0 ] && [ "$AUTO_CONFIRM_BUILD" = "true" ] && read -p "Press enter to continue with the $MAIN_HELPER_SCRIPT script"
}

#-------------------------------------------------------------------
# A template example of a wrapper, should you want to use it
#-------------------------------------------------------------------
wrapper_main() {
	#
	# The MAIN_HELPER_SCRIPT will put the minimal additions that are reasonable to always include when you work a lot with the build system,
	# on top of the build system entry point which is stand-alone, and does not require any wrappers, which is $BUILD_TOP/build-image.sh
	# We first initialize its environment, to have the log available early, for example. Then, we add our logic (documented further down this function),
	# and then we call the MAIN_HELPER_SCRIPT's main() function, which in turn sources $BUILD_TOP/build-image.sh and invokes the build system
	#
	MAIN_HELPER_SCRIPT=./build-pscgbuildos-image.sh
	. $MAIN_HELPER_SCRIPT || { echo "Failed to source $MAIN_HELPER_SCRIPT"; exit 1; }
	init_main_builder_env
	#
	# This is where most of your code or modifications would go
	#
	wrapper_override_environment_variables "$@"
	#	
	# wrapper_exports is optional and the function would usually do nothing as the build system should export everything that is 
	# necessary for its components (and if not, or you add some new features, you need to be mindful of that and fix it!)
	#
	wrapper_exports 

	#
	# Call the main function of the main helper script
	#
	main "$@"
}

wrapper_main "$@"
