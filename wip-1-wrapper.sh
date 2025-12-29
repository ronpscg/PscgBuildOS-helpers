#!/bin/bash
#
# The objective of this function is to be very clear on what is exported, before setting default variables
#

override_buildtasks_variables() {
	:
}


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

# essentially they set IKCONFIG IKCONFIG_PROC and CONFIG_MODULES and have comments that explain why they are needed
# I will do another kernel config pass at another time.
# I think that I made this when I used more minimal configs that build much faster, but I don't remember when and how I did it
kernel_config_demonstrations_and_i_dont_know_what_but_i_will_check() {
	config_kernel__list_of_config_overrides+=" IKCONFIG=y IKCONFIG_PROC=y"
	config_kernel__list_of_config_overrides+=" MODULES=y"
}

example_more_kernel_qemu_graphics_related_and_notes_about_virtiogpu() {
	config_kernel__list_of_config_overrides+=" FB=y FB_VESA=y FRAMEBUFFER_CONSOLE=y  LOGO=y  LOGO_LINUX_CLUT224=y"
	config_kernel__list_of_config_overrides+=" INPUT_EVDEV=y" # required for input in weston
	
	config_kernel__list_of_config_overrides+=" FB_CIRRUS=y DRM_VIRTIO_GPU=y"
	config_kernel__list_of_config_overrides+=" DRM=y" # Without this you will have linkage probems as stated above!
	config_kernel__list_of_config_overrides+=" DRM_FBDEV_EMULATION=y" #  This is not necessary - just for the VTs...
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
	override_buildtasks_variables	# This can be useful in a wrapper as it can help saving a lot of time for some tasks. 

	override_storage_and_installer_variables_for_some_dev_speedup # TODO: this is completely commented out - but the comments there are useful. 
	
	override_qemu_cmdline_variables

	kernel_config_demonstrations_and_i_dont_know_what_but_i_will_check
	
	example_more_kernel_qemu_graphics_related_and_notes_about_virtiogpu

	

	# one could select to set the partition sizes or scale factors by the distro - we'll look at it later
	if [ "$distro" = "pscg_debos" ] ; then
		:  # export config_imager__ext_partition_system_size_scale_factor=1.15 
	fi

	# just for now while testing, to stop. easily removed, will be removed
	# [ -t 0 ] && [ "$AUTO_CONFIRM_BUILD" = "true" ] && read -p "Press enter to continue with the $MAIN_HELPER_SCRIPT script"
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
