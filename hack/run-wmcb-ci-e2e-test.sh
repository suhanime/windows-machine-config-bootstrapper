#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SKIP_VM_SETUP=""
VM_CREDS=""

while getopts ":v:s" opt; do
  case ${opt} in
    v ) # process option for providing existing VM credentials
      VM_CREDS=$OPTARG
      ;;
    s ) # process option for skipping setup in VMs
      SKIP_VM_SETUP="-skipVMSetup"
      ;;
    \? )
      echo "Usage: $0 [-v] [-s]"
      exit 0
      ;;
  esac
done

# TODO: Add steps to execute code that will kick off the e2e tests in CI
WMCO_ROOT=$(dirname "${BASH_SOURCE}")/..
WMCB_TEST_DIR=$WMCO_ROOT/internal/test/wmcb

# Build the unit test binary
cd "${WMCO_ROOT}"
make build-wmcb-unit-test

# The WMCB e2e tests requires the cluster address, we parse that here using oc
CLUSTER_ADDR=$(oc cluster-info | head -n1 | sed 's/.*\/\/api.//g'| sed 's/:.*//g')

# Transfer the binary and run the unit tests
CGO_ENABLED=0 GO111MODULE=on CLUSTER_ADDR=$CLUSTER_ADDR go test -v -run=TestWMCBUnit -binaryToBeTransferred=../../../wmcb_unit_test.exe -vmCreds="$VM_CREDS" $SKIP_VM_SETUP -timeout=30m .
