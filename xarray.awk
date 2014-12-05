#! /usr/bin/gawk -f

# --------------------------------------------------------------------
#  xarray.awk V3.5                                         2008-03-18
# --------------------------------------------------------------------	 
#  USAGE: xarray.awk  DS4000_profile.txt
# --------------------------------------------------------------------
#  This script extracts RAID array information from a given IBM 
#  System Storage DS4000 profile (firmware >= 6.1) and creates a file
#  named [array_XY.ary] for each array (XY=array number) containing
#  a list of all logical drives associated with this particular array.
# --------------------------------------------------------------------
#  This script is called by the xperf.sh script and must reside in 
#  the same current working directory.
# --------------------------------------------------------------------
#  NOTE: This script may fail if the names of the DS4000 logical 
#  drives or the hosts / host groups do contain special characters
#  which are not suitable for file names.
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

BEGIN { FS=" "; array=0; arrayno=0; oldarrayno=-1; start=0; vols=0;
      }

{j++;	if (($0=="\r")||($0=="")) next;

	if ((start==0)&&(substr($0,1,23)=="STANDARD LOGICAL DRIVES"))
	{ 
		start=1; 
		next; 
	};

	if ((start==1)&&(substr($0,1,7)=="   NAME"))
	{ 
		start=2; 
		next; 
	};

	if ((start==2)&&(substr($0,1,7)=="DETAILS"))
	{ 
		start=0; 
		exit; 
	};

	if (start==2)
	{
		vols+=1;
		
		logvol=$1
		raid=$5
		arrayno=$6

		if (arrayno!=oldarrayno)
		{
			oldarrayno=arrayno;
			filename=sprintf("array_%d.ary",arrayno); 
			
			found=0;
			for (i in arraynames)
			{ 
				if (arraynames[i]==filename) { found=1; }
			}
			
			if (found==0)
			{
				
				array+=1;
				arraynames[array]=filename;
				printf("### Array %3d - (RAID %d)\n",arrayno,raid);
				printf("### ARRAY : Array %3d - (RAID %d)\n",arrayno,raid) > filename ;
			}
		}

		print logvol >> filename ;
		next;
	};
}

END {
	printf("\n=> %d arrays found with %d logical drives\n\n",array,vols);
    }
