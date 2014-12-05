#! /usr/bin/gawk -f

# --------------------------------------------------------------------
#  xconv2.awk V3.5                                         2008-03-18
# --------------------------------------------------------------------
#  USAGE: xconv2.awk  perfstats_wrong.csv  >  perfstats_right.csv
# --------------------------------------------------------------------
#  Occasionally the performance statistics output file from the IBM
#  System Storage DS4000 subsystem is not properly formatted due to
#  specific regional settings of the used operating system on which
#  the data was collected. In some cases where already a period is 
#  used as decimal separator you may still have improper fomatted 
#  columns with more than 7 data values where additional commas are
#  inserted to separate the thousands and millions of each value. 
#  If the output of the DS4000 performance statistics shows a varying
#  number of columns with commas separating the thousands and millions
#  of each value this script will help and convert this output into
#  a properly formatted one with only a period as decimal separator.
#  This new file can then be properly processed with the other scripts
#  available in this set.
# --------------------------------------------------------------------
#  This script converts DS4000 performance statistics with data values
#  of the format 1,000,000.0 into the standard format 1000000.0 which
#  makes it easy to process the data within spread sheets or other
#  scripts.
#  Performance statistics with a comma as separator for THOUSANDS and
#  MILLIONS are changed into statistics with only a period as decimal
#  separator and seven properly formatted columns:
#
#  IN:  ...,[XXX x 1000000],[YYY x 1000],[ZZZ.V],...
#  OUT: ...,XXXYYYZZZ.V,...
# --------------------------------------------------------------------
#  EXAMPLE:
#    input :  CONTRL A,2,533.0,97.8,15.1,8,252.7,8,252.7,422.2,422.2,
#    output:  CONTRL A,2533.0,97.8,15.1,8252.7,8252.7,422.2,422.2,
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
	all=$0;
	name=$1;

	# extract Comma Separated Values
	
	data=substr(all,index(all,",")+1);
	data=sprintf("0.0,%s",substr(data,0,length(data)-2));
	partno=split(data,parts,".")

	n=1;
	
	while(n<8)
	{
		count=split(parts[n+1],a,",")-1;
		m=1;
		value=0;

		while(m<=count)
		{
			value=value+strtonum(a[m+1])*(1000**(count-m));
			m=m+1;
		}

		res[n]=value+0.1*strtonum(substr(parts[n+2],0,1));
		n=n+1;
	}

	newio=res[1]; 	newrd=res[2];	newch=res[3];
	newck=res[4];	newmk=res[5];	newco=res[6];	newmo=res[7];

	printf "%s,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,\n", name, newio, newrd, newch, newck, newmk, newco, newmo; 
	
	}
}

END {    }
