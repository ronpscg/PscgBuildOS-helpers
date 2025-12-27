#!/bin/bash
#
# This script is an example of integrating the 8821cu necessary software and firmware and the hello kernel module, for a pscg_alpineos distro.
#
# The script demonstrates a concise and cleaned up example of the contents shown at https://www.youtube.com/watch?v=WfoMf0H3Hag&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=113 and the videos that preceded it
# The videos that preceded it are:
# - https://www.youtube.com/watch?v=Y6BKlzAHRsM&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=109 (Adding WiFi)
# - https://www.youtube.com/watch?v=nxNWKX9sSCA&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=110 (adding Bluetooth)
# - https://www.youtube.com/watch?v=WJzppdaqk0Y&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=111 (adding firmware directly to the kernel builtin)
# - https://www.youtube.com/watch?v=Ns-gvGooBrc&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=112 (controlling what goes where firmware and modules wise - builtin, initramfs, rootfs)
# - https://www.youtube.com/watch?v=WfoMf0H3Hag&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=113 (The creation of the layer [which has been updated since putting it])

LOCAL_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
cd $LOCAL_DIR/.. # work on the helpers main directory (cleanup example)
NEXT_WRAPPER_SCRIPT=./qemu-2-wrapper.sh  # Allow easy chaining of a subsequent script
: ${ARCH=x86_64}

override_ext_partition_system_params() {
	# Sizing examples - all numbers here can change accordign to the rootfs build version and Linux kernel version, so you may want to experiment and adjust accordingly
	# It is important to either specify the scale factor, or specify the minimal image size. 
	# You can specify both, but you would almost always want to specify one or use the build-system defaults if you know the sizes.
	# If you underestimate your minimum size - the scale factor will be used. For example, the current alpine Image is almost 30MB. If we set it to 20MB - the scale factor will be used
	# In the same example, a scale factor of 1.07 or 1.10 will likely not do for the file system itself
	# For the kernel modules, and extracting them into the system partition as a livecd - even 1.15 won't do 
	: ${config_imager__ext_partition_system_size_scale_factor=1.20}
	export config_imager__ext_partition_system_size_scale_factor
	: ${config_imager__ext_partition_system_minimum_size_bytes=$((20*1024*1024))}
	export config_imager__ext_partition_system_minimum_size_bytes
}



main() {
	export ARCH
	export config_distro__extra_layers
	config_distro__extra_layers+=" /home/ron/dev/otaworkshop/PscgBuildOS-extra-layers/examples/bsp/realtek/8821cu"
	config_distro__extra_layers+=" /home/ron/dev/otaworkshop/PscgBuildOS-extra-layers/examples/basic-examples/"
	override_ext_partition_system_params
	config_buildtasks__do_build_kernel=true config_bsp__qemu_livecd_extract_system_overlays_into_live_image=true  config_distro=pscg_alpineos BUILD_IMAGE_VERSION=stamtest  $NEXT_WRAPPER_SCRIPT buildall
}

main $@
