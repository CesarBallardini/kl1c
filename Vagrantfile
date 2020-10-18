# -*- mode: ruby -*-
# vi: set ft=ruby :

# Para aprovechar este Vagrantfile necesita Vagrant y Virtualbox instalados:
#
#   * Virtualbox
#
#   * Vagrant
#
#   * Plugins de Vagrant:
#       + vagrant-proxyconf y su configuracion si requiere de un Proxy para salir a Internet
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
Proyecto de Quinta Generación japonés

Ubuntu 16.04 Trusty i686 (32 bits)

Ver directorio /vagrant/examples/ para compilar y correr
los ejemplos que trae la distribución

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

    # uso cachier con NFS solamente si el hostmanager gestiona los nombres en /etc/hosts del host
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

      # NOTA: con encrypted HOME, no funciona el NFS, si no es tu caso, descomenta los parametros siguientes:
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
      srv.hostmanager.aliases = %W(#{HOSTNAME+".dominio.local.tld'"} #{HOSTNAME} )
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


      # https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm mas parametros para personalizar en VB
    end
  end

    ##
    # Aprovisionamiento
    #
    config.vm.provision "fix-no-tty", type: "shell" do |s|
        s.privileged = false
        s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
    end
    config.vm.provision "actualiza", type: "shell" do |s|  # http://foo-o-rama.com/vagrant--stdin-is-not-a-tty--fix.html
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
          puts "No hay claves publicas en el HOME de su pc"
          s.inline = "echo OK sin claves publicas"
      end
    end
    config.vm.provision "crea_paquete_deb", type: "shell", run: "never" do |s|  # http://foo-o-rama.com/vagrant--stdin-is-not-a-tty--fix.html
        s.privileged = false
        s.inline = <<-SHELL
          export DEBIAN_FRONTEND=noninteractive
          export APT_LISTCHANGES_FRONTEND=none
          export APT_OPTIONS=' -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold '

          sudo apt-get install build-essential devscripts lintian diffutils patch patchutils quilt git dgit ${APT_OPTIONS}
          sudo apt-get install debhelper dh-make expect xterm vim mc ${APT_OPTIONS}


          mkdir deb/
          pushd deb/
          
          export PAQUETE=klic
          export VERSION_LARGA=3.003-gm1-4.1
          export VERSION_CORTA=3.003-gm1
          export SNAPSHOT_URL_BASE=https://snapshot.debian.org/archive/debian/20061106T000000Z/pool/main/k/klic/

          wget ${SNAPSHOT_URL_BASE}/${PAQUETE}-doc_${VERSION_LARGA}_all.deb

          wget ${SNAPSHOT_URL_BASE}/${PAQUETE}_${VERSION_LARGA}.dsc
          wget ${SNAPSHOT_URL_BASE}/${PAQUETE}_${VERSION_LARGA}.diff.gz
          wget ${SNAPSHOT_URL_BASE}/${PAQUETE}_${VERSION_CORTA}.orig.tar.gz

          
          dpkg-source -x *.dsc
          pushd klic-3.003-gm1/

          #agrego comentario al changelog
          #dch -i

          # klic (3.003-gm1-4.1ubuntu1) UNRELEASED; urgency=medium
          # 
          #   * Ubuntu 16.04 Trusty Release
          # 
          #  -- Cesar Ballardini <cesar.ballardini@gmail.com>  Sun, 18 Oct 2020 17:46:31 +0000

          echo 5 > debian/compat
          patch  -p0 < /vagrant/patch.rules 
          cp /vagrant/patch5.configure-bcmp debian/patch5.configure-bcmp
          patch -p0 < /vagrant/patch.configure.expect
          debuild -us -uc -d

          popd

          # instala paquetes recién creados:
          sudo dpkg -i klic_3.003-gm1-4.1_i386.deb  klic-doc_3.003-gm1-4.1_all.deb



          # verifica la instalación:
          dpkg -l | grep klic
#          # ii  klic                                    3.003-gm1-4.1ubuntu1                       i386         KL1 to C compiler system
#          # ii  klic-doc                                3.003-gm1-4.1ubuntu1                       all          Documentation and sample KL1 files for the KLIC

        SHELL
    end


#    proxy_host_port = ENV['all_proxy'] || ENV['http_proxy']  || ""
#    proxy_host_port = if proxy_host_port.empty? then "" else proxy_host_port.scan(/\/\/([0-9\.]*):/)[0][0]+':'+proxy_host_port.scan(/:([0-9]*)$/)[0][0] end

end
