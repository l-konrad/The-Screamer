#!/usr/bin/env bash
set -eu -o pipefail

cc="$1"
cxx="$2"
ar="${3%% *}"
strip="${4%% *}"
cflags="$5"
cxxflags="$6"

march="${cflags/*-march=/}"
march="${march/ */}"

# TODO this is pretty hacky!
# This removes quotation marks because those are not supported either. We remove
# all of them which is huge hack.
# Flags are being reordered and options are removed from their argument if they
# have space between them. This removes that one specific space for -I.
flags_sanit() {
	sed -E "s#-Werror##;s#\"##g; s#-I #-I#g" <<<"$1"
}
# Make from flag words list of arguments for Meson to use
meson_flags_sanit() {
	flags_sanit "$1" |
		sed -E "s#([^ ]+)#'\1'#g; s# +#, #g"
}

update_file() {
	local name="$1"
	cat >"$name.new"
	if diff -q "$name" "$name.new" 2>/dev/null >&2; then
		rm -f "$name.new"
	else
		mv "$name.new" "$name"
	fi
}

update_file "crossfile.ini" <<EOF
[binaries]
c = '$cc'
cpp = '$cxx'
ar = '$ar'
strip = '$strip'
[built-in options]
c_args = [$(meson_flags_sanit "$cflags")]
c_link_args = ['-nostdlib', '-static', '-r']
cpp_args = [$(meson_flags_sanit "$cxxflags")]
cpp_link_args = ['-nostdlib', '-static', '-r']
[host_machine]
system = 'nuttx'
cpu_family = '${cc%%-*}'
cpu = '${march}'
endian = 'little'
[properties]
cmake_toolchain_file = '$(pwd)/Toolchain.cmake'
EOF

# TODO use cflags only for C and for C++ use cxxflags
update_file "Toolchain.cmake" <<EOF
add_compile_options($(flags_sanit "$cflags"))
add_link_options(-nostdlib -static -r)
EOF
