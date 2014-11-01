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

package Odw::Queries;
use base 'Class::Accessor::Fast', 'Odw';
use SQL::Abstract;
use Odw::Host;

use strict;

__PACKAGE__->mk_accessors(qw(list summary));

=head1 NAME

Odw::Queries - Manual SQL for Odw interrogation

=head1 DESCRIPTION

Returns a listref of the data requested

=head1 METHODS

=item Odw::Queries->list_notifications( { start => $time, end => $time, %$args } )

Returns arrayref ordered by time, or notifications. start and end time in epoch time. Other args can be 
anything in the search columns - it is blindly passed through to the SQL using SQL::Abstract. Use
the controller to limit what can be passed.

Will return a mixture of hosts and services, depending on whether a host and/or service
has been specified or not.

Returns a listref. Ordered by entry time, latest first. Structure:
  item.hostname
  item.servicename (if applicable)
  item.entry_dt (DateTime object)
  item.status
  item.output
  item.notification_reason
  item.notification_number
  item.notified (arrayref)
    notified.contactname
    notified.methodname

=cut

# Expects $args->{where} to be set
# Expects $args->{cols}
# Returns an arrayref
sub list_host_notifications {
    my ( $class, $args ) = @_;
    $args = {%$args};
    if ( $_ = delete $args->{hostname} ) {
        $args->{name} = $_;
    }
    my $sql   = SQL::Abstract->new;
    my $table = [ "notification_host_history notifications", "hosts" ];
    my $cols  = [ "UNIX_TIMESTAMP(entry_datetime) as entry_tv", "status", "output", "notification_reason", "notification_number", "contactname", "methodname" ];
    unshift @$cols, "name as hostname";
    $args->{"notifications.host"} = \"= hosts.id";
    my ( $stmt, @bind ) = $sql->select( $table, $cols, $args, ["entry_datetime DESC, host, contactname, methodname"] );
    my $sth = Odw->db_Main->prepare_cached($stmt);
    $sth->execute(@bind);

    my @results     = ();
    my $item        = {};
    my $hostname    = "";
    my @notified    = ();
    my $lastcontact = "";
    my @methods;
    while ( my $hash = $sth->fetchrow_hashref ) {
        if ( $hostname ne $hash->{entry_tv} . "-" . $hash->{hostname} ) {
            if ($hostname) {
                push @notified, { contactname => $lastcontact, methods => [@methods] };
                $item->{notified} = [@notified];
                push @results, $item;
            }
            $item             = {};
            $item->{hostname} = $hash->{hostname};
            $item->{entry_tv} = $hash->{entry_tv};
            $item->{entry_dt}            = DateTime->from_epoch( epoch => $hash->{entry_tv}, time_zone => "local" );
            $item->{notification_reason} = $hash->{notification_reason};
            $item->{notification_number} = $hash->{notification_number};
            $item->{status}              = $hash->{status};
            $item->{output}              = $hash->{output};
            $lastcontact                 = $hash->{contactname};
            $hostname                    = $hash->{entry_tv} . "-" . $hash->{hostname};
            @notified                    = ();
            @methods                     = ();
        }
        if ( $lastcontact ne $hash->{contactname} ) {
            push @notified, { contactname => $lastcontact, methods => [@methods] };
            $lastcontact = $hash->{contactname};
            @methods     = ();
        }
        push @methods, $hash->{methodname};
    }
    if ($hostname) {
        push @notified, { contactname => $lastcontact, methods => [@methods] };
        $item->{notified} = [@notified];
        push @results, $item;
    }
    return \@results;
}

