vagrant-soasuite
================

Oracle SOA Suite PS6 domain with a 12c database with RCU

steps:
- vagrant up db
- vagrant up admin

OS users oracle/oracle

console http://10.10.10.10:7001/console  
username weblogic password weblogic1

database (10.10.10.5) 
username sys password Welcome01


used software for DB
- jdk-7u45-linux-x64.tar.gz
- linuxamd64_12c_database_1of2.zip
- linuxamd64_12c_database_2of2.zip
- ofm_rcu_linux_11.1.1.7.0_64_disk1_1of1.zip

used software for SOA
- ofm_soa_generic_11.1.1.7.0_disk1_1of2.zip
- ofm_soa_generic_11.1.1.7.0_disk1_2of2.zip
- p17071663_1036_Generic.zip
- wls1036_generic.jar
