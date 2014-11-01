#!/usr/bin/perl
#
#
# SYNTAX:
# 	upgradedb_odw.pl
#
# DESCRIPTION:
# 	Connects to odw DB and upgrades it to the latest level
#
#	Warning!!!! This file must be kept up to date with db_odw
#
#	Warning #2 !!! Only use DBI commands - no Class::DBI allowed
#
# AUTHORS:
#	Copyright (C) 2003-2012 Opsview Limited. All rights reserved
#
#    This file is part of Opsview
#
#    Opsview is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    Opsview is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Opsview; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

use strict;
use Getopt::Std;
use FindBin qw($Bin);
use lib "/usr/local/nagios/lib", "/usr/local/nagios/etc";
use Odw;

# Do not use Class::DBI methods to amend data
use Opsview::Config;

use Utils::DBVersion;

my $runtime_db = Opsview::Config->runtime_db;

sub create_db {
    print "Creating odw database\n";
    my $odw_create = "$FindBin::Bin/../bin/db_odw";
    exec("$odw_create db_install") or die("Couldn't exec '$odw_create db_install': $!");
}

# Check odw exists; if not then exec the create script
BEGIN {
    my $db;
    unless ( eval '$db = Odw->db_Main;' ) {
        create_db();
    }
    else {
        $db->disconnect();
    }
}

my $dbh        = Odw->db_Main;
my $db_changed = 0;

# Set no stdout buffering, needed due to top level tee
$| = 1;

# secondary check to ensure odw exists properly (i.e. DB may be there but have
# incorrect structure due to past partial upgrades
{
    my $found  = 0;
    my $tables = $dbh->prepare('show tables');
    $tables->execute;

    while ( my $table = $tables->fetchrow ) {

        # comparison must be for an original table else this wont work correctly
        $found = 1 if ( $table eq 'availability' );
    }
    create_db if ( !$found );
}

print "Upgrading ODW database", $/;
{
    local $dbh->{RaiseError};    # Turn off to ignore error
    local $dbh->{PrintError};
    my $value = $dbh->selectrow_array("SELECT version FROM database_version");
    unless ($value) {
        $dbh->do("CREATE TABLE database_version (version varchar(10))");
        $dbh->do("INSERT database_version VALUES ('2.7.0')");
    }
}

