# Pkgbase Modularization - Issue Tracking

## Overview

This document tracks all planned PRs for the pkgbase modularization effort.
These issues should be created in the FreeBSD Bugzilla or GitHub once PRs are ready for submission.

---

## Issue #1: [PR-001] Modularize pkgbase - Extract configuration variables

**Status:** ✅ IMPLEMENTED AND COMMITTED

**Branch:** `pkgbase-modularize-part1-vars`

**Description:**
Extract pkgbase-related configuration variables from Makefile.inc1 into tools/pkgbase/build/vars.mk.

**Changes:**
- Move PKG_NAME_PREFIX, PKG_MAINTAINER, PKG_WWW, PKG_WORKERS_COUNT
- Move SOURCE_DATE_EPOCH calculation logic
- Add include in Makefile.inc1
- Create tools/pkgbase/build/vars.mk
- Update documentation (README.md, pkgbase-build.7, IMPLEMENTATION.md)

**Backward Compatibility:** Full - all variables use ?= assignment

**Estimated Effort:** 3-5 days

---

## Issue #2: [PR-002] Modularize pkgbase - Extract staging targets

**Status:** 📝 READY FOR IMPLEMENTATION

**Branch:** `pkgbase-modularize-part2-stage`

**Description:**
Extract staging-related targets from Makefile.inc1 into tools/pkgbase/build/stage.mk.

**Changes:**
- Move stage-packages-world target
- Move stage-packages-kernel target
- Move stage-packages-source target
- Move stage-packages meta-target
- Create tools/pkgbase/build/stage.mk
- Create tools/pkgbase/build/common.mk for shared functions (_repodir, directories)

**Dependencies:**
- Requires PR-001 to be merged

**Testing:**
- [ ] make stage-packages works
- [ ] Individual stage-* targets work
- [ ] No regression in make packages

**Estimated Effort:** 1 week

---

## Issue #3: [PR-003] Modularize pkgbase - Complete modularization

**Status:** 📝 READY FOR IMPLEMENTATION

**Branch:** `pkgbase-modularize-part3-complete`

**Description:**
Complete modularization of pkgbase build system with separate files for each phase.

**Changes:**
- Create tools/pkgbase/build/bootstrap.mk (pkg bootstrap)
- Create tools/pkgbase/build/create.mk (package creation)
- Create tools/pkgbase/build/sign.mk (repository signing)
- Create tools/pkgbase/build/update.mk (update packages)
- Update Makefile.inc1 to include all modules
- Reduce Makefile.inc1 pkgbase code from ~400 to ~20 lines

**Dependencies:**
- Requires PR-001 and PR-002

**Testing:**
- [ ] Full make packages works
- [ ] make update-packages works
- [ ] Individual targets work
- [ ] CI passes

**Estimated Effort:** 2-3 weeks

---

## Issue #4: [PR-004] Add declarative dependencies to UCL

**Status:** 📋 PLANNED

**Description:**
Add explicit dependency declarations to package UCL files.

