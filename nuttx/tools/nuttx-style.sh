#!/usr/bin/env bash
set -eu
# We want to make sure that our board sources are formatted correctly according
# the NuttX code style. At the same time we can't ensure  simply that absolute
# path is in header and thus we just simply mask this type of error and keep
# path as it would be in NuttX repository.

project="${0%/*}/.."
nuttx_tools="${0%/*}/../core/tools"

export CROSSDEV="riscv32-none-elf-"

itype=' error'
imessage=' Path relative to repository other than "nuttx" must begin with the root directory'

make -C "$project/core/tools" -f Makefile.host nxstyle 1>/dev/null

ec=0
while IFS=: read -r file line char type message; do
	[[ -n "$file" ]] || continue
	echo -n "$file:$line:$char$type:$message" >&2
	if [[ "$type" == "$itype" ]] && [[ "$message" == "$imessage" ]]; then
		echo " (Ignored)"
	else
		echo
		ec=1
	fi
done <<<"$(
	git ls-files \
		"$project/board/**" \
		"$project/project-apps/**" \
		"$project/project-libs/**" |
		xargs -n1 "$nuttx_tools/nxstyle" 2>&1
)"

exit $ec
