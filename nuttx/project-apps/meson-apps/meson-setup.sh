#!/usr/bin/env bash
# Build directory generator for meson based applications.
set -eu -o pipefail

sdir="$(pwd)"
# Lock the directory to prevent anyone calling build commands
exec 3>>".lock"
flock -x 3

## Build directory #############################################################
mkdir -p build
if ! [[ -f "build/build.ninja" ]] || [[ "crossfile.ini" -nt "build/build.ninja" ]]; then
	[[ -f "build/build.ninja" ]] && meson_wipe="y"
	echo "Meson applications setup"
	meson setup ${meson_wipe:+--wipe} \
		--default-library static \
		--backend ninja \
		--cross-file crossfile.ini \
		build ../../..
else
	ninja -C build build.ninja
fi

## build.ninja dependency file #################################################
{
	# Build targets
	meson introspect --targets "build" |
		jq -r '.[] | select((.type == "static library" or .type == "executable") and .installed) | .name, .filename[0], .type' |
		while read -r name && read -r file && read -r type; do
			target="${file#"$sdir/build/"}"
			if [[ "$type" == "executable" ]]; then
				echo "\$(eval \$(call EXECUTABLE,$target,$name,${name//-/_}_main))"
			else
				echo "\$(eval \$(call STATIC_LIBRARY,$target))"
			fi
		done

	echo

	# Files triggering refresh of the build system
	meson introspect --buildsystem-files build |
		jq -r '.[]' |
		sed 's#^#build/build.ninja: #'
} >"build.ninja.mk"
