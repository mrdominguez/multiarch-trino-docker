#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOF 1>&2
Usage: $0 [-h] [-a <ARCHITECTURES>] [-r <VERSION>] [-m]
Builds the Trino Docker image

-h       Display help
-a       Build the specified comma-separated architectures, defaults to amd64
-p       Use the specified server package (artifact id), for example: trino-server (default), trino-server-core
-t       Image tag name, defaults to trino
-r       Build the specified Trino release version, downloads all required artifacts
-m       Build multi-platform image (amd64 <> arm64)
-x       Skip image tests
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "${SCRIPT_DIR}" || exit 2

ARCHITECTURES=("amd64")
TRINO_VERSION=$(git ls-remote \
   --refs --tags --sort="v:refname" https://github.com/trinodb/trino \
   | awk -F/ '{ print $3 }' \
   | grep -v [[:alpha:]] \
   | tail -1)
TAG_PREFIX=trino
SERVER_ARTIFACT=trino-server
MULTIARCH=false
SKIP_TESTS=false

while getopts ":ma:hr:p:t:x" o; do
    case "${o}" in
        m)
            MULTIARCH=true
            ;;
        a)
            IFS=, read -ra ARCH_ARG <<< "$OPTARG"
            for arch in "${ARCH_ARG[@]}"; do
                if echo "amd64 arm64 ppc64le" | grep -v -w "$arch" &>/dev/null; then
                    usage
                    exit 0
                fi
            done
            ARCHITECTURES=("${ARCH_ARG[@]}")
            ;;
        r)
            TRINO_VERSION=${OPTARG}
            ;;
        p)
            SERVER_ARTIFACT=${OPTARG}
            ;;
        t)
            TAG_PREFIX=${OPTARG}
            ;;
        h)
            usage
            exit 0
            ;;
        x)
           SKIP_TESTS=true
           ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

TRINO_MAVEN_URL=https://repo1.maven.org/maven2/io/trino
echo "Downloading server and client artifacts for release version ${TRINO_VERSION}"
curl -s -O -L -C - $TRINO_MAVEN_URL/${SERVER_ARTIFACT}/${TRINO_VERSION}/${SERVER_ARTIFACT}-${TRINO_VERSION}.tar.gz
curl -s -O -L -C - $TRINO_MAVEN_URL/trino-cli/${TRINO_VERSION}/trino-cli-${TRINO_VERSION}-executable.jar
chmod +x trino-cli-${TRINO_VERSION}-executable.jar

echo "Preparing the image build context directory"
WORK_DIR="$(mktemp -d)"
cp "trino-cli-${TRINO_VERSION}-executable.jar" "${WORK_DIR}/trino-cli.jar"
tar -C "${WORK_DIR}" -xzf "${SERVER_ARTIFACT}-${TRINO_VERSION}.tar.gz"
mv "${WORK_DIR}/${SERVER_ARTIFACT}-${TRINO_VERSION}" "${WORK_DIR}/trino-server"
cp -R bin "${WORK_DIR}/trino-server"
cp -R default "${WORK_DIR}/"
if [ "${SERVER_ARTIFACT}" != "trino-server" ]; then
    rm -rf "${WORK_DIR}"/default/etc/catalog/*.properties
fi

JAVA_VERSION=24.0.1_9
JDK_RELEASE="temurin/jdk-${JAVA_VERSION/_/+}"
echo "Downloading ${JDK_RELEASE}"
JAVA_MAJOR_VER=${JAVA_VERSION%%.*}
[[ "${MULTIARCH}" == "true" ]] && ARCHITECTURES=("amd64" "arm64")
for arch in "${ARCHITECTURES[@]}"; do
    echo "\_ Downloading JDK ${JAVA_MAJOR_VER} for ${arch}"
    [[ "${arch}" == "arm64" ]] && arch="aarch64"
    [[ "${arch}" == "amd64" ]] && arch="x64"
    JDK_REPO="https://github.com/adoptium/temurin${JAVA_MAJOR_VER}-binaries/releases/download/jdk-${JAVA_VERSION/_/+}"
    JRE="$JDK_REPO/OpenJDK${JAVA_MAJOR_VER}U-jre_${arch}_linux_hotspot_${JAVA_VERSION}.tar.gz"
    [[ "${arch}" == "aarch64" ]] && arch="arm64"
    [[ "${arch}" == "x64" ]] && arch="amd64"
    curl -s -L -C - $JRE -o OpenJDK${JAVA_MAJOR_VER}U-jre_${arch}.tar.gz
    cp OpenJDK${JAVA_MAJOR_VER}U*_${arch}.tar.gz "${WORK_DIR}/"
done

TAG="${TAG_PREFIX}:${TRINO_VERSION}"

if [[ "${MULTIARCH}" == "false" ]]; then
  for arch in "${ARCHITECTURES[@]}"; do
    echo "Building the image for $arch with Java ${JDK_RELEASE}"
    docker build \
        "${WORK_DIR}" \
        --pull \
        --no-cache \
        --build-arg JDK_VERSION="${JDK_RELEASE}" \
        --platform "linux/$arch" \
        -f Dockerfile \
        -t "${TAG}-$arch"
  done
else
  echo "Building multi-platform image with Java ${JAVA_VERSION}"
  docker buildx build \
      "${WORK_DIR}" \
      --load \
      --pull \
      --no-cache \
      --build-arg JDK_VERSION="${JDK_RELEASE}" \
      --platform linux/arm64,linux/amd64 \
      -f Dockerfile \
      -t ${TAG}
fi

echo "Cleaning up the build context directory"
rm -r "${WORK_DIR}"

echo -n "Testing built images"
if [[ "${SKIP_TESTS}" == "true" ]];then
  echo " (skipped)"
else
  echo
  source container-test.sh
  if [[ "${MULTIARCH}" == "false" ]]; then
    for arch in "${ARCHITECTURES[@]}"; do
      test_container "${TAG}-$arch" "linux/$arch"
      docker image inspect -f 'Built {{.RepoTags}} {{.Id}}' "${TAG}-$arch"
    done
  else
    test_container "${TAG}" "linux/amd64"
    docker image inspect -f 'Built {{.RepoTags}} {{.Id}}' "${TAG}"
  fi
fi