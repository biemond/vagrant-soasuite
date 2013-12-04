#
# one machine setup with 11g XE database
#
# needs the following fiddyspence-sysctl, erwbgy-limits puppet modules
#

node 'xe11g.example.com' {

 
  include os2, oraclexe, orautils

  Class['os2'] -> 
    Class['oraclexe']

}


# operating settings for Database & Middleware
class os2 {

  group { 'dba' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  user { 'oracle' :
    ensure     => present,
    groups     => 'dba',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/oracle",
    comment    => 'Oracle user created by Puppet',
    managehome => true,
    require    => Group['dba'],
  }
 

  $install = [ 'binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64','ksh.x86_64','libaio.x86_64',
               'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64','compat-libcap1.x86_64', 'gcc.x86_64',
               'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64','libstdc++-devel.x86_64',
               'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.i686','libXtst.i686','bc.x86_64']
               
               
  package { $install:
    ensure  => present,
  }

  $remove = [ "java-1.7.0-openjdk.x86_64", "java-1.6.0-openjdk.x86_64" ]

  package { $remove:
    ensure  => absent,
  }

  # $downloadDir = "/data/install"
  # check oracle install folder
  file { "/data/install" :
    ensure        => directory,
    recurse       => false,
    replace       => false,
  }

  include jdk7

  jdk7::install7{ 'jdk1.7.0_45':
    version              => "7u45" , 
    fullVersion          => "jdk1.7.0_45",
    alternativesPriority => 18000, 
    x64                  => true,
    downloadDir          => "/data/install",
    urandomJavaFix       => true,
    sourcePath           => "/vagrant",
  } # end jdk7::install7


  class { 'limits':
    config => {
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'oracle'  => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
               },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}


  # 2GB is the largest swapfle that XE allows

  exec { "create swap file":
    command => "/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=2048",
    user => root,
    creates => "/var/swap.1",
  }
 
  exec { "attach swap file":
    command => "/sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1",
    require => Exec["create swap file"],
    user => root,
    unless => "/sbin/swapon -s | grep /var/swap.1",
  }

  # add swap file entry to fstab
  exec {"add swapfile entry to fstab":
    command => "/bin/echo >>/etc/fstab /var/swap.1 swap swap defaults 0 0",
    require => Exec["attach swap file"],
    user => root,
    unless => "/bin/grep '^/var/swap.1' /etc/fstab 2>/dev/null",
  }

  service { iptables:
    enable    => false,
    ensure    => false,
    hasstatus => true,
  }
    
} # end os2



class oraclexe {

  $downloadDir = "/data/install"

  if ! defined(File[$downloadDir]) {
    # check oracle install folder
    file { $downloadDir :
      ensure        => directory,
      recurse       => false,
      replace       => false,
    }
  }

  file { '/vagrant/sql/setUpSQL.sh':
    ensure  => 'present',
    mode    => '0755',
    owner   => 'vagrant';
  }
  
  exec { "Install Oracle XE 11g":
    command => "/bin/rpm -ivh /vagrant/oracle-xe-11.2.0-1.0.x86_64.rpm > /tmp/XEsilentinstall.log",
    require => Exec["attach swap file"],
    creates => "/etc/init.d/oracle-xe",
  }
  
  exec { "Configure Oracle XE":
    command     => "/etc/init.d/oracle-xe configure responseFile=/vagrant/xe.rsp >> /tmp/XEsilentinstall.log" ,
    subscribe   => Exec["Install Oracle XE 11g"],
    refreshonly => true,
  }
  
  exec { "SetORACLE_ENVForVagrant":
    command     => "/bin/echo . /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh  >> .bashrc" ,
    subscribe   => Exec["Configure Oracle XE"],
    refreshonly => true,
    user        => "vagrant",
  }
  
  exec { "AddVagrantToDBAGroup":
    command     => "/usr/sbin/usermod -g dba vagrant",
    subscribe   => Exec["SetORACLE_ENVForVagrant"],
    refreshonly => true,
  }
  
  exec { "UnlockHR":
    command     => "/vagrant/sql/setUpSQL.sh",
    subscribe   => Exec["AddVagrantToDBAGroup"],
    user        => "vagrant",
    refreshonly => true,
  }

  exec { "resizeTemp":
    command     => "/vagrant/sql/setUpTemp.sh",
    subscribe   => Exec["UnlockHR"],
    user        => "vagrant",
    refreshonly => true,
  }

  include oradb
      
      # RCU runs as root from /data/install 

  oradb::rcu{ 'DEV_PS6':
                     rcuFile          => 'ofm_rcu_linux_11.1.1.7.0_64_disk1_1of1.zip',
                     product          => 'soasuite',
                     version          => '11.1.1.7',
                     oracleHome       => '/u01/app/oracle/product/11.2.0/xe',
                     user             => 'oracle',
                     group            => 'dba',
                     downloadDir      => $downloadDir,
                     action           => 'create',
                     dbServer         => 'localhost:1521',
                     dbService        => 'XE',
                     sysPassword      => 'oracle',
                     schemaPrefix     => 'DEV',
                     reposPassword    => 'oracle',
                     tempTablespace   => 'TEMP',
                     puppetDownloadMntPoint  => '/vagrant',
                     require          =>  Exec["UnlockHR"],
  }

} #end oraclexe

