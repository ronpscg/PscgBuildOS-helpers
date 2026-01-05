# PscgBuildOS-helpers

This repository contains some helper scripts for building [*PscgbuildOS*](https://github.com/ronpscg/PscgBuildOS)* using its build system entry point, `build-image.sh`.
The scripts are constantly changing, and unless someone really wants to clean them up, they are considered WIP.
This repository is published only to help those who first got exposure to the build system via the public meetups and talks (the repos from the PSCG training, and customer projects are different, but not too different), and you are welcome to add more documentation, and more scripts, as well as suggest alternative organization. If you do so - please prove significant amount of testing.
Otherwise, I will do do it myself at some point, but it took me so many years to publish this (you can't imagine, and I definitely could not imagine, how complicated it can be to separate 90% of the work you want to publish from the 10% you can't - especially when everything is written in bash).

Given the mass amounts of videos using and explaining the build system in my Youtube channel, I am not in a hurry to change script names that have been in use there. So the name of the scripts and the dates in them are quite insignificant.

In addition, there is a lot of redunancy in the variables among the scripts. It can, and should be cleaned up, and its is published the way it is published, simply because it would never be published otherwise.

**NOTE:** The aforementioned *URL* for *PscgBuildOS* refers to the public open sourced project. The documentation applies for whatever version you have either as part of The PSCG training, or as part of common and private work. If you are not sure what to use (and you have access to public repos) just ask Ron Munitz,

## Some script usage/inclusion

This is a typical usage example of the scripts, as per now. The names are merely examples. `-->` means *sources* .
The main script in the *PscgBuildOS* project (referred to as `BUILD_TOP`), is `build-image.sh`.
```bash
wrapper-all-archs.sh
--> ./qemu-2-wrapper.sh $build_tasks
  --> . ./qemu-1-wrapper.sh
    --> . /build-pscgbuildos-image.sh ( aka the MAIN_HELPER_SCRIPT --> main() there is called)
      --> . $BUILD_TOP/build-image.sh

```

Some more details:
- [qemu-2-wrapper.sh](qemu-2-wrapper.sh) is a script that groups several defaults and logics, and gets a *buildtask* to do as an argument. That could be:
  - `buildall`
  - `ramdisk-only`
  - `ramdisk-kernel`

## Usage Examples

```bash
ENABLE_GRAPHICS=true config_distro=pscg_debos config_pscgdebos__debian_or_ubuntu=debian config_pscgdebos__debian_codename=bookworm ARCH=x86_64  ./qemu-1-wrapper.sh
```

Another example with an intended caveat:
```bash
config_buildtasks__do_pack_images=false config_distro__add_oot_ota_code=true config_buildtasks__do_build_rootfs=true config_pscgdebos__extra_layers_file=$PWD/more-layers/more-layers.txt   ENABLE_GRAPHICS=true ENABLE_BROWSERS=true config_distro=pscg_debos config_pscgdebos__debian_or_ubuntu=debian config_pscgdebos__debian_codename=trixie ARCH=i386   ./qemu-1-wrapper.sh
```

Running something like this would result (as per the time of writing) in an error like this - because of the *explicit* `config_buildtasks__do_pack_images` skipping!:
```
cp: cannot stat '/home/ron/shared_artifacts-jul/aug16-build-image-version-installer.img': No such file or directory
25-12-26 21:43:50 common-qemu: [generate-qemu-scripts.sh:] Failed to cp /home/ron/shared_artifacts-jul/aug16-build-image-version-installer.img /home/ron/tmp-but-persistent/PscgBuildOS/removable_media.img /home/ron/dev/otaworkshop/PscgBuildOS/layers/bsp/recipes/linux/common-qemu/generate-qemu-scripts.sh FAILED ( 9s)
Backtrace:
```

The takeaway here is simple - if you modify build parameters - be ready to handle the consequences, or know what you are doing. In other words - read the code if you use it - it was made (or at least was made public) for you to learn! :-)

## General tips
Familiarize yourself with the different images and parameters. Everything is in the build-system itself, but a lot of things are documented with full examples in the scripts in this repo. They are the documentation, not this *README.md* file, and the documentation there is very extensive and clear!

Other than that, there are some things we provided to avoid giving automatic examples for, so that you will not have huge sizes. Once you start building your installers and disk images, you may want to exaggerate,
to prevent running out of space. Some examples are in the scripts. Others, that have not failed to date (but are very wasteful in terms of disk space, and copying and flashing times) are:
```
    : ${config_imager__installer_media_size_sectors=$((6*1024*1024*1024))}  # That's 6 GB... the default installer size is 2GB
    : ${config_imager__ext_partition_system_size_scale_factor=1.35}         # that's adding more than 1/3 of the system.img
```

While it is strongly discouraged to use such values, it can be useful for you if you don't care about disk space or your time, and it is super useful as you start experimenting, as your first build will use
the latest versions of the upstream components (Linux kernel, rootfs, etc.), and things can change! In addition, smaller limits were *deliberately* introduced in the build system itself, to assure that
it is not wasteful, and that the developer (builder) knows what they are doing, and optimizes their parameters accordingly, without forcing exaggerated values on the build sytem itself.

## More scripts (partial list of examples)
- [pscg_alpineos-modules-firmware-demo.sh](pscg_alpineos-modules-firmware-demo.sh) concludes a list of important videos (see links in the file and in the Youtube channel) explaining how to add drivers and firmware to  pscg_alpineos, also nicely explaining how to include more layers in the build
- [reuse-example-alpineos.sh](reuse-example-alpineos.sh) - shows how to reuse materials from previous builds. I have not revisited it lately. The idea and explanations are covered fully in https://www.youtube.com/watch?v=JKlz2s47E9s&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=108 
- [examples-arch-subarch.sh](examples-arch-subarch.sh) - shows how to build separately for *armel* (*Debian, Busybox) *armv7l* (Alpine) as opposed to the default *armhf* variant for *arm*
