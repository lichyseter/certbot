#!/bin/sh -e
# pip installs the requested packages in editable mode and runs unit tests on
# them. Each package is installed and tested in the order they are provided
# before the script moves on to the next package. If CERTBOT_NO_PIN is set not
# set to 1, packages are installed using pinned versions of all of our
# dependencies. See pip_install.sh for more information on the versions pinned
# to.

if [ "$CERTBOT_NO_PIN" = 1 ]; then
  pip_install="pip install -q -e"
else
  pip_install="$(dirname $0)/pip_install_editable.sh"
fi

temp_cwd=$(mktemp -d)
trap "rm -rf $temp_cwd" EXIT
cp pytest.ini "$temp_cwd"

set -x
for requirement in "$@" ; do
  $pip_install $requirement
  pkg=$(echo $requirement | cut -f1 -d\[)  # remove any extras such as [dev]
  pkg=$(echo "$pkg" | tr - _ )  # convert package names to Python import names
  if [ $pkg = "." ]; then
    pkg="certbot"
  fi
  cd "$temp_cwd"
  pytest --quiet $pkg
  cd -
done
