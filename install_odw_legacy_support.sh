#!/bin/bash
#
#
# SYNTAX:
#	Don't have any, just run it.
#
# DESCRIPTION:
#	Simple script to install "Opsview Data Warehouse" (ODW) that no longer available with "Opsview Core".
#	ODW was a part of "Opsview Community" (has been deprecated for a while now) and this script making ODW working with "Opsview Core".
#	For more information please check:
#	- http://docs.opsview.com/doku.php?id=opsview-core:upgrading:upgradetocore
#	- http://docs.opsview.com/doku.php?id=opsview4.4:odw
#	- http://www.opsview.com/products/opsview-core
#
# NOTES:
#       1. All ODW files/scripts are from Opsview Community 20120424 (The last Community Version).
#       2. This script tested with Opsview Core 3.20131016.0 and RHEL/Cetnos 6.5.
#       3. Some Opsview scripts have multi fuctions beside ODW functions,
#          so all files included with odw_legacy_support script get back to ODW only,
#          and any script has multi functions didn't included. (e.g. utils/rename_host script)"
#       4. This script working and tested with option "enable_odw_import" only,
#          the option "enable_full_odw_import" didn't tested practically yet.
#
# VERSION:
#	ODW legacy support script v0.3 - 1 November 2014.
#
#
# BY:
#	Ahmed M. AbouZaid (www.aabouzaid.com) - Under MIT license.
#	All copyright of "ODW" scripts goes to "Opsview Limited" and licensed under the terms of the GNU General Public License Version 2.
#
# TODO:
#	Make more testing and automate any manual actions.
#
#


##############################################################
# Main.
##############################################################

#Logging errors.
start_error_logging () { cat << EOF
$(printf '=%.0s' {1..75})
ODW legacy support script started - $(date)
$(printf '=%.0s' {1..75})
EOF
}

start_error_logging | tee -a odw_legacy_installer_error.log

#Displaying STDERR of script and logging it.
exec 2> >(tee -a odw_legacy_installer_error.log >&2)


#Check exit status and return message in the case of success or failure.
check_exit_status () {
  if [[ $? = 0 ]]; then
      echo -e "Done.\n"
   else
      echo -e "Unexpected Error! all errors logged in: odw_legacy_installer_error.log\n"
  fi
}


##############################################################
# Copying ODW files ... Bin, Installer, Lib, Libexec and Utils.
##############################################################

echo "REMEMBER! some Opsview scripts have multi fuctions plus ODW function, \
so all files included with odw_legacy_support script get back to ODW only, \
and any script has multi functions didn't included."

ODW_FILES_PATH="./ODW_files"

find ./ODW_files/ -type f | while read odw_file_path; do

  dirname_of_odw_file=$(dirname $odw_file_path)

  #Print message when start copying each directory and set its path in nagios.
  case $dirname_of_odw_file in
    "$ODW_FILES_PATH/Bin")
      [[ $dirname_of_odw_file != $dirname_of_previous_odw_file ]] && echo -e "\nCopying ODW/Bin files ..."
      nagios_copy_path="/usr/local/nagios/bin"
    ;;
    "$ODW_FILES_PATH/Installer")
      [[ $dirname_of_odw_file != $dirname_of_previous_odw_file ]] && echo -e "\nCopying ODW/Installer files ..."
      nagios_copy_path="/usr/local/nagios/installer"
    ;;
    "$ODW_FILES_PATH/Lib")
      [[ $dirname_of_odw_file != $dirname_of_previous_odw_file ]] && echo -e "\nCopying ODW/Lib files ..."
      nagios_copy_path="/usr/local/nagios/lib"
    ;;
    "$ODW_FILES_PATH/Lib/Odw")
      [[ ! -d /usr/local/nagios/lib/Odw/ ]] && mkdir /usr/local/nagios/lib/Odw/
      nagios_copy_path="/usr/local/nagios/lib/Odw"
    ;;
    "$ODW_FILES_PATH/Libexec")
      [[ $dirname_of_odw_file != $dirname_of_previous_odw_file ]] && echo -e "\nCopying ODW/Libexec files ..."
      nagios_copy_path="/usr/local/nagios/libexec"
    ;;
    "$ODW_FILES_PATH/Utils")
      [[ $dirname_of_odw_file != $dirname_of_previous_odw_file ]] && echo -e "\nCopying ODW/Utils files ..."
      nagios_copy_path="/usr/local/nagios/utils"
    ;;
  esac

  dirname_of_previous_odw_file=$(dirname $odw_file_path)
  odw_file_name=$(basename $odw_file_path)

  #Copying each ODW files to Nagios/Opsview.
  echo "  - $odw_file_name => $nagios_copy_path/$odw_file_name"
  cp -a $odw_file_path $nagios_copy_path/$odw_file_name &&
  chown -R nagios:nagios $nagios_copy_path/$odw_file_name &&
  chmod -R 550 $nagios_copy_path/$odw_file_name

  #Check exit status of previous operation.
  check_exit_status

