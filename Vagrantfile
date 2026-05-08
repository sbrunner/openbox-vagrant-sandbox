require "digest"
require "shellwords"

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
  file_mounts = []
  mounted_file_parent_dirs = {}

  project_mount = lambda do |host_path, guest_path, writable: false, fmode: "664", dmode: "775"|
    expanded_host = File.expand_path(host_path.to_s)
    blocked_paths = ["/", "/home", host_home]

    raise "Host path does not exist: #{expanded_host}" unless File.exist?(expanded_host)
    raise "Refusing to mount broad/sensitive path: #{expanded_host}" if blocked_paths.include?(expanded_host)

    mount_options = ["uid=#{host_uid}", "gid=#{host_gid}", "dmode=#{dmode}", "fmode=#{fmode}"]
    mount_options << "ro" unless writable

    if File.directory?(expanded_host)
      config.vm.synced_folder expanded_host, guest_path,
                              type: "virtualbox",
                              mount_options: mount_options
      next
    end

    host_parent_dir = File.dirname(expanded_host)
    guest_parent_mount = mounted_file_parent_dirs[host_parent_dir]

    unless guest_parent_mount
      guest_parent_mount = "/tmp/host-files/#{Digest::SHA1.hexdigest(host_parent_dir)[0, 12]}"
      mounted_file_parent_dirs[host_parent_dir] = guest_parent_mount

      config.vm.synced_folder host_parent_dir, guest_parent_mount,
                              type: "virtualbox",
                              mount_options: mount_options
    end

    file_mounts << {
      source: File.join(guest_parent_mount, File.basename(expanded_host)),
      target: guest_path
    }
  end

  local_vagrantfile = File.join(__dir__, "Vagrantfile.local")
  eval(File.read(local_vagrantfile), binding, local_vagrantfile) if File.file?(local_vagrantfile)

  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = vm_hostname
  config.vm.boot_timeout = 600
  config.ssh.forward_x11 = true


  # Disable default mapping of current folder to /vagrant.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.name = vm_name
    vb.cpus = vm_cpus
    vb.memory = vm_memory
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on", "--clipboard", "bidirectional"]
  end

  unless file_mounts.empty?
    commands = ["set -eu"]

    file_mounts.each do |mount|
      source = Shellwords.escape(mount[:source])
      target = Shellwords.escape(mount[:target])
      target_dir = Shellwords.escape(File.dirname(mount[:target]))

      commands << "mkdir -p #{target_dir}"
      commands << "rm -rf #{target}"
      commands << "ln -s #{source} #{target}"
    end

    config.vm.provision "shell",
                        inline: commands.join("\n"),
                        privileged: true,
                        run: "always"
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
