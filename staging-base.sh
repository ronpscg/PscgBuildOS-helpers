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
