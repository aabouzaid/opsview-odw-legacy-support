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

package Odw::Dataload;
use strict;

use base qw/Odw/;

__PACKAGE__->table("dataloads");

__PACKAGE__->columns( Primary => qw/id/, );
__PACKAGE__->columns(
    Essential => qw/opsview_instance_id period_start_timev period_end_timev
        load_start_timev load_end_timev status
        num_hosts num_services num_serviceresults num_perfdata duration
        last_reload_duration reloads
        /
);

__PACKAGE__->has_a(
    period_start_timev => 'DateTime',
    inflate            => sub { DateTime->from_epoch( epoch => shift, time_zone => "local" ) },
    deflate => sub { shift->epoch }
);

__PACKAGE__->has_a(
    period_end_timev => 'DateTime',
    inflate          => sub { DateTime->from_epoch( epoch => shift, time_zone => "local" ) },
    deflate => sub { shift->epoch }
);

__PACKAGE__->has_a(
    load_start_timev => 'DateTime',
    inflate          => sub { DateTime->from_epoch( epoch => shift, time_zone => "local" ) },
    deflate => sub { shift->epoch }
);

__PACKAGE__->has_a(
    load_end_timev => 'DateTime',
    inflate        => sub { DateTime->from_epoch( epoch => shift, time_zone => "local" ) },
    deflate => sub { shift->epoch }
);

__PACKAGE__->set_sql(
    maximum_period_end_timev => q{
  SELECT MAX(period_end_timev) FROM __TABLE__ WHERE opsview_instance_id = ?
}
);

sub maximum_period_end_timev {
    my ( $class, $opsview_instance_id ) = @_;
    return $class->sql_maximum_period_end_timev->select_val($opsview_instance_id);
}
1;