if ( db_version_lower("2.7.1") ) {
    $dbh->do(
        qq{
CREATE TABLE hosts (
	id int AUTO_INCREMENT,
	name varchar(255) NOT NULL,
	alias varchar(255),
	hostgroup1 varchar(128),
	hostgroup2 varchar(128),
	hostgroup3 varchar(128),
	hostgroup4 varchar(128),
	hostgroup5 varchar(128),
	hostgroup6 varchar(128),
	hostgroup7 varchar(128),
	hostgroup8 varchar(128),
	hostgroup9 varchar(128),
	hostgroup varchar(128),
	monitored_by varchar(128),
	active_date int NOT NULL,
	crc int,
	most_recent bool,
	PRIMARY KEY (id),
	INDEX (name),
	UNIQUE (active_date, name)
)
	}
    );
    $dbh->do('INSERT INTO hosts (id, name, alias, active_date) VALUES (1, "deletedhost", "Host that has been deleted before storing into datawarehouse", UNIX_TIMESTAMP(NOW()))');

    $dbh->do(
        qq{
CREATE TABLE servicechecks (
	id int AUTO_INCREMENT,
	hostname varchar(128) NOT NULL,
	name varchar(128) NOT NULL,
	host int NOT NULL,
	nagios_object_id int NOT NULL,
	description varchar(255),
	servicegroup varchar(128),
	active_date int NOT NULL,
	crc int,
	most_recent bool,
	PRIMARY KEY (id),
	INDEX (name),
	INDEX (host),
	UNIQUE (active_date, host, name),
	CONSTRAINT servicecheck_host_fk FOREIGN KEY (host) REFERENCES hosts(id)
)
	}
    );
    $dbh->do('INSERT INTO servicechecks (id, host, name, description, active_date) VALUES (1, 1, "deletedservicecheck", "Servicecheck that has been deleted before storing into datawarehouse", UNIX_TIMESTAMP(NOW()))');

    $dbh->do(
        qq{
CREATE TABLE servicecheck_results (
	start_datetime datetime NOT NULL,
	start_datetime_usec int NOT NULL,
	servicecheck int NOT NULL,
	check_type ENUM("ACTIVE","PASSIVE"),
	status ENUM("OK", "WARNING", "CRITICAL", "UNKNOWN") NOT NULL,
	status_type ENUM("SOFT","HARD") NOT NULL,
	duration float NOT NULL,
	output varchar(255) NOT NULL,
	UNIQUE (start_datetime,start_datetime_usec,servicecheck),
	INDEX (servicecheck),
	CONSTRAINT servicecheck_results_servicecheck_fk FOREIGN KEY (servicecheck) REFERENCES servicechecks(id)
);
	}
    );

    $dbh->do(
        qq{
CREATE TABLE performance_labels (
	id int AUTO_INCREMENT,
	host int NOT NULL,
	servicecheck int NOT NULL,
	name varchar(64),
	units varchar(16),
	PRIMARY KEY (id),
	UNIQUE (host, servicecheck, name, units),
	INDEX (host),
	CONSTRAINT performance_label_host_fk FOREIGN KEY (host) REFERENCES hosts(id),
	INDEX (servicecheck),
	CONSTRAINT performance_label_servicecheck_fk FOREIGN KEY (servicecheck) REFERENCES servicechecks(id)
)
	}
    );
    $dbh->do('INSERT INTO performance_labels (id, host, servicecheck, name) VALUES (1, 1, 1, "deletedlabel")');

    $dbh->do(
        qq{
CREATE TABLE performance_data (
	datetime DATETIME NOT NULL,
	performance_label int NOT NULL,
	value double NOT NULL,
	UNIQUE (datetime,performance_label),
	INDEX (performance_label),
	CONSTRAINT performance_data_performance_label_fk FOREIGN KEY (performance_label) REFERENCES performance_labels(id)
)
	}
    );

    $dbh->do(
        qq{
CREATE TABLE service_outages (
	id int AUTO_INCREMENT,
	start_datetime DATETIME NOT NULL,
	servicecheck int NOT NULL,
	initial_failure_status ENUM("OK", "WARNING", "CRITICAL", "UNKNOWN") NOT NULL,
	highest_failure_status ENUM("OK", "WARNING", "CRITICAL", "UNKNOWN") NOT NULL,
	started_in_scheduled_downtime bool DEFAULT 0,
	hard_state_datetime DATETIME DEFAULT NULL,
	acknowledged_datetime DATETIME DEFAULT NULL,
	acknowledged_by varchar(64) DEFAULT NULL,
	acknowledged_comment varchar(255) DEFAULT NULL,
	scheduled_downtime_end_datetime DATETIME DEFAULT NULL,
	downtime_duration int DEFAULT NULL,
	end_datetime DATETIME DEFAULT NULL,
	PRIMARY KEY (id),
	UNIQUE (start_datetime, servicecheck),
	INDEX (end_datetime),
	INDEX (servicecheck),
	CONSTRAINT service_outages_servicecheck_fk FOREIGN KEY (servicecheck) REFERENCES servicechecks(id)
)
	}
    );

    $dbh->do(
        qq{
CREATE TABLE service_availability_hourly_summary (
	start_datetime DATETIME NOT NULL,
	servicecheck int NOT NULL,
	seconds_ok smallint NOT NULL,
	seconds_not_ok smallint NOT NULL,                       # ok + not ok = 3600
	UNIQUE (start_datetime, servicecheck),
	INDEX (servicecheck),
	CONSTRAINT service_availability_hourly_summary_servicecheck_fk FOREIGN KEY (servicecheck) REFERENCES servicechecks(id)
)
	}
    );

    $dbh->do(
        qq{
CREATE TABLE dataloads (
	id int AUTO_INCREMENT,
	period_start_timev int NOT NULL,
	period_end_timev int NOT NULL,
	load_start_timev int NOT NULL,
	load_end_timev int,
	status ENUM ("running", "failed", "success"),
	PRIMARY KEY (id),
	UNIQUE (period_start_timev),
	INDEX (period_end_timev),
	INDEX (status)
)
	}
    );

    $dbh->do(
        qq{
CREATE TABLE metadata (
	name varchar(32),
	value varchar(32),
	PRIMARY KEY (name)
);
	}
    );
    $dbh->do('INSERT INTO metadata (name, value) VALUES ("last_successful_servicecheck_id", 0)');

    set_db_version("2.7.1");
}

