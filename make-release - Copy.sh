#!/bin/bash
#
# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

# Release process automation script.

NOCOMMIT=0

git remote remove origin
git remote add origin https://${CHE_BOT_GITHUB_TOKEN}@github.com/vibhutisawant/che-theia.git

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-v'|'--version') VERSION="$2"; shift 1;;
    '-n'|'--no-commit') NOCOMMIT=1; shift 0;;
  esac
  shift 1
done

usage ()
{
  echo "Usage: $0 --version <VERSION_TO_RELEASE>"
  echo "Example: $0 --repo git@github.com:eclipse/che-theia --version 7.7.0"; echo
}

if [[ ! ${VERSION} ]]; then
  usage
  exit 1
fi

sed_in_place() {
    SHORT_UNAME=$(uname -s)
  if [ "$(uname)" == "Darwin" ]; then
    sed -i '' "$@"
  elif [ "${SHORT_UNAME:0:5}" == "Linux" ]; then
    sed -i "$@"
  fi
}

# derive branch from version
BRANCH=${VERSION%.*}.x

# if doing a .0 release, use master; if doing a .z release, use $BRANCH
if [[ ${VERSION} == *".0" ]]; then
  BASEBRANCH="master"
else
  BASEBRANCH="${BRANCH}"
fi

git fetch origin "${BASEBRANCH}":"${BASEBRANCH}" || true
git checkout "${BASEBRANCH}"

# create new branch off ${BASEBRANCH} (or check out latest commits if branch already exists), then push to origin
if [[ "${BASEBRANCH}" != "${BRANCH}" ]]; then
  git branch "${BRANCH}" || git checkout "${BRANCH}" && git pull origin "${BRANCH}"
  git push origin "${BRANCH}"
  git fetch origin "${BRANCH}:${BRANCH}"
  git checkout "${BRANCH}"
fi

# commit change into branch
if [[ ${NOCOMMIT} -eq 0 ]]; then
  COMMIT_MSG="[release] Bump to ${VERSION} in ${BRANCH}"
  git commit -a -s -m "${COMMIT_MSG}"
  git pull origin "${BRANCH}"
  git push origin "${BRANCH}"
fi

git checkout "${BRANCH}"
git tag "${VERSION}"
git push origin "${VERSION}"