done


##############################################################
# Configure database.
##############################################################

#Creating ODW database and user.
echo "Creating ODW database and adding its user..."
opsviewmysql_password=$(openssl rand -base64 8) &&
config_odw_database() { cat << EOF
    /* Creat ODW database and import its structure */
    CREATE DATABASE odw;
    USE odw;
    SOURCE odw_database_structure.sql;

    /* Add ODW user */
    GRANT SELECT ON *.* TO 'odw'@'localhost' IDENTIFIED BY '$opsviewmysql_password';
    GRANT ALL PRIVILEGES ON odw.* TO 'odw'@'localhost';
    FLUSH privileges;

    /* Enable ODW in opsview database */
    USE opsview;
    UPDATE systempreferences SET enable_odw_import='1';
EOF
}

if [[ -f /root/.my.cnf && -s /root/.my.cnf ]]; then
    config_odw_database | mysql
elif egrep -q "user=.?root.?" /etc/my.cnf; then
    config_odw_database | mysql
else
    echo 'Cannot connect to MySQL! You neet to enter MySQL root password!'
    config_odw_database | mysql -u root -p
fi

#Unhash next line if you need to enable "enable_full_odw_import" option (UNTESTED).
#mysql -e "USE opsview; UPDATE systempreferences SET enable_full_odw_import='1';"

#Check exit status of previous operation.
check_exit_status


##############################################################
# Modify configuration files.
##############################################################

#Adding ODW configuration to main Opsview config file (opsview.conf).
echo "Adding ODW configuration to main Opsview config file (opsview.conf)..."
sed -i '/runtime_dbpasswd/a\
\
#Added by odw_legacy_support script (https://github.com/AAbouZaid/ODW-Legacy-Support).\
#ODW db information for datawarehousing.\
$odw_dbuser = "odw";\
$odw_dbpasswd = "opsviewmysql_password";\
$odw_db = "odw";\
$odw_dbhost = "localhost";\
$odw_dbi = "dbi:mysql";' /usr/local/nagios/etc/opsview.conf &&
sed -i "s/opsviewmysql_password/$opsviewmysql_password/" /usr/local/nagios/etc/opsview.conf
#Check exit status of previous operation.
check_exit_status


#Modifying ODW configuration in Opsview config perl module (Opsview/Config.pm).
echo "Modifying ODW configuration in Opsview config perl module (Opsview/Config.pm)..."
sed -i '/runtime_dbpasswd/a\
\
#Added by odw_legacy_support script (https://github.com/AAbouZaid/ODW-Legacy-Support).\
sub odw_dbi      { return $Settings::odw_dbi }\
sub odw_db       { return $Settings::odw_db }\
sub odw_dbhost   { return $Settings::odw_dbhost }\
sub odw_dbuser   { return $Settings::odw_dbuser }\
sub odw_dbpasswd { return $Settings::odw_dbpasswd }' /usr/local/nagios/lib/Opsview/Config.pm
#Check exit status of previous operation.
check_exit_status


#Modifying ODW configuration in Opsview config perl module (Opsview/Systempreference.pm).
echo "Modifying ODW configuration in Opsview config perl module (Opsview/System Preference)..."
sed -i -r 's/^([ ]+)(opsview_server_name)([ ]*)$/\1enable_odw_import enable_full_odw_import \2\3/g' /usr/local/nagios/lib/Opsview/Systempreference.pm &&

sed -i '/sub hostgroup_info_url/a\
\
#Added by odw_legacy_support script (https://github.com/AAbouZaid/ODW-Legacy-Support).\
sub enable_odw_import          { return _pref( shift, "enable_odw_import",          shift ); }\
sub enable_full_odw_import     { return _pref( shift, "enable_full_odw_import",     shift ); }' /usr/local/nagios/lib/Opsview/Systempreference.pm
#Check exit status of previous operation.
check_exit_status


##############################################################
# Add import_runtime script to crontab.
##############################################################

#Adding ODW script to crontab that working every 4h to store data in "odw" database.
#The script takes data in runtime and imports into ODW.
echo "Adding ODW cron..."
odw_crontab () { cat << EOF
# OPSVIEW ODW START
4 * * * * . /usr/local/nagios/bin/profile && /usr/local/nagios/bin/import_runtime -q
# OPSVIEW ODW END
EOF
} &&

odw_crontab >> /var/spool/cron/root &&
chmod 600 /var/spool/cron/root

#Check exit status of previous operation.
check_exit_status


##############################################################
# End logging.
##############################################################

#End errors logging.
end_errors_logging () { cat << EOF

ODW legacy support script ended - $(date)
$(printf '_%.0s' {1..75})
EOF
}

end_errors_logging >> odw_legacy_installer_error.log

