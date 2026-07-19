# syntax=docker/dockerfile:1
#
# KLIC (KL1 -> C) on Debian 13 "trixie" (slim), amd64 host.
# Reproduces the Vagrantfile's `build_deb_packages` provisioner: builds the Debian
# `klic 3.003-gm1` package (source from snapshot.debian.org) applying this repo's three
# patches (patch.rules, patch5.configure-bcmp, patch.configure.expect).
#
# KLIC is a 32-bit application: even on an amd64 host it is compiled with `gcc -m32`
# via i386 multiarch.
#
# Build:  docker build -t kl1c .
# Usage (mount the repo, compile a .kl1 in place):
#   Linux / macOS / WSL:   docker run --rm -it -v "$PWD":/work kl1c
#   Windows PowerShell:    docker run --rm -it -v "${PWD}:/work" kl1c
#   Windows Git Bash:      MSYS_NO_PATHCONV=1 docker run --rm -it -v "$PWD":/work kl1c
#   Windows cmd.exe:       docker run --rm -it -v "%cd%":/work kl1c
#         # inside:  cd examples && make fact && ./fact      # -> 39916800
#   Git Bash needs MSYS_NO_PATHCONV=1 or MSYS mangles the ":/work" target into a Windows path
#   (symptom: /work is empty). The in-place compile also relies on -D_FILE_OFFSET_BITS=64 baked
#   into klic (below) so its 32-bit stat() works on the Docker Desktop mount.
#
# NOTE: the source is from 2006, the toolchain from 2026. Adaptations applied below:
#   - debian/compat 5 -> 7 (trixie's debhelper no longer accepts < 7).
#   - 32-bit libc.a lives in /usr/lib32/ (not /usr/lib/i386-linux-gnu/).
#   - stub /usr/bin/x-terminal-emulator (X tracer in a headless container).
#   - debuild --prepend-path=/usr/local/bin so the `gcc` wrapper is on the sanitised PATH.
#   - `gcc` wrapper (-m32 -fpermissive -fcommon -fgnu89-inline -D_FILE_OFFSET_BITS=64) to force
#     32-bit and relax/adapt the 2006 K&R C (see the wrapper RUN for the per-flag rationale).

############################  Stage 1: build the .deb  ############################
FROM debian:trixie-slim AS build

ARG PACKAGE=klic
ARG FULL_VERSION=3.003-gm1-4.1
ARG SHORT_VERSION=3.003-gm1
ARG SNAPSHOT_URL_BASE=https://snapshot.debian.org/archive/debian/20061106T000000Z/pool/main/k/klic

ENV DEBIAN_FRONTEND=noninteractive

# Debian packaging toolchain + 32-bit toolchain (i386 multiarch).
# gcc-multilib provides `gcc -m32`; libc6-dev-i386 are the 32-bit headers/libs.
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential fakeroot \
      devscripts debhelper dh-make quilt lintian \
      patch patchutils diffutils \
      expect wget ca-certificates \
      gcc-multilib libc6-dev-i386 libc6:i386 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# The Debian source is vendored in this repo under download-cache/ (fetched once from
# ${SNAPSHOT_URL_BASE}). Bring the cache into the image, then use it: for each source file,
# copy it from the cache if present, otherwise download it into the cache first and then copy.
# So a populated cache means a fully offline, reproducible build (even if snapshot.debian.org
# disappears), while an empty/partial cache self-heals by fetching only what is missing.
COPY download-cache/ /build/cache/
RUN set -e; mkdir -p /build/cache; \
    for f in ${PACKAGE}_${SHORT_VERSION}.orig.tar.gz \
             ${PACKAGE}_${FULL_VERSION}.diff.gz \
             ${PACKAGE}_${FULL_VERSION}.dsc; do \
      if [ ! -f "/build/cache/$f" ]; then \
        echo "cache miss -> downloading $f"; \
        wget -q -O "/build/cache/$f.tmp" "${SNAPSHOT_URL_BASE}/$f" && mv "/build/cache/$f.tmp" "/build/cache/$f"; \
      else echo "cache hit  -> $f"; fi; \
      cp "/build/cache/$f" /build/; \
    done