# Expects $args->{where} to be set
# Returns an arrayref
sub list_service_notifications {
    my ( $class, $args ) = @_;
    $args = {%$args};
    if ( $_ = delete $args->{servicename} ) {
        $args->{name} = $_;
    }
    my $sql   = SQL::Abstract->new;
    my $table = [ "notification_service_history notifications", "servicechecks" ];
    my $cols  = [ "UNIX_TIMESTAMP(entry_datetime) as entry_tv", "status", "output", "notification_reason", "notification_number", "contactname", "methodname" ];
    unshift @$cols, "hostname", "name as servicename", "service as serviceid";
    $args->{"notifications.service"} = \"= servicechecks.id";
    my ( $stmt, @bind ) = $sql->select( $table, $cols, $args, ["entry_datetime DESC, service, contactname, methodname"] );
    my $sth = Odw->db_Main->prepare_cached($stmt);
    $sth->execute(@bind);

    my @results     = ();
    my $item        = {};
    my $serviceid   = "";
    my @notified    = ();
    my $lastcontact = "";
    my @methods;
    while ( my $hash = $sth->fetchrow_hashref ) {
        if ( $serviceid ne $hash->{entry_tv} . "-" . $hash->{serviceid} ) {
            if ($serviceid) {
                push @notified, { contactname => $lastcontact, methods => [@methods] };
                $item->{notified} = [@notified];
                push @results, $item;
            }
            $item             = {};
            $item->{hostname} = $hash->{hostname};
            $item->{service}  = $hash->{servicename};
            $item->{entry_tv} = $hash->{entry_tv};
            $item->{entry_dt}            = DateTime->from_epoch( epoch => $hash->{entry_tv}, time_zone => "local" );
            $item->{notification_reason} = $hash->{notification_reason};
            $item->{notification_number} = $hash->{notification_number};
            $item->{status}              = $hash->{status};
            $item->{output}              = $hash->{output};
            $lastcontact                 = $hash->{contactname};
            $serviceid                   = $hash->{entry_tv} . "-" . $hash->{serviceid};
            @notified                    = ();
            @methods                     = ();
        }
        if ( $lastcontact ne $hash->{contactname} ) {
            push @notified, { contactname => $lastcontact, methods => [@methods] };
            $lastcontact = $hash->{contactname};
            @methods     = ();
        }
        push @methods, $hash->{methodname};
    }
    if ($serviceid) {
        push @notified, { contactname => $lastcontact, methods => [@methods] };
        $item->{notified} = [@notified];
        push @results, $item;
    }
    return \@results;
}

sub list_notifications {
    my ( $class, $args ) = @_;

    my $where = {%$args};

    my $endtime   = delete $where->{end};
    my $starttime = delete $where->{start};

    my $start_dt = DateTime->from_epoch( epoch => $starttime, time_zone => "local" );
    my $end_dt   = DateTime->from_epoch( epoch => $endtime,   time_zone => "local" );

    $where->{entry_datetime} = { -between => [ $start_dt->ymd . " " . $start_dt->hms, $end_dt->ymd . " " . $end_dt->hms ] };

    my ( $host_results, $service_results );
    if ( exists $args->{host} && exists $args->{service} ) {
        $where->{hostname} = delete $where->{host};
        my $servicename = delete $where->{service};
        $host_results         = $class->list_host_notifications($where);
        $where->{servicename} = $servicename;
        $service_results      = $class->list_service_notifications($where);
        return $class->merge_results( $host_results, $service_results );
    }
    elsif ( exists $args->{host} ) {
        $where->{hostname} = delete $where->{host};
        $host_results      = $class->list_host_notifications($where);
        $service_results   = $class->list_service_notifications($where);
        return $class->merge_results( $host_results, $service_results );
    }
    elsif ( exists $args->{service} ) {
        $where->{servicename} = delete $where->{service};
        return $class->list_service_notifications($where);
    }
    else {
        $host_results    = $class->list_host_notifications($where);
        $service_results = $class->list_service_notifications($where);
        return $class->merge_results( $host_results, $service_results );
    }
}

sub merge_results {
    my ( $class, $first, $second ) = @_;

    # Note: the sort is reversed! We want latest first
    my @results = sort { $b->{entry_tv} <=> $a->{entry_tv} } @$first, @$second;
    return \@results;
}

=item Odw::Queries->list_all_hostgroups_by_name

Returns a list of hostgroups, of all active hosts

=cut

sub list_all_hostgroups_by_name {
    my $class = shift;
    my $sth   = $class->db_Main->prepare_cached( "
SELECT hostgroup, hostgroup1, hostgroup2, hostgroup3, hostgroup4, 
 hostgroup5, hostgroup6, hostgroup7, hostgroup8, hostgroup9
FROM hosts
WHERE most_recent=1
" );
    $sth->execute;
    my %hostgroups;
    while ( my $row = $sth->fetchrow_arrayref ) {
        map { $hostgroups{$_} = 1 if defined $_ } @$row;
    }
    return keys %hostgroups;
}

1;
