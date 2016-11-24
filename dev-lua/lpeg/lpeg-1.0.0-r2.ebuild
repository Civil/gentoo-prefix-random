# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit flag-o-matic multilib toolchain-funcs

DESCRIPTION="Parsing Expression Grammars for Lua"
HOMEPAGE="http://www.inf.puc-rio.br/~roberto/lpeg/"
SRC_URI="http://www.inf.puc-rio.br/~roberto/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~x86"
IUSE="debug doc luajit"

RDEPEND="!luajit? ( >=dev-lang/lua-5.1:= )
	luajit? ( dev-lang/luajit:2= )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS=( "HISTORY" )
HTML_DOCS=( "lpeg.html"  "re.html"  )
PATCHES=( "${FILESDIR}"/${PN}-0.12.1-makefile.patch )

src_prepare() {
	default
	append-ldflags $($(tc-getPKG_CONFIG) --libs $(usex luajit 'luajit' 'lua'))
	use debug && append-cflags -DLPEG_DEBUG
}

src_compile() {
	emake CC="$(tc-getCC)" \
		LUADIR="$($(tc-getPKG_CONFIG) --variable includedir $(usex luajit 'luajit' 'lua'))"
	if [[ ${CHOST} == *-darwin* ]]; then
		einfo "Fixing self-reference"
		install_name_tool -id "$($(tc-getPKG_CONFIG) --variable INSTALL_CMOD $(usex luajit 'luajit' 'lua'))/lpeg.so" "lpeg.so"
	fi
}

src_test() {
	$(usex luajit 'luajit' 'lua') test.lua || die
}

src_install() {
	exeinto "$($(tc-getPKG_CONFIG) --variable INSTALL_CMOD $(usex luajit 'luajit' 'lua') | sed "s#${EROOT}##")"
	doexe lpeg.so
	insinto "$($(tc-getPKG_CONFIG) --variable INSTALL_LMOD $(usex luajit 'luajit' 'lua') | sed "s#${EROOT}##")"
	doins re.lua

	use doc && einstalldocs
}
