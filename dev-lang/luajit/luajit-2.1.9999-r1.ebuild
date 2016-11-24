# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils multilib multilib-minimal portability pax-utils toolchain-funcs versionator flag-o-matic check-reqs git-r3

DESCRIPTION="Just-In-Time Compiler for the Lua programming language"
HOMEPAGE="http://luajit.org/"
SRC_URI=""
EGIT_REPO_URI="http://luajit.org/git/luajit-2.0.git"
SLOT="2"
EGIT_BRANCH="v2.1"

LICENSE="MIT"
KEYWORDS=""
IUSE="debug valgrind lua52compat +optimization"

RDEPEND="
	valgrind? ( dev-util/valgrind )
"
DEPEND="
	${RDEPEND}
	app-eselect/eselect-luajit
	app-eselect/eselect-lua
"

PDEPEND="
	virtual/lua[luajit]
"

HTML_DOCS=( "doc/." )

MULTILIB_WRAPPED_HEADERS=(
    /usr/include/luajit-${SLOT}/luaconf.h
)


check_req() {
	if use optimization; then
		CHECKREQS_MEMORY="300M"
		check-reqs_pkg_${1}
	fi
}

pkg_pretend() {
	check_req pretend
}

pkg_setup() {
	check_req setup
}

src_prepare(){
	# fixing prefix and version
	sed -r \
		-e 's|^(VERSION)=.*|\1=${PV}|' \
		-e 's|^(INSTALL_SONAME)=.*|\1=$(INSTALL_SOSHORT1).$(VERSION)|' \
		-e 's|^(INSTALL_PCNAME)=.*|\1=${P}.pc|' \
		-e "s|( PREFIX)=.*|\1=${EROOT}/usr|" \
		-e 's|^(FILE_MAN)=.*|\1=${P}.1|' \
		-i Makefile || die "failed to fix prefix in Makefile"

	sed -r \
		-e 's|^(#define LUA_LJDIR).*|\1 "/'${P}'/"|' \
		-i src/luaconf.h || die "Failed to slotify"

	use debug && (
		sed -r \
			-e 's/#(CCDEBUG= -g)/\1 -ggdb -O0/' \
			-i src/Makefile || die "Failed to enable debug"
	)
	mv "${S}"/etc/${PN}.1 "${S}"/etc/${P}.1

	eapply_user
	multilib_copy_sources
}

multilib_src_configure() {
	sed -r \
		-e "s|^(prefix)=.*|\1=/usr|" \
		-e "s|^(multilib)=.*|\1=$(get_libdir)|" \
		-i "etc/${PN}.pc" || die "Failed to slottify"
}

multilib_src_compile() {
	local opt xcflags;
	use optimization && opt="amalg";

	tc-export CC

	xcflags=(
		$(usex lua52compat "-DLUAJIT_ENABLE_LUA52COMPAT" "")
		$(usex debug "-DLUAJIT_USE_GDBJIT" "")
		$(usex valgrind "-DLUAJIT_USE_VALGRIND" "")
		$(usex valgrind "-DLUAJIT_USE_SYSMALLOC" "")
	)

	emake \
		Q= \
		HOST_CC="$(tc-getCC)" \
		CC="${CC}" \
		TARGET_STRIP="true" \
		XCFLAGS="${xcflags[*]}" "${opt}"
}

multilib_src_install() {
	emake DESTDIR="${D}" MULTILIB="$(get_libdir)" install

	base_src_install_docs

	host-is-pax && pax-mark m "${ED}usr/bin/${P}"
	newman "etc/${P}.1" "luacjit-${PV}.1"
	newbin "${FILESDIR}/luac.jit" "luacjit-${PV}"
	ln -s "${P}" "${ED}usr/bin/${PN}-${SLOT}"
	#if [[ ${CHOST} = *-darwin-* ]]; then
	#	einfo "Fixing self-reference"
	#	lib="usr/$(get_libdir)/libluajit-5.1.2.1.0.dylib"
	#	install_name_tool -id "${EPREFIX}/${lib}" "${ED}/${lib}"
	#fi
}

pkg_postinst() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/luajit) ]] ; then
		eselect luajit set luajit-${PV}
	fi
	if [[ ! -n $(readlink "${ROOT}"usr/bin/lua) ]] ; then
		eselect lua set jit-${PV}
	fi
}
