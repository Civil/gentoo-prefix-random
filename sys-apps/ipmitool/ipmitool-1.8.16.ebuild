# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit autotools eutils

DESCRIPTION="Utility for controlling IPMI enabled devices."
HOMEPAGE="http://ipmitool.sf.net/"
DEBIAN_PR="3.debian"
DEBIAN_P="${P/-/_}"
DEBIAN_PF="${DEBIAN_P}-${DEBIAN_PR}"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz
	https://launchpad.net/ubuntu/+archive/primary/+files/${DEBIAN_PF}.tar.xz"
#IUSE="freeipmi openipmi status"
IUSE="openipmi static"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ia64 ~ppc ~x86"
LICENSE="BSD"

RDEPEND="dev-libs/openssl:0="
DEPEND="${RDEPEND}
		openipmi? ( sys-libs/openipmi )
		virtual/os-headers"
		#freeipmi? ( sys-libs/freeipmi )
# ipmitool CAN build against || ( sys-libs/openipmi sys-libs/freeipmi )
# but it doesn't actually need either.

src_prepare() {
	default
	[ -d "${S}"/debian ] && mv "${S}"/debian{,.package}
	ln -s "${WORKDIR}"/debian "${S}"
	for p in $(cat debian/patches/series) ; do
		eapply debian/patches/$p
	done
	eapply "${FILESDIR}/${P}-macosx-ftbs.patch"

	eautoreconf
}

src_configure() {
	# - LIPMI and BMC are the Solaris libs
	# - OpenIPMI is unconditionally enabled in the configure as there is compat
	# code that is used if the library itself is not available
	# FreeIPMI does build now, but is disabled until the other arches keyword it
	#	`use_enable freeipmi intf-free` \
	# --enable-ipmievd is now unconditional
	if [[ ${CHOST} != *-linux-* ]]; then
		myconf="--disable-intf-usb"
	else
		myconf="--enable-intf-usb"
	fi
	econf \
		$(use_enable static) \
		--enable-ipmishell \
		--enable-intf-lan \
		--enable-intf-lanplus \
		--enable-intf-open \
		--enable-intf-serial \
		--disable-intf-bmc \
		--disable-intf-dummy \
		--disable-intf-free \
		--disable-intf-imb \
		--disable-intf-lipmi \
		--disable-internal-md5 \
		${myconf} \
		--with-kerneldir=/usr --bindir=/usr/sbin \
		|| die "econf failed"
	if [[ ${CHOST} != *-darwin* ]] ; then
		# Fix linux/ipmi.h to compile properly. This is a hack since it doesn't
		# include the below file to define some things.
		echo "#include <asm/byteorder.h>" >>config.h
	else
		sed -i 's#HAVE_PRAGMA_PACK#DISABLE_PRAGMA_PACK#' "${S}/include/ipmitool/ipmi_user.h"
		sed -i 's#s6_addr16#s6_addr#' "${S}/src/plugins/ipmi_intf.c"
	fi
}

src_install() {
	emake DESTDIR="${ED}" PACKAGE="${PF}" install || die "emake install failed"

	into /usr
	dosbin contrib/bmclanconf
	rm -f "${ED}"/usr/share/doc/${PF}/COPYING
	docinto contrib
	cd "${S}"/contrib
	dodoc collect_data.sh create_rrds.sh create_webpage_compact.sh create_webpage.sh README

	newinitd "${FILESDIR}"/${PN}-1.8.9-ipmievd.initd ipmievd
	newconfd "${FILESDIR}"/${PN}-1.8.9-ipmievd.confd ipmievd
	# TODO: init script for contrib/bmc-snmp-proxy
	# TODO: contrib/exchange-bmc-os-info
}
