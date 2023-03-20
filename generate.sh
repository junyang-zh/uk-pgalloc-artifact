#!/bin/bash
# generate.sh

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
  echo "  Usage: $0 <arg1> <arg2> [-ap] [-g pgo_use] [-l pgalloc_use]" >&2
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
rm -rf app
mkdir app
cp scaffolding/Makefile* app/

makefile_file="app/Makefile"
search_libs_assign="LIBS :="
replace_libs_assign="LIBS := "

if [[ $target_app == "redis" ]]; then
  replace_libs_assign+=":\$(UK_LIBS)/lib-musl:\$(UK_LIBS)/lib-lwip:\$(UK_LIBS)/lib-redis"
fi

if [[ $allocator == "bbuddy" ]]; then
  true
fi

if [[ $allocator == "pgalloc" ]]; then
  replace_libs_assign+=":\$(UK_LIBS)/lib-pgalloc"
fi

if [[ $allocator == "mimalloc" ]]; then
  replace_libs_assign+=":\$(UK_LIBS)/lib-mimalloc"
fi

# Use awk to replace the search string with the new value in the file
awk -v s="$search_libs_assign" -v r="$replace_libs_assign" \
'{ if (match($0, s)) { gsub(s, r); }; print }' \
"$makefile_file" > tmpfile && mv tmpfile "$makefile_file"

# Done
echo "[$0][Info] Done."
