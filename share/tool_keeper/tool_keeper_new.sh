tool_name=$1; shift
opts=($@)


POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    versions)
      echo $(installed_versions)
      shift # past argument
      ;;
    version)
      echo $(tool_version)
      shift # past argument
      ;;
    install)
      INSTALL=TRUE
      shift # past argument
      shift # past value
      ;;
    uninstall)
      uninstall=TRUE
      shift # past argument
      shift # past value
      ;;
    which)
      SEARCHPATH="$2"
      shift # past argument
      shift # past value
      ;;
    -?|-h|--help)
      LIBPATH="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

usage() {
  print <<EOT
Usage: $0 TOOL_NAME [OPTIONS]...
Run TOOL_NAME with given OPTIONS

The version of TOOL_NAME to run can be selected in the following ways.

  Environment Variable:

EOT
}

installed_versions() {
  local tool_dir=$(dirname $(tool_path "fake_version"))
  local versions=$(cd $tool_dir; ls | sort -V )
  echo $versions
}

tool_path() {
  local version=$1
  echo ${TOOL_KEEPER_DIR}/${tool_name}/${version}
}

any_existing_version() {
  local version=$(installed_versions | tail -n 1)
  echo $version
}

tool_version() {
  local version_var=TK_$(echo $tool_name | tr '[:lower:]' '[:upper:]')_VERSION
  local version=$(expand_var $version_var) # try to read version from version_var

  if [ -z "$version" ]; then
    version=${version:-$(any_existing_version)} # use anything we have
    version=${version:-$(${tool_name}_latest_version)} # we don't have anything, download the latest
    [ -z "${version}" ] && echo $0: $tool_name: Unable to determine version >&2 && return 4
    #echo "# ${tool_name}: TK_${tool_name}_VERSION not set, using $version" >&2
  fi
  echo $version
}

tool_version_source() {
  local version_var=TK_$(echo $tool_name | tr '[:lower:]' '[:upper:]')_VERSION
  local version=$(expand_var $version_var) # try to read version from version_var
  [ -n "$version" ] && echo $version_var environment variable; return 0

  version=${version:-$(any_existing_version)} # use anything we have
  [ -n "$version" ] && echo DEFAULT latest installed version; return 0

  # FIXME; I left off here
  version=${version:-$(${tool_name}_latest_version)} # we don't have anything, download the latest
  [ -z "${version}" ] && echo $0: $tool_name: Unable to determine version >&2 && return 4
}

run_tool() {
  local version=$(tool_version)
  [ "$?" -eq 0 ] || return 1
  local version_path=$(tool_path $version)
  if [[ ! -f $version_path || ! -x $version_path ]]; then
    # tool isn't installed (correctly), install it
    mkdir -p $(dirname ${version_path})
    ${tool_name}_install ${version} ${version_path}
  fi
  $version_path ${opts[@]}
}

source_lines() {
  for file in $some_dir/tk_*; do
    echo "source $file"
  done
}

run_tool