# The patches live in this repo; bring them into the build context.
#   patch.rules            -> injects the patch5/patch6 apply lines into debian/rules
#   patch5.configure-bcmp  -> forces USEBCMP/USEBZERO/USESTRCHR in KLIC's Configure
#   patch6.print-varargs   -> rewrites klic_fprintf & friends with real <stdarg.h>
#                             varargs (gcc>=14 -O2 miscompiles the old fake-varargs,
#                             crashing builtin:print on compound terms)
#   patch.configure.expect -> answers KLIC's interactive Configure non-interactively
COPY patch.rules patch5.configure-bcmp patch6.print-varargs patch.configure.expect /build/

# Extract the source -> klic-3.003-gm1/  and apply the patches (like the provisioner).
# NOTE: the original provisioner used compat 5, but trixie's debhelper no longer accepts
# levels < 7 (dh_clean fails). We use 7, the lowest supported (least behavior change).
RUN dpkg-source -x *.dsc \
 && cd klic-${SHORT_VERSION} \
 && echo 7 > debian/compat \
 && patch -p0 < /build/patch.rules \
 && cp /build/patch5.configure-bcmp debian/patch5.configure-bcmp \
 && cp /build/patch6.print-varargs debian/patch6.print-varargs \
 && patch -p0 < /build/patch.configure.expect \
 # On Trusty (native 32-bit) libc.a was in /usr/lib/i386-linux-gnu/, but here
 # (amd64 + biarch toolchain) the 32-bit static libs are in /usr/lib32/.
 # We adapt ONLY in the Docker build (the repo patch still serves the Vagrant flow).
 && sed -i 's|/usr/lib/i386-linux-gnu/|/usr/lib32/|g' debian/configure.expect

# KLIC's Configure enables an X tracer and requires a terminal at
# /usr/bin/x-terminal-emulator; a headless container has no X. Configure only CHECKS
# that the executable exists (it does not launch it at build time), so we provide a stub
# to let it finish and generate the Makefile. The tracer is unused headless.
RUN ln -sf /bin/true /usr/bin/x-terminal-emulator

# KLIC's Configure hard-codes CC=gcc / LD=gcc interactively and IGNORES $CC, so exporting
# CC="gcc -m32" does not work (binaries would come out amd64). The 2000-era C also needs
# three legacy-compatibility flags that modern gcc (>=10/>=14) no longer defaults to:
#   -fpermissive     K&R definitions with no return type ("int f()") -> otherwise -Wimplicit-int
#                    is a hard error (gcc >=14).
#   -fcommon         headers define bare globals (e.g. `} my_klic_sgnl_flags;` in sighndl.h,
#                    included by several .c). gcc >=10 defaults to -fno-common, turning those
#                    tentative definitions into conflicting strong ones -> "multiple definition".
#   -fgnu89-inline   functions are defined plain `__inline__` in .c (e.g. resume_same_prio in
#                    unify.c). Under C99/gnu11 inline semantics gcc emits NO out-of-line copy,
#                    so libklict.a lacks the symbol -> "undefined reference". gnu89 inline
#                    restores the out-of-line emission KLIC relies on.
#   -D_FILE_OFFSET_BITS=64
#                    LFS. klic is a 32-bit binary; on a Docker Desktop bind mount (Win/macOS,
#                    virtiofs) file inode numbers exceed 32 bits, so klic's stat() fails with
#                    EOVERFLOW ("Value too large") -> "Can't access file foo.kl1" when compiling
#                    a .kl1 straight off a `-v "$PWD":/work` mount. 64-bit off_t/ino_t fixes it.
#                    Harmless on the native 32-bit Vagrant/Trusty flow (small inodes).
# FIXED via debian/patch6.print-varargs: `builtin:print` of a COMPOUND term (list/structure)
# used to crash (segfault / "invalid stdio handle") -- atoms/integers were fine. Root cause:
# klic_fprintf & friends (runtime/debug.c) were a pre-<stdarg.h> "fake varargs" hack (12 fixed
# `long' params, callers passing fewer with only a K&R prototype), which gcc 14 at -O2
# miscompiles -- a recursive fprint_partially() call had its FILE* argument clobbered. The
# patch reimplements them with real <stdarg.h> varargs (+ proper variadic prototypes in
# basic.h). Confirmed: at -O0 the old code worked, so it was an -O2 miscompilation, not a
# logic bug. (`putt` via klicio always worked and is still what the examples/tests use.)
# Robust wrapper: a `gcc` at the front of PATH forcing -m32 + the flags above. Since KLIC
# records CC/LD as "gcc" (PATH-relative), the wrapper transparently affects the compiler,
# the linker, and every sub-make.
RUN printf '#!/bin/sh\nexec /usr/bin/gcc -m32 -fpermissive -fcommon -fgnu89-inline -D_FILE_OFFSET_BITS=64 "$@"\n' > /usr/local/bin/gcc \
 && chmod +x /usr/local/bin/gcc

