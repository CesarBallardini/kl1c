# -*- mode: ruby -*-
# vi: set ft=ruby :

# To use this Vagrantfile you need Vagrant and Virtualbox installed:
#
#   * Virtualbox
#
#   * Vagrant
#
#   * Vagrant plugins:
#       + vagrant-proxyconf and its configuration if you need a Proxy to reach the Internet
#       + vagrant-cachier
#       + vagrant-disksize
#       + vagrant-hostmanager
#       + vagrant-share
#       + vagrant-vbguest

VAGRANTFILE_API_VERSION = "2"

HOSTNAME = "kl1c"


$post_up_message = <<POST_UP_MESSAGE
------------------------------------------------------
KL1 - Kernel Language 1
Japanese Fifth Generation project

Ubuntu 16.04 Trusty i686 (32-bit)

See the /vagrant/examples/ directory to compile and run
the examples that ship with the distribution

------------------------------------------------------
POST_UP_MESSAGE


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.post_up_message = $post_up_message

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    # use cachier with NFS only if hostmanager manages the names in the host's /etc/hosts
    if Vagrant.has_plugin?("vagrant-cachier")

      config.cache.auto_detect = false
      # W: Download is performed unsandboxed as root as file '/var/cache/apt/archives/partial/xyz' couldn't be accessed by user '_apt'. - pkgAcquire::Run (13: Permission denied)

      #config.cache.synced_folder_opts = {
      #  owner: "_apt"
      #}
      # Configure cached packages to be shared between instances of the same base box.
      # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
      config.cache.scope = :box

      # OPTIONAL: If you are using VirtualBox, you might want to use that to enable
      # NFS for shared folders. This is also very useful for vagrant-libvirt if you
      # want bi-directional sync

      # NOTE: with an encrypted HOME, NFS does not work; if that's not your case, uncomment the following parameters:
      #config.cache.synced_folder_opts = {
      #  type: :nfs,
      #  # The nolock option can be useful for an NFSv3 client that wants to avoid the
      #  # NLM sideband protocol. Without this option, apt-get might hang if it tries
      #  # to lock files needed for /var/cache/* operations. All of this can be avoided
      #  # by using NFSv4 everywhere. Please note that the tcp option is not the default.
      #  mount_options: ['rw', 'vers=3', 'tcp', 'nolock', 'fsc' , 'actimeo=2']
      #}

      # For more information please check http://docs.vagrantup.com/v2/synced-folders/basic_usage.html
   end

  end

 config.vm.define HOSTNAME do |srv|

    srv.vm.box = "ubuntu/trusty32"
    srv.disksize.size = '10GB'
    #srv.disksize.size = '20GB'


    srv.vm.network "private_network", ip: "192.168.33.11"

    srv.vm.boot_timeout = 3600
    srv.vm.box_check_update = true
    srv.ssh.forward_agent = true
    srv.ssh.forward_x11 = true
    srv.vm.hostname = HOSTNAME

    if Vagrant.has_plugin?("vagrant-hostmanager")
      srv.hostmanager.aliases = %W(#{HOSTNAME+".domain.local.tld'"} #{HOSTNAME} )
    end

    if Vagrant.has_plugin?("vagrant-vbguest") then
        srv.vbguest.auto_update = true
        srv.vbguest.no_install = false
    end

    srv.vm.synced_folder ".", "/vagrant", disabled: false, SharedFoldersEnableSymlinksCreate: false


    srv.vm.provider :virtualbox do |vb|
      vb.gui = false
      vb.cpus = 2
      vb.memory = "1024"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]


      # https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm more parameters to customize in VB
    end
  end

    ##
    # Provisioning
    #
    config.vm.provision "fix-no-tty", type: "shell" do |s|
        s.privileged = false
        s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
    end
    config.vm.provision "system_update", type: "shell" do |s|  # http://foo-o-rama.com/vagrant--stdin-is-not-a-tty--fix.html
        s.privileged = false
        s.inline = <<-SHELL
          export DEBIAN_FRONTEND=noninteractive
          export APT_LISTCHANGES_FRONTEND=none
          export APT_OPTIONS=' -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold '

          sudo -E apt-get --purge remove apt-listchanges -y > /dev/null 2>&1
          sudo -E apt-get update -y -qq > /dev/null 2>&1
          sudo dpkg-reconfigure --frontend=noninteractive libc6 > /dev/null 2>&1
          sudo -E apt-get -q --option "Dpkg::Options::=--force-confold" --assume-yes install libssl1.1  > /dev/null 2>&1 # https://bugs.launchpad.net/ubuntu/+source/openssl/+bug/1832919
          sudo -E apt-get install linux-image-generic ${APT_OPTIONS} || true
          sudo -E apt-get upgrade ${APT_OPTIONS} > /dev/null 2>&1
          sudo -E apt-get dist-upgrade ${APT_OPTIONS} > /dev/null 2>&1
          sudo -E apt-get autoremove -y > /dev/null 2>&1
          sudo -E apt-get autoclean -y > /dev/null 2>&1
          sudo -E apt-get clean > /dev/null 2>&1
        SHELL
    end
    config.vm.provision "ssh_pub_key", type: :shell do |s|
      begin
          ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
          s.inline = <<-SHELL
            mkdir -p /root/.ssh/
            touch /root/.ssh/authorized_keys
            echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
            echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
          SHELL
      rescue
          puts "No public keys in your PC's HOME"
          s.inline = "echo OK without public keys"
      end
    end
    config.vm.provision "build_deb_packages", type: "shell", run: "never" do |s|  # http://foo-o-rama.com/vagrant--stdin-is-not-a-tty--fix.html
        s.privileged = false
        s.inline = <<-SHELL
          export DEBIAN_FRONTEND=noninteractive
          export APT_LISTCHANGES_FRONTEND=none
          export APT_OPTIONS=' -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold '

          sudo apt-get install build-essential devscripts lintian diffutils patch patchutils quilt git dgit ${APT_OPTIONS}
          sudo apt-get install debhelper dh-make expect xterm vim mc ${APT_OPTIONS}


          # Start from a clean working area so re-runs are idempotent: a previous build leaves
          # its own klic_*+kl1c1.{dsc,deb,changes,...} here, and a stray second .dsc would make
          # `dpkg-source -x` misparse (it treats a 2nd arg as the output dir). The source cache
          # lives under /vagrant/download-cache (below), NOT here, so this wipe is safe.
          rm -rf deb/
          mkdir -p deb/
          pushd deb/

          export PACKAGE=klic
          export FULL_VERSION=3.003-gm1-4.1
          export SHORT_VERSION=3.003-gm1
          export SNAPSHOT_URL_BASE=https://snapshot.debian.org/archive/debian/20061106T000000Z/pool/main/k/klic/

          # Cache the downloaded Debian source on the host (persists across `vagrant destroy`,
          # since /vagrant is the repo mount). Each file is fetched only if not already cached,
          # downloaded to a .tmp first so an interrupted wget never leaves a corrupt cache entry.
          # Only the three source files are cached; the build regenerates the doc .deb itself.
          CACHE=/vagrant/download-cache
          mkdir -p "$CACHE"
          for f in ${PACKAGE}_${FULL_VERSION}.dsc \
                   ${PACKAGE}_${FULL_VERSION}.diff.gz \
                   ${PACKAGE}_${SHORT_VERSION}.orig.tar.gz; do
            if [ ! -f "$CACHE/$f" ]; then
              wget -O "$CACHE/$f.tmp" "${SNAPSHOT_URL_BASE}/$f" && mv "$CACHE/$f.tmp" "$CACHE/$f"
            fi
            cp "$CACHE/$f" .
          done

          dpkg-source -x ${PACKAGE}_${FULL_VERSION}.dsc   # explicit .dsc (not *.dsc) -> unambiguous
          pushd klic-3.003-gm1/

          echo 5 > debian/compat
          patch  -p0 < /vagrant/patch.rules
          cp /vagrant/patch5.configure-bcmp debian/patch5.configure-bcmp
          cp /vagrant/patch6.print-varargs debian/patch6.print-varargs   # patch.rules applies this too; fixes builtin:print of compound terms ([..] -> [1,2,3])
          patch -p0 < /vagrant/patch.configure.expect

          # Bump the Debian revision so the patched packages are distinguishable from the pristine
          # 3.003-gm1-4.1 (`dpkg -s klic` then shows the new version -- the easy way to confirm a
          # rebuild took). `dch --local +kl1c` turns 3.003-gm1-4.1 into 3.003-gm1-4.1+kl1c1; the
          # changelog entry also documents why these packages differ from Debian's.
          export DEBEMAIL="cesar.ballardini@gmail.com"
          export DEBFULLNAME="Cesar Ballardini"
          dch --local +kl1c -D UNRELEASED "Rebuild for modern hosts: patch5 (force USEBCMP/USEBZERO/USESTRCHR), patch6 (real <stdarg.h> varargs, fixes builtin:print of compound terms), configure.expect tweaks, debian/compat set for the build host."

          debuild -us -uc -d

          popd

          # install the freshly created packages (globs so this stays version-agnostic after the dch bump):
          sudo dpkg -i klic_*_i386.deb klic-doc_*_all.deb

          # Publish the freshly built packages into the repo's trusty/ dir (via the /vagrant mount).
          # Older builds are kept (each version bump adds a new filename); trusty/install-latest.sh
          # picks the highest version at install time, so the newest is always the one chosen.
          cp klic_*_i386.deb klic-doc_*_all.deb /vagrant/trusty/

          # verify the installation (the +kl1c1 revision confirms the patched rebuild is what got installed):
          dpkg -l | grep klic
#          # ii  klic                                    3.003-gm1-4.1+kl1c1                        i386         KL1 to C compiler system
#          # ii  klic-doc                                3.003-gm1-4.1+kl1c1                        all          Documentation and sample KL1 files for the KLIC

        SHELL
    end


#    proxy_host_port = ENV['all_proxy'] || ENV['http_proxy']  || ""
#    proxy_host_port = if proxy_host_port.empty? then "" else proxy_host_port.scan(/\/\/([0-9\.]*):/)[0][0]+':'+proxy_host_port.scan(/:([0-9]*)$/)[0][0] end

end
