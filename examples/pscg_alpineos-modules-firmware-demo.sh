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
NEXT_WRAPPER_SCRIPT=./wip-2-wrapper.sh  # Allow easy chaining of a subsequent script
: ${ARCH=x86_64}

export ARCH
export config_distro__extra_layers
config_distro__extra_layers+=" /home/ron/dev/otaworkshop/PscgBuildOS-extra-layers/examples/bsp/realtek/8821cu"
config_distro__extra_layers+=" /home/ron/dev/otaworkshop/PscgBuildOS-extra-layers/examples/basic-examples/"

config_buildtasks__do_build_kernel=true config_bsp__qemu_livecd_extract_system_overlays_into_live_image=true  config_distro=pscg_alpineos BUILD_IMAGE_VERSION=stamtest  $NEXT_WRAPPER_SCRIPT buildall

