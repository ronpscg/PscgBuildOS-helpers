#
# What is here goes out of 2025-... and yet makes a good default
#

#
# Reusing artifacts, when appropriate, can save a lot of time during builds.
# The disadvantage can be that if you modify something for one distro, you could modify it, without wanting,
# for the others, while working on the same shared code, or artifacs from the same archietcture.
# If you always rebuild everything, it doesn't matter at all. I use the system mostly to build what I need
# SUPER FAST, so these are important parts of my build considerations.
# Note that we separate busybox from ramdisk, as busybox is a common component, while ramdisk is a specific one.
# You might have met a similar version of the buildsystem when they always shared the code in pscg_busyboxos - it is 
# not longer the case, by design
#
set_standard_default_values_distro_reuse() {
	: ${config_distro__reuse_shared_src=true}               # Reuse the source code of the distro, if it exists
	: ${config_distro__reuse_shared_arch=true}              # Reuse the architecture specific artifacts, if they exist
	: ${config_distro__reuse_shared_src_busybox=true}       # Reuse the source code of busybox, if it exists
	: ${config_distro__reuse_shared_src_ramdisk=true}       # Reuse the source code of ramdisk, if it exists
	: ${config_distro__reuse_shared_arch_busybox=true}      # Reuse the architecture specific artifacts of busybox, if they exist
	: ${config_distro__reuse_shared_arch_ramdisk=true}      # Reuse the architecture specific artifacts of the ramdisk, if they exist
}
distro_reuse_exports() {
	export config_distro__reuse_shared_src
	export config_distro__reuse_shared_arch
	export config_distro__reuse_shared_src_busybox
	export config_distro__reuse_shared_src_ramdisk
	export config_distro__reuse_shared_arch_busybox
	export config_distro__reuse_shared_arch_ramdisk
}

#
# This is like tricky but required sort of
#
set_standard_default_values_wip() {
        : ${config_kernel__autoadd_tricky_and_required_config_items=true}
}


#
# This is for a minor speedup in working with the initramfs (ramdisk), and for less verbosity when packing it
#
override_ramdisk_variables() {
        : ${config_ramdisk__compression=cpio}
        : ${config_ramdisk__verbose_cpio=false}
}
ramdisk_exports() {
        export config_ramdisk__compression
        export config_ramdisk__verbose_cpio
}

#------------------------------------------------------------------
# The default of the build system is something lighter than systemd, and it has not been used in a long while.
# systemd is of course a much better choice usually, but not always. So we keep this, as an aware decision of the build system user, and set the default to systemd at the last-line,
# unless someone else wants to modify it and use another init system (which is just fine).
#-------------------------------------------------------------------
override_pscgdebos_variables_init_frameworks() {
        if [ "${config_distro}" = "pscg_debos" ] ; then
                # In general, it is less likely to think of any modern full system that uses Debian and does not use systemd.
                # It would preferrably test here for feature_graphics/for package groups/etc. but I still did not make it up entirely (I did the former, ENABLE_GRAPHICS).
                # So we just set the last-line defaults to be systemd.
                #
                # Do note while at it, that it could be VERY useful to minimize the number of packages downloaded in the cache
                # I just downloaded everthing that is declared so that complete offline build are possible, but on
                # some architectures where debootstrap takes a lot of time, it can even take more time just to prepare the initial cache and download things
                : ${config_pscgdebos__init_frameworks=systemd} # to assist with lightdm dependencies
        fi
}



#XoXoXo
tmpstuffbeforeputtingitinthealmostmainscript() {
	override_ramdisk_variables
	ramdisk_exports

	override_pscgdebos_variables_init_frameworks # set to systemd for pscg_debos
}

tmpstuffbeforeputtingitinthealmostmainscript
