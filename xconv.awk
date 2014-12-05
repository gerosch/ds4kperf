#! /usr/bin/gawk -f

# --------------------------------------------------------------------
#  xconv.awk V3.5                                          2008-03-18
# --------------------------------------------------------------------
#  USAGE: xconv.awk  perfstats_wrong.csv  >  perfstats_right.csv
# --------------------------------------------------------------------
#  Occasionally the performance statistics output file from the IBM
#  System Storage DS4000 subsystem is not properly formatted due to
#  specific regional settings of the used operating system on which
#  the data was collected. In countries (e.g. Germany) where a comma 
#  instead of a period is used as decimal separator the individual
#  data columns cannot be identified anymore properly in a comma 
#  separated list of values. If the output of the DS4000 performance
#  statistics shows comma separated values which themselves use a 
#  comma instead of a period as decimal separator this script will
#  help and convert this output into a properly formatted one with
#  a period as decimal separator. This new file can then be properly 
#  processed with the other scripts available in this set.
# --------------------------------------------------------------------
#  This script converts the following input into the following output:
#
#  Performance statistics with a comma as decimal separator (XX,Y)
#  are changed into statistics with a period as decimal separator (XX.Y)
#
#  IN:  ...,[valueX-integer],[valueY-single decimal],...
#  OUT: ...,X.Y,...
# --------------------------------------------------------------------
#  EXAMPLE:
#    input :  Logical Drive A01DB1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
#    output:  Logical Drive A01DB1,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
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

BEGIN { FS=","; name=""; }

{j++;	

	if ((substr($0,1,13)!="Logical Drive")&&(substr($0,1,24)!="STORAGE SUBSYSTEM TOTALS")&&(substr($0,1,18)!="CONTROLLER IN SLOT")) 
	{
		print $0;
		next;
	}
	else
	{
		name=$1;
		vala=sprintf("%d.%d",$2,$3);
		valb=sprintf("%d.%d",$4,$5);
		valc=sprintf("%d.%d",$6,$7);
		vald=sprintf("%d.%d",$8,$9);
		vale=sprintf("%d.%d",$10,$11);
		valf=sprintf("%d.%d",$12,$13);
		valg=sprintf("%d.%d",$14,$15);
		
		printf "%s,%s,%s,%s,%s,%s,%s,%s,\n", name, vala, valb, valc, vald, vale, valf, valg; 
	}
}

END {    }
