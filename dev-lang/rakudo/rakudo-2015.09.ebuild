# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils multilib

DESCRIPTION="A Perl 6 implementation built on the Parrot virtual machine"
HOMEPAGE="http://rakudo.org/"
SRC_URI="http://rakudo.org/downloads/${PN}/${P}.tar.gz"

LICENSE="Artistic-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc java +moar"

RDEPEND=">=dev-lang/nqp-2015.09.1[java?,moar?]"
DEPEND="${RDEPEND}
	dev-lang/perl"

src_configure() {
	use java && myconf+="jvm,"
	use moar && myconf+="moar,"
	perl Configure.pl --backends=${myconf} --prefix=${EPREFIX}/usr || die
}

src_test() {
	emake -j1 test || die
}

src_install() {
	emake -j1 DESTDIR="${D}" install || die
	if [[ ${CHOST} == *-darwin* ]] ; then
		lib="usr/share/perl6/runtime/dynext/libperl6_ops_moar.dylib"
		install_name_tool \
			-id "${EPREFIX}/${lib}" \
			"${ED}/${lib}"
	fi

	dodoc CREDITS README.md docs/ChangeLog docs/ROADMAP || die

	if use doc; then
		dohtml -A svg docs/architecture.html docs/architecture.svg || die
		dodoc docs/*.pod || die
		docinto announce
		dodoc docs/announce/* || die
	fi
}
