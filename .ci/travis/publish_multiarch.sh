#!/bin/bash
#
# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# See: https://sipb.mit.edu/doc/safe-shell/
set -e
REGISTRY="quay.io"

PUBLISH_IMAGES_LIST=(
  prabhav/che-theia-dev
  prabhav/che-theia
  prabhav/che-theia-endpoint-runtime-binary
  prabhav/che-theia-vsix-installer
)

SHORT_SHA=$(git rev-parse --short HEAD)

for image in "${PUBLISH_IMAGES_LIST[@]}"
  do
    AMEND=""
    AMEND+=" --amend ${REGISTRY}/${image}:${TAG}-amd64";
    AMEND+=" --amend ${REGISTRY}/${image}:${TAG}-arm64";
    AMEND+=" --amend ${REGISTRY}/${image}:${TAG}-ppc64le";
    AMEND+=" --amend ${REGISTRY}/${image}:${TAG}-s390x";

    eval docker manifest create "${REGISTRY}/${image}:${TAG}" "$AMEND"
    docker manifest push "${REGISTRY}/${image}:${TAG}"
    
    if [[ "${TAG}" != "next-travis" ]]; then
       eval docker manifest create "${REGISTRY}/${image}:latest" "$AMEND"
       docker manifest push "${REGISTRY}/${image}:latest"
    fi

    if [[ "${TAG}" == "next-travis" ]]; then
       eval docker manifest create "${REGISTRY}/${image}:${SHORT_SHA}" "$AMEND"
       docker manifest push "${REGISTRY}/${image}:${SHORT_SHA}"
    fi

  done