# debuild -us -uc (unsigned), -d (skip build-dependency check).
# --prepend-path=/usr/local/bin is ESSENTIAL: debuild sanitises the environment and
# deliberately DROPS /usr/local/bin from PATH ("Debian programs are built without locally
# installed programs"), so without this our `gcc` wrapper above is never seen -- the build
# would run the real /usr/bin/gcc, get no -m32 (amd64 binaries) and no -fpermissive
# (the 2006 K&R code fails with -Wimplicit-int errors under gcc >=14).
# Bump the Debian revision (3.003-gm1-4.1 -> 3.003-gm1-4.1+kl1c1) so the patched packages are
# distinguishable from the pristine Debian ones -- same scheme as the Vagrant provisioner, so both
# build paths emit identically-versioned packages. The final-stage COPY/dpkg globs on klic_*.deb,
# so the new filename needs no other change here.
RUN cd klic-${SHORT_VERSION} \
 && DEBEMAIL="cesar.ballardini@gmail.com" DEBFULLNAME="Cesar Ballardini" \
    dch --local +kl1c -D UNRELEASED "Rebuild for modern hosts: patch5 (force USEBCMP/USEBZERO/USESTRCHR), patch6 (real <stdarg.h> varargs, fixes builtin:print of compound terms), configure.expect tweaks, debian/compat 5->7 for trixie." \
 && debuild --prepend-path=/usr/local/bin -us -uc -d

# The .deb files end up in /build (the parent dir of the source tree).


###########################  Stage 2: runtime  ##########################
FROM debian:trixie-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# klic invokes `gcc` AT RUNTIME to compile the C it generates; since it recorded CC="gcc"
# (PATH-relative) and klic's runtime is 32-bit, that gcc must be -m32.
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      gcc-multilib libc6-dev-i386 libc6:i386 make \
 && rm -rf /var/lib/apt/lists/*

# Same wrapper as in build. -fpermissive is dropped (the C klic generates is clean of K&R), but
# the rest are kept: the generated C #includes the SAME 2000-era KLIC headers (sighndl.h,
# g_basic.h, ...) and links against libklict.a, so it needs -fcommon / -fgnu89-inline for the
# same reasons; and -D_FILE_OFFSET_BITS=64 so any 32-bit program klic builds here can also
# stat() files on the bind mount without EOVERFLOW.
RUN printf '#!/bin/sh\nexec /usr/bin/gcc -m32 -fcommon -fgnu89-inline -D_FILE_OFFSET_BITS=64 "$@"\n' > /usr/local/bin/gcc \
 && chmod +x /usr/local/bin/gcc

# Install the freshly built .deb files (klic + klic-doc). Wildcards to stay
# agnostic to the architecture in the name (_i386.deb / _amd64.deb).
COPY --from=build /build/klic_*.deb /build/klic-doc_*_all.deb /tmp/deb/
RUN apt-get update \
 && { dpkg -i /tmp/deb/*.deb || apt-get install -y -f --no-install-recommends; } \
 && rm -rf /tmp/deb /var/lib/apt/lists/*

# Mount the repo here to compile the .kl1 files:
#   docker run --rm -it -v "$PWD":/work kl1c
WORKDIR /work

CMD ["bash"]
