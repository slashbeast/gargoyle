#!/bin/bash

if [ -z "${BASH_VERSION}" ] || ! [ "${BASH_VERSION:0:1}" -ge '4' ]; then
	echo 'This script was designed to work with bash in version 4 (at least). Exiting...'
	exit 1
fi

set -e

einfo() { echo -e "\033[1;32m>>> \033[0m$@" ;}
config_option() {
	# $1 name
	# $2 value
	# $3 file

	# example:
	# config_option CONFIG_CCACHE y .config
	# config_option CONFIG_TARGET_INIT_CMD '/sbin/init' .config

	# If there is no such option, add it as unset.
	if [ -n "$2" ] && ! grep -Eq "^(# |)$1( is not set|=)" "$3"; then
		echo "# $1 is not set" >> "$3"
	fi

	case "$2" in
		y)
			# set as YES.
			sed -e "s:# $1 is not set:$1=y:; s:$1=.*:$1=y:" -i "$3"
		;;
		n)
			# set as NO.
			sed -e "s:# $1 is not set:$1=n:; s:$1=.*:$1=n:" -i "$3"
		;;
		'--unset')
			# unset.
			sed -e "s:$1=.*:# $1 is not set:" -i "$3"
		;;
		'--check')
			# Return 0 if config option is set but not to NO.
			if grep -Eq "^$1=.*[^n]$" "$3"; then
				return 0
			else
				return 1
			fi
		;;
		*)
			# set to $2 value.
			sed -e "s:# $1 is not set:$1=$2:; s:$1=.*:$1=$2:" -i "$3"
		;;
	esac
}

scriptpath="$(readlink -f "$0")"
workdir="${scriptpath%/${0##*/}}"

. "${workdir}/builder.conf"

while [ "$#" -gt 0 ]; do
	case "$1" in
		--revision)
			revision_num="$2"
			shift 2
		;;
		--branch)
			branch_name="$2"
			shift 2
		;;
		--target)
			target="$2"
			shift 2
		;;
		--profile)
			target_profile="$2"
			shift 2
		;;
		--version)
			version_name="$2"
			shift 2
		;;
		--verbose)
			verbose="true"
			shift
		;;
		--custom)
			custom="true"
			shift
		;;
		*)
			echo "Wat?"
			echo "$@"
			exit 1
		;;
	esac
done

# debug
exec 2>"${workdir}/debug.log"
set -x

if [ -n "${revision_num}" ] && ! [ "${revision_num}" = 'latest' ]; then
	svn_revision_get="-r ${revision_num}";
else
	revision_num="latest"
fi
if [ -z "${version_name}" ] || [ "${version_name}" = 'AUTO' ]; then
	version_name="git-$(git log -1 --pretty='format:%h') openwrt-${branch_name}-${revision_num} bulit $(date -u +%d-%m-%Y-%H-%M)"
fi
version_name="${version_name//[^ .a-zA-Z0-9_+-]}" # Strip unwanted chars.
version_name="${version_name// /_}" # Replace spaces with underscore.
version_name="${version_name,,}" # Convert string to lower case.

distfiles="${workdir}/distfiles"
targets_dir="${workdir}/targets"
patches_dir="${workdir}/patches-generic"
netfilter_patch_script="${workdir}/netfilter-match-modules/integrate_netfilter_modules_backfire.sh"
openwrt_src_dir="${distfiles}/${branch_name}-${revision_num}"
openwrt_packages_src_dir="${distfiles}/openwrt-packages-${revision_num}"
distfiles="${workdir}/distfiles"
build_dir="${workdir}/tmp/${target}-src"

if ! [ -d "${distfiles}" ]; then mkdir "${distfiles}"; fi
if ! [ -d "${workdir}/tmp" ]; then mkdir "${workdir}/tmp"; fi

# Get list of available target's profiles.
available_profiles=( 'default' )
for profile in "${targets_dir}/${target}/profiles"/*; do
	# Do not add to array 'default' and non-directory.
	if ! [ -d "${profile}" ] || [ "${profile##*/}" = 'default' ]; then continue; fi
	available_profiles+=( "${profile##*/}" )
done

# target_profile is variable set by switches, if empty, set target_profiles array to all available profiles.
# if not empty, out selected profile in this array.
if [ -z "${target_profile}" ]; then
	target_profiles=( "${available_profiles[@]}" )
else
	target_profiles=( "${target_profile}" )
fi

einfo "Summary:"
einfo "Target: $target"
einfo "Target's profiles: ${target_profiles[@]}"
einfo "Version name: $version_name"
einfo "Revision: $revision_num"

if ! [ -d "${openwrt_src_dir}" ]; then
	einfo "Fetching openwrt source."
	rm "${openwrt_src_dir}" -rf
	svn checkout ${svn_revision_get} "svn://svn.openwrt.org/openwrt/branches/${branch_name}/" "${openwrt_src_dir}"
elif [ "${revision_num}" = 'latest' ]; then
	einfo "Updating openwrt source."
	cd "${openwrt_src_dir}" && svn update
fi


if [ -d "${build_dir}" ]; then 
	einfo 'Cleaning old build root.'
	rm -rf "${build_dir}"
fi

einfo "Coping openwrt sources to '${build_dir}' dir."
rsync --size-only -r -l --exclude '.svn' "${openwrt_src_dir}/" "${build_dir}"

