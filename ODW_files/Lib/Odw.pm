#
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

package Odw;
use strict;
use lib "/usr/local/nagios/perl/lib";
use base "Exporter", 'ClassDBIExtras', 'Class::DBI::Sweet';
use DateTime;
use DateTime::Format::MySQL;
use Opsview::Config;

use Carp;
use Exporter;
our $VERSION = '$Version$';

my $db_options = { RaiseError => 1, AutoCommit => 1, mysql_auto_reconnect => 1 };

__PACKAGE__->connection( Opsview::Config->odw_dbi . ":database=" . Opsview::Config->odw_db . ";host=" . Opsview::Config->odw_dbhost, Opsview::Config->odw_dbuser, Opsview::Config->odw_dbpasswd, $db_options, { on_connect_do => "SET time_zone='+00:00'" }, );

sub db       { Opsview::Config->odw_db }
sub dbhost   { Opsview::Config->odw_dbhost }
sub dbuser   { Opsview::Config->odw_dbuser }
sub dbpasswd { Opsview::Config->odw_dbpasswd }

=head1 NAME

Odw - Middleware for ODW database

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

Handles interaction with database for ODW data storage

=head1 METHODS

=over 4

=item $class->calculate_crc( \%hash )

Returns a crc16 value based on the values in the hash

=cut

sub calculate_crc {
    my ( $class, $hash ) = @_;
    use Digest::CRC qw(crc16);
    my $crc = crc16( join( "", map { $hash->{$_} } keys %$hash ) );
    return $crc;
}

=item $class->find_or_create_with_crc( 
	{ search_vals => value, ... },
	{ crc_data => value, ... },
	{ non_crc_data => value, ... },
	)

Does a search based on search_vals. If found, check the crc data. Creates a new entry if crcs differ.
The non_crc_data gets added only if an insert occurs - this is optional.
Expects the columns: most_recent, active_date and crc

Returns the object.

=cut

sub find_or_create_with_crc {
    my ( $class, $primary_hash, $data_hash, $extra_hash ) = @_;
    die "Need to have name" unless $primary_hash->{name};

    my $crc = $class->calculate_crc($data_hash);

    my ($servicecheck) = $class->search( %$primary_hash, most_recent => 1 );
    if ($servicecheck) {
        if ( $servicecheck->crc == $crc ) {
            return $servicecheck;
        }
        else {
            $servicecheck->most_recent(0);
            $servicecheck->update;
        }
    }
    $data_hash->{crc}         = $crc;
    $data_hash->{most_recent} = 1;
    $data_hash->{active_date} = time();
    map { $data_hash->{$_} = $primary_hash->{$_} } ( keys %$primary_hash );
    if ($extra_hash) {
        map { $data_hash->{$_} = $extra_hash->{$_} } ( keys %$extra_hash );
    }
    return $class->insert($data_hash);
}

=item $class->search_between_dates('colname', 'start date/time','end date/time')

Search between two dates within a given column.  Returns an array of objects
sorted by $colname.

=cut

sub search_between_dates {
    my $class  = shift;
    my $column = shift;
    my $start  = shift;
    my $end    = shift;

    return $class->retrieve_from_sql("$column BETWEEN '$start' AND '$end' ORDER BY '$column'");
}

=back

=head1 AUTHOR

Opsview Limited

=head1 LICENSE

GNU General Public License v2

=cut

1;
