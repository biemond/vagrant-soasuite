node 'db'  {
   include os
   include db12c
}

# operating settings for Database & Middleware
class os {

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

  group { 'dba' :
    ensure      => present,
  }

  user { 'oracle' :
    ensure      => present,
    gid         => 'dba',  
    groups      => 'dba',
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => "/home/oracle",
    comment     => "This user ${user} was created by Puppet",
    require     => Group['dba'],
    managehome  => true,
  }

  $install = [ 'binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64','ksh.x86_64','libaio.x86_64',
               'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64','compat-libcap1.x86_64', 'gcc.x86_64',
               'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64','libstdc++-devel.x86_64',
               'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.i686','libXtst.i686']
       

  package { $install:
    ensure  => present,
  }

  class { 'limits':
         config => {
                    '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
                    'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                    'nproc'  => { soft => '2048'   , hard => '16384',  },
                                    'stack'  => { soft => '10240'  ,},},
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




}

class db12c {
  require os

    oradb::installdb{ '12.1_linux-x64':
            version                => '12.1.0.1',
            file                   => 'linuxamd64_12c_database',
            databaseType           => 'SE',
            oracleBase             => '/oracle',
            oracleHome             => '/oracle/product/12.1/db',
            userBaseDir            => '/home',
            createUser             => false,
            user                   => 'oracle',
            group                  => 'dba',
            downloadDir            => '/install',
            remoteFile             => false,
            puppetDownloadMntPoint => "/vagrant",  
    }

   oradb::net{ 'config net8':
            oracleHome   => '/oracle/product/12.1/db',
            version      => '12.1',
            user         => 'oracle',
            group        => 'dba',
            downloadDir  => '/install',
            require      => Oradb::Installdb['12.1_linux-x64'],
   }

   oradb::listener{'start listener':
            oracleBase   => '/oracle',
            oracleHome   => '/oracle/product/12.1/db',
            user         => 'oracle',
            group        => 'dba',
            action       => 'start',  
            require      => Oradb::Net['config net8'],
   }

   oradb::database{ 'testDb': 
                    oracleBase              => '/oracle',
                    oracleHome              => '/oracle/product/12.1/db',
                    version                 => '12.1',
                    user                    => 'oracle',
                    group                   => 'dba',
                    downloadDir             => '/install',
                    action                  => 'create',
                    dbName                  => 'test',
                    dbDomain                => 'oracle.com',
                    sysPassword             => 'Welcome01',
                    systemPassword          => 'Welcome01',
                    dataFileDestination     => "/oracle/oradata",
                    recoveryAreaDestination => "/oracle/flash_recovery_area",
                    characterSet            => "AL32UTF8",
                    nationalCharacterSet    => "UTF8",
                    initParams              => "open_cursors=1000,processes=600,job_queue_processes=4,compatible=12.1.0.0.0",
                    sampleSchema            => 'TRUE',
                    memoryPercentage        => "40",
                    memoryTotal             => "800",
                    databaseType            => "MULTIPURPOSE",                         
                    require                 => Oradb::Listener['start listener'],
   }

   oradb::dbactions{ 'start testDb': 
                   oracleHome              => '/oracle/product/12.1/db',
                   user                    => 'oracle',
                   group                   => 'dba',
                   action                  => 'start',
                   dbName                  => 'test',
                   require                 => Oradb::Database['testDb'],
   }

   oradb::autostartdatabase{ 'autostart oracle': 
                    oracleHome              => '/oracle/product/12.1/db',
                    user                    => 'oracle',
                    dbName                  => 'test',
                    require                 => Oradb::Dbactions['start testDb'],
   }

  oradb::rcu{  'DEV_PS6':
                 rcuFile          => 'ofm_rcu_linux_11.1.1.7.0_64_disk1_1of1.zip',
                 product          => 'soasuite',
                 version          => '11.1.1.7',
                 user             => 'oracle',
                 group            => 'dba',
                 downloadDir      => '/install',
                 action           => 'create',
                 oracleHome       => '/oracle/product/12.1/db',
                 dbServer         => 'db.example.com:1521',
                 dbService        => 'test.oracle.com',
                 sysPassword      => 'Welcome01',
                 schemaPrefix     => 'DEV',
                 reposPassword    => 'Welcome01',
                 tempTablespace   => 'TEMP',
                 puppetDownloadMntPoint => '/vagrant',
                 remoteFile       => false,
                 logoutput        => true,
                 require          => Oradb::Dbactions['start testDb'],
  }

}

