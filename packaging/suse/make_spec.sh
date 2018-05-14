#!/bin/bash

if [ -z "$1" ]; then
  cat <<EOF
usage:
  ./make_spec.sh PACKAGE [BRANCH]
EOF
  exit 1
fi

cd $(dirname $0)

YEAR=$(date +%Y)
VERSION=$(git describe --abbrev=0 --tags)
# remove "v"
VERSION=$(echo $VERSION | sed -e "s/v//g")
REVISION=$(git rev-list HEAD | wc -l)
COMMIT=$(git rev-parse --short HEAD)
VERSION="${VERSION%+*}+git_r${REVISION}_${COMMIT}"
NAME=$1
BRANCH=${2:-master}
SAFE_BRANCH=${BRANCH//\//-}

cat <<EOF > ${NAME}.spec
#
# spec file for package containment-rpm-docker
#
# Copyright (c) $YEAR SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           $NAME
Version:        $VERSION
Release:        0
License:        MIT
Summary:        Wraps OBS/kiwi-built images in rpms
Url:            https://github.com/SUSE/containment-rpm-docker
Group:          System/Management
Source:         ${SAFE_BRANCH}.tar.gz
BuildRequires:  filesystem
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
%if !0%{?is_opensuse}
%if 0%{?suse_version} >= 1230
Recommends:       rubygem(changelog_generator)
%else
Recommends:       rubygem-changelog_generator
%endif
Recommends:       changelog-generator-data
%endif
Requires:       libxml2-tools
# Conflicts with other packages that provide /usr/lib/build/kiwi_post_run
Conflicts:      infos-creator-rpm

%description
OBS kiwi_post_run hook to wrap a kiwi-produced image in an rpm package.

This package should be required by the Build Service project's meta
prjconf, so that the kiwi_post_run hook is present in the kiwi image
and gets executed at the end of the image build.  It will then build
an rpm which contains the newly-produced image from kiwi (using
image.spec.in), and place the rpm in the correct location that it
becomes an additional build artefact.

%prep
%setup -q -n %{name}-${SAFE_BRANCH}

%build

%install
mkdir -p %{buildroot}/usr/lib/build/
install -m 644 image.spec.in %{buildroot}/usr/lib/build/
install -m 755 kiwi_post_run %{buildroot}/usr/lib/build/

%files
%defattr(-,root,root)
/usr/lib/build/kiwi_post_run
/usr/lib/build/image.spec.in

%changelog
EOF