if ( db_version_lower("2.7.2") ) {
    $dbh->do("ALTER TABLE servicecheck_results MAX_ROWS=1000000000");
    $dbh->do("ALTER TABLE performance_data MAX_ROWS=1000000000");
    set_db_version("2.7.2");
}

if ( db_version_lower("2.7.3") ) {
    $dbh->do(
        qq{
CREATE TABLE state_history (
	datetime DATETIME NOT NULL,
	datetime_usec int NOT NULL,
	servicecheck int NOT NULL,
	status ENUM("OK", "WARNING", "CRITICAL", "UNKNOWN") NOT NULL,
	status_type ENUM("SOFT","HARD") NOT NULL,
	UNIQUE (datetime,datetime_usec,servicecheck),
	INDEX (servicecheck),
	CONSTRAINT state_history_servicecheck_fk FOREIGN KEY (servicecheck) REFERENCES servicechecks(id)
)
	}
    );
    set_db_version("2.7.3");
}

if ( db_version_lower("2.7.4") ) {
    for my $table (
        qw/
        availability
        availability_host_summary
        availability_hostgroup_summary
        availability_summary
        events
        reports
        report_comments
        hosts
        servicechecks
        servicecheck_results
        performance_labels
        performance_data
        state_history
        service_outages
        service_availability_hourly_summary
        dataloads
        metadata
        database_version
        /
        )
    {
        $dbh->do("ALTER TABLE $table ENGINE=MyISAM");
    }
    set_db_version("2.7.4");
}

if ( db_version_lower("2.7.5") ) {
    $dbh->do("ALTER TABLE servicechecks DROP INDEX active_date");
    $dbh->do("ALTER TABLE servicecheck_results DROP INDEX start_datetime, ADD INDEX (start_datetime)");
    $dbh->do("ALTER TABLE performance_labels DROP INDEX host");
    $dbh->do("ALTER TABLE performance_data DROP INDEX datetime, ADD INDEX (datetime)");
    $dbh->do("ALTER TABLE state_history DROP FOREIGN KEY performance_labels_servicecheck_fk, ADD CONSTRAINT state_history_servicecheck_fk FOREIGN KEY (servicecheck) REFERENCES servicechecks(id)");
    $dbh->do("ALTER TABLE state_history ADD INDEX (datetime)");
    $dbh->do("ALTER TABLE service_outages DROP INDEX start_datetime, ADD INDEX (start_datetime)");
    $dbh->do("ALTER TABLE service_availability_hourly_summary DROP INDEX start_datetime, ADD COLUMN seconds_warning smallint NOT NULL, ADD COLUMN seconds_critical smallint NOT NULL, ADD COLUMN seconds_unknown smallint NOT NULL, ADD INDEX (start_datetime)");
    set_db_version("2.7.5");
}

if ( db_version_lower("2.7.6") ) {
    $dbh->do("ALTER TABLE state_history ADD COLUMN prior_status_datetime DATETIME");
    $dbh->do('ALTER TABLE state_history ADD COLUMN prior_status ENUM("OK", "WARNING", "CRITICAL", "UNKNOWN")');
    set_db_version("2.7.6");
}

if ( db_version_lower("2.7.7") ) {
    $dbh->do('ALTER TABLE state_history MODIFY COLUMN prior_status ENUM("OK", "WARNING", "CRITICAL", "UNKNOWN", "INDETERMINATE")');
    set_db_version("2.7.7");
}

if ( db_version_lower("2.7.8") ) {
    $dbh->do('CREATE TABLE schema_version ( major_release varchar(16), version varchar(16) ) ENGINE=InnoDB');
    set_db_version("2.7.8");
}

my $db = Utils::DBVersion->new( { dbh => $dbh, name => "odw", stop_point => shift @ARGV } );

if ( $db->is_lower("2.9.1") ) {
    $dbh->do("ALTER TABLE state_history DROP INDEX datetime");
    $dbh->do("ALTER TABLE state_history DROP INDEX servicecheck");
    $dbh->do("ALTER TABLE state_history ADD INDEX (datetime, servicecheck)");

    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_not_ok_hard SMALLINT");
    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_warning_hard SMALLINT");
    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_critical_hard SMALLINT");
    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_unknown_hard SMALLINT");
    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_not_ok_scheduled SMALLINT");
    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_unacknowledged SMALLINT");
    $db->updated;
}

