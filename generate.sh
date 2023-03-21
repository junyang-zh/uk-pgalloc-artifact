#!/bin/bash
# generate.sh
set -e

# Use awk to replace the search string with the new value in the file
# replace_in_file <file> <search> <replace>
function replace_in_file() {
  awk -v s="$2" -v r="$3" \
  '{ if (match($0, s)) { gsub(s, r); }; print }' \
  "$1" > tmpfile && mv tmpfile "$1"
}

function show_arguments() {
  echo "[$0][Info] Commandline arguments:"
  echo "  Target app: $target_app"
  echo "  Allocator: $allocator"
  echo "  --pgo-profile: $pgo_profile"
  echo "  --pgo-use: $pgo_use"
  echo "  --pgalloc-profile: $pgalloc_profile"
  echo "  --pgalloc-use: $pgalloc_use"
}

# Defined variables for optional arguments
pgo_profile=""
pgo_use=""
pgalloc_profile=""
pgalloc_use=""

# Defined variables for positional arguments
positional_args=()
# Available apps: redis
target_app=""
# Available allocators: pgalloc mimalloc bbuddy
allocator=""

# Parse optional arguments
while [[ $# -gt 0 ]]; do
	case $1 in
    -p|--pgo-profile)
      pgo_profile="true"
      shift
      ;;
    -g|--pgo-use)
      pgo_use=$2
      shift
      shift
      ;;
    -a|--pgalloc-profile)
      pgalloc_profile="true"
      shift
      ;;
    -l|--pgalloc-use)
      pgalloc_use=$2
      shift
      shift
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      positional_args+=("$1")
      shift
      ;;
  esac
done

# Make sure we have 2 positional arguments
if [[ ${#positional_args[@]} != 2 ]]; then
  echo "[$0][Error] Number of positional arguments is not 2!" >&2
  echo "  Usage: $0 <app> <allocator> [-ap] [-g pgo_use] [-l pgalloc_use]" >&2
  exit 1
fi

target_app=${positional_args[0]}
allocator=${positional_args[1]}

show_arguments

# Make sure we have pgalloc options are valid
if [[ $allocator != "pgalloc" && ($pgalloc_profile == "true" || $pgalloc_use != "") ]]; then
  echo "[$0][Error] pgalloc options used with non-pg allocator!" >&2
  exit 1
fi

# Generate the app
rm -rf app && mkdir app
cp scaffolding/Makefile* app/

makefile_file="app/Makefile"
search_libs_assign="LIBS :="
replace_libs_assign="LIBS := "

# Add app libraries, there's no preceding colon

if [[ $target_app == "redis" ]]; then
  replace_libs_assign+="\$(UK_LIBS)/lib-musl:\$(UK_LIBS)/lib-lwip:\$(UK_LIBS)/lib-redis"
  mkdir app/fs0
  cp scaffolding/redis/redis.conf app/fs0
fi

# Add allocator libraries

if [[ $allocator == "bbuddy" ]]; then
  true
fi

if [[ $allocator == "pgalloc" ]]; then
  replace_libs_assign+=":\$(UK_LIBS)/lib-pgalloc"
fi

if [[ $allocator == "mimalloc" ]]; then
  replace_libs_assign+=":\$(UK_LIBS)/lib-mimalloc"
fi

replace_in_file "$makefile_file" "$search_libs_assign" "$replace_libs_assign"

# Generate configs
defconfig_file=""

if [[ $target_app == "redis" ]]; then
  defconfig_file="scaffolding/redis/defconfig"
fi

cp $defconfig_file app

if [[ $allocator == "bbuddy" ]]; then
  echo "CONFIG_LIBUKBOOT_INITBBUDDY=y" >> app/defconfig
fi

if [[ $allocator == "pgalloc" ]]; then
  echo "CONFIG_LIBUKBOOT_INITPGALLOC" >> app/defconfig
fi

if [[ $allocator == "mimalloc" ]]; then
  echo "CONFIG_LIBUKBOOT_INITMIMALLOC=y" >> app/defconfig
fi

cd app
make olddefconfig
cd $OLDPWD

replace_in_file app/.config "# CONFIG_PLAT_KVM is not set" "CONFIG_PLAT_KVM=y"

# Copy scripts
cp scaffolding/scripts/*.sh app

if [[ $target_app == "redis" ]]; then
  cp scaffolding/redis/*.sh app
fi

# Done
echo "[$0][Info] Done."
