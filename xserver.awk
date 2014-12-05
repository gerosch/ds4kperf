#! /usr/bin/gawk -f

# --------------------------------------------------------------------
#  xserver.awk V3.5                                        2008-03-18
# --------------------------------------------------------------------
#  USAGE: xserver.awk  DS4000_profile.txt
# --------------------------------------------------------------------
#  This script extracts host and host group information from a given
#  IBM System Storage DS4000 subsystem profile (firmware >=6.1) and 
#  creates a file named [host_HOSTNAME.svr] for each host or host 
#  group containing a list of all logical drives associated with this
#  particular host or host group.
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

BEGIN { FS=" "; server=0; serverno=0; servername=""; oldservername=""; start=0; vols=0;
      }

{j++;	if (($0=="\r")||($0=="")) next;

	if ((start==0)&&(substr($0,1,8)=="MAPPINGS"))
	{ 
		start=1; 
		next; 
	};

	if ((start==1)&&(substr($0,1,14)=="   VOLUME NAME"))
	{ 
		start=2; 
		next; 
	};

	if ((start==2)&&(substr($0,1,23)=="   TOPOLOGY DEFINITIONS"))
	{ 
		start=0; 
		exit; 
	};

	if ((start==2)&&(substr($0,1,23)=="   Access Logical Drive"))
	{ 
		next; 
	};

	if (start==2)
	{
		vols+=1;
		logvol=$1;

		servername=$5;
		if (servername=="Group") { servername=$6; }

		filename=sprintf("host_%s.srv",servername); 

		if (servername!=oldservername)
		{
			oldservername=servername;

			found=0;
			for (i in servernames)
			{ 
				if (servernames[i]==servername) { found=1; }
			}
		
			if (found==0)
			{
				serverno+=1;
				servernames[serverno]=servername;
				printf("### SERVER %s\n",servername);
				printf("### SERVER %s\n",servername) > filename ;
			}
		}

		print logvol >> filename ;
		next;
	};
}

END {
	printf("\n=> %d servers found with %d assigned logical drives\n\n",serverno,vols);
    }
