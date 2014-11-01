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

package Odw::Performancedata;
use base qw/Odw/;

use strict;

__PACKAGE__->table("performance_data");

__PACKAGE__->columns( Essential => qw/ datetime performance_label value/ );

__PACKAGE__->has_a( performance_label => "Odw::Performancelabel" );

__PACKAGE__->has_datetime('datetime');

1;
