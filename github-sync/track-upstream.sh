#!/bin/bash

#set -e
#set -x

SCRIPT_PATH=$(dirname "$0")
SCRIPT_PATH=`(cd "${SCRIPT_PATH}" && pwd)`
JQ=${SCRIPT_PATH}/jq
GHAPI=https://api.github.com
GHTOKEN='?access_token=<your github token>'
AWK=gawk

name=$1

parent_fork_url () {
    local REPO_NAME=$1
    echo $(curl -s ${GHAPI}/repos/${REPO_NAME}${GHTOKEN}|"${JQ}" -r '.parent.git_url')
}

enovance_url () {
    echo $(git remote -v|${AWK} '/origin\s+((git|https?):\/\/|git@)github.com(\/|:)enovance\/.*\.git\s+\(fetch\)$/ { print $2; }')
}

remote_url () {
    local REMOTE=$1
    echo $(git remote -v|${AWK} '/^'${REMOTE}'\s+\S+\s+\(fetch\)$/ { print $2; }')
}

repo_name () {
    local URL=$1

    echo $(echo ${URL}|${AWK} 'match($0, /github.com:(enovance\/.*).git/, a) { print a[1]; }')
}

add_remote () {
    local REMOTE_NAME=$1
    local REMOTE_URL=$2
    git remote add ${REMOTE_NAME} ${REMOTE_URL}
}

fix_push_url () {
    local REMOTE_NAME=$1
    local REPO_NAME=$2

    git remote -v|egrep -q ${REMOTE_NAME}'\s+.*\(push\)'
    if [ $? -eq 0 ]; then
        git remote set-url --push ${REMOTE_NAME} "git@github.com:${REPO_NAME}.git"
    fi
}

echo_color() {
  local color=$1
  local msg=$2
  color_code=''

  case $color in
    'red')
      color_code='\033[31m'
      ;;
    'green')
      color_code='\033[32m'
      ;;
    'yellow')
      color_code='\033[33m'
      ;;
  esac

  echo -e "${color_code}${msg}\033[39m"
}

check_gawk () {
    which gawk > /dev/null
    if [ $? != 0 ]; then
        echo_color red "Aborting, can't find gawk"
        exit
    fi

}

trap_handler () {
    echo_color red "${name}: ✗"
    exit
}

trap trap_handler ERR

check_gawk

OUR_REMOTE=$(enovance_url)
if [ -z "${OUR_REMOTE}" ]; then
    exit;
fi

REPO_NAME=$(repo_name ${OUR_REMOTE})
PARENT_FORK=$(parent_fork_url ${REPO_NAME})

if [ ! -z "${PARENT_FORK}" -a x${PARENT_FORK} != xnull ]; then
    REMOTE_URL=$(remote_url upstream)

    if [ ! -z "${REMOTE_URL}" -a x${REMOTE_URL} != x${PARENT_FORK} ]; then
        git remote rm upstream
    fi

    if [ -z ${REMOTE_URL} ]; then
        add_remote upstream ${PARENT_FORK}
    fi

    fix_push_url origin ${REPO_NAME}
    git remote update
    git push --tags origin
    git branch -r --list 'upstream/*' | while read UPSTREAM_BRANCH; do
        git push origin "${UPSTREAM_BRANCH}:refs/heads/${UPSTREAM_BRANCH#upstream/}"
    done
fi

echo_color green "${name}: ✓"
