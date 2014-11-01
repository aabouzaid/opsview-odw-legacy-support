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

package Odw::Servicecheck;
use base qw/Odw/;

use strict;

__PACKAGE__->table("servicechecks");

__PACKAGE__->columns( Primary => qw/id/, );

# crc and hostname are essential to stop a 2nd lookup to DB and lots of DateTime inflation - roll on DBIx::Class!
__PACKAGE__->columns( Essential => qw/name host hostname description crc nagios_object_id/ );
__PACKAGE__->columns(
    Others => qw/
        servicegroup active_date most_recent
        keywords
        /
);

__PACKAGE__->has_a( host => "Odw::Host" );
__PACKAGE__->has_many( performance_labels => "Odw::Performancelabel" );

__PACKAGE__->has_a(
    active_date => 'DateTime',
    inflate     => sub { DateTime->from_epoch( epoch => shift, time_zone => "local" ) },
    deflate => sub { shift->epoch }
);

=item $class->list_host_servicecheck_metrics( $hostname, $servicecheck_name );

Returns a list of servicecheck names for a given hostname that has performance 
data available

=cut

__PACKAGE__->set_sql(
    host_servicecheck_metrics => qq{
	SELECT DISTINCT(pl.name)
	FROM servicechecks sc, performance_labels pl
	WHERE sc.hostname = ?
	AND sc.name = ?
	AND pl.servicecheck = sc.id
	ORDER BY pl.name
}
);

sub list_host_servicecheck_metrics {
    my $class    = shift;
    my $hostname = shift;
    my $svcname  = shift;
    my $sth      = $class->sql_host_servicecheck_metrics;
    $sth->execute( $hostname, $svcname );
    my @metrics;
    while ( my $row = $sth->fetchrow_array ) {
        push( @metrics, $row );
    }
    return @metrics;
}

1;