**Changes:**
- Add 'deps' section to packages/*/ucl/*.ucl files
- Update release/packages/template.ucl with deps template
- Update generate-ucl.lua to parse and validate deps
- Document dependency format

**Example:**
```ucl
deps:
  "${PKG_NAME_PREFIX}-clibs":
    version: ">=14.0"
    origin: "base/${PKG_NAME_PREFIX}-clibs"
```

**Estimated Effort:** 2 weeks

---

## Issue #5: [PR-005] Implement dependency solver in C

**Status:** 📋 PLANNED

**Description:**
Implement SAT-based dependency solver in C with Lua bindings.

**Changes:**
- Create tools/pkgbase/libdeps/
- depsolver.h - Public API
- depsolver.c - SAT solver implementation
- toposort.c - Fallback topological sort
- lua_bindings.c - Lua integration

**Features:**
- Parse declarative dependencies from UCL
- Detect circular dependencies
- Topological sort for build ordering
- Suggestions for unsatisfied dependencies

**Estimated Effort:** 4-6 weeks

**Performance Impact:** 10-100x faster than Lua for complex dependency resolution

---

## Issue #6: [PR-006] Add SQLite cache for incremental builds

**Status:** 📋 PLANNED

**Description:**
Implement SQLite-based caching to enable incremental package builds.

**Changes:**
- Create tools/pkgbase/libcache/
- pkgcache.h / pkgcache.c - Cache API
- schema.sql - Database schema
- Integration with create.mk

**Features:**
- Store file hashes for source files
- Track package build times
- Skip unchanged packages
- Invalidate cache on changes

**Performance Impact:** Build time reduced from 4-8h to 10-30 min for incremental changes

**Estimated Effort:** 3-4 weeks

---

## Issue #7: [PR-007] Implement parallel package builder

**Status:** 📋 PLANNED

**Description:**
Enable parallel building of independent packages using worker threads.

**Changes:**
- Create tools/pkgbase/parallel-builder.c
- Job queue implementation
- Worker pool with pthread
- Dependency-aware scheduling
- Progress reporting

**Usage:**
```bash
make packages PKG_PARALLEL_JOBS=8
```

**Performance Impact:** 4-8x speedup on multi-core systems

**Estimated Effort:** 3-4 weeks

---

## Issue #8: [PR-008] Add unit tests for metalog_reader.lua

**Status:** 📋 PLANNED

**Description:**
Create comprehensive unit tests for metalog_reader.lua using luaunit.

**Changes:**
- Create tools/pkgbase/tests/
- test_metalog_reader.lua
- Test fixtures (sample.metalog files)
- CI integration

**Test Cases:**
- Parse valid METALOG
- Detect duplicate entries
- Filter packages
- Generate statistics

**Estimated Effort:** 1 week

---

## Issue #9: [PR-009] Add unit tests for generate-ucl.lua

**Status:** 📋 PLANNED

**Description:**
Create unit tests for UCL generation scripts.

**Changes:**
- Create release/packages/tests/
- test_generate_ucl.lua
- test_generate_set_ucl.lua
- Test fixtures and expected outputs

**Test Cases:**
- Variable substitution
- Suffix generation
- Dependency addition
- Set assignment

**Estimated Effort:** 1 week

---

## Issue #10: [PR-010] Update pkgbase documentation

**Status:** 📋 PLANNED

**Description:**
Update and expand pkgbase documentation.

**Changes:**
- Update tools/pkgbase/README.md
- Add architecture overview
- Document all build modules
- Add troubleshooting guide
- Create examples

**Documentation:**
- User guide for pkgbase
- Developer guide for extending
- Migration guide from old system
- Performance tuning

**Estimated Effort:** 3-5 days

---

## Issue #11: [Future] Add per-package signing

**Status:** 📋 FUTURE

**Description:**
Sign individual packages in addition to repository metadata.

**Benefits:**
- Mirror without full trust
- Verification before installation
- Key rotation without rebuild

---

## Issue #12: [Future] Implement delta packages

**Status:** 📋 FUTURE

**Description:**
Generate delta packages using bsdiff for smaller updates.

**Benefits:**
- 70-90% reduction in update size
- Faster downloads
- Bandwidth savings

---

## Dependency Graph

```
PR-001: vars.mk
    ↓
PR-002: stage.mk (needs vars.mk)
    ↓
PR-003: complete (needs vars.mk + stage.mk)
    ↓
    ├── PR-004: UCL deps (can be parallel)
    ├── PR-006: SQLite cache (can be parallel)
    │
    ↓
PR-005: Dependency solver
    ↓
PR-007: Parallel builder (needs solver)

Documentation (can be anytime):
- PR-008: Tests metalog_reader
- PR-009: Tests generate-ucl
- PR-010: Documentation update
```

---

## Milestones

### Milestone 1: Foundation (Month 1-2)
- ✅ PR-001: Variables
- 📝 PR-002: Staging
- 📝 PR-003: Complete modularization

### Milestone 2: Dependencies (Month 2-4)
- 📋 PR-004: Declarative deps
- 📋 PR-005: Dependency solver

### Milestone 3: Performance (Month 4-5)
- 📋 PR-006: SQLite cache
- 📋 PR-007: Parallel builds

### Milestone 4: Quality (Month 5-6)
- 📋 PR-008: Tests metalog_reader
- 📋 PR-009: Tests generate-ucl
- 📋 PR-010: Documentation

---

## How to Use This Tracking

1. When starting work on an issue:
   - Update status from 📋 to 🚧
   - Assign yourself
   - Create branch: `pkgbase-<issue-name>`

2. When submitting PR:
   - Update status to ⏳ (in review)
   - Link PR in comments

3. When merged:
   - Update status to ✅
   - Note merge commit

---

## Notes

- These issues should be submitted to FreeBSD Bugzilla or GitHub
- Each PR should reference the appropriate issue
- Use 'Closes #X' in commit message to auto-close issues

---

*Generated: 2026-04-25*
*Maintainer: mkilijanek*
