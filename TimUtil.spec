Name:		TimUtil
Version:	2.6
Release:	3%{?dist}
Summary:	Tim Currie's awesome Perl utility module

Group:		tools
License:	GPL
BuildArch:  noarch

%description
Tim Currie's personal Perl utility library

Provides
 - Complex command-line argument parsing
 - Fancy error messages
 - Formatted conditional debug output

%prep

/bin/rm -rf TimUtil/

%build

git clone git@github.com:TimTheTerrible/TimUtil.git

%install

mkdir -p %{buildroot}/usr/local/lib64/perl5/vendor_perl/
install -m 755 TimUtil/TimUtil.pm %{buildroot}/usr/local/lib64/perl5/vendor_perl/

%files

/usr/local/lib64/perl5/vendor_perl/TimUtil.pm

%changelog
* Mon Jun 09 2025 Tim Currie <tim@dforge.cc>
- Fixed Perl path

