#
# spec file for package containment-rpm
#
# Copyright (c) 2023 SUSE LINUX Products GmbH, Nuernberg, Germany.
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

Name:           containment-rpm
Version:        2.0.0
Release:        0
License:        MIT
Summary:        Wraps OBS docker/kiwi-built images in rpms
Url:            https://github.com/SUSE/containment-rpm-docker
Group:          System/Management
Source:         %{name}-%{version}.tar.bz2
Source1:	image.spec.in
Source2:	container_post_run
BuildRequires:  filesystem
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
# disabled for now, not used for public cloud purpose
%if 0
%if 0%{?suse_version} >= 1230
Requires:       rubygem(changelog_generator)
%else
Requires:       rubygem-changelog_generator
%endif
Requires:       changelog-generator-data
Requires:       libxml2-tools
%endif
Requires:	jq
Requires:	libxml2-tools

%description
OBS container_post_run hook to wrap a kiwi or docker image in an rpm package.

This package should be required by the Build Service project's meta
prjconf, so that the container_post_run hook is present in the container image
and gets executed at the end of the image build.  It will then build
an rpm which contains the newly-produced image from kiwi/docker (using
image.spec.in), and place the rpm in the correct location that it
becomes an additional build artefact.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}/usr/lib/build/post_build.d
install -m 644 %{SOURCE1} %{buildroot}/usr/lib/build/
install -m 755 %{SOURCE2} %{buildroot}/usr/lib/build/post_build.d/

%files
%defattr(-,root,root)
%dir /usr/lib/build/post_build.d
/usr/lib/build/post_build.d/*_post_run
/usr/lib/build/image.spec.in

%changelog