if ( $db->is_lower("2.9.2") ) {
    $dbh->do(
        "CREATE TABLE downtime_host_history (
		actual_start_datetime DATETIME NOT NULL,
		actual_end_datetime DATETIME NOT NULL,
		nagios_object_id int NOT NULL,
		author_name varchar(128) NOT NULL,
		comment_data varchar(255) NOT NULL,
		entry_datetime DATETIME NOT NULL,
		scheduled_start_datetime DATETIME NOT NULL,
		scheduled_end_datetime DATETIME NOT NULL,
		is_fixed smallint NOT NULL,
		duration smallint NOT NULL,
		was_cancelled smallint NOT NULL,
		nagios_internal_downtime_id INT NOT NULL,
		INDEX(actual_start_datetime,actual_end_datetime,nagios_object_id),
		INDEX(nagios_object_id),
		INDEX(nagios_internal_downtime_id),
		CONSTRAINT downtime_host_history_nagios_object_id_fk FOREIGN KEY (nagios_object_id) REFERENCES hosts(nagios_object_id)
	) ENGINE=MyISAM"
    );

    $dbh->do(
        "CREATE TABLE downtime_service_history (
		actual_start_datetime DATETIME NOT NULL,
		actual_end_datetime DATETIME NOT NULL,
		nagios_object_id int NOT NULL,
		author_name varchar(128) NOT NULL,
		comment_data varchar(255) NOT NULL,
		entry_datetime DATETIME NOT NULL,
		scheduled_start_datetime DATETIME NOT NULL,
		scheduled_end_datetime DATETIME NOT NULL,
		is_fixed smallint NOT NULL,
		duration smallint NOT NULL,
		was_cancelled smallint NOT NULL,
		nagios_internal_downtime_id INT NOT NULL,
		INDEX(actual_start_datetime,actual_end_datetime,nagios_object_id),
		INDEX(nagios_object_id),
		INDEX(nagios_internal_downtime_id),
		CONSTRAINT downtime_service_history_nagios_object_id_fk FOREIGN KEY (nagios_object_id) REFERENCES servicechecks(nagios_object_id)
	) ENGINE=MyISAM"
    );

    $dbh->do("ALTER TABLE hosts ADD COLUMN nagios_object_id INT NOT NULL");
    $dbh->do("ALTER TABLE hosts ADD INDEX (nagios_object_id)");
    $dbh->do("ALTER TABLE servicechecks ADD INDEX (nagios_object_id)");
    $db->updated;
}

