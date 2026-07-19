# README

The goal is to write programs in KLIC, the implementation of KL1 that compiles on Unix systems.

The project behind KL1 is ICOT, which is now closed. There was a Debian package until 2006, whose
binaries were 32-bit.

To recreate the package on a more modern distro, I used Ubuntu 16.04 Trusty i686.

# Prerequisites

The Vagrantfile requires the `vagrant-disksize` plugin (it sets the VM disk size). Install it once
before bringing the VM up:

```bash
vagrant plugin install vagrant-disksize
```

Do **not** install `vagrant-vbguest`. The `ubuntu/trusty32` box already ships with Guest Additions,
which are enough for the `/vagrant` synced folder. On a mismatch (box GA 4.3.40 vs a modern VirtualBox)
Vagrant only prints a harmless warning and continues. The `vagrant-vbguest` plugin (0.32.0), on the
other hand, crashes `vagrant up` on current Vagrant: it calls `File.exists?`, which Ruby 3.2+ removed,
and Vagrant 2.4.9 embeds Ruby 3.3. If it is already installed, remove it:

```bash
vagrant plugin uninstall vagrant-vbguest
```

# How to use the ready-made packages

The `trusty` directory holds the `.deb` packages built for Trusty.

```bash

# create the VM
vagrant up
vagrant reload

# install the packages
vagrant ssh  #  log into the VM

cd /vagrant/trusty/
./install-latest.sh    # installs the newest klic + klic-doc .deb present (highest Debian version)
```

# How to recreate the `.deb` packages

```bash

# create the VM
vagrant up
vagrant reload

# create the packages
vagrant provision --provision-with build_deb_packages

```

The packages end up in `/home/vagrant/deb/` (that is inside the VM).




# Using the Docker container

Instead of the Vagrant VM, you can build KLIC as a Docker image (Debian trixie, amd64 host; KLIC is
compiled 32-bit via `gcc -m32`). This needs only Docker.

## Build the image

```bash
docker build -t kl1c .
```

The build downloads the Debian `klic 3.003-gm1` source, applies this repo's patches, builds the
`.deb`s and installs them, so `klic` is ready to use.

## Run the container (mounting the repo)

Mount the repo at `/work` so you can compile the `.kl1` files in place. The mount syntax depends on
your shell:

| Host shell          | Command                                                        |
|---------------------|----------------------------------------------------------------|
| Linux / macOS / WSL | `docker run --rm -it -v "$PWD":/work kl1c`                      |
| Windows PowerShell  | `docker run --rm -it -v "${PWD}:/work" kl1c`                    |
| Windows Git Bash    | `MSYS_NO_PATHCONV=1 docker run --rm -it -v "$PWD":/work kl1c`   |
| Windows cmd.exe     | `docker run --rm -it -v "%cd%":/work kl1c`                      |

On **Windows** (Git Bash) you must set `MSYS_NO_PATHCONV=1`, otherwise MSYS mangles the `:/work`
target and the mount comes up empty. It is a harmless no-op on Linux/macOS/WSL, so every mount command
below is prefixed with it and works on all platforms as written.

## Build and test everything with `make`

The repo has recursive `make` targets. The container's working directory is `/work` (the mount), so
`make` runs there by default:

```bash
# build every KL1 program (distribution examples + book examples, all chapters)
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/work kl1c make all

# run every test and example: tests/ compares each program's output to its .expected,
# the book examples are verified the same way, and the distribution examples are compiled
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/work kl1c make test

# remove all generated files
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/work kl1c make clean
```

`make all`/`make test`/`make clean` recurse into `examples/`, `agent-oriented-programming/` (per
chapter) and `tests/` (per category), running the same target in each. `make test` prints one line per
program (`PASS` / `FAIL` / `RUN` / `CFAIL`) and exits non-zero if anything fails.

You can also run a single subtree or category:

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/work kl1c make -C tests/float test
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/work kl1c make -C agent-oriented-programming test
```

## Run a single example interactively

```bash
MSYS_NO_PATHCONV=1 docker run --rm -it -v "$PWD":/work kl1c
# then, inside the container:
make -C agent-oriented-programming/ch04-event-driven-condition-synchronization
./agent-oriented-programming/ch04-event-driven-condition-synchronization/primes_sieve  # -> [2,3,5,7,11,13,17,19,23,29]

cd examples && make fact && ./fact   # KLIC distribution example -> 39916800
```

See `tests/README.md`, `agent-oriented-programming/README.md` and `examples/README.md` for details.
(`tests/` also ships a `run.sh` runner with category filters and a configurable per-case timeout.)


# Appendix: Downloading klic sources

* We download a mirror of ICOT's free software (ifs: ICOT Free Software) from its online DVD; from
  2005 through at least October 2020. It takes about 122 MB, with more software than just klic.

```bash
wget --tries=inf --timestamping --recursive --level=inf --convert-links --page-requisites --no-parent -R '\?C=' https://www.ueda.info.waseda.ac.jp/AITEC_ICOT_ARCHIVES/ICOT/ifs/
popd

