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

package Odw::Performancelabel;
use base qw/Odw/;

use strict;

__PACKAGE__->table("performance_labels");

__PACKAGE__->columns( Primary   => qw/id/, );
__PACKAGE__->columns( Essential => qw/host servicecheck name units/ );

__PACKAGE__->has_a( host         => "Odw::Host" );
__PACKAGE__->has_a( servicecheck => "Odw::Servicecheck" );
__PACKAGE__->has_many( data => "Odw::Performancedata" => "id" );

1;
