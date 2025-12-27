UP - 19
DOWN - 16

BUILD_IMAGE_VERSION - appears in both
BUILD_IMAGE_VERSION depdendent files are
- config_imager__installer_image_file - that's the USB image (the installer image)
- config_imager__recovery_tarball     - that's the recovery tarball, which is identical to the OTA tarball
- config_imager__workdir_compressed   - that's the OTA tarball


BUILD_OUT is the top most build - but not for the caches and not for the others. The others:
aug19-pscgbuildos
------------------
- build
- artifacts
- tmp-but-persistent


- tmp and build are created at the beginning of the build
- tmp-but-persistent and artifacts are created at the end of the build, when preparing the different images


drwxrwxr-x  3 ron ron 4096 Dec 27 12:26 tmp
drwxrwxr-x  3 ron ron 4096 Dec 27 12:26 build
drwxrwxr-x  3 ron ron 4096 Dec 27 12:32 tmp-but-persistent
drwxrwxr-x  6 ron ron 4096 Dec 27 12:32 .
drwxrwxr-x  3 ron ron 4096 Dec 27 12:33 artifacts



tmp/
--------------
tmp has:
- The build log
- oot-build (e.g. ota tarball, other tarballs that are to be overlaid (TODO check that statement)
- wip-images (check statement later as well) 

``
ron@ronmsi:~$ tree aug19-pscgbuildos/tmp/PscgBuildOS/
aug19-pscgbuildos/tmp/PscgBuildOS/
├── aug18-wrapper.log
├── oot-build
│   ├── ota-targetfiles
│   │   ├── etc
│   │   │   ├── systemd
│   │   │   │   └── system
│   │   │   │       └── ota.service
│   │   │   └── update-motd.d
│   │   │       └── 01-versions-and-stats
│   │   ├── opt
│   │   │   ├── ota
│   │   │   │   ├── otaCommon.sh
│   │   │   │   ├── ota-richos-defs.sh
│   │   │   │   ├── ota-state-machine.sh
│   │   │   │   ├── ota-test-reflashed-images-on-system.sh
│   │   │   │   ├── ota-update.sh
│   │   │   │   └── test
│   │   │   │       ├── reflash-extracted.sh
│   │   │   │       └── reset-state.sh
│   │   │   └── scripts
│   │   │       ├── bash-utils.sh
│   │   │       ├── commonEnv.sh
│   │   │       └── utils.sh
│   │   └── overlay-install-instructions.sh
│   └── ota-targetfiles-tarball.tar.xz
└── staging-x86_64
    └── wip-images
        └── system.img
``
13 directories, 16 files

``
$ tree aug19-pscgbuildos/tmp-but-persistent/
aug19-pscgbuildos/tmp-but-persistent/
└── PscgBuildOS
    ├── removable_media-x86_64.img
    ├── staging
    │   ├── aug19_busyboxos_image_2308-x86_64.tar.xz
    │   ├── aug19_busyboxos_image_2308-x86_64.tar.xz.digest
    │   └── aug19_busyboxos_image_2308-x86_64.tar.xz.manifest
    └── staging-x86_64
        └── installer_fs_workdir
            ├── autoflash
            ├── bzImage
            ├── initramfs.cpio
            ├── installables
            │   ├── bootfat
            │   │   ├── bzImage
            │   │   ├── initramfs.cpio
            │   │   └── kernel.config
            │   ├── ext4images
            │   │   └── system.img
            │   └── overlays
            │       └── system
            │           └── ota-targetfiles-tarball.tar.xz
            └── kernel.config

10 directories, 13 files
``



======================================================================================================

BUILD_IMAGE_VERSION: aug19_busyboxos_image_2308-x86_64
config_imager__installer_image_file:	/home/ron/aug19-pscgbuildos/artifacts/aug19_busyboxos_image_2308-x86_64-installer.img
config_imager__recovery_tarball:	/home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging/aug19_busyboxos_image_2308-x86_64.tar.xz
config_imager__workdir_compressed:	/home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging/aug19_busyboxos_image_2308-x86_64.tar.xz


pscgbuildos-build-caches-host
---------------------------------
config_toplevel__caches_base_path: 		/home/ron/pscgbuildos-build-caches-host/host/caches_dir
config_toplevel__caches_workdir_base_path: 	/home/ron/pscgbuildos-build-caches-host/host/caches_workdir
config_toplevel__downloads_base_path: 		/home/ron/pscgbuildos-build-caches-host/host/downloads_dir


BUILD_SHARED_ARCH_DIR: 				/home/ron/aug19-pscgbuildos/build/target/shared/arch/x86_64
BUILD_SHARED_ARCH_SUBARCH_DIR: 			/home/ron/aug19-pscgbuildos/build/target/shared/arch/x86_64
BUILD_SHARED_SRC_DIR: 				/home/ron/aug19-pscgbuildos/build/target/shared/src


BUILD_DIR: 				   /home/ron/aug19-pscgbuildos/build/target/product/pscg_busyboxos/build-x86_64
BUILD_OUT: 				   /home/ron/aug19-pscgbuildos/build
config_bsp__qemu_removable_media_path: 	   /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/removable_media-x86_64.img
config_imager__installer_image_file: 	   /home/ron/aug19-pscgbuildos/artifacts/aug19_busyboxos_image_2308-x86_64-installer.img
config_imager__recovery_tarball: 	   /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging/aug19_busyboxos_image_2308-x86_64.tar.xz
config_imager__workdir: 		   /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging-x86_64/installer_fs_workdir
config_imager__workdir_compressed: 	   /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging/aug19_busyboxos_image_2308-x86_64.tar.xz
config_toplevel__product_build_dir_prefix: /home/ron/aug19-pscgbuildos/build/target/product/pscg_busyboxos/build
config_toplevel__shared_artifacts: 	   /home/ron/aug19-pscgbuildos/artifacts




====================================================================================================================================================
BUILD_DIR: /home/ron/aug19-pscgbuildos/build/target/product/pscg_busyboxos/build-x86_64

BUILD_IMAGE_VERSION: aug19_busyboxos_image_2308-x86_64

BUILD_OUT: /home/ron/aug19-pscgbuildos/build

config_bsp__qemu_removable_media_path: /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/removable_media-x86_64.img

config_imager__installer_image_file: /home/ron/aug19-pscgbuildos/artifacts/aug19_busyboxos_image_2308-x86_64-installer.img

config_imager__recovery_tarball: /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging/aug19_busyboxos_image_2308-x86_64.tar.xz

config_imager__workdir: /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging-x86_64/installer_fs_workdir

config_imager__workdir_compressed: /home/ron/aug19-pscgbuildos/tmp-but-persistent/PscgBuildOS/staging/aug19_busyboxos_image_2308-x86_64.tar.xz

config_toplevel__caches_base_path: /home/ron/pscgbuildos-build-caches-host/host/caches_dir

config_toplevel__caches_workdir_base_path: /home/ron/pscgbuildos-build-caches-host/host/caches_workdir

config_toplevel__downloads_base_path: /home/ron/pscgbuildos-build-caches-host/host/downloads_dir

config_toplevel__product_build_dir_prefix: /home/ron/aug19-pscgbuildos/build/target/product/pscg_busyboxos/build

config_toplevel__shared_artifacts: /home/ron/aug19-pscgbuildos/artifacts

BUILD_SHARED_ARCH_DIR: /home/ron/aug19-pscgbuildos/build/target/shared/arch/x86_64
BUILD_SHARED_ARCH_SUBARCH_DIR: /home/ron/aug19-pscgbuildos/build/target/shared/arch/x86_64
BUILD_SHARED_SRC_DIR: /home/ron/aug19-pscgbuildos/build/target/shared/src

