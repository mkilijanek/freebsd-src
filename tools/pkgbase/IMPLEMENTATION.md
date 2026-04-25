# PR-001 Implementation Guide

## Overview

Extract pkgbase configuration variables from Makefile.inc1 into a dedicated
file `tools/pkgbase/build/vars.mk`.

## Documentation-First Approach

Before modifying code, we document:
1. What variables are being moved
2. Why they are being moved
3. How the change maintains compatibility

## Changes Required

### Step 1: Create vars.mk

Create `tools/pkgbase/build/vars.mk` with the following content:

```makefile
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
```

### Step 2: Modify Makefile.inc1

**Location:** After line 591 (after revision/version detection)

**Remove:** Lines 592-612 (existing pkgbase variable definitions)

**Add:**
```makefile
# pkgbase configuration - modular build system
.include "${.CURDIR}/tools/pkgbase/build/vars.mk"
```

### Step 3: Verify Directory Structure

Ensure directory exists:
```bash
mkdir -p tools/pkgbase/build
```

## Compatibility Analysis

### Backward Compatibility

This change maintains full backward compatibility:

1. **Variable Semantics**: All variables use `?=` (lazy assignment), so:
   - User settings in `/etc/src.conf` are preserved
   - Command-line overrides work: `make packages PKG_NAME_PREFIX=Custom`
   - Environment variables respected

2. **Processing Order**: The include happens at the exact same point in
   Makefile.inc1 processing, maintaining evaluation order.

3. **No API Changes**: All variable names remain identical.

### Risk Assessment

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Include path fails | Low | Use `${.CURDIR}` for absolute path |
| Syntax error in vars.mk | Low | Test with `make -n` before commit |
| Variable ordering issue | Low | Same position in Makefile.inc1 |

## Testing Procedure

### Pre-implementation Baseline

```bash
cd /usr/src

# Record current values
make -V PKG_NAME_PREFIX > /tmp/before.txt
make -V PKG_MAINTAINER >> /tmp/before.txt
make -V PKG_WWW >> /tmp/before.txt

# Verify packages target works (dry-run)
make -n packages > /tmp/packages-before.txt 2>&1
```

### Post-implementation Verification

```bash
# After changes
make -V PKG_NAME_PREFIX > /tmp/after.txt
make -V PKG_MAINTAINER >> /tmp/after.txt
make -V PKG_WWW >> /tmp/after.txt

# Compare - should be identical
diff /tmp/before.txt /tmp/after.txt
# Expected: no output

# Test dry-run
make -n packages > /tmp/packages-after.txt 2>&1
# Should show same output structure
```

### Override Testing

```bash
# Test that overrides still work
make -V PKG_NAME_PREFIX PKG_NAME_PREFIX=CustomBSD
# Expected: CustomBSD

# Test command-line for packages
make -n packages PKG_NAME_PREFIX=CustomBSD 2>&1 | grep CustomBSD
# Expected: Shows CustomBSD in paths
```

## Style Guidelines

Following FreeBSD style.Makefile(5):

1. **Indentation**: Use tabs, not spaces
2. **Comments**: Use `#` for comments, `##` for documentation
3. **Variable Names**: Uppercase with underscores
4. **Assignment**: Use `?=` for defaults, `=` for computed values
5. **Line Length**: Prefer under 80 characters
6. **License**: Include SPDX-License-Identifier

## Commit Message

```
pkgbase: Extract pkgbase configuration variables into separate file

Extract pkgbase-related configuration variables from Makefile.inc1 into
tools/pkgbase/build/vars.mk. This is Part 1 of modularizing the pkgbase
build system.

Changes:
- Move PKG_NAME_PREFIX, PKG_MAINTAINER, PKG_WWW, PKG_WORKERS_COUNT
- Move SOURCE_DATE_EPOCH calculation logic
- Add include in Makefile.inc1 after revision detection
- Create tools/pkgbase/build/ directory

This separation:
- Improves maintainability by isolating configuration
- Makes variables easier to find and modify
- Prepares foundation for Part 2 (staging targets)
- Maintains full backward compatibility

All variables continue to use ?= assignment, preserving user overrides
from /etc/src.conf, /etc/make.conf, or command line.

No functional changes intended.

Reviewed by:
MFC after: 2 weeks
Relnotes: No
Differential Revision: https://reviews.freebsd.org/Dxxxxx
```

## Post-Implementation Checklist

- [ ] vars.mk created with proper license header
- [ ] Makefile.inc1 modified to include vars.mk
- [ ] Variables tested with `make -V`
- [ ] Dry-run packages tested: `make -n packages`
- [ ] Override behavior verified
- [ ] Documentation updated (README.md, pkgbase-build.7)
- [ ] Style verified with checkstyle9.pl
- [ ] No trailing whitespace introduced
- [ ] Commit message follows guidelines

## Related Work

This PR is the foundation for:
- PR-002: Extract staging targets
- PR-003: Complete modularization
- Future: Parallel builds, dependency solving

## References

- style.Makefile(5) - FreeBSD Makefile style guide
- https://docs.freebsd.org/en/books/handbook/cutting-edge/#makeworld
- pkg(8) - Package manager documentation
