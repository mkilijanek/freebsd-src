# FreeBSD pkgbase Build System

## Overview

The pkgbase build system creates binary packages from the FreeBSD base system.
It transforms the traditional `make installworld` workflow into a modern
package-based update mechanism using `pkg(8)`.

## Architecture

The build system is modular, with each phase of package creation handled by
separate components:

```
tools/pkgbase/
├── README.md                    # This file
├── build/                       # Modular build system (NEW)
│   ├── vars.mk                  # Configuration variables
│   ├── common.mk                # Shared functions and definitions
│   ├── bootstrap.mk             # pkg bootstrap handling
│   ├── stage.mk                 # Staging targets (world, kernel, source)
│   ├── create.mk                # Package creation
│   ├── sign.mk                  # Repository signing
│   └── update.mk                # Update package logic
└── metalog_reader.lua           # METALOG analysis tool
```

## Build Process

The package build follows these phases:

### 1. Staging

Files are staged into temporary directories:

- **World**: Userland components → `${WSTAGEDIR}`
- **Kernel**: Kernel and modules → `${KSTAGEDIR}`  
- **Source**: Source code → `${SSTAGEDIR}`

Targets:
```makefile
make stage-packages-world    # Stage userland
make stage-packages-kernel   # Stage kernel
make stage-packages-source   # Stage source
make stage-packages          # All of the above
```

### 2. Package Creation

Staged files are packaged into `.pkg` files:

- **World packages**: Individual component packages (runtime, libraries, etc.)
- **Kernel packages**: Kernel packages per configuration
- **Source packages**: Source code as installable packages
- **Sets**: Metapackages grouping related packages

Targets:
```makefile
make create-packages-world   # Create world packages
make create-packages-kernel  # Create kernel packages
make create-packages-source  # Create source packages
make create-packages         # All of the above
```

### 3. Signing

Repository metadata is signed for secure distribution:

```makefile
make sign-packages           # Sign repository
```

### 4. Full Build

The complete process:

```bash
# Complete package build
make packages

# Or step by step:
make stage-packages
make create-packages
make sign-packages
```

## Configuration

### Variables (tools/pkgbase/build/vars.mk)

| Variable | Default | Description |
|----------|---------|-------------|
| `PKG_NAME_PREFIX` | `FreeBSD` | Package name prefix |
| `PKG_MAINTAINER` | `re@FreeBSD.org` | Maintainer email |
| `PKG_WWW` | `https://www.FreeBSD.org` | Project website |
| `PKG_WORKERS_COUNT` | `1` | Parallel workers for signing |

### Staging Directories (tools/pkgbase/build/common.mk)

| Variable | Default | Description |
|----------|---------|-------------|
| `WSTAGEDIR` | `${OBJTOP}/worldstage` | World staging directory |
| `KSTAGEDIR` | `${OBJTOP}/kernelstage` | Kernel staging directory |
| `SSTAGEDIR` | `${OBJTOP}/sourcestage` | Source staging directory |
| `REPODIR` | `${OBJTOP}/repodir` | Package repository output |

## Module Reference

### vars.mk

Configuration variables for the pkgbase build system.

**Exported Variables:**
- `PKG_NAME_PREFIX` - Package naming prefix
- `PKG_MAINTAINER` - Contact for package issues
- `PKG_WWW` - Project website URL
- `SOURCE_DATE_EPOCH` - For reproducible builds

### common.mk

Shared functions and directory definitions.

**Targets:**
- `_repodir` - Ensure repository directory exists

**Variables:**
- Staging directory paths
- Export definitions

### bootstrap.mk

Handles bootstrapping of the `pkg` tool if not present.

**Targets:**
- `_pkgbootstrap` - Install pkg if missing

**Behavior:**
- If `BOOTSTRAP_PKG_FROM_PORTS` is set, builds from ports
- Otherwise uses `pkg bootstrap`

### stage.mk

Staging targets for preparing files for packaging.

**Targets:**
- `stage-packages-world` - Stage userland files
- `stage-packages-kernel` - Stage kernel files
- `stage-packages-source` - Stage source files
- `stage-packages` - Run all staging

**Details:**
Each target:
1. Creates staging directory
2. Runs `make stageworld/stagekernel` with `DESTDIR`
3. Uses `-DNO_ROOT` for non-root staging

### create.mk

Package creation from staged files.

**Targets:**
- `create-packages-world` - Create world packages via packages/Makefile
- `create-packages-kernel` - Create kernel packages
- `create-packages-source` - Create source packages
- `create-packages-sets` - Create metapackages
- `create-packages` - All package creation

**Dependencies:**
- Requires staging complete (`.ORDER` constraints)
- Requires pkg bootstrapped

### sign.mk

Repository signing for secure distribution.

**Targets:**
- `sign-packages` - Sign repository metadata
- `real-sign-packages` - Actual signing implementation

**Output:**
- Creates `repo.signature` in repository
- Updates `latest` symlink

### update.mk

Incremental package updates.

**Targets:**
- `update-packages` - Build only changed packages
- `real-update-packages` - Implementation with comparison logic

**Features:**
- Compares with previous version (`PKG_VERSION_FROM`)
- Preserves unchanged packages
- Rebuilds changed packages only

## METALOG Format

The METALOG file tracks file metadata during staging:

```
./bin/ls type=file uname=root gname=wheel mode=0755 \
    tags=package=FreeBSD-utilities
```

Tools:
- `metalog_reader.lua` - Analyze and lint METALOG files

## Testing

### Dry-run Testing

```bash
# See what would be done without executing
make -n stage-packages
make -n create-packages
make -n packages
```

### Variable Verification

```bash
# Check configuration variables
make -V PKG_NAME_PREFIX
make -V WSTAGEDIR
```

### CI Testing

The pkgbase build is tested in Cirrus CI:
- Build verification on multiple architectures
- Package integrity checks
- Installation testing

## Contributing

When modifying the pkgbase build system:

1. **Document First**: Update this README before code changes
2. **Test Thoroughly**: Run full `make packages` before submitting
3. **Follow Style**: Use BSD Makefile style (see style.Makefile(5))
4. **Maintain Compatibility**: Don't break existing workflows

## See Also

- `build(7)` - General build instructions
- `pkg(8)` - Package management
- `src.conf(5)` - Source configuration
- `release/packages/` - Package definitions

## History

The modular build system was introduced to:
- Improve maintainability of pkgbase code
- Enable future enhancements (parallel builds, dependency tracking)
- Separate concerns for easier testing

## License

SPDX-License-Identifier: BSD-2-Clause
