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
  provision_sections = ["base", "python", "node", "opencode"]
  allowed_sections = ["base", "python", "docker", "node", "k8s", "gh", "security", "opencode"]
  file_mounts = []
  mounted_file_parent_dirs = {}
  vm_disk_size = false

  if vm_disk_size
    # https://github.com/sprotheroe/vagrant-disksize
    # vagrant plugin install vagrant-disksize
    config.disksize.size = '100GB'
  end

  project_mount = lambda do |host_path, guest_path, writable: false, dmask: "000", fmask: "111", dmode: false, fmode: false|
    expanded_host = File.expand_path(host_path.to_s)
    blocked_paths = ["/", "/home", host_home]

    raise "Host path does not exist: #{expanded_host}" unless File.exist?(expanded_host)
    raise "Refusing to mount broad/sensitive path: #{expanded_host}" if blocked_paths.include?(expanded_host)

    mount_options = ["uid=#{host_uid}", "gid=#{host_gid}"]
    if dmode
      mount_options << "dmode=#{dmode}"
    else
      mount_options << "dmask=#{dmask}"
    end
    if fmode
      mount_options << "fmode=#{fmode}"
    else
      mount_options << "fmask=#{fmask}"
    end
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

  normalized_sections = Array(provision_sections).map { |section| section.to_s.strip.downcase }.reject(&:empty?).uniq
  normalized_sections = ["base", "python"] if normalized_sections.empty?
  unknown_sections = normalized_sections - allowed_sections
  unless unknown_sections.empty?
    raise "Unknown provision section(s): #{unknown_sections.join(", ")}. Allowed values: #{allowed_sections.join(", ")}."
  end

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

  config.vm.synced_folder File.expand_path("provision", __dir__), "/opt/provision",
                          type: "virtualbox",
                          mount_options: ["ro", "dmode=755", "fmode=644"]
  config.vm.provision "shell",
                      inline: "set -eu; test -f /opt/provision/bootstrap.sh || (echo '/opt/provision/bootstrap.sh not found' >&2; ls -la /opt >&2 || true; exit 1); bash /opt/provision/bootstrap.sh",
                      privileged: true,
                      env: {
                        "PROVISION_SECTIONS" => normalized_sections.join(",")
                      }
  config.vm.provision "shell",
                      path: "provision/user_mapping.sh",
                      privileged: true,
                      reboot: true,
                      env: {
                        "HOST_UID" => host_uid.to_s,
                        "HOST_GID" => host_gid.to_s
                      }
end
