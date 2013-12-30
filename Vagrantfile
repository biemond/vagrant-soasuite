# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "admin" , primary: true do |admin|
    admin.vm.box = "centos-6.5-x86_64"
    admin.vm.box_url = "https://dl.dropboxusercontent.com/s/np39xdpw05wfmv4/centos-6.5-x86_64.box"

    admin.vm.hostname = "admin.example.com"
    # admin.vm.network :forwarded_port, guest: 80, host: 8888 ,auto_correct: true
    # admin.vm.network :forwarded_port, guest: 7001, host: 7001, auto_correct: false
    admin.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
  
    admin.vm.network :private_network, ip: "10.10.10.10"
  
    admin.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2552"]
      vb.customize ["modifyvm", :id, "--name", "admin"]
    end
  
    admin.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml"
    
    admin.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "site.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"
  
      puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }
      
    end
  
  end

  config.vm.define "db" , primary: true do |db|
    db.vm.box = "centos-6.5-x86_64"
    db.vm.box_url = "https://dl.dropboxusercontent.com/s/np39xdpw05wfmv4/centos-6.5-x86_64.box"

    db.vm.hostname = "db.example.com"
    db.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    db.vm.network :private_network, ip: "10.10.10.5"
  
    db.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm"     , :id, "--memory", "2048"]
      vb.customize ["modifyvm"     , :id, "--name", "db"]
    end

  
    db.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml"
    
    db.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "db.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"
  
      puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }
      
    end
  
  end  



end
