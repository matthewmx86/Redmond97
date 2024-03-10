#!/usr/bin/env bash

set -e

version="0.0.1"

cd "$(realpath "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"

rm    -rf "output/"
mkdir -p  "output/"

# Build redmond97-icons
mkdir -p                                                  "output/redmond97-icons/DEBIAN/"
mkdir -p                                                  "output/redmond97-icons/usr/share/icons/Redmond97/"
rsync -az "Extras/Icons/Redmond97/"                       "output/redmond97-icons/usr/share/icons/Redmond97/"
BUILD_VERSION="${version}" INSTALLED_SIZE="$(du -s output/redmond97-icons/ | awk '{print $1}')" \
  envsubst < "Templates/Debian/redmond97-icons-control.tpl" > "output/redmond97-icons/DEBIAN/control"
dpkg -b "output/redmond97-icons"                          "output/redmond97-icons_${version}_all.deb"
echo "OK: output/redmond97-icons_${version}_all.deb"

# Build redmond97-themes
mkdir -p                                                  "output/redmond97-themes/DEBIAN/"
mkdir -p                                                  "output/redmond97-themes/usr/share/themes/"
BUILD_VERSION="${version}" INSTALLED_SIZE="$(du -s output/redmond97-themes/ | awk '{print $1}')" \
  envsubst < "Templates/Debian/redmond97-themes-control.tpl" > "output/redmond97-themes/DEBIAN/control"
rsync -az "Theme/csd/"                                    "output/redmond97-themes/usr/share/themes/"
dpkg -b "output/redmond97-themes"                         "output/redmond97-themes_${version}_all.deb"
echo "OK: output/redmond97-themes_${version}_all.deb"
