Füge folgende Zeile der Datei "/etc/sysctl.conf" zu, oder erstelle diese Datei "/etc/sysctl.d/98-oracle.conf" mit den Zeilen als Inhalt.

fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500

Führe dieses Kommando aus um die Änderungen wirksam werden zu lassen.

/sbin/sysctl -p
# Or
/sbin/sysctl -p /etc/sysctl.d/98-oracle.conf

Überprüfe ob folgende Einträge in der Datei "/etc/security/limits.d/oracle-database-preinstall-19c.conf" sind.

oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768
oracle   hard   memlock    134217728
oracle   soft   memlock    134217728

Überprüfe ob alle diese Pakete installiert sind.

dnf install -y bc    
dnf install -y binutils
dnf install -y compat-libstdc++-33
dnf install -y elfutils-libelf
dnf install -y elfutils-libelf-devel
dnf install -y fontconfig-devel
dnf install -y glibc
dnf install -y glibc-devel
dnf install -y ksh
dnf install -y libaio
dnf install -y libaio-devel
dnf install -y libXrender
dnf install -y libXrender-devel
dnf install -y libX11
dnf install -y libXau
dnf install -y libXi
dnf install -y libXtst
dnf install -y libgcc
dnf install -y librdmacm-devel
dnf install -y libstdc++
dnf install -y libstdc++-devel
dnf install -y libxcb
dnf install -y make
dnf install -y net-tools # Clusterware
dnf install -y nfs-utils # ACFS
dnf install -y python # ACFS
dnf install -y python-configshell # ACFS
dnf install -y python-rtslib # ACFS
dnf install -y python-six # ACFS
dnf install -y targetcli # ACFS
dnf install -y smartmontools
dnf install -y sysstat
dnf install -y unixODBC

Erzeuge folgende Gruppen:

groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper 
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin
groupadd -g 54330 racdba

Sorge dafür das der Benutzer Oracle in diesen Gruppen Mitglied ist:

useradd -u 54321 -g oinstall -G dba,oper oracle

Setze die Sicherheitseinstellungen für Linux in der Datei "/etc/selinux/config" wie folgt.

SELINUX=permissive

Führe dieses Kommando aus damit diese Änderung wirksam ist.

setenforce Permissive

Scahlte die Linux Firewall aus und entferne sie aus dem Autostart

systemctl stop firewalld
systemctl disable firewalld

Erzeuge folgende Verzeichnisse

mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
mkdir -p /u02/oradata
chown -R oracle:oinstall /u01 /u02
chmod -R 775 /u01 /u02


Um sich das Leben später zu vereinfachen können Scripte helfen.
Dazu im Homeverzeichnis von Oracle das Verzeichnis scripts erstellen.

mkdir /home/oracle/scrips

Dann werden folgende Scripts erstellt:

cat > /home/oracle/scripts/setEnv.sh <<EOF
# Oracle Settings
export TMP=/tmp
export TMPDIR=\$TMP

export ORACLE_HOSTNAME=ol8-19.localdomain
export ORACLE_UNQNAME=cdb1
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_SID=cdb1
export PDB_NAME=pdb1
export DATA_DIR=/u02/oradata

export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH

export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF

Dieser Befehl fügt dieses Startscript dem Profil des Nutzers Oracle hinzu und es wird beim Anmelden ausgeführt.

echo ". /home/oracle/scripts/setEnv.sh" >> /home/oracle/.bash_profile

mit diesen Scripten lässt sich die Datenbank dann starten und stoppen:

cat > /home/oracle/scripts/start_all.sh <<EOF
#!/bin/bash
. /home/oracle/scripts/setEnv.sh

export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbstart \$ORACLE_HOME
EOF


cat > /home/oracle/scripts/stop_all.sh <<EOF
#!/bin/bash
. /home/oracle/scripts/setEnv.sh

export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbshut \$ORACLE_HOME
EOF

chown -R oracle:oinstall /home/oracle/scripts
chmod u+x /home/oracle/scripts/*.sh

Nach der Installation

Die Datei "/etc/oratab" ändern und das Neustart Flag auf 'Y'setzen.

cdb1:/u01/app/oracle/product/19.0.0/db_1:Y

Stelle sicher, dass die Containerdatenbanken nach dem Instanz Start mit hochgefahren werden.

sqlplus / as sysdba
alter system set db_create_file_dest='${DATA_DIR}';
alter pluggable database <Name des Containers> save state;
exit;


