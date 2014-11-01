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

package Odw::Searches;
use Class::Accessor::Fast;
use base 'Class::Accessor::Fast', 'Odw';
use SQL::Abstract;
use DateTime;

use strict;

#__PACKAGE__->mk_accessors(qw(list summary));

=pod

=head1 NAME

Odw::Searches - Searches the runtime DB for hostgroup, host and service 
information

=head1 DESCRIPTION

Holds all the searches of the runtime DB to retrieve status summaries 
depending on whether specified by hostgroup, host or service.

=head1 METHODS

=over 4

=item OdwDB::Searches->list_performance_data($start,$end,$host,$check,$metric)

Returns arrayref of data for the service check.  If $metric_id is also
provided will only return data for that metric.

Returns a array of hashes containing an array of keys (epoc) and values for 
each metric, i.e.

	[
		{
			metric => "name",
			units => "%",
			keys => [1,2,3,4,5],
			values => [5,4,3,2,1],
		}, 
		{
			metric => "name",
			units => "MB",
			keys => [1,2,3,4,5],
			values => [5,4,3,2,1],
		}, 
	],

=cut

sub list_performance_data {
    my ( $class, $startdate, $enddate, $hostname, $svcname, $metricname ) = @_;
    my %results;

    my $dbh = $class->db_Main();

    my $sql = qq{
		SELECT UNIX_TIMESTAMP(pd.datetime) AS datetime, pl.name AS name, pd.value AS value, pl.units AS units
		FROM performance_labels pl, performance_data pd, servicechecks sc
		WHERE pd.performance_label = pl.id
		AND sc.id = pl.servicecheck
		AND sc.hostname = ?
		AND sc.name     = ?
		AND pd.datetime BETWEEN ? AND ?
	};

    my @args = ( $hostname, $svcname, $startdate, $enddate );

    if ($metricname) {
        $sql .= qq{
			AND
			pl.name = ?
		};
        push @args, $metricname;
    }

    $sql .= qq{
		ORDER BY pd.datetime
	};

    my $sth = $dbh->prepare_cached($sql);

    $sth->execute(@args);

    while ( my $row = $sth->fetchrow_hashref ) {
        $results{ $row->{name} }{metric} = $row->{name}
            if ( $row->{name} && !$results{ $row->{name} }{metric} );
        $results{ $row->{name} }{units} = $row->{units}
            if ( $row->{units} && !$results{ $row->{name} }{units} );
        push( @{ $results{ $row->{name} }{keys} },   $row->{datetime} );
        push( @{ $results{ $row->{name} }{values} }, $row->{value} );
    }

    my @results;

    foreach my $key ( sort( keys(%results) ) ) {
        push( @results, $results{$key} );
    }

    return \@results;
}

=back

=cut

1;
