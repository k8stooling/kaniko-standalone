#!/bin/bash
# Script to build Docker images using Kaniko

set -e

# Default values
platform="amd64"
extra_args=""

# Function to show usage
usage() {
  echo "Usage: $0 --dockerfile <path-to-dockerfile> --destination <image:tag> [--platform <platform>] [--extra_args <kaniko-args>]"
  exit 1
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dockerfile)
      dockerfile="$2"
      shift 2
      ;;
    --destination)
      destination="$2"
      shift 2
      ;;
    --platform)
      platform="$2"
      shift 2
      ;;
    --extra_args)
      extra_args="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      ;;
  esac
done

# Ensure required arguments are provided
if [[ -z "$dockerfile" || -z "$destination" ]]; then
  echo "Error: --dockerfile and --destination are required."
  usage
fi

# Determine context directory from Dockerfile path
context="$(dirname "${dockerfile}")"
WORKDIR=$(mktemp -d)

# Download Kaniko Binaries
mkdir -p /tmp/kaniko
cd /tmp/kaniko
url="https://github.com/k8stooling/kaniko-standalone/releases/download/v1.23.2/kaniko-binaries-linux-${platform}.scrambled"
TARFILE=/tmp/kaniko-binaries.scrambled

curl -s -L -o $TARFILE $url

dd if=$TARFILE of=${TARFILE}_1 bs=1 count=1
dd if=$TARFILE of=${TARFILE}_2 bs=1 count=1 skip=1
dd if=${TARFILE}_2 of=$TARFILE bs=1 conv=notrunc
dd if=${TARFILE}_1 of=$TARFILE bs=1 seek=1 conv=notrunc

tar zxf $TARFILE

chmod +x /tmp/kaniko/executor

# Prepare chroot
cp -r /tmp/kaniko "$WORKDIR/"
export DOCKER_CONFIG=/kaniko/.docker/
mkdir -p "$WORKDIR/kaniko/workspace"

cd "$WORKDIR"

mkdir dev
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/zero c 1 5

mkdir bin
cp /bin/bash bin/

mkdir -p proc/self
cp /proc/self/mountinfo proc/self/

mkdir etc
cp /etc/resolv.conf etc/
cp /etc/nsswitch.conf etc

mkdir -p etc/ssl/certs
cat /etc/ssl/certs/* > etc/ssl/certs/sa-certificates.crt

# Conditionally add AWS_WEB_IDENTITY_TOKEN_FILE
if [[ -n "$AWS_WEB_IDENTITY_TOKEN_FILE" ]]; then
  mkdir -p var/run/secrets/eks.amazonaws.com/serviceaccount
  cat "$AWS_WEB_IDENTITY_TOKEN_FILE" > var/run/secrets/eks.amazonaws.com/serviceaccount/token
fi

# Copy necessary libraries
mkdir -p lib/x86_64-linux-gnu
cp /lib/x86_64-linux-gnu/libtinfo.so.6 lib/x86_64-linux-gnu
cp /lib/x86_64-linux-gnu/libc.so.6 lib/x86_64-linux-gnu
mkdir lib64
cp /lib64/ld-linux-x86-64.so.2 lib64/

# Copy the Dockerfile and context
cp -r "${context}"/* kaniko/workspace

# Create environment file
cat > .env << END
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export AWS_REGION=$AWS_REGION
export AWS_ROLE_ARN=$AWS_ROLE_ARN
export AWS_STS_REGIONAL_ENDPOINTS=regional
export AWS_WEB_IDENTITY_TOKEN_FILE=$AWS_WEB_IDENTITY_TOKEN_FILE
export DOCKER_CONFIG=/kaniko/.docker/
export KANIKO_EXTRA_ARGS="$extra_args"
END

# Execute Kaniko build
sudo chroot . bash -c ". /.env; set; ./kaniko/executor -f /kaniko/workspace/$(basename ${dockerfile}) --context=/kaniko/workspace/ --force --destination=$destination --cleanup $KANIKO_EXTRA_ARGS"
