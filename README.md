ODW Legacy Support
==================

![Alt text](Eenable_ODW_with_Opsview_Core.png?raw=true "Eenable ODW with Opsview Core")

#####SYNTAX:
Don't have any, just run it.

#####DESCRIPTION:
Simple script to install "Opsview Data Warehouse" (ODW) that no longer available with "Opsview Core".<br>
ODW was a part of "Opsview Community" (had been deprecated for a while now) and this script making ODW working with "Opsview Core".<br>
For more information please check:<br>
- http://docs.opsview.com/doku.php?id=opsview-core:upgrading:upgradetocore<br>
- http://docs.opsview.com/doku.php?id=opsview4.4:odw<br>
- http://www.opsview.com/products/opsview-core<br>

#####NOTES:
1. All ODW files/scripts are from Opsview Community 20120424 (The last Community Version).<br>
2. This script tested with Opsview Core 3.20131016.0 and RHEL/Cetnos 6.5.<br>
3. Some Opsview scripts have multi fuctions beside ODW functions, so all files included with odw_legacy_support script get back to ODW only, and any script has multi functions didn't included. (e.g. utils/rename_host script)"<br>
4. This script working and tested with option "enable_odw_import" only, the option "enable_full_odw_import" didn't tested practically yet.<br>

#####VERSION:
ODW legacy support script v0.3 - 1 November 2014.


#####BY:
Ahmed M. AbouZaid (www.aabouzaid.com) - Under MIT license.<br>
All copyright of "ODW" scripts goes to "Opsview Limited" and licensed under the terms of the GNU General Public License Version 2.<br>

#####TODO:
Make more testing and automate any manual actions.
