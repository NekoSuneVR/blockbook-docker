#!/usr/bin/env bash

if [[ ! -d /root/blockbook ]]; then
  start_build=`date +%s`
  echo -e "| BLOCKBOOK BUILDER v1.0 [$(date '+%Y-%m-%d %H:%M:%S')]"
  echo -e "|-----------------------------------------------------"
  echo -e "| Installing RocksDB..."
  cd /root && git clone -b $ROCKSDB_VERSION --depth 1 https://github.com/facebook/rocksdb.git > /dev/null 2>&1
  cd /root/rocksdb && CFLAGS=-fPIC CXXFLAGS=-fPIC make -j 4 release > /dev/null 2>&1
  echo -e "| Installing BlockBook..."

  if [[ "$BLOCKBOOKGIT_URL" == "" ]]; then
    BLOCKBOOKGIT_URL="https://github.com/trezor/blockbook.git"
  fi
  echo -e "| Blockbook GITHUB URL: $BLOCKBOOKGIT_URL"
  cd /root && git clone $BLOCKBOOKGIT_URL > /dev/null 2>&1 && \
  cd /root/blockbook && \
  go mod download > /dev/null 2>&1  && \
  BUILDTIME=$(date --iso-8601=seconds); \
  GITCOMMIT=$(git describe --always --dirty); \
  LDFLAGS="-X github.com/trezor/blockbook/common.version=${TAG} -X github.com/trezor/blockbook/common.gitcommit=${GITCOMMIT} -X github.com/trezor/blockbook/common.buildtime=${BUILDTIME}" && \
  go build -tags rocksdb_6_16 -ldflags="-s -w ${LDFLAGS}" > /dev/null 2>&1
  echo -e "| Build: $BUILDTIME, Commit: $GITCOMMIT, Version: $TAG, Duration: $((($(date +%s)-$start_build)/60)) min. $((($(date +%s)-$start_build) % 60)) sec."
  if [[ -f /root/blockbook/blockbook ]]; then
    echo -e "| Blockbook build [OK]..."
  else
    echo -e "| Blockbook build [FAILED]..."
    echo -e "| Cleaning..."
    echo -e "|-----------------------------------------------------"
    rm -rf /root/blockbook > /dev/null 2>&1
    rm -rf /root/libzmq > /dev/null 2>&1
    rm -rf /root/rocksdb > /dev/null 2>&1
    exit 1
  fi
  echo -e "| Creating blockchaincfg.sh for $COIN..."
  echo -n "| "
  cd /root/blockbook
  if [[ "$ALIAS" == "" ]]; then
    ./contrib/scripts/build-blockchaincfg.sh $COIN
  else
    ./contrib/scripts/build-blockchaincfg.sh $ALIAS
  fi
  echo -e "|-----------------------------------------------------"
else
  echo -e "| BLOCKBOOK ALREADY INSTALLED.."
  echo -e "|-----------------------------------------------------"
  sleep 5
fi
