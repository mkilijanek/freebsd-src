#-
# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright (c) 2026 The FreeBSD Foundation
#
# pkgbase configuration variables
#
# This file contains all pkgbase-related configuration variables.
# It is included from Makefile.inc1 during package builds.
#
# Variables here use ?= assignment to allow override from:
# - /etc/src.conf
# - /etc/make.conf
# - Command line
#

# Package naming configuration
PKG_NAME_PREFIX?=	FreeBSD
PKG_MAINTAINER?=	re@FreeBSD.org
PKG_WWW?=		https://www.FreeBSD.org

# Build settings
PKG_WORKERS_COUNT?=	1

# Export variables for package builds
.if make(*package*)
.export PKG_NAME_PREFIX
.export PKG_MAINTAINER
.export PKG_WWW

# Source date epoch for reproducible builds
# Used to ensure package timestamps are deterministic
.if !defined(PKG_TIMESTAMP)
.if !empty(GIT_CMD) && exists(${GIT_CMD}) && exists(${SRCDIR}/.git)
SOURCE_DATE_EPOCH!=	${GIT_CMD} -C ${SRCDIR} show -s --format=%ct HEAD
.else
TIMEEPOCHNOW=		%s
SOURCE_DATE_EPOCH=	${TIMEEPOCHNOW:gmtime}
.endif
.else
SOURCE_DATE_EPOCH=	${PKG_TIMESTAMP}
.endif

.endif	# make(*package*)
