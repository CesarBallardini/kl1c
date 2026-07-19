# KL1 examples

Example programs in **KL1** (Kernel Language 1) to compile and run with `klic`.

Each `.kl1` compiles to a native executable with `klic -o <name> <name>.kl1`. The `Makefile`
automates the process.

## Compile and run (common to both environments)

Once inside the machine/container, and located in this directory (`examples/`):

```bash
make fact        # compiles fact.kl1 -> ./fact  (klic -o fact fact.kl1)
./fact           # run -> 39916800

make             # compile ALL examples
make clean       # remove intermediates (*.c *.h *.o *.ext work* klic.db), keep executables
make distclean   # also remove the executables
```

Available examples: `atomfunc client cmac deriv fact hanoi iotest kkqueen life mastermind
merge parsetest pascal pp primes primesp prio puzzle qlay qsort server turtles vecstr wave`.

> `klic` compiles the `.kl1` to C and then to a native executable; the `*.c/*.h/*.ext/*.o`
> and `klic.db` files are byproducts that `make clean` removes.

---

## Run from the Vagrant machine

The VM (Ubuntu Trusty i686) mounts the repo root at `/vagrant`.

1. Bring up and provision the VM (from the repo root, on the host):

   ```bash
   vagrant up
   vagrant reload        # required: picks up kernel / guest additions changes
   vagrant ssh
   ```

2. Install the pre-built `klic` packages (once, inside the VM):

   ```bash
   cd /vagrant/trusty/
   sudo dpkg -i klic_3.003-gm1-4.1_i386.deb klic-doc_3.003-gm1-4.1_all.deb
   ```

3. Compile and run the examples:

   ```bash
   cd /vagrant/examples/
   make fact
   ./fact               # -> 39916800
   ```

> The generated executables stay in the mounted directory (`/vagrant/examples`), also visible
> from the host.

---

## Run from the Docker container

The `kl1c` image ships `klic` already installed. Mount the repo at `/work` to compile the `.kl1`
in place.

1. Build the image (from the repo root, on the host):

   ```bash
   docker build -t kl1c .
   ```

2. Start the container mounting the repo. **The mount syntax depends on the host shell:**

   | Host shell                | Command                                                            |
   |---------------------------|--------------------------------------------------------------------|
   | Linux / macOS / WSL       | `docker run --rm -it -v "$PWD":/work kl1c`                          |
   | Windows PowerShell        | `docker run --rm -it -v "${PWD}:/work" kl1c`                        |
   | Windows Git Bash          | `MSYS_NO_PATHCONV=1 docker run --rm -it -v "$PWD":/work kl1c`       |
   | Windows cmd.exe           | `docker run --rm -it -v "%cd%":/work kl1c`                          |

   > On **Git Bash** you need `MSYS_NO_PATHCONV=1`, otherwise MSYS mangles the `:/work` target
   > and the mount comes up empty. Compiling on the mount works because `klic` was built with
   > `-D_FILE_OFFSET_BITS=64` (otherwise its 32-bit `stat()` fails with EOVERFLOW on the Docker
   > Desktop mount). See the `Dockerfile` header for details.

3. Once inside the container:

   ```bash
   cd examples
   make fact
   ./fact               # -> 39916800
   ```

> Since the repo is mounted, the generated executables and intermediates also appear on the host.
> Run `make distclean` before leaving to keep the tree clean.
