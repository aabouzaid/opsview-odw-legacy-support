-- MySQL dump 10.13  Distrib 5.1.72, for pc-linux-gnu (i686)
--
-- Host: localhost    Database: odw
-- ------------------------------------------------------
-- Server version	5.1.72-rel14.10

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `acknowledgement_host`
--

DROP TABLE IF EXISTS `acknowledgement_host`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acknowledgement_host` (
  `entry_datetime` datetime NOT NULL,
  `host` int(11) NOT NULL,
  `author_name` varchar(128) NOT NULL,
  `comment_data` text NOT NULL,
  `is_sticky` smallint(6) NOT NULL,
  `persistent_comment` smallint(6) NOT NULL,
  `notify_contacts` smallint(6) NOT NULL,
  KEY `entry_datetime` (`entry_datetime`,`host`),
  KEY `acknowledgement_host_host_fk` (`host`),
  CONSTRAINT `acknowledgement_host_host_fk` FOREIGN KEY (`host`) REFERENCES `hosts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `acknowledgement_service`
--

DROP TABLE IF EXISTS `acknowledgement_service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acknowledgement_service` (
  `entry_datetime` datetime NOT NULL,
  `service` int(11) NOT NULL,
  `author_name` varchar(128) NOT NULL,
  `comment_data` text NOT NULL,
  `is_sticky` smallint(6) NOT NULL,
  `persistent_comment` smallint(6) NOT NULL,
  `notify_contacts` smallint(6) NOT NULL,
  KEY `entry_datetime` (`entry_datetime`,`service`),
  KEY `acknowledgement_service_service_fk` (`service`),
  CONSTRAINT `acknowledgement_service_service_fk` FOREIGN KEY (`service`) REFERENCES `servicechecks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `availability`
--

DROP TABLE IF EXISTS `availability`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `availability` (
  `date` date NOT NULL,
  `hostname` varchar(128) NOT NULL,
  `servicename` varchar(128) NOT NULL,
  `percent_total_time_okay` double NOT NULL,
  `percent_total_scheduled_downtime` double NOT NULL,
  `percent_total_unscheduled_downtime` double NOT NULL,
  UNIQUE KEY `date_2` (`date`,`hostname`,`servicename`),
  KEY `date` (`date`),
  KEY `hostname` (`hostname`),
  KEY `servicename` (`servicename`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `availability_host_summary`
--

DROP TABLE IF EXISTS `availability_host_summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `availability_host_summary` (
  `date` date NOT NULL,
  `hostname` varchar(128) NOT NULL,
  `percent_total_time_okay` double NOT NULL,
  `percent_total_scheduled_downtime` double NOT NULL,
  `percent_total_unscheduled_downtime` double NOT NULL,
  UNIQUE KEY `date_2` (`date`,`hostname`),
  KEY `date` (`date`),
  KEY `hostname` (`hostname`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `availability_hostgroup_summary`
--

DROP TABLE IF EXISTS `availability_hostgroup_summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `availability_hostgroup_summary` (
  `date` date NOT NULL,
  `hostgroup` varchar(128) NOT NULL,
  `percent_total_time_okay` double NOT NULL,
  `percent_total_scheduled_downtime` double NOT NULL,
  `percent_total_unscheduled_downtime` double NOT NULL,
  UNIQUE KEY `date_2` (`date`,`hostgroup`),
  KEY `date` (`date`),
  KEY `hostgroup` (`hostgroup`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `availability_summary`
--

DROP TABLE IF EXISTS `availability_summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `availability_summary` (
  `date` date NOT NULL,
  `percent_total_time_okay` double NOT NULL,
  `percent_total_scheduled_downtime` double NOT NULL,
  `percent_total_unscheduled_downtime` double NOT NULL,
  UNIQUE KEY `date_2` (`date`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `database_version`
--

DROP TABLE IF EXISTS `database_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `database_version` (
  `version` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dataloads`
--

DROP TABLE IF EXISTS `dataloads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dataloads` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `opsview_instance_id` smallint(6) DEFAULT '1',
  `period_start_timev` int(11) NOT NULL,
  `period_end_timev` int(11) NOT NULL,
  `load_start_timev` int(11) NOT NULL,
  `load_end_timev` int(11) DEFAULT NULL,
  `status` enum('running','failed','success') DEFAULT NULL,
  `num_hosts` int(11) DEFAULT NULL,
  `num_services` int(11) DEFAULT NULL,
  `num_serviceresults` int(11) DEFAULT NULL,
  `num_perfdata` int(11) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `last_reload_duration` smallint(6) DEFAULT NULL,
  `reloads` smallint(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `period_start_timev` (`period_start_timev`,`opsview_instance_id`),
  KEY `period_end_timev` (`period_end_timev`),
  KEY `status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=23587 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `downtime_host_history`
--

DROP TABLE IF EXISTS `downtime_host_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `downtime_host_history` (
  `actual_start_datetime` datetime NOT NULL,
  `actual_end_datetime` datetime NOT NULL,
  `nagios_object_id` int(11) NOT NULL,
  `author_name` varchar(128) NOT NULL,
  `comment_data` text NOT NULL,
  `entry_datetime` datetime NOT NULL,
  `scheduled_start_datetime` datetime NOT NULL,
  `scheduled_end_datetime` datetime NOT NULL,
  `is_fixed` smallint(6) NOT NULL,
  `duration` smallint(6) NOT NULL,
  `was_cancelled` smallint(6) NOT NULL,
  `nagios_internal_downtime_id` int(11) NOT NULL,
  KEY `actual_start_datetime` (`actual_start_datetime`,`actual_end_datetime`,`nagios_object_id`),
  KEY `nagios_object_id` (`nagios_object_id`),
  KEY `nagios_internal_downtime_id` (`nagios_internal_downtime_id`),
  CONSTRAINT `downtime_host_history_nagios_object_id_fk` FOREIGN KEY (`nagios_object_id`) REFERENCES `hosts` (`nagios_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `downtime_service_history`
--

DROP TABLE IF EXISTS `downtime_service_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `downtime_service_history` (
  `actual_start_datetime` datetime NOT NULL,
  `actual_end_datetime` datetime NOT NULL,
  `nagios_object_id` int(11) NOT NULL,
  `author_name` varchar(128) NOT NULL,
  `comment_data` text NOT NULL,
  `entry_datetime` datetime NOT NULL,
  `scheduled_start_datetime` datetime NOT NULL,
  `scheduled_end_datetime` datetime NOT NULL,
  `is_fixed` smallint(6) NOT NULL,
  `duration` smallint(6) NOT NULL,
  `was_cancelled` smallint(6) NOT NULL,
  `nagios_internal_downtime_id` int(11) NOT NULL,
  KEY `actual_start_datetime` (`actual_start_datetime`,`actual_end_datetime`,`nagios_object_id`),
  KEY `nagios_object_id` (`nagios_object_id`),
  KEY `nagios_internal_downtime_id` (`nagios_internal_downtime_id`),
  CONSTRAINT `downtime_service_history_nagios_object_id_fk` FOREIGN KEY (`nagios_object_id`) REFERENCES `servicechecks` (`nagios_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `events` (
  `datetime` datetime NOT NULL,
  `type` enum('host','service') NOT NULL,
  `hostname` varchar(128) NOT NULL,
  `servicename` varchar(128) DEFAULT NULL,
  `state` varchar(16) NOT NULL,
  `statetype` varchar(5) NOT NULL,
  `attempt` int(11) NOT NULL,
  `laststatechange` datetime NOT NULL,
  `executiontimetaken` float NOT NULL,
  `latency` float NOT NULL,
  `output` longtext,
  KEY `datetime` (`datetime`),
  KEY `type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hosts`
--

DROP TABLE IF EXISTS `hosts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hosts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `alias` varchar(255) DEFAULT NULL,
  `hostgroup1` varchar(128) DEFAULT NULL,
  `hostgroup2` varchar(128) DEFAULT NULL,
  `hostgroup3` varchar(128) DEFAULT NULL,
  `hostgroup4` varchar(128) DEFAULT NULL,
  `hostgroup5` varchar(128) DEFAULT NULL,
  `hostgroup6` varchar(128) DEFAULT NULL,
  `hostgroup7` varchar(128) DEFAULT NULL,
  `hostgroup8` varchar(128) DEFAULT NULL,
  `hostgroup9` varchar(128) DEFAULT NULL,
  `hostgroup` varchar(128) DEFAULT NULL,
  `nagios_object_id` int(11) NOT NULL,
  `monitored_by` varchar(128) DEFAULT NULL,
  `active_date` int(11) NOT NULL,
  `crc` int(11) DEFAULT NULL,
  `most_recent` tinyint(1) DEFAULT NULL,
  `opsview_instance_id` smallint(6) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `active_date` (`active_date`,`name`),
  KEY `name` (`name`),
  KEY `nagios_object_id` (`nagios_object_id`)
) ENGINE=InnoDB AUTO_INCREMENT=283 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `locks`
--

DROP TABLE IF EXISTS `locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `locks` (
  `name` varchar(32) NOT NULL DEFAULT '',
  `value` int(11) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `metadata`
--

DROP TABLE IF EXISTS `metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metadata` (
  `name` varchar(32) NOT NULL DEFAULT '',
  `value` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_host_history`
--

DROP TABLE IF EXISTS `notification_host_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification_host_history` (
  `entry_datetime` datetime NOT NULL,
  `host` int(11) NOT NULL,
  `status` enum('UP','DOWN','UNREACHABLE') DEFAULT NULL,
  `output` text,
  `notification_reason` enum('NORMAL','ACKNOWLEDGEMENT','FLAPPING STARTED','FLAPPING STOPPED','FLAPPING DISABLED','DOWNTIME STARTED','DOWNTIME STOPPED','DOWNTIME CANCELLED','CUSTOM') NOT NULL,
  `notification_number` smallint(6) NOT NULL,
  `contactname` varchar(128) NOT NULL,
  `methodname` varchar(128) NOT NULL,
  KEY `entry_datetime` (`entry_datetime`,`host`),
  KEY `notification_host_host_fk` (`host`),
  CONSTRAINT `notification_host_host_fk` FOREIGN KEY (`host`) REFERENCES `hosts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_service_history`
--

DROP TABLE IF EXISTS `notification_service_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification_service_history` (
  `entry_datetime` datetime NOT NULL,
  `service` int(11) NOT NULL,
  `status` enum('OK','WARNING','CRITICAL','UNKNOWN') DEFAULT NULL,
  `output` text,
  `notification_reason` enum('NORMAL','ACKNOWLEDGEMENT','FLAPPING STARTED','FLAPPING STOPPED','FLAPPING DISABLED','DOWNTIME STARTED','DOWNTIME STOPPED','DOWNTIME CANCELLED','CUSTOM') NOT NULL,
  `notification_number` smallint(6) NOT NULL,
  `contactname` varchar(128) NOT NULL,
  `methodname` varchar(128) NOT NULL,
  KEY `entry_datetime` (`entry_datetime`,`service`),
  KEY `notification_service_service_fk` (`service`),
  CONSTRAINT `notification_service_service_fk` FOREIGN KEY (`service`) REFERENCES `servicechecks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `performance_data`
--

DROP TABLE IF EXISTS `performance_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `performance_data` (
  `datetime` datetime NOT NULL,
  `performance_label` int(11) NOT NULL,
  `value` double NOT NULL,
  KEY `datetime` (`datetime`),
  KEY `performance_label` (`performance_label`),
  CONSTRAINT `performance_data_performance_labels_fk` FOREIGN KEY (`performance_label`) REFERENCES `performance_labels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 MAX_ROWS=1000000000;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `performance_hourly_summary`
--

DROP TABLE IF EXISTS `performance_hourly_summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `performance_hourly_summary` (
  `start_datetime` datetime NOT NULL,
  `performance_label` int(11) NOT NULL,
  `average` double NOT NULL,
  `max` double NOT NULL,
  `min` double NOT NULL,
  `count` smallint(6) NOT NULL,
  `stddev` double NOT NULL,
  `stddevp` double NOT NULL,
  `first` double NOT NULL,
  `sum` double NOT NULL,
  KEY `start_datetime` (`start_datetime`),
  KEY `performance_label` (`performance_label`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `performance_labels`
--

DROP TABLE IF EXISTS `performance_labels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `performance_labels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host` int(11) NOT NULL,
  `servicecheck` int(11) NOT NULL,
  `name` varchar(64) DEFAULT NULL,
  `units` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `host` (`host`),
  KEY `servicecheck` (`servicecheck`),
  CONSTRAINT `performance_labels_host_fk` FOREIGN KEY (`host`) REFERENCES `hosts` (`id`),
  CONSTRAINT `performance_labels_servicecheck_fk` FOREIGN KEY (`servicecheck`) REFERENCES `servicechecks` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=32265 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `report_comments`
--

DROP TABLE IF EXISTS `report_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `report_comments` (
  `name` varchar(128) NOT NULL,
  `text` longtext,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reports`
--

DROP TABLE IF EXISTS `reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `filename` varchar(128) NOT NULL,
  `report_date` int(11) DEFAULT NULL,
  `created_on` int(11) DEFAULT NULL,
  `created_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `filename_2` (`filename`),
  KEY `filename` (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schema_version`
--

DROP TABLE IF EXISTS `schema_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_version` (
  `major_release` varchar(16) DEFAULT NULL,
  `version` varchar(16) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_availability_hourly_summary`
--

DROP TABLE IF EXISTS `service_availability_hourly_summary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_availability_hourly_summary` (
  `start_datetime` datetime NOT NULL,
  `servicecheck` int(11) NOT NULL,
  `seconds_ok` smallint(6) NOT NULL,
  `seconds_not_ok` smallint(6) NOT NULL,
  `seconds_warning` smallint(6) NOT NULL,
  `seconds_critical` smallint(6) NOT NULL,
  `seconds_unknown` smallint(6) NOT NULL,
  `seconds_not_ok_hard` smallint(6) NOT NULL,
  `seconds_warning_hard` smallint(6) NOT NULL,
  `seconds_critical_hard` smallint(6) NOT NULL,
  `seconds_unknown_hard` smallint(6) NOT NULL,
  `seconds_not_ok_scheduled` smallint(6) NOT NULL,
  `seconds_warning_scheduled` smallint(6) NOT NULL,
  `seconds_critical_scheduled` smallint(6) NOT NULL,
  `seconds_unknown_scheduled` smallint(6) NOT NULL,
  `seconds_unacknowledged` smallint(6) NOT NULL,
  KEY `start_datetime` (`start_datetime`),
  KEY `servicecheck` (`servicecheck`),
  CONSTRAINT `service_availability_hourly_summary_servicecheck_fk` FOREIGN KEY (`servicecheck`) REFERENCES `servicechecks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_outages`
--

DROP TABLE IF EXISTS `service_outages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_outages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `start_datetime` datetime NOT NULL,
  `servicecheck` int(11) NOT NULL,
  `initial_failure_status` enum('OK','WARNING','CRITICAL','UNKNOWN') NOT NULL,
  `highest_failure_status` enum('OK','WARNING','CRITICAL','UNKNOWN') NOT NULL,
  `started_in_scheduled_downtime` tinyint(1) DEFAULT '0',
  `hard_state_datetime` datetime DEFAULT NULL,
  `acknowledged_datetime` datetime DEFAULT NULL,
  `acknowledged_by` varchar(64) DEFAULT NULL,
  `acknowledged_comment` varchar(255) DEFAULT NULL,
  `scheduled_downtime_end_datetime` datetime DEFAULT NULL,
  `downtime_duration` int(11) DEFAULT NULL,
  `end_datetime` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `start_datetime` (`start_datetime`),
  KEY `end_datetime` (`end_datetime`),
  KEY `servicecheck` (`servicecheck`),
  CONSTRAINT `service_outages_servicecheck_fk` FOREIGN KEY (`servicecheck`) REFERENCES `servicechecks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_saved_state`
--

DROP TABLE IF EXISTS `service_saved_state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_saved_state` (
  `start_timev` int(11) NOT NULL,
  `hostname` varchar(128) NOT NULL,
  `servicename` varchar(128) NOT NULL,
  `last_state` enum('OK','WARNING','CRITICAL','UNKNOWN') NOT NULL,
  `last_hard_state` enum('OK','WARNING','CRITICAL','UNKNOWN') NOT NULL,
  `acknowledged` smallint(6) NOT NULL,
  `opsview_instance_id` smallint(6) DEFAULT '1',
  KEY `hostname` (`hostname`,`servicename`,`start_timev`),
  KEY `start_timev` (`start_timev`,`opsview_instance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servicecheck_results`
--

DROP TABLE IF EXISTS `servicecheck_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `servicecheck_results` (
  `start_datetime` datetime NOT NULL,
  `start_datetime_usec` int(11) NOT NULL,
  `servicecheck` int(11) NOT NULL,
  `check_type` enum('ACTIVE','PASSIVE') DEFAULT NULL,
  `status` enum('OK','WARNING','CRITICAL','UNKNOWN') NOT NULL,
  `status_type` enum('SOFT','HARD') NOT NULL,
  `duration` float NOT NULL,
  `output` text NOT NULL,
  KEY `start_datetime` (`start_datetime`),
  KEY `servicecheck` (`servicecheck`),
  CONSTRAINT `servicecheck_results_servicecheck_fk` FOREIGN KEY (`servicecheck`) REFERENCES `servicechecks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 MAX_ROWS=1000000000;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servicechecks`
--

DROP TABLE IF EXISTS `servicechecks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `servicechecks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hostname` varchar(128) NOT NULL,
  `name` varchar(128) NOT NULL,
  `host` int(11) NOT NULL,
  `nagios_object_id` int(11) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `servicegroup` varchar(128) DEFAULT NULL,
  `keywords` text,
  `active_date` int(11) NOT NULL,
  `crc` int(11) DEFAULT NULL,
  `most_recent` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`),
  KEY `host` (`host`),
  KEY `nagios_object_id` (`nagios_object_id`),
  CONSTRAINT `servicecheck_host_fk` FOREIGN KEY (`host`) REFERENCES `hosts` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13888 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `state_history`
--

DROP TABLE IF EXISTS `state_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `state_history` (
  `datetime` datetime NOT NULL,
  `datetime_usec` int(11) NOT NULL,
  `servicecheck` int(11) NOT NULL,
  `status` enum('OK','WARNING','CRITICAL','UNKNOWN') NOT NULL,
  `status_type` enum('SOFT','HARD') NOT NULL,
  `prior_status_datetime` datetime NOT NULL,
  `prior_status` enum('OK','WARNING','CRITICAL','UNKNOWN','INDETERMINATE') NOT NULL,
  `output` text NOT NULL,
  KEY `datetime` (`datetime`,`servicecheck`),
  KEY `state_history_servicecheck_fk` (`servicecheck`),
  CONSTRAINT `state_history_servicecheck_fk` FOREIGN KEY (`servicecheck`) REFERENCES `servicechecks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

