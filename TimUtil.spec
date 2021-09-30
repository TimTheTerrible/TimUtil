Name:		TimUtil
Version:	2.6
Release:	1%{?dist}
Summary:	Tim Currie's awesome Perl utility module

Group:		tools
License:	GPL

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

mkdir -p %{buildroot}/usr/local/lib64/perl5/
install -m 755 TimUtil/TimUtil.pm %{buildroot}/usr/local/lib64/perl5/

%files

/usr/local/lib64/perl5/*

%changelog

