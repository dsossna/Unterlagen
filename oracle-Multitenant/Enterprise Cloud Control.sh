dbca -silent -createDatabase                                                    \
     -templateName General_Purpose.dbc                                          \
     -gdbname emcdb -sid emcdb -responseFile NO_VALUE                           \
     -characterSet AL32UTF8                                                     \
     -sysPassword oracle_4U                                                  \
     -systemPassword oracle_4U                                               \
     -createAsContainerDatabase true                                            \
     -numberOfPDBs 1                                                            \
     -pdbName emrep                                                             \
     -pdbAdminPassword oracle_4U                                             \
     -databaseType MULTIPURPOSE                                                 \
     -automaticMemoryManagement false                                           \
     -totalMemory 2000                                                          \
     -storageType FS                                                            \
     -datafileDestination /u02/oradata                                          \
     -redoLogFileSize 50                                                        \
     -emConfiguration NONE                                                      \
     -ignorePreReqs
	 
sqlplus / as sysdba <<EOF
  alter system set db_create_file_dest='/u02/oradata';
  alter pluggable database emrep save state;
  alter system set "_allow_insert_with_update_check"=true scope=both;
  alter system set session_cached_cursors=200 scope=spfile;
  alter system set sga_target=800M scope=both;
  alter system set pga_aggregate_target=450M scope=both;
  alter system set optimizer_adaptive_features=false scope=both;
  exit;
EOF

# Set restart flag in /etc/oratab.
cp /etc/oratab /tmp
sed -i -e "s|${ORACLE_SID}:${ORACLE_HOME}:N|${ORACLE_SID}:${ORACLE_HOME}:Y|g" /tmp/oratab
cp -f /tmp/oratab /etc/oratab