# plugable tool keeper for bash and zsh

TOOL_KEEPER_DIR=${TOOL_KEEPER_DIR:-~/.tool_keeper}
test -d $TOOL_KEEPER_DIR || mkdir -p $TOOL_KEEPER_DIR

tool_keeper_mod_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
for tool in $tool_keeper_mod_dir/tools/*_tk; do
  source $tool
done


if [ -n "$ZSH_VERSION" ]; then
  _tk_expand_var() {
    echo ${(P)1}
  }
else
  _tk_expand_var() {
    echo ${!1}
  }
fi

_tk_tool_path() {
  local tool_name=$1
  local version=$2
  echo ${TOOL_KEEPER_DIR}/${tool_name}/${version}
}

_tk_any_existing_version() {
  local tool_name=$1
  local tool_dir=$(dirname $(_tk_tool_path $tool_name "fake_version"))
  local version=$(cd $tool_dir; ls | sort -V | tail -n 1)
  echo $version
}

_tk_tool_version() {
  local tool_name=$1
  local version_var=TK_$(echo $tool_name | tr '[:lower:]' '[:upper:]')_VERSION
  local version=$(_tk_expand_var $version_var) # try to read version from version_var

  if [ -z "$version" ]; then
    version=${version:-$(_tk_any_existing_version $tool_name)} # use anything we have
    version=${version:-$(_tk_${tool_name}_latest_version)} # we don't have anything, download the latest
    [ -z "${version}" ] && echo $0: $tool_name: Unable to determine version >&2 && return 4
    #echo "# ${tool_name}: TK_${tool_name}_VERSION not set, using $version" >&2
  fi
  echo $version
}

_tk_run_tool() {
  local tool_name=$1; shift
  local opts=($@)
  local version=$(_tk_tool_version $tool_name)
  [ "$?" -eq 0 ] || return 1
  local version_path=$(_tk_tool_path $tool_name $version)
  if [[ ! -f $version_path || ! -x $version_path ]]; then
    # tool isn't installed (correctly), install it
    mkdir -p $(dirname ${version_path})
    _tk_${tool_name}_install ${version} ${version_path}
  fi
  $version_path ${opts[@]}
}
