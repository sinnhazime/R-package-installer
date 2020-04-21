#! /bin/bash

# change here #
PKG_DIR="${HOME}/r_pkg"
INSTALL_DIR="${HOME}/R/x86_64-redhat-linux-gnu-library/3.6"
###############

set -eu

PACKAGE_LIST="pkg_list.none.txt" # "pkg_list.all.txt" for installing all downloaded packageds

tar xf "${PKG_DIR}.tgz"

mkdir ${INSTALL_DIR} -p
cd ${PKG_DIR}
Rscript --vanilla --slave r_pkg_check_installed.R

while IFS= read -r line; do
  if [ ! "$line" = "" ]; then
    R CMD INSTALL "$line" --library="${INSTALL_DIR}"
  fi
done < "${PACKAGE_LIST}"
