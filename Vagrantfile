require "digest"

Vagrant.configure("2") do |config|
  host_uid = Process.uid
  host_gid = Process.gid
  host_home = File.expand_path("~")
  instance_dir = File.expand_path(__dir__)
  instance_slug = File.basename(instance_dir).downcase.gsub(/[^a-z0-9-]/, "-")
  instance_slug = "sandbox" if instance_slug.empty?
  instance_hash = Digest::SHA1.hexdigest(instance_dir)[0, 8]
  vm_name = ENV.fetch("VM_NAME", "opencode-#{instance_slug}-#{instance_hash}")
  vm_hostname = ENV.fetch("VM_HOSTNAME", vm_name)[0, 63]
  vm_cpus = ENV.fetch("VM_CPUS", "2")
  vm_memory = ENV.fetch("VM_MEMORY", "4096")

  project_mount = lambda do |host_path, guest_path, writable: false, fmode: "664", dmode: "775"|
    expanded_host = File.expand_path(host_path.to_s)
    blocked_paths = ["/", "/home", host_home]

    raise "Host path does not exist: #{expanded_host}" unless Dir.exist?(expanded_host)
    raise "Refusing to mount broad/sensitive path: #{expanded_host}" if blocked_paths.include?(expanded_host)

    mount_options = ["uid=#{host_uid}", "gid=#{host_gid}", "dmode=#{dmode}", "fmode=#{fmode}"]
    mount_options << "ro" unless writable

    config.vm.synced_folder expanded_host, guest_path,
                            type: "virtualbox",
                            mount_options: mount_options
  end

  # Mount a single file from the host by mounting its parent directory to a
  # temporary guest path, then copying it to the final destination with the
  # desired permissions. This works around VirtualBox shared folders being
  # read-only filesystems that ignore chmod at runtime.
  mount_file = lambda do |host_file, guest_file, mode: "600"|
    expanded_file = File.expand_path(host_file.to_s)
    return unless File.file?(expanded_file)

    tmp_mount = "/mnt/vagrant_file_#{Digest::SHA1.hexdigest(expanded_file)[0, 8]}"
    project_mount.call(File.dirname(expanded_file), tmp_mount, fmode: "400", dmode: "500")
    config.vm.provision "shell", privileged: true, inline: <<~SHELL
      install -o vagrant -g vagrant -m #{mode} #{tmp_mount}/#{File.basename(expanded_file)} #{guest_file}
    SHELL
  end

  local_vagrantfile = File.join(__dir__, "Vagrantfile.local")
  eval(File.read(local_vagrantfile), binding, local_vagrantfile) if File.file?(local_vagrantfile)

  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = vm_hostname
  config.vm.boot_timeout = 600

  # Disable default mapping of current folder to /vagrant.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.name = vm_name
    vb.cpus = vm_cpus
    vb.memory = vm_memory
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provision "shell", path: "provision/bootstrap.sh", privileged: true
  config.vm.provision "shell", path: "provision/hardening.sh", privileged: true
  config.vm.provision "shell",
                      path: "provision/user_mapping.sh",
                      privileged: true,
                      reboot: true,
                      env: {
                        "HOST_UID" => host_uid.to_s,
                        "HOST_GID" => host_gid.to_s
                      }
end