# It may also be interesting to mirror ALL of ICOT, although too much is written in Japanese, and I
# understand none of it. (a couple of gigabytes)
wget --tries=inf --timestamping --recursive --level=inf --convert-links --page-requisites --no-parent -R '\?C=' https://www.ueda.info.waseda.ac.jp/AITEC_ICOT_ARCHIVES/ICOT/


```

# Appendix: References

* https://www.ueda.info.waseda.ac.jp/software.html [revived!] KLIC: Portable implementation of KL1 (version 3.012) Ubuntu 18.04LTS REVIEW TO CONTINUE!!!


* https://en.wikipedia.org/wiki/Fifth_generation_computer In the past, generations were about electronics: vacuum tubes, transistors, integrated circuits. Now generations are about the languages we use to communicate with the computer.


* https://www.sciencedirect.com/science/article/abs/pii/0167739X93900038 The Japanese national Fifth Generation project: Introduction, survey, and evaluation en: Future Generation Computer Systems Volume 9, Issue 2, July 1993, Pages 105-117
  Projecting a great vision of intelligent systems in the service of the economy and society, the Japanese government in 1982 launched the national Fifth Generation Computer Systems (FGCS) project. The project was carried out by a central research institute, ICOT, with personnel from its member-owners, the Japanese computer manufacturers (JCMs) and other electronics industry firms. The project was planned for ten years, but continues through year eleven and beyond. ICOT chose to focus its efforts on language issues and programming methods for logic programming, supported by special hardware. Sequential ‘inference machines’ (PSI) and parallel ‘inference machines’ (PIM) were built. Performances of the hardware-software hybrid was measured in the range planned (150 million logical inferences per second). An excellent system for logic programming on parallel machines was constructed (KL1). 

* The KL1 language
  * https://en.wikipedia.org/wiki/KL1
  * https://es.wikipedia.org/wiki/Kernel_Language_1 an example of programming in KL1
  * https://www.airc.aist.go.jp/aitec-icot/ICOT/Museum/IFS/abst/078.html KLIC, an implementation of KL1 for general-purpose computers (not the special-purpose ones of the Japanese fifth-generation project)


* https://www.springer.com/gp/book/9783540666837 Agent-Oriented Programming, From Prolog to Guarded Definite Clauses / Authors: Huntbach, Matthew M., Ringwood, Graem A. / 1999 / a book that can blow your mind
  * [Agent-oriented programming](https://archive.org/details/springer_10.1007-3-540-47938-4)

* KLIC Association, now defunct, its pages on the Web Archive:
  * https://web.archive.org/web/20100117145812/http://www.klic.org/software/klic/index.en.html
  * https://web.archive.org/web/20100110085645/http://www.klic.org/ the mailing lists haven't been updated since September 2000


* https://github.com/GunterMueller/KLIC — mirror of the "revived" KLIC from Waseda. It contains
  versions 3.01 / 3.011 / 3.013 / 3.014. It is still **32-bit** (runs "all as 32-bit applications",
  requires `gcc-multilib`), but its build is **non-interactive**: `cp config.sh.Ubuntu config.sh`
  (already carries `DEF_CC='gcc -m32'`) → `./Configure` → `make all` → `make install`, without the
  Debian package's interactive `Configure`. It is the basis of **Path B** (alternative source to
  `3.003-gm1`). My fork at https://github.com/CesarBallardini/KLIC
 * https://archive.org/details/springer_10.1007-3-540-47938-4 Book online, ready to read

* https://ja.wikipedia.org/wiki/Guarded_Horn_Clauses (in Japanese, use Google Translate to English)
* https://www.ueda.info.waseda.ac.jp/~ueda/pub/GHCthesis.pdf GUARDED HORN CLAUSES / Kazunori Ueda / March 1986
* https://core.ac.uk/download/pdf/82787481.pdf THE DEEVOLUTION OF CONCURRENT LOGIC PROGRAMMING LANGUAGES / E. TICK / 1995
* https://www.ueda.info.waseda.ac.jp/~ueda/readings/GHC-intro.pdf presentation in Japanese
* https://www.ida.liu.se/~ulfni53/lpp/bok/bok.pdf LOGIC, PROGRAMMING AND PROLOG (2ED) / Ulf Nilsson and Jan Małuszyński (a gentle intro to the GHC topic)
* http://blog.solutekcolombia.com/quinta-generacion-de-computadoras/ Review of events in the fifth-generation project.
* https://www.wikiwand.com/es/Quinta_generaci%C3%B3n_de_computadoras another review, with an interesting bibliography list
* https://www.cs.unm.edu/~eschulte/classes/cs550/data/middle-hist-lp.pdf Middle History of Logic Programming / Resolution, Planner, Prolog, and the Japanese Fifth Generation Project / Carl Hewitt
* https://www.cs.utexas.edu/users/EWD/transcriptions/EWD04xx/EWD472.html Guarded commands, non-determinacy and formal derivation of programs. / by Edsger W.Dijkstra https://www.cs.utexas.edu/users/EWD/ewd04xx/EWD472.PDF
