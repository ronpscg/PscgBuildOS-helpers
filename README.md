# PscgBuildOS-helpers

This repository contains some helper scripts for building *PscgbuildOS* using its build system entry point, `build-image.sh`.
The scripts are constantly changing, and unless someone really wants to clean them up, they are considered WIP.
This repository is published only to help those who first got exposure to the build system via the public meetups and talks (the repos from the PSCG training, and customer projects are different, but not too different), and you are welcome to add more documentation, and more scripts, as well as suggest alternative organization. If you do so - please prove significant amount of testing.
Otherwise, I will do do it myself at some point, but it took me so many years to publish this (you can't imagine, and I definitely could not imagine, how complicated it can be to separate 90% of the work you want to publish from the 10% you can't - especially when everything is written in bash).

Given the mass amounts of videos using and explaining the build system in my Youtube channel, I am not in a hurry to change script names that have been in use there. So the name of the scripts and the dates in them are quite insignificant.

In addition, there is a lot of redunancy in the variables among the scripts. It can, and should be cleaned up, and its is published the way it is published, simply because it would never be published otherwise.

## Some script usage/inclusion

This is a typical usage example of the scripts, as per now. The names are merely examples. `-->` means *sources* .
The main script in the *PscgBuildOS* project (referred to as `BUILD_TOP`), is `build-image.sh`.
```bash
wrapper-all-archs.sh
--> ./aug18-wrapper.sh $build_tasks
  --> . ./2025-aug-prep.sh
    --> . /build-pscgbuildos-image.sh ( aka the MAIN_HELPER_SCRIPT --> main() there is called)
      --> . $BUILD_TOP/build-image.sh

```

Some more details:
- [aug18-wrapper.sh](aug18-wrapper.sh) is a script that groups several defaults and logics, and gets a *buildtask* to do as an argument. That could be:
  - `buildall`
  - `ramdisk-only`
  - `ramdisk-kernel`


## Usage Examples

```bash
ENABLE_GRAPHICS=true config_distro=pscg_debos config_pscgdebos__debian_or_ubuntu=debian config_pscgdebos__debian_codename=bookworm ARCH=x86_64  ./2025-aug-prep.sh 
```

Another example with an intended caveat:
```bash
config_buildtasks__do_pack_images=false config_distro__add_oot_ota_code=true config_buildtasks__do_build_rootfs=true config_pscgdebos__extra_layers_file=$PWD/more-layers/more-layers.txt   ENABLE_GRAPHICS=true ENABLE_BROWSERS=true config_distro=pscg_debos config_pscgdebos__debian_or_ubuntu=debian config_pscgdebos__debian_codename=trixie ARCH=i386   ./2025-aug-prep.sh
```

Running something like this would result (as per the time of writing) in an error like this - because of the *explicit* `config_buildtasks__do_pack_images` skipping!:
```
cp: cannot stat '/home/ron/shared_artifacts-jul/aug16-build-image-version-installer.img': No such file or directory
25-12-26 21:43:50 common-qemu: [generate-qemu-scripts.sh:] Failed to cp /home/ron/shared_artifacts-jul/aug16-build-image-version-installer.img /home/ron/tmp-but-persistent/PscgBuildOS/removable_media.img /home/ron/dev/otaworkshop/PscgBuildOS/layers/bsp/recipes/linux/common-qemu/generate-qemu-scripts.sh FAILED ( 9s)
Backtrace:
```

The takeaway here is simple - if you modify build parameters - be ready to handle the consequences, or know what you are doing. In other words - read the code if you use it - it was made (or at least was made public) for you to learn! :-)

## More scripts (partial list of examples)
- [pscg_alpineos-modules-firmware-demo.sh](pscg_alpineos-modules-firmware-demo.sh) concludes a list of important videos (see links in the file and in the Youtube channel) explaining how to add drivers and firmware to  pscg_alpineos, also nicely explaining how to include more layers in the build
- [reuse-example-alpineos.sh](reuse-example-alpineos.sh) - shows how to reuse materials from previous builds. I have not revisited it lately. The idea and explanations are covered fully in https://www.youtube.com/watch?v=JKlz2s47E9s&list=PLBaH8x4hthVysdRTOlg2_8hL6CWCnN5l-&index=108 
