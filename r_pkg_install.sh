#! /bin/bash

# change here #
PKG_DIR="${HOME}/r_pkg"
INSTALL_DIR="${HOME}/R/x86_64-redhat-linux-gnu-library/3.6"
###############

set -eu

PACKAGE_LIST="pkg_list.none.txt" # "pkg_list.all.txt" for installing all downloaded packageds
SCRIPT_DIR=${0%/*}

tar xf "${PKG_DIR}.tgz"

mkdir ${INSTALL_DIR} -p
Rscript --vanilla --slave ${SCRIPT_DIR}/r_pkg_check_installed.R ${PKG_DIR}

cd ${PKG_DIR}
while IFS= read -r line; do
  if [ ! "$line" = "" ]; then
    R CMD INSTALL "$line" --library="${INSTALL_DIR}"
  fi
done < "${PACKAGE_LIST}"
