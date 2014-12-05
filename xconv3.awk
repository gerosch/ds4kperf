#! /usr/bin/gawk -f

# --------------------------------------------------------------------
#  xconv3.awk V1.0                                         2008-09-24
# --------------------------------------------------------------------
#  USAGE: xconv3.awk perfstats_V71.csv > perfstats_regular.csv
# --------------------------------------------------------------------
#  This gawk script converts DS3000/DS4000/DS5000 performance data 
#  output files collected on systems with firmware levels 7.10 and 
#  above to regular CSV files by removing the additional quotation
#  marks in the data introduced with firmware levels 7.10 and above.
# --------------------------------------------------------------------
#  Background: Starting with DS3000 and DS4000 firmware levels 7.10 and 
#  above the output of the performance data collection changed to a new
#  format where all values are surrounded by quotation marks:
#
#  "Capture Iteration: 1","","","","","","",""
#  "Date/Time: 12.02.08 10:29:14","","","","","","",""
#  "CONTROLLER IN SLOT A","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
#  "Logical Drive Data_1","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
#  "Logical Drive Data_3","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
#
#  Values enclosed by quotation marks are typically interpreted as
#  strings and not as numbers, which can make data processing in this
#  format more complicated. The script removes the quotation marks 
#  and convert the file back into a standard CSV format.
# --------------------------------------------------------------------
#  Copyright (C) 2008  Gero Schmidt       EMail: groscht<at>gmail.com
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 or any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  You should have received a copy of the GNU General Public License
#  along with this program. If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------
#  DISCLAIMER OF WARRANTY
#
#  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
#  APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
#  HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
#  OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
#  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#  PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
#  IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
#  ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
#
#  LIMITATION OF LIABILITY
#
#  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
#  WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
#  THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
#  GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
#  USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
#  DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
#  PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
#  EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
#  SUCH DAMAGES.
# --------------------------------------------------------------------
#  TRADEMARKS:
#  The following terms are trademarks of International Business 
#  Machines Corporation in the United States and/or other countries:
#  DS4000, System Storage
# --------------------------------------------------------------------
#            WARNING:  Use this script at your own risk!
# --------------------------------------------------------------------
#  Please run the DS4000 performance statistics file through the
#  <dos2unix> command before processing it with these scripts!
# --------------------------------------------------------------------

BEGIN {}
{ gsub("\"", ""); gsub(" - ", "\n"); }
{ gsub(",,,,,,,", ""); }
/CONTROLLER IN SLOT/ { print $0 ","; next; }
/STORAGE SUBSYSTEM TOTALS/ { print $0 ","; next; }
/Logical Drive/ { print $0 ","; next; }
{ print $0; }
END {}
