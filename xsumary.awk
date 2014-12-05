#! /usr/bin/gawk -f

# --------------------------------------------------------------------
#  xsumary.awk V3.5                                        2008-03-18
# --------------------------------------------------------------------
#  USAGE: xsumary.awk -v intvl=5 -v arrayfile="array_10.ary" perf.csv
#   with: intvl     = measurement interval time in seconds
#         arrayfile = file with list of associated logical drives
#         perf.csv  = DS4000 performance statistics file     
# --------------------------------------------------------------------
#  This script extracts specific data lines from a given performance
#  statistics file collected on an IBM System Storage DS4000 subsystem
#  and calculates appropriate I/O statistics for a given array from
#  the logical drives associated with this particular array.
#  It requires a [array_XY.ary] file as input to identify the
#  associated logical drives for the given array and
#  - calculates IO size and current Read Ratio / Read Cache Hit Ratio
#    (only a very rough calculation based on the change of the 
#     total IO statistics from the previous to the current interval)  
#  - calculates avg. IOps, avg. kBps and avg. IO size at end of file
#    (avg. IO size is an IO count weighted average, avg. IOps and
#     avg. kBps exclude idle intervals and are non-idle time weighted
#     averages) 
#  - ignores lines without any performance information (e.g. header)
#  - outputs a tabulator separated list of values
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

BEGIN { FS=","; 
	newio=0; newrd=0; newch=0; newck=0; newmk=0; newco=0; newmo=0; counter=0; volcount=0; 
	oldio=0; oldrd=0; oldch=0; counter=0; avgsz=0; iocnt=0; init=0; oldmo=0; oldmk=0;
	avgiopssum=0; avgkbpssum=0;
	printf "# Time [s]\t Total IOs\t  Read [%]\t Cache Hit\t cur. kB/s\t max. kB/s\t cur. IO/s\t max. IO/s\t  c.IOsize\tc.Read [%]\tc.CacheHit\n"
      }

{j++;	if (init==0)
	{
		init=1;
		maxcount=0;
		while((getline volname < arrayfile)>0)
		{
			if (substr(volname,1,9)!="### ARRAY")
			{
				maxcount++;
				arraylist[maxcount]=volname
			};
		}
		close(arrayfile);
	}
	
	# if no volumes in array quit
	
	if (maxcount==0) { print "*** NO VOLUMES ***"; exit; }
	
	if (substr($0,1,13)=="Logical Drive")
	{
		volname=substr($1,15); 
	
		for (volid in arraylist)
		{
			if (volname==arraylist[volid])
			{
				n=2;
				while(n<9)
				{
					res[n-1]=strtonum($n);
					n=n+1;
				}

				newio+=res[1]; 	
				newrd+=(res[1]*(res[2]/100));	
				newch+=(res[1]*(res[2]/100)*(res[3]/100));
				newck+=res[4];	
				newco+=res[6];	
				# newmo+=res[7];
				# newmk+=res[5];	
				
				volcount++;
			};
		}
	}

	# print summary after having read all volume statistics per capture interval

	if (volcount==maxcount)
	{
		if (newrd!=0) { newch=(newch/newrd)*100 } else { newch=0 };
		if (newio!=0) { newrd=(newrd/newio)*100 } else { newrd=0 };

		# newmo=(newmo/volcount);
		# newmk=(newmk/volcount);	

		if (newck >= oldmk) { newmk=newck; oldmk=newmk; } else { newmk=oldmk; };
		if (newco >= oldmo) { newmo=newco; oldmo=newmo; } else { newmo=oldmo; };

		# calculate current io size

		if (newco==0) ciosize=0; else ciosize=newck/newco;

		# calculate current read ratio / cache hit ratio / io size

		deltaio=(newio-oldio);
		deltard=(newio*newrd)-(oldio*oldrd);
		deltach=(newio*newrd*newch)-(oldio*oldrd*oldch);
	
		# calculated values are only within range of +/-0.1% -> set to 0 if smaller
	
		if (deltard < (0.1*newio)) deltard=0; 	
		if (deltach < (0.1*newio)) deltach=0;

		# calculate current read percentage

		if (deltaio == 0) newcrd=0; else newcrd=(deltard/deltaio);
	
		if (newcrd < 0)   newcrd=0;
		if (newcrd > 100) newcrd=100;
	
		# calculate current read cache hit percentage

		if (deltard == 0) newcch=0; else newcch=deltach/deltard;

		if (newcch < 0)   newcch=0;
		if (newcch > 100) newcch=100;

		# calculate average io size and count intervals with i/o traffic for avg. IOps calculation

		if (deltaio != 0) 
		{ 
			iocnt++; 
			avgsz+=(deltaio*ciosize); 
			avgiopssum+=newco;
			avgkbpssum+=newck;
		};

		counter++;
		
		printf "%10d\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\t%10.1f\n", (counter*intvl), newio, newrd, newch, newck, newmk, newco, newmo, ciosize, newcrd, newcch;
	
		volcount=0; oldio=newio; oldrd=newrd; oldch=newch;

		newio=0; newrd=0; newch=0; newck=0; newmk=0; newco=0; newmo=0;
	}
}

END {
	runtime=(counter*intvl);
	if (runtime != 0) totiops=(oldio/runtime); else totiops=0;
	if (runtime != 0) idletime=100*(runtime-(iocnt*intvl))/runtime; else idletime=100;
	if (oldio != 0)   avgiosize=(avgsz/oldio); else avgiosize=0;
	if (iocnt != 0)   avgiops=(avgiopssum/iocnt); else avgiops=0;
	if (iocnt != 0)   avgkbps=(avgkbpssum/iocnt); else avgkbps=0;
	printf "\n";
	printf "### Total Runtime : %10d [s] ( %5.1f percent idle time )\n", runtime, idletime;
	printf "### Total IO/s    : %10.1f [IO/s]\n", totiops;
	printf "### Average IO/s  : %10.1f [IO/s]\n", avgiops;
	printf "### Average kB/s  : %10.1f [kB/s]\n", avgkbps;
	printf "### Avg. IO Size  : %10.1f [kB]\n", avgiosize;
    }
