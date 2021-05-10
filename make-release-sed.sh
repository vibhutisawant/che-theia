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

sed_in_place() {
    SHORT_UNAME=$(uname -s)
  if [ "$(uname)" == "Darwin" ]; then
    sed -i '' "$@"
  elif [ "${SHORT_UNAME:0:5}" == "Linux" ]; then
    sed -i "$@"
  fi
}

apply_files_edits () {
  THEIA_VERSION=$(curl --silent http://registry.npmjs.org/-/package/@theia/core/dist-tags | sed 's/.*"next":"\(.*\)".*/\1/')
  if [[ ! ${THEIA_VERSION} ]] || [[ ${THEIA_VERSION} == \"Unauthorized\" ]]; then
    echo "Failed to get Theia next version from npmjs.org. Try again."; echo
    exit 1
  fi

  WS_CLIENT_VERSION=$(curl --silent http://registry.npmjs.org/-/package/@eclipse-che/workspace-client/dist-tags | sed 's/.*"latest":"\(.*\)".*/\1/')
  if [[ ! ${WS_CLIENT_VERSION} ]] || [[ ${WS_CLIENT_VERSION} == \"Unauthorized\" ]]; then
    echo "Failed to get @eclipse-che/workspace-client latest version from npmjs.org. Try again."; echo
    exit 1
  fi

  WS_TELEMETRY_CLIENT_VERSION=$(curl --silent http://registry.npmjs.org/-/package/@eclipse-che/workspace-telemetry-client/dist-tags | sed 's/.*"latest":"\(.*\)".*/\1/')
  if [[ ! ${WS_TELEMETRY_CLIENT_VERSION} ]] || [[ ${WS_TELEMETRY_CLIENT_VERSION} == \"Unauthorized\" ]]; then
    echo "Failed to get @eclipse-che/workspace-telemetry-client latest version from npmjs.org. Try again."; echo
    exit 1
  fi

  API_DTO_VERSION=$(curl --silent http://registry.npmjs.org/-/package/@eclipse-che/api/dist-tags | sed 's/.*"latest":"\(.*\)".*/\1/')
  if [[ ! ${API_DTO_VERSION} ]] || [[ ${API_DTO_VERSION} == \"Unauthorized\" ]]; then
    echo "Failed to get @eclipse-che/api latest version from npmjs.org. Try again."; echo
    exit 1
  fi

    # update config for Che-Theia generator
  sed_in_place -e "/checkoutTo:/s/master/${BRANCH}/" che-theia-init-sources.yml
  sed_in_place -e "/checkoutTo:/s/master/${BRANCH}/" che-theia-init-sources.yml

  # set the variables for building the images
  sed_in_place -e "s/IMAGE_TAG=\"..*\"/IMAGE_TAG=\"latest\"/" build.include
  sed_in_place -e "s/^THEIA_COMMIT_SHA=$/THEIA_COMMIT_SHA=\"${THEIA_VERSION##*.}\"/" build.include
  sed_in_place -e "s/THEIA_DOCKER_IMAGE_VERSION=.*/THEIA_DOCKER_IMAGE_VERSION=\"${VERSION}\"/" build.include

  for m in "extensions/*" "plugins/*"; do
    PACKAGE_JSON="${m}"/package.json
    # shellcheck disable=SC2086
    sed_in_place -r -e "s/(\"version\": )(\".*\")/\1\"$VERSION\"/" ${PACKAGE_JSON}
    # shellcheck disable=SC2086
    sed_in_place -r -e "/@eclipse-che\/api|@eclipse-che\/workspace-client|@eclipse-che\/workspace-telemetry-client/!s/(\"@eclipse-che\/..*\": )(\".*\")/\1\"$VERSION\"/" ${PACKAGE_JSON}
  done

  if [[ ${VERSION} == *".0" ]]; then
    for m in "extensions/*" "plugins/*"; do
      PACKAGE_JSON="${m}"/package.json
      # shellcheck disable=SC2086
      sed_in_place -r -e "/plugin-packager/!s/(\"@theia\/..*\": )(\"next\")/\1\"${THEIA_VERSION}\"/" ${PACKAGE_JSON}
      # shellcheck disable=SC2086
      sed_in_place -r -e "s/(\"@eclipse-che\/workspace-client\": )(\"latest\")/\1\"$WS_CLIENT_VERSION\"/" ${PACKAGE_JSON}
      # shellcheck disable=SC2086
      sed_in_place -r -e "s/(\"@eclipse-che\/workspace-telemetry-client\": )(\"latest\")/\1\"$WS_TELEMETRY_CLIENT_VERSION\"/" ${PACKAGE_JSON}
      # shellcheck disable=SC2086
      sed_in_place -r -e "s/(\"@eclipse-che\/api\": )(\"latest\")/\1\"$API_DTO_VERSION\"/" ${PACKAGE_JSON}
    done

    sed_in_place -e '$ a RUN cd ${HOME} \&\& tar zcf ${HOME}/theia-source-code.tgz theia-source-code' dockerfiles/theia/docker/ubi8/builder-clone-theia.dockerfile
  fi
}