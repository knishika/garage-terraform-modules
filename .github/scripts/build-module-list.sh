#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
BASE_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd -P)

DEST_DIR="$1"

if [[ -z "${DEST_DIR}" ]]; then
  DEST_DIR="${BASE_DIR}/dist"
fi

rm -rf "${DEST_DIR}"
mkdir -p "${DEST_DIR}"

if [[ -z "${TMO_DIR}" ]]; then
  TMP_DIR="${BASE_DIR}/.tmp"
fi

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

OUTPUT="${DEST_DIR}/MODULES.md"

echo "## Module catalog" > "${OUTPUT}"

yq r -j "${BASE_DIR}/catalog.yaml" | jq -r '.categories | .[] | .category' | while read category; do
  echo "*** category: ${category}"

  category_config=$(yq r -j "${BASE_DIR}/catalog.yaml" | jq -c --arg CATEGORY "${category}" '.categories | .[] | select(.category == $CATEGORY) | del(.modules)')
  category_name=$(echo "${category_config}" | jq -r '.categoryName // .category')

  echo "### ${category_name}" >> "${OUTPUT}"
  echo "" >> "${OUTPUT}"
  echo "| **Module name** | **Module location** | **Latest release** | **Last build status** |" >> "${OUTPUT}"
  echo "|-----------------|---------------------|--------------------|-----------------------|" >> "${OUTPUT}"

  yq r -j "${BASE_DIR}/catalog.yaml" | \
    jq -c --arg CATEGORY "${category}" '.categories | .[] | select(.category == $CATEGORY) | .modules | .[]' | \
    while read module; do

    module_name=$(echo "${module}" | jq -r '.name')
    module_id=$(echo "${module}" | jq -r '.id')
    module_slug=$(echo "${module_id}" | sed -E "s~[^/]+/(.+)~\1~g")

    module_location="https://${module_id}"
    module_release="https://img.shields.io/github/v/release/${module_slug}?sort=semver"
    module_build="${module_location}/workflows/Verify%20and%20release%20module/badge.svg"

    echo "| *${module_name}* | ${module_location} | ![Latest release](${module_release}) | ![Verify and release module](${module_build}) |" >> "${OUTPUT}"
  done

  echo "" >> "${OUTPUT}"
done
