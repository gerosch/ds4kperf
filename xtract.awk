#! /usr/bin/gawk -f

# --------------------------------------------------------------------
#  xtract.awk V3.5                                         2008-03-18
# --------------------------------------------------------------------
#  USAGE: xtract.awk  perfstats.csv  >  perfstats.dat
#   with: perfstats.csv = DS4000 performance statistics file
#         perfstats.dat = performance statistics file with
#                         tabulator separated values
# --------------------------------------------------------------------
#  This script extracts the appropriate data columns from a 
#  performance statistics file collected on an IBM System Storage
#  DS4000 subsystem and removes all lines without any performance data 
#  information. The output is a new performance data file with
#  tabulator separated values. This script is used for formatting the 
#  output of the last measurement interval in the SUMMARY.dat file.
#  The IBM DS4000 subsystem needs to be at firmware level >= 6.1.
# --------------------------------------------------------------------
#  This script is called by the xperf.sh script and must reside in 
#  the same current working directory.
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

BEGIN { FS=","
	printf "# Device   \t Total IOs\t  Read [%]\t Cache Hit\t cur. kB/s\t max. kB/s\t cur. IO/s\t max. IO/s\n"
      }

{j++;	if (($0=="\r")||($0=="")) next;
	if ((substr($0,1,13)!="Logical Drive")&&(substr($0,1,24)!="STORAGE SUBSYSTEM TOTALS")&&(substr($0,1,18)!="CONTROLLER IN SLOT")) next;
	if (substr($0,0,13)=="Logical Drive") volname=substr($1,15);
	if (substr($0,1,24)=="STORAGE SUBSYSTEM TOTALS") volname="SYSTEM TOTALS";
	if (substr($0,1,20)=="CONTROLLER IN SLOT A")     volname="CTRL A TOTALS";
	if (substr($0,1,20)=="CONTROLLER IN SLOT B")     volname="CTRL B TOTALS";
		
	# extract Comma Separated Values
	
	n=2;

	while(n<9)
	{
		res[n-1]=strtonum($n);
		n=n+1;
	}

	printf "%s\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\n", volname, res[1], res[2], res[3], res[4], res[5], res[6], res[7];

}

END {
    }
