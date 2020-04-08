# change here #
pkg_dir="${HOME}/r_pkg_tgz"
install_dir="${HOME}/R/x86_64-redhat-linux-gnu-library/3.6"
###############

set -eu

package_list="pkg_list.txt"

mkdir $install_dir -p
cd $pkg_dir

while IFS= read -r line; do
  if [ ! "$line" = "" ]; then
    R CMD INSTALL "$line" --library="$install_dir"
  fi
done < "$package_list"
