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

package Odw::Host;
use strict;

use base qw/Odw/;

__PACKAGE__->table("hosts");

__PACKAGE__->columns( Primary   => qw/id/, );
__PACKAGE__->columns( Essential => qw/name most_recent crc nagios_object_id/ );
__PACKAGE__->columns(
    Others => qw/alias hostgroup hostgroup1 hostgroup2 hostgroup3
        hostgroup4 hostgroup5 hostgroup6 hostgroup7 hostgroup8
        hostgroup9 monitored_by active_date
        opsview_instance_id
        /,
);

__PACKAGE__->has_a(
    active_date => 'DateTime',
    inflate     => sub { DateTime->from_epoch( epoch => shift, time_zone => "local" ) },
    deflate => sub { shift->epoch }
);

__PACKAGE__->has_many( performance_labels => "Odw::Performancelabel" );

=item Odw::Host->find_or_create_with_crc

See Odw->find_or_create_with_crc. All this does is change the list of hostgroups into a
set of key values

=cut

sub find_or_create_with_crc {
    my $class = shift;
    my ( $primary_hash, $data_hash ) = @_;

    $class->transform_hostgroups($data_hash);
    $class->SUPER::find_or_create_with_crc(@_);
}

sub transform_hostgroups {
    my ( $class, $hash ) = @_;
    my $i = 1;
    my $hostgroups = delete $hash->{hostgroups} || die "Must have hostgroups set";
    foreach my $hg (@$hostgroups) {
        my $n = "hostgroup" . $i;
        $hash->{$n} = $hg;
        $i++;
        last if $i >= 10;
    }
}

=item $class->list_host_servicechecks_with_perfdata( $hostname );

Returns a list of servicecheck names for a given hostname that has performance 
data available

=cut

__PACKAGE__->set_sql(
    host_servicechecks_with_perfdata => qq{
	SELECT DISTINCT(sc.name)
	FROM servicechecks sc, performance_labels pl
	WHERE sc.id = pl.servicecheck
	AND sc.hostname = ?
	ORDER BY sc.name
}
);

sub list_host_servicechecks_with_perfdata {
    my $class    = shift;
    my $hostname = shift;
    my $sth      = $class->sql_host_servicechecks_with_perfdata;
    $sth->execute($hostname);
    my @checks;
    while ( my $row = $sth->fetchrow_array ) {
        push( @checks, $row );
    }
    return @checks;
}

=item $class->list_leaf_hostgroups( $search )

List all distinct hostgroups, ordered by name, searched by name. Returns an arrayref

=cut

__PACKAGE__->set_sql(
    leaf_hostgroups => qq{
SELECT DISTINCT(hostgroup)
FROM __TABLE__
WHERE most_recent = 1
AND hostgroup LIKE ?
ORDER BY hostgroup
}
);

sub list_leaf_hostgroups {
    my ( $class, $search ) = @_;
    $search = "" unless defined $search;
    my $sth = $class->sql_leaf_hostgroups;
    $sth->execute("%$search%");
    my @hgs;
    while ( my $hg = $sth->fetchrow_array ) {
        push @hgs, $hg;
    }
    return \@hgs;
}

1;
