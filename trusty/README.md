# README

`.deb` files for the binaries and the documentation. Built on an Ubuntu 14.04.6 LTS Trusty i686 (32-bit).

Each rebuild is published here under a bumped Debian revision, and older builds are kept, so several
versions may be present. Currently:

* `klic_3.003-gm1-4.1_i386.deb`          / `klic-doc_3.003-gm1-4.1_all.deb`          (pristine Debian)
* `klic_3.003-gm1-4.1+kl1c1_i386.deb`    / `klic-doc_3.003-gm1-4.1+kl1c1_all.deb`    (this project's patched rebuild)
* `install-latest.sh`                    — installs the newest of the above (see below)

The `+kl1c1` revision marks the patched rebuild (notably `patch6`, which fixes `builtin:print` of
compound terms — plain `-4.1` prints lists as `[..]`). New builds are added here automatically by the
`Vagrantfile` `build_deb_packages` provisioner.

To install, run the helper — it picks the **highest version** of each package automatically (by Debian
version comparison, not filename order):

```bash
./install-latest.sh
```
