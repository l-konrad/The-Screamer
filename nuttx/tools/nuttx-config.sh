# shellcheck shell=bash
# NuttX configuration generator
# This scripts is expected to be run in the top level directory of the project.
set -eu

# Top level configuration ######################################################
declare -A config
while IFS="=" read -r name value; do
	config["${name#CONFIG_}"]="${value}"
done <.config

dependencies="n"
for arg in "$@"; do
	case "$arg" in
	dependencies)
		dependencies="y"
		;;
	*)
		echo "Invalid argument: $arg" >&2
		exit 1
		;;
	esac
done

# Configuration in files #######################################################
declare -a config_files
config_files=("./board/configs/defconfig")
################################################################################

declare -A deployfiles
deployfiles=(
	['./board/scripts/Make.defs']='./core/Make.defs'
)

if [[ "$dependencies" == "y" ]]; then
	# We are interested only in dependencies so dump them and exit
	for src in "${!deployfiles[@]}" "${config_files[@]}"; do
		echo "core/.config: $src"
	done
	exit 0
fi

# Check that submodules are present
for submodule in core apps; do
	if ! [ -d "$submodule" ]; then
		echo "Submodule seems to be missing \"$submodule\". Please run: git submodule update --init" >&2
		exit 1
	fi
done

# Perform distclean if deployed files differ
if [ -f "./core/.config" ]; then
	for src in "${!deployfiles[@]}"; do
		if cmp -s "$src" "${deployfiles["$src"]}"; then
			${MAKE:-make} distclean
			break
		fi
	done
fi

# Deploy our files
for src in "${!deployfiles[@]}"; do
	install -m 644 "$src" "${deployfiles["$src"]}"
done

# Configure our libraries as external in NuttX
rm -f core/external
[ -d project-libs ] &&
	ln -sf ../project-libs core/external
# Configure our applications as external in NuttX applications
rm -f apps/external
if [[ -d project-apps ]]; then
	ln -sf ../project-apps apps/external
fi

# Assemble the configuration
declare -A nuttx_options
while read -r line; do
	cnf="${line#CONFIG_}"
	[ "$cnf" != "$line" ] || continue
	nuttx_options["${cnf%%=*}"]="${cnf#*=}"
done <<<"$(cat "${config_files[@]}")"

# Dynamic configuration ########################################################
# Assert
if [ "${config['ASSERT']:-n}" = "y" ]; then
	nuttx_options['DEBUG_FEATURES']="y"
	nuttx_options['DEBUG_ASSERTIONS']="y"
	nuttx_options['DEBUG_ERROR']="y"
	nuttx_options['DEBUG_WARN']="y"
fi
## Debug
if [ "${config['DEBUG']:-n}" = "y" ]; then
	nuttx_options['DEBUG_NOOPT']="y"
	nuttx_options['DEBUG_INFO']="y"
	nuttx_options['DEBUG_ASSERTIONS_EXPRESSION']="y"
	nuttx_options['DEBUG_ASSERTIONS_FILENAME']="y"
	nuttx_options['STACK_COLORATION']="y"
	nuttx_options['FRAME_POINTER']="y"
	nuttx_options['STACK_CANARIES']="y"
else
	nuttx_options['DEBUG_FULLOPT']="y"
fi
################################################################################

# Now dump all configuration
rm -f core/.config
for option in "${!nuttx_options[@]}"; do
	echo "CONFIG_$option=${nuttx_options[$option]}" >>core/.config
done
echo "CONFIG_VERSION_STRING ?= \"$(cat .version)\"" >>core/.config
echo "CONFIG_VERSION_BUILD ?= \"$(../.version.sh nuttx)\"\"" >>core/.config

# Update configuration
${MAKE:-make} -C core olddefconfig

# Save NuttX version
if [[ -f core/.version ]]; then
	sed -nE 's/^CONFIG_VERSION_STRING="([^"]*)"$/\1/p' core/.version >.version
fi

# Verify
for option in "${!nuttx_options[@]}"; do
	if [[ "${nuttx_options[$option]}" == "n" ]]; then
		# The no is propagated as not set and thus we rather chack if it is not
		# enabled or set as module.
		if grep -q "^CONFIG_$option=(y|m)$" core/.config; then
			echo "The NuttX config is not correctly set: $option" >&2
			exit 1
		fi
	else
		if ! grep -qF "CONFIG_$option=${nuttx_options[$option]}" core/.config; then
			echo "The NuttX config is not correctly set: $option" >&2
			exit 1
		fi
	fi
done
