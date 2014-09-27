#!/bin/bash
#
#
# SYNTAX:
#	Don't have any, just run it.
#
# DESCRIPTION:
#	Simple script to install Opsview Data Warehouse (ODW) that no longer available with "Opsview Core".
#	ODW was a part of "Opsview Community" (has been deprecated for a while now) and this script making ODW working with "Opsview Core".
#	For more information please check: http://docs.opsview.com/doku.php?id=opsview4.4:odw
#
# NOTE:
#	This script working and tested with option "enable_odw_import" only.
#	The option "enable_full_odw_import" hadn't tested practically yet.
#
# VERSION:
#	ODW legacy installer v0.2.
#	Tested with Opsview Core 3.20131016.0 and RHEL/Cetnos 6.5.
#
# BY:
#	Ahmed M. AbouZaid (www.aabouzaid.com), September 2014, under MIT license.
#	All copyright of "ODW" goes to "Opsview Limited" and are licensed under the terms of the GNU General Public License Version 2.
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
###########################################################################
#ODW legacy support script started - $(date)
###########################################################################
EOF
}

start_error_logging | tee -a odw_legacy_installer_error.log

#Displaying STDERR of script and logging it.
exec 2> >(tee -a odw_legacy_installer_error.log >&2)


#Check exit status and return message in the case of success or failure.
check_exit_status () {
  if [[ $? = 0 ]]; then
      echo -e "Done. \n"
   else
      echo -e "Unexpected Error! all errors logged in: odw_legacy_installer_error.log\n"
  fi
}


##############################################################
# Copying ODW scripts, libraries and checks.
##############################################################

#Copying "import_runtime" script that responsible for store data in odw database.
#This modified version of original script, to see modifications
#search with "#Disabled by odw_legacy_script_installer." in script.
echo "Copying import_runtime..."
cp -a import_runtime /usr/local/nagios/bin/import_runtime &&
chown nagios:nagios /usr/local/nagios/bin/import_runtime &&
chmod 550 /usr/local/nagios/bin/import_runtime
#Check exit status of previous operation.
check_exit_status


#Copying "cleanup_import" script that responsible for store data in odw database.
echo "Copying cleanup_import..."
cp -a cleanup_import /usr/local/nagios/bin/cleanup_import &&
chown nagios:nagios /usr/local/nagios/bin/cleanup_import &&
chmod 550 /usr/local/nagios/bin/cleanup_import
#Check exit status of previous operation.
check_exit_status


#Copying Odw.pm
echo "Copying Odw.pm..."
cp -a Odw.pm /usr/local/nagios/lib/ &&
chown nagios:nagios /usr/local/nagios/lib/Odw.pm
#Check exit status of previous operation.
check_exit_status


#Copying Odw perl libraries.
echo "Copying Odw perl libraries..."
cp -a Odw_perl_libs /usr/local/nagios/lib/Odw/ &&
chown -R nagios:nagios /usr/local/nagios/lib/Odw/
#Check exit status of previous operation.
check_exit_status


#Install check_odw_status script that used in check ODW stat.
#Remember, you need to add check to Opsview form web interface after this.
echo "Copying check_odw_status..."
cp -a import_runtime /usr/local/nagios/libexec/check_odw_status &&
chown nagios:nagios /usr/local/nagios/libexec/check_odw_status &&
chmod 550 /usr/local/nagios/libexec/check_odw_status
#Check exit status of previous operation.
check_exit_status


##############################################################
# Configure database.
##############################################################

#Creating ODW database and user.
echo "Creating ODW database and adding its user..."
mysql -e "CREATE DATABASE odw;" &&
mysql odw < odw_database_structure.sql &&
mysql -e "GRANT SELECT ON *.* TO 'odw'@'localhost' IDENTIFIED BY 'opsviewmysql'; GRANT ALL PRIVILEGES ON odw.* TO 'odw'@'localhost'; flush privileges;" &&
mysql -e "USE opsview; UPDATE systempreferences SET enable_odw_import='1';"

#Unhash next line if you need to enable this option (UNTESTED).
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
#Added by odw_legacy_script_installer.\
#ODW db information for datawarehousing.\
$odw_dbuser = "odw";\
$odw_dbpasswd = "opsviewmysql";\
$odw_db = "odw";\
$odw_dbhost = "localhost";\
$odw_dbi = "dbi:mysql";' /usr/local/nagios/etc/opsview.conf
#Check exit status of previous operation.
check_exit_status


#Fixing ODW configuration in Opsview config perl module (Opsview/Config.pm).
echo "Fixing ODW configuration in Opsview config perl module (Opsview/Config.pm)..."
sed -i '/runtime_dbpasswd/a\
\
#Added by odw_legacy_script_installer.\
sub odw_dbi      { return $Settings::odw_dbi }\
sub odw_db       { return $Settings::odw_db }\
sub odw_dbhost   { return $Settings::odw_dbhost }\
sub odw_dbuser   { return $Settings::odw_dbuser }\
sub odw_dbpasswd { return $Settings::odw_dbpasswd }' /usr/local/nagios/lib/Opsview/Config.pm
#Check exit status of previous operation.
check_exit_status


#Fixing ODW configuration in Opsview config perl module (Opsview/Systempreference.pm).
echo "Fixing ODW configuration in Opsview config perl module (Opsview/System Preference)..."
sed -i -r 's/^([ ]+)(opsview_server_name)([ ]*)$/\1enable_odw_import enable_full_odw_import \2\3/g' /usr/local/nagios/lib/Opsview/Systempreference.pm
#Check exit status of previous operation.
check_exit_status

sed -i '/sub hostgroup_info_url/a\
\
#Added by odw_legacy_script_installer.\
sub enable_odw_import          { return _pref( shift, "enable_odw_import",          shift ); }\
sub enable_full_odw_import     { return _pref( shift, "enable_full_odw_import",     shift ); }' /usr/local/nagios/lib/Opsview/Systempreference.pm
#Check exit status of previous operation.
check_exit_status


##############################################################
# Modify configuration files.
##############################################################

#Adding ODW script to crontab that working every 4h to store data in "odw" database.
#The script takes data in runtime and imports into ODW.
echo "Installing ODW cron..."
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