if ( $db->is_lower("2.9.3") ) {
    $dbh->do(
        'CREATE TABLE service_saved_state (
		start_timev INT NOT NULL,
		hostname varchar(128) NOT NULL,
		servicename varchar(128) NOT NULL,
		last_state ENUM("OK", "WARNING", "CRITICAL", "UNKNOWN") NOT NULL,
		last_hard_state ENUM("OK", "WARNING", "CRITICAL", "UNKNOWN") NOT NULL,
		acknowledged SMALLINT NOT NULL,
		INDEX (hostname,servicename)
	) ENGINE=MyISAM'
    );
    $dbh->do( '
	CREATE TABLE acknowledgement_host (
		entry_datetime DATETIME NOT NULL,
		host int NOT NULL,
		author_name varchar(128) NOT NULL,
		comment_data varchar(255) NOT NULL,
		is_sticky SMALLINT NOT NULL,
		persistent_comment SMALLINT NOT NULL,
		notify_contacts SMALLINT NOT NULL,
		INDEX(entry_datetime,host),
		CONSTRAINT acknowledgement_host_host_fk FOREIGN KEY (host) REFERENCES hosts(id)
	) ENGINE=MyISAM
	' );
    $dbh->do( '
	CREATE TABLE acknowledgement_service (
		entry_datetime DATETIME NOT NULL,
		service int NOT NULL,
		author_name varchar(128) NOT NULL,
		comment_data varchar(255) NOT NULL,
		is_sticky SMALLINT NOT NULL,
		persistent_comment SMALLINT NOT NULL,
		notify_contacts SMALLINT NOT NULL,
		INDEX(entry_datetime,service),
		CONSTRAINT acknowledgement_service_service_fk FOREIGN KEY (service) REFERENCES servicechecks(id)
	) ENGINE=MyISAM;
	' );
    $db->updated;
}

if ( $db->is_lower("2.9.4") ) {

    # This fixes problems with most_recent not being set correctly for services
    $dbh->do("UPDATE servicechecks SET most_recent=0");
    $dbh->do("CREATE TEMPORARY TABLE temp_ids (id int)");
    $dbh->do("INSERT INTO temp_ids SELECT MAX(id) FROM servicechecks GROUP BY hostname,name");
    $dbh->do("UPDATE servicechecks SET most_recent=1 WHERE id IN (SELECT id FROM temp_ids)");

    # Also set the deletedhost to most_recent=1. Above will sort out services
    $dbh->do("UPDATE hosts SET most_recent=1 WHERE id=1");
    $db->updated;
}

if ( $db->is_lower("2.9.5") ) {
    $dbh->do( "
	CREATE TABLE locks (
		name varchar(32),
		value INT,
		PRIMARY KEY (name)
	) ENGINE=MyISAM
" );
    $dbh->do('INSERT INTO locks (name, value) VALUES ("import_disabled", 0)');
    $db->updated;
}

if ( $db->is_lower("2.10.1") ) {

    # Add some reasonable values historically
    $dbh->do( "
	UPDATE service_availability_hourly_summary 
	SET 
	 seconds_not_ok_hard = seconds_not_ok, 
	 seconds_warning_hard = seconds_warning, 
	 seconds_critical_hard = seconds_critical, 
	 seconds_unknown_hard = seconds_unknown, 
	 seconds_not_ok_scheduled = 0, 
	 seconds_unacknowledged = seconds_not_ok 
	WHERE 
	 seconds_not_ok_hard is null 
	 and seconds_warning_hard is null 
	 and seconds_critical_hard is null 
	 and seconds_unknown_hard is null 
	 and seconds_not_ok_scheduled is null 
	 and seconds_unacknowledged is null
	" );
    $db->updated;
}

if ( $db->is_lower("2.10.2") ) {
    $dbh->do( "
		CREATE TABLE notification_host_history (
		entry_datetime DATETIME NOT NULL,
		host int NOT NULL,
		notification_reason ENUM('Normal','Acknowledgement','Flapping Started','Flapping Stopped','Flapping Disabled','Downtime Started','Downtime Stopped','Downtime Cancelled','Custom') NOT NULL,
		notification_number SMALLINT NOT NULL,
		contactname varchar(128) NOT NULL,
		methodname varchar(128) NOT NULL,
		INDEX(entry_datetime,host),
		CONSTRAINT notification_host_host_fk FOREIGN KEY (host) REFERENCES hosts(id)
		) ENGINE=MyISAM
	" );
    $dbh->do( "
		CREATE TABLE notification_service_history (
		entry_datetime DATETIME NOT NULL,
		service int NOT NULL,
		notification_reason ENUM('Normal','Acknowledgement','Flapping Started','Flapping Stopped','Flapping Disabled','Downtime Started','Downtime Stopped','Downtime Cancelled','Custom') NOT NULL,
		notification_number SMALLINT NOT NULL,
		contactname varchar(128) NOT NULL,
		methodname varchar(128) NOT NULL,
		INDEX(entry_datetime,service),
		CONSTRAINT notification_service_service_fk FOREIGN KEY (service) REFERENCES servicechecks(id)
		) ENGINE=MyISAM
	" );
    $db->updated;
}

if ( $db->is_lower("2.10.3") ) {

    $dbh->do("ALTER TABLE notification_host_history ADD COLUMN status ENUM('UP', 'DOWN', 'UNREACHABLE') DEFAULT NULL AFTER host");
    $dbh->do("ALTER TABLE notification_host_history ADD COLUMN output VARCHAR(255) DEFAULT NULL AFTER status");
    $dbh->do("ALTER TABLE notification_service_history ADD COLUMN status ENUM('OK', 'WARNING', 'CRITICAL', 'UNKNOWN') DEFAULT NULL AFTER service");
    $dbh->do("ALTER TABLE notification_service_history ADD COLUMN output varchar(255) DEFAULT NULL AFTER status");

    # These enum changes should be safe as the index order have not changed
    $dbh->do("ALTER TABLE notification_host_history MODIFY COLUMN notification_reason ENUM('NORMAL','ACKNOWLEDGEMENT','FLAPPING STARTED','FLAPPING STOPPED','FLAPPING DISABLED','DOWNTIME STARTED','DOWNTIME STOPPED','DOWNTIME CANCELLED','CUSTOM') NOT NULL");
    $dbh->do("ALTER TABLE notification_service_history MODIFY COLUMN notification_reason ENUM('NORMAL','ACKNOWLEDGEMENT','FLAPPING STARTED','FLAPPING STOPPED','FLAPPING DISABLED','DOWNTIME STARTED','DOWNTIME STOPPED','DOWNTIME CANCELLED','CUSTOM') NOT NULL");

    $dbh->do( "
UPDATE notification_service_history, servicechecks, $runtime_db.nagios_notifications
SET 
 notification_service_history.output = $runtime_db.nagios_notifications.output,
 notification_service_history.status = $runtime_db.nagios_notifications.state+1
WHERE
 $runtime_db.nagios_notifications.start_time = notification_service_history.entry_datetime
 AND notification_service_history.service = servicechecks.id
 AND $runtime_db.nagios_notifications.object_id = servicechecks.nagios_object_id
 	" );

    $dbh->do( "
UPDATE notification_host_history, hosts, $runtime_db.nagios_notifications
SET
 notification_host_history.output = $runtime_db.nagios_notifications.output,
 notification_host_history.status = $runtime_db.nagios_notifications.state+1
WHERE
 $runtime_db.nagios_notifications.start_time = notification_host_history.entry_datetime
 AND notification_host_history.host = hosts.id
 AND $runtime_db.nagios_notifications.object_id = hosts.nagios_object_id
 	" );

    $dbh->do("UPDATE notification_host_history SET methodname=replace(replace(replace(methodname,'host-notify-by-',''),'service-notify-by-',''),'notify-by-','')");
    $dbh->do("UPDATE notification_service_history SET methodname=replace(replace(replace(methodname,'host-notify-by-',''),'service-notify-by-',''),'notify-by-','')");

    $db->updated;
}

if ( $db->is_lower("2.12.1") ) {
    $dbh->do("ALTER TABLE servicechecks ADD COLUMN keywords TEXT AFTER servicegroup");
    $dbh->do("ALTER TABLE state_history ADD COLUMN output VARCHAR(255) AFTER prior_status");

    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_warning_scheduled SMALLINT");
    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_critical_scheduled SMALLINT");
    $dbh->do("ALTER TABLE service_availability_hourly_summary ADD COLUMN seconds_unknown_scheduled SMALLINT");

    # Add some reasonable values historically - we deliberately say 0 at the moment because if we
    # put into one category, the summation would be wrong
    $dbh->do( "
	UPDATE service_availability_hourly_summary 
	SET 
	 seconds_warning_scheduled = 0,
	 seconds_critical_scheduled = 0,
	 seconds_unknown_scheduled = 0
	WHERE 
	 seconds_warning_scheduled is null
	 and seconds_critical_scheduled is null 
	 and seconds_unknown_scheduled is null 
	" );

    $db->updated;
}

# The following two below should be 2.14, but because there are no entries for 2.14, Opsview 3 will ignore them
# So use 2.12 instead - it is only a label
if ( $db->is_lower("2.12.2") ) {
    $dbh->do("ALTER TABLE dataloads ADD COLUMN opsview_instance_id SMALLINT DEFAULT 1 AFTER id");
    $dbh->do("ALTER TABLE dataloads DROP INDEX period_start_timev");
    $dbh->do("ALTER TABLE dataloads ADD UNIQUE INDEX (period_start_timev, opsview_instance_id)");
    $db->updated;
}

if ( $db->is_lower("2.12.3") ) {
    $dbh->do("ALTER TABLE service_saved_state ADD COLUMN opsview_instance_id SMALLINT DEFAULT 1 AFTER acknowledged");
    $db->updated;
}

if ( $db->is_lower("2.12.4") ) {
    $dbh->do("ALTER TABLE hosts ADD COLUMN opsview_instance_id SMALLINT DEFAULT 1 AFTER most_recent");
    $db->updated;
}

if ( $db->is_lower("3.0.1") ) {
    my $start = time;
    $db->print("Changing output columns to TEXT - this could take some time\n");
    $db->print("...servicecheck_results\n");
    $dbh->do("ALTER TABLE servicecheck_results CHANGE output output TEXT");
    $db->print("...state_history\n");
    $dbh->do("ALTER TABLE state_history CHANGE output output TEXT");
    $db->print("...downtime_host_history\n");
    $dbh->do("ALTER TABLE downtime_host_history CHANGE comment_data comment_data TEXT");
    $db->print("...downtime_service_history\n");
    $dbh->do("ALTER TABLE downtime_service_history CHANGE comment_data comment_data TEXT");
    $db->print("...acknowledgement_host\n");
    $dbh->do("ALTER TABLE acknowledgement_host CHANGE comment_data comment_data TEXT");
    $db->print("...acknowledgement_service\n");
    $dbh->do("ALTER TABLE acknowledgement_service CHANGE comment_data comment_data TEXT");
    $db->print("...notification_host_history\n");
    $dbh->do("ALTER TABLE notification_host_history CHANGE output output TEXT");
    $db->print("...notification_service_history\n");
    $dbh->do("ALTER TABLE notification_service_history CHANGE output output TEXT");
    $db->print( "Time taken: " . ( time - $start ) . " seconds\n" );
    $db->updated;
}

# We split the dropping and the updating and the readding of indexes into separate steps
# This is to reduce the possibility of a full disk causing a problem with the upgrade scripts
# because the UPDATE to change to UTC can NOT be re-run without data corruption
if ( $db->is_lower("3.0.2") ) {

    # We remove this index change. Tests show that it doesn't appear to make a big difference
    # in query times, so we leave indexes as they currently are in Opsview 2
    #print("Dropping unused indexes - this could take some time\n");
    #print("Servicecheck results table\n");
    #$dbh->do("ALTER TABLE servicecheck_results DROP INDEX start_datetime");
    #print("Performancedata table\n");
    #$dbh->do("ALTER TABLE performance_data DROP INDEX datetime");
    #print("Service availability hourly summary\n");
    #$dbh->do("ALTER TABLE service_availability_hourly_summary DROP INDEX start_datetime");

    $db->updated;
}

if ( $db->is_lower("3.0.3") ) {
    my $start = time;
    $db->print("Converting to UTC - this could take some time\n");
    $db->print("Servicecheck results table\n");
    $dbh->do("UPDATE servicecheck_results SET start_datetime=CONVERT_TZ(start_datetime,'SYSTEM','+00:00')");

    $db->print("Performancedata table\n");
    $dbh->do("UPDATE performance_data SET datetime=CONVERT_TZ(datetime,'SYSTEM','+00:00')");

    $db->print("State history table\n");
    $dbh->do("UPDATE state_history SET datetime=CONVERT_TZ(datetime,'SYSTEM','+00:00')");

    $db->print("Downtime host history\n");
    $dbh->do(
        "UPDATE downtime_host_history SET 
actual_start_datetime=CONVERT_TZ(actual_start_datetime,'SYSTEM','+00:00'),
actual_end_datetime=CONVERT_TZ(actual_end_datetime,'SYSTEM','+00:00'),
entry_datetime=CONVERT_TZ(entry_datetime,'SYSTEM','+00:00'),
scheduled_start_datetime=CONVERT_TZ(scheduled_start_datetime,'SYSTEM','+00:00'),
scheduled_end_datetime=CONVERT_TZ(scheduled_end_datetime,'SYSTEM','+00:00')
"
    );

    $db->print("Downtime service history\n");
    $dbh->do(
        "UPDATE downtime_service_history SET 
actual_start_datetime=CONVERT_TZ(actual_start_datetime,'SYSTEM','+00:00'),
actual_end_datetime=CONVERT_TZ(actual_end_datetime,'SYSTEM','+00:00'),
entry_datetime=CONVERT_TZ(entry_datetime,'SYSTEM','+00:00'),
scheduled_start_datetime=CONVERT_TZ(scheduled_start_datetime,'SYSTEM','+00:00'),
scheduled_end_datetime=CONVERT_TZ(scheduled_end_datetime,'SYSTEM','+00:00')
"
    );

    $db->print("Acknowledgement host\n");
    $dbh->do("UPDATE acknowledgement_host SET entry_datetime=CONVERT_TZ(entry_datetime,'SYSTEM','+00:00')");

    $db->print("Acknowledgement service\n");
    $dbh->do("UPDATE acknowledgement_service SET entry_datetime=CONVERT_TZ(entry_datetime,'SYSTEM','+00:00')");

    $db->print("Notification host history\n");
    $dbh->do("UPDATE notification_host_history SET entry_datetime=CONVERT_TZ(entry_datetime,'SYSTEM','+00:00')");

    $db->print("Notification service history\n");
    $dbh->do("UPDATE notification_service_history SET entry_datetime=CONVERT_TZ(entry_datetime,'SYSTEM','+00:00')");

    $db->print("Service availability hourly summary\n");
    $db->print("Converting to UTC\n");
    $dbh->do("UPDATE service_availability_hourly_summary SET start_datetime=CONVERT_TZ(start_datetime,'SYSTEM','+00:00')");

    $db->print( "Time taken: " . ( time - $start ) . " seconds\n" );
    $db->updated;
}

if ( $db->is_lower("3.0.4") ) {

    # See 3.0.2
    #print("Creating new indexes - this could take some time\n");
    #print("Servicecheck results table\n");
    #$dbh->do("ALTER TABLE servicecheck_results ADD INDEX servicecheck_results_start_datetime_servicecheck (start_datetime, servicecheck)");

    #print("Performancedata table\n");
    #$dbh->do("ALTER TABLE performance_data ADD INDEX performance_data_datetime_performance_label (datetime, performance_label)");

    #print("Service availability hourly summary\n");
    #$dbh->do("ALTER TABLE service_availability_hourly_summary ADD INDEX service_availability_hourly_summary_start_datetime_servicecheck (start_datetime, servicecheck)");

    $db->updated;
}

if ( $db->is_lower('3.3.1') ) {
    $db->print("Extending index with time column for service_saved_state\n");
    $dbh->do("ALTER TABLE service_saved_state DROP INDEX hostname");
    $dbh->do("ALTER TABLE service_saved_state ADD INDEX hostname (hostname, servicename, start_timev)");
    $db->updated;
}

if ( $db->is_lower('3.7.1') ) {
    $db->print("ODW tables may be converted from MyISAM to InnoDB\n");
    $db->print("Please run\n");
    $db->print("  /usr/local/nagios/installer/convert_odw_tables_to_innodb --man\n");
    $db->print("to learn more about how and why to do this\n");
    $db->updated;
}

if ( $db->is_lower('3.9.1') ) {
    $db->print("Adding hourly performance summary table");
    $dbh->do(
        qq{
    CREATE TABLE performance_hourly_summary (
        start_datetime DATETIME NOT NULL,
        performance_label INT NOT NULL,
        average DOUBLE NOT NULL,
        max DOUBLE NOT NULL,
        min DOUBLE NOT NULL,
        count SMALLINT NOT NULL,
        stddev DOUBLE NOT NULL,
        stddevp DOUBLE NOT NULL,
        first DOUBLE NOT NULL,
        sum DOUBLE NOT NULL,
        INDEX (start_datetime),
        INDEX (performance_label)
    ) ENGINE=InnoDB;
}
    );
    $db->updated;
}

if ( $db->is_lower('3.9.2') ) {
    $db->print("Adding extra statistical columns to dataloads table");
    $dbh->do(
        "ALTER TABLE dataloads ADD COLUMN num_hosts INT DEFAULT NULL, 
    ADD COLUMN num_services INT DEFAULT NULL, 
    ADD COLUMN num_serviceresults INT DEFAULT NULL, 
    ADD COLUMN num_perfdata INT DEFAULT NULL, 
    ADD COLUMN duration INT DEFAULT NULL,
    ADD COLUMN last_reload_duration SMALLINT DEFAULT NULL,
    ADD COLUMN reloads SMALLINT DEFAULT NULL"
    );
    $db->updated;
}

if ( $db->is_lower('3.9.3') ) {
    $db->print("Updating duration column");
    $dbh->do("UPDATE dataloads SET duration=load_end_timev-load_start_timev");
    $db->updated;
}

if ( $db->is_lower('3.11.1') ) {
    $db->print("Adding index for service_saved_state - this could take some time");
    $dbh->do("ALTER TABLE service_saved_state ADD INDEX start_timev_opsview_instance_id (start_timev,opsview_instance_id)");
    $db->updated;
}

if ( $db_changed || $db->changed ) {
    print "Finished updating database", $/;
}
else {
    print "Database already up to date", $/;
}

sub db_version_lower {
    my $target  = shift;
    my $version = $dbh->selectrow_array("SELECT version FROM database_version");
    $version =~ s/[a-zA-Z]+$//;    # Remove suffix letter
    my @a = split( /[\.-]/, $version );
    my @b = split( /[\.-]/, $target );
    my $rc = $a[0] <=> $b[0] || $a[1] <=> $b[1] || $a[2] <=> $b[2] || $a[3] <=> $b[3];
    if ( $rc == -1 ) {
        print "DB at version $version", $/;
    }
    return ( $rc == -1 );
}

sub set_db_version {
    my $version = shift;
    $dbh->do("UPDATE database_version SET version='$version'");
    print "Updated database to version $version", $/;
    $db_changed = 1;
}