# Lets link dl to distfiles so we can share downloaded source.
rm -rf "${build_dir}/dl"
ln -s "${distfiles}" "${build_dir}/dl"

for package in "${workdir}"/package/*; do
	if [ -d "${build_dir}/package/${package##*/}" ]; then
		einfo "Replacing openwrt's '${package##*/}' package with gargoyle's version."
		rm -rf "${build_dir}/package/${package##*/}"
	else
		einfo "Coping '${package##*/}' to '${build_dir}/package/' dir."
	fi
	cp -r "${package}" "${build_dir}/package/"
done; unset package

if [ "${custom}" = 'true' ]; then
	einfo "Custom mode enabled, deploying extra packages."
	openwrt_packages_src_dir="${distfiles}/openwrt-packages-${revision_num}"
	if ! [ -d "${openwrt_packages_src_dir}" ]; then
		einfo "Fetching openwrt packages source."
		svn checkout ${svn_revision_get} "svn://svn.openwrt.org/openwrt/packages" "${openwrt_packages_src_dir}"
	elif [ "${revision_num}" = 'latest' ]; then
		einfo "Updating openwrt packages source."
		cd "${openwrt_packages_src_dir}" && svn update
	fi
	
	for package in "${openwrt_packages_src_dir}"/*; do
		if ! [ -d "${build_dir}/package/${package##*/}" ]; then
			einfo "Coping '${package##*/}' to '${build_dir}/package/' dir."
			#cp -r "${package}" "${build_dir}/package/"
			rsync --size-only -r -l --exclude '.svn' "${package}" "${build_dir}/package/"
		fi
	done; unset package
fi

# Lets clean remaining .svn dirs, if any. stderr goes to null as find will print some errors with nested .svn dirs.
find "${build_dir}/" -type d -name '.svn' -exec rm -rf '{}' \; 2> /dev/null

cd "${build_dir}/"

if [ -n "${version_name}" ]; then
	sed -i "1iOFFICIAL_VERSION:=${version_name}" 'package/gargoyle/Makefile'
fi

for profile in "${target_profiles[@]}"; do
	einfo "Building '${profile}' profile."
	cp "${targets_dir}/${target}/profiles/${profile}/config" "${build_dir}/.config"
	einfo "Applying kernel patches."

	if [ "${already_patched}" != 'true' ]; then
		sh scripts/patch-kernel.sh . "${patches_dir}/" > /dev/null
		set +e; sh scripts/patch-kernel.sh . "${targets_dir}/${target}/patches/" > /dev/null; set -e
		sh "${netfilter_patch_script}" '.' "../../netfilter-match-modules" 1 1
		already_patched='true'
	fi

	if [ "${use_ccache}" = 'true' ]; then
		config_option CONFIG_DEVEL y "${build_dir}/.config"
		config_option CONFIG_CCACHE y "${build_dir}/.config"
		export PATH="/usr/lib64/ccache/bin:${PATH}"
		export CCACHE_DIR="${workdir}/tmp/ccache"
		sed "s#CCACHE_DIR:=\$(STAGING_DIR)/ccache#CCACHE_DIR:=${CCACHE_DIR}#" -i "${build_dir}/include/package.mk"
	fi

	if [ "${custom}" = 'true' ]; then
		make menuconfig
		
		# Enable libgcrypt or ntfs-3g will fail to compile.
		config_option 'CONFIG_PACKAGE_ntfs-3g' --check "${build_dir}/.config" && config_option 'CONFIG_PACKAGE_libgcrypt' 'y' "${build_dir}/.config"
	fi

	if [ "${verbose}" = 'true' ]; then kernel_verbose='V=99'; fi
	make ${kernel_verbose} -j4 GARGOYLE_VERSION="${version_name}"

	if [ ! -d "${workdir}/output/${target}/${profile}" ]; then mkdir -p "${workdir}/output/${target}/${profile}"; fi

	if [ ! -d "${workdir}/output/${target}/${profile}/packages" ]; then mkdir "${workdir}/output/${target}/${profile}/packages"; fi
	einfo "Coping packages to '${workdir}/output/${target}/${profile}/packages' dir."
	find "${build_dir}/bin" -type f \( -name '*.ipk' -o -name 'Packa*' \) -exec cp '{}' "${workdir}/output/${target}/${profile}/packages" \;

	# Lets grab arch name, if there is more than one, or there is none at all files in bin/ exit with status 1.
	shopt -s nullglob
	getarch=( "${build_dir}/bin"/* )
	shopt -u nullglob
	if [ "${#getarch[@]}" != '1' ]; then
	        echo 'Something went wrong.'; exit 1
	else
	        arch="${getarch[0]##*/}"
	        unset getarch
	fi


	if [ ! -d "${workdir}/output/${target}/${profile}/images" ]; then mkdir "${workdir}/output/${target}/${profile}/images"; fi
	einfo "Coping images to '${workdir}/output/${target}/${profile}/images' dir."
	while read match; do
		for image in "${build_dir}/bin/${arch}"/*${match}*; do
			newname="${image##*/}"
			newname="${newname/openwrt/gargoyle_${version_name}}"
			cp "${image}" "${workdir}/output/${target}/${profile}/images/${newname}"
		done
	done < "${targets_dir}/${target}/profiles/${profile}/profile_images"
done

echo
einfo 'That would be all.'
