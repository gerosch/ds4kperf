#!/bin/sh

# --------------------------------------------------------------------
#  xperf.sh V3.5                                           2008-03-18
# --------------------------------------------------------------------
#  USAGE: xperf.sh [DS4000 Profile] [DS4000 Performance Statistics]
# --------------------------------------------------------------------
#  This shell script extracts individual performance statistics from
#  a single performance statistics file that has been collected on an
#  IBM System Storage DS4000 subsystem with firmware >= 6.1.
#  It creates individual files with performance statistics for 
#   - each logical drive       (in the directory ./_VOL)
#   - each array               (in the directory ./_ARY)
#   - each host / host group   (in the directory ./_SRV)
#   - CONTROLLER IN SLOT A     (in the directory ./_SYS)
#   - CONTROLLER IN SLOT B     (in the directory ./_SYS)
#   - STORAGE SUBSYSTEM TOTALS (in the directory ./_SYS)
#  and a SUMMARY.dat file from the last measurement interval.
# --------------------------------------------------------------------
#  This script requires a DS4000 profile and a DS4000 performance
#  statistics file as input. The DS4000 profile needs to meet the
#  current configuration that was used during the performance data
#  collection otherwise **only** the volumes which are present in the
#  DS4000 profile are extracted from the performance statistics file
#  and used for calculating the additional array and server statistics.
#  If you do not have the DS4000 profile which represents the exact 
#  volume configuration during the performance measurement consider to
#  use the xperfvols.sh script instead which extracts all volumes from
#  the performance statistics file without calculating advanced
#  array and server statistics based on the DS4000 configuration.
# --------------------------------------------------------------------
#  This script calls and thus depends on the following additional
#  scripts which must reside in the same current working directory:
#   - xfilter.awk
#   - xtract.awk
#   - xarray.awk
#   - xserver.awk
#   - xsumary.awk
#   - xsumsrv.awk
# --------------------------------------------------------------------
#  The script should be executed in a newly created working directory 
#  containing only the script files listed above, the DS4000 profile
#  and the performance statistics file.
# --------------------------------------------------------------------
#  Multiple executions of the script on different DS4000 performance
#  statistics files and appropriate DS4000 profiles within the same
#  working directory are possible, if the _ARY, _SRV, _SYS and _VOL
#  directories from each run are just moved into another newly
#  created subdirectory before the next run, for example:
#  1.RUN   ./xperf.sh  DS4k_RZ1_profile.txt  DS4k_RZ1_perfstats.txt
#          mkdir DS4k_RZ1
#          mv _ARY _SRV _SYS _VOL DS4k_RZ1
#  2.RUN   ./xperf.sh  DS4k_RZ2_profile.txt  DS4k_RZ2_perfstats.txt
#          mkdir DS4k_RZ2
#          mv _??? DS4k_RZ2
# --------------------------------------------------------------------
#  The script will create additional directories called 
#    _ARY
#    _SRV
#    _SYS
#    _VOL
#  in the current working directory containing the individual array, 
#  volume, server and system statistics. Existing directories with 
#  these file names in the current working directory will be DELETED 
#  prior to calculating the new performance statistics in order to 
#  clean up remaining files from previous script executions.
# --------------------------------------------------------------------
#  The script execution depends on the creation of some temporary 
#  files ending with .tmp and some additional working files which 
#  contain the volume information with regard to the servers and 
#  arrays which are named array_XY.ary and host_XYZ.srv.
#  By executing this script existing files with names ending in
#    .tmp
#    .ary
#    .srv 
#  in the current working directory may be be LOST.
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
#  Please run the DS4000 performance statistics file through the
#  <dos2unix> command before processing it with these scripts!
# --------------------------------------------------------------------


### Variables

profile=$1
logname=$2

PID=$$
volsperffile="vols_in_perfstats"
volsprocfile="vols_in_profile"
volsperfcount=""
volsproccount=""
intervaltime=""
fasttname=""

VOLDIR="_VOL"
ARYDIR="_ARY"
SRVDIR="_SRV"
SYSDIR="_SYS"

IFSOLD="${IFS}"


### User functions

function myexit
{
	echo >&2
	echo ">>> $1" >&2
	echo >&2
	exit 1
}


### Check Parameter Count

[[ $# != 2 ]] && myexit "Usage: # xperf.sh [DS4000 Profile] [DS4000 PerfStats]"
[[ ! -f "${profile}" ]] && myexit ">>> Profile [${profile}] not found. Please check file name!"
[[ ! -f "${logname}" ]] && myexit ">>> Performance Statistics File [${logname}] not found. Please check file name!"


### Start Processing Performance Log

echo "--------------------------"
echo "xperf.sh V3.5 (2008-03-18)"
echo "--------------------------"
echo
echo "Started at $(date)"
echo "on performance statistics file [${logname}]"
echo "with subsystem profile [${profile}]."


### Extract DS4000 Performance Statistics Header Information

fasttname=$(grep -m 1 'Performance Monitor Statistics for Storage Subsystem:' "${logname}" | cut -b 55-)
[[ "$fasttname" = "" ]] && fasttname="./."
intervaltime=$(grep -m 1 'Polling interval in seconds:' "${logname}" | cut -b 30-)
starttime=$(grep -m 1 'Date/Time:' "${logname}" | cut -b 12-)

echo
echo "DS4000 Name       : $fasttname"
echo "Date of PerfStats : $starttime"
echo "Sample Interval   : $intervaltime seconds"
echo


### Clean up remaining Files from previous runs

rm -rf "$ARYDIR" 2>/dev/null
rm -rf "$SRVDIR" 2>/dev/null
rm -rf "$SYSDIR" 2>/dev/null
rm -rf "$VOLDIR" 2>/dev/null
ls -1 | grep -E "array_[0-9]+\.ary" | while read a; do rm -f $a 2>/dev/null ; done
ls -1 | grep -E "host_.+\.srv"      | while read a; do rm -f $a 2>/dev/null ; done
rm -f "${volsperffile}.tmp" 2>/dev/null
rm -f "${volsprocfile}.tmp" 2>/dev/null


### Extract DS4000 Logical Drives per Array from DS4000 Profile

mkdir  "$ARYDIR" 2>/dev/null
[[ $? != 0 ]] && myexit "ERROR: Could not create directory $ARYDIR !"
./xarray.awk "${profile}"


### Extract DS4000 Logical Drives per Hosts and Hosts Groups from DS4000 Profile

mkdir  "$SRVDIR" 2>/dev/null
[[ $? != 0 ]] && myexit "ERROR: Could not create directory $SVRDIR !"
./xserver.awk "${profile}"


### Extract DS4000 Controller and Subsystems Totals

mkdir  "$SYSDIR" 2>/dev/null
[[ $? != 0 ]] && myexit "ERROR: Could not create directory $SYSDIR !"
for b in "STORAGE SUBSYSTEM TOTALS" "CONTROLLER IN SLOT A" "CONTROLLER IN SLOT B"
do
	echo "# Devices,Total,Read [%],Cache [%],Current kB/s,Maximum kB/s,Current IO/s,Maximum IO/s" >  "${b}.tmp"
	grep -w "$b" "${logname}"  >> "${b}.tmp"
	echo "...processing data for ${b}"
	./xfilter.awk -v "intvl=${intervaltime}" "${b}.tmp" > "${SYSDIR}/${b}.dat"
	rm -f "${b}.tmp"
done


### Extract Logical Drive Performance Data

IFS="${IFSOLD}"

mkdir  "$VOLDIR" 2>/dev/null
[[ $? != 0 ]] && myexit "ERROR: Could not create directory $VOLDIR !"
ls -1 | grep -E "array_[0-9]+\.ary" | while read a
do
	arno=$(echo $a|cut -d"." -f1|cut -d"_" -f2);
	grep -v "### ARRAY" $a | while read b
	do
		echo "# Devices,Total,Read [%],Cache [%],Current kB/s,Maximum kB/s,Current IO/s,Maximum IO/s" >  "${arno}_${b}.tmp"
		grep "Logical Drive $b," "${logname}"  >> "${arno}_${b}.tmp"
		echo "...processing data for array ${arno} and logical drive [${b}]"
		echo "$b" >> "${volsprocfile}.tmp"
		./xfilter.awk -v "intvl=${intervaltime}" "${arno}_${b}.tmp" > "${VOLDIR}/${arno}_${b}.dat"
		rm -f "${arno}_${b}.tmp" 
	done
done


### Summarize Array I/O Load

ls -1 | grep -E "array_[0-9]+\.ary" | while read a
do
	arno=$(echo $a|cut -d"." -f1|cut -d"_" -f2);
	echo "...calculating totals for array ${arno} on $a"
	./xsumary.awk -v "intvl=${intervaltime}" -v "arrayfile=${a}" "${logname}" > "${ARYDIR}/array_${arno}.dat"
	mv -f "$a" "${ARYDIR}/"
done


### Summarize Host and Host Group I/O Load

ls -1 | grep -E "host_.+\.srv" | while read a
do
	srvname=$(echo $a|cut -d"." -f1);
	echo "...calculating totals for server $(echo ${srvname}|cut -b 6-) on $a"
	./xsumsrv.awk -v "intvl=${intervaltime}" -v "serverfile=${a}" "${logname}" > "${SRVDIR}/${srvname}.dat"
	mv -f "$a" "${SRVDIR}/"
done


### Extract last Sample Interval as overall Volume Summary

echo "...processing last capture iteration for summary: Interval No.$(grep 'Capture Iteration:' "${logname}" | tail -1 | cut -d':' -f 2)"
wc -l "${logname}" | while read a b
do
 echo   "# DS4000 Name       : $fasttname"             > "${SYSDIR}/SUMMARY.dat"
 echo   "# Date of PerfStats : $starttime"            >> "${SYSDIR}/SUMMARY.dat"
 echo   "# Sample Interval   : $intervaltime seconds" >> "${SYSDIR}/SUMMARY.dat"
 c=$(grep -n 'Capture Iteration:' "${logname}" | tail -1 | cut -d ':' -f 1 )
 let d=a-c
 lastint=$(tail -$d "${logname}" | head -1 | cut -b 12-)
 echo   "# Last Interval     : $lastint"              >> "${SYSDIR}/SUMMARY.dat"
 tail -$d "${logname}" | ./xtract.awk		      >> "${SYSDIR}/SUMMARY.dat"
done


### Verify volume count in DS4000 performance statistics and in DS4000 profile

IFS=","

count=$(grep -m 2 -n 'Capture Iteration' "${logname}" | tail -1 | cut -d ':' -f 1)

head -$count "${logname}" | grep 'Logical Drive' | sort -u -t ',' -k 1,1 | while read a rest
do 
 echo $a | cut -b 15- >> "${volsperffile}.tmp"
done

volsperfcount=$(wc -l "${volsperffile}.tmp" | cut -d' ' -f 1)
volsproccount=$(wc -l "${volsprocfile}.tmp" | cut -d' ' -f 1)

mv -f "${volsperffile}.tmp"   "${SYSDIR}/${volsperffile}.vol"
sort  "${volsprocfile}.tmp" > "${SYSDIR}/${volsprocfile}.vol"
rm -f "${volsprocfile}.tmp"

echo
echo "### SUMMARY: logical drives"  
echo "=> $volsproccount logical drives processed as found in DS4000 profile (for list see <${volsprocfile}.vol>)"
echo "=> $volsperfcount logical drives found in DS4000 performance statistics file (for list see <${volsperffile}.vol>)"
echo

[[ $volsproccount != $volsperfcount ]] && { echo; 
  echo ">>> ================================================================================="
  echo ">>> WARNING: LOGICAL DRIVE MISMATCH IN DS4000 PERFORMANCE STATISTICS FILE AND PROFILE"
  echo ">>> ================================================================================="
  echo ">>> $volsperfcount logical drives have been found in DS4000 performance statistics file"
  echo ">>> but only $volsproccount volumes according to the DS4000 profile have been processed!"
  echo ">>> The DS4000 profile probably does not reflect the proper logical drive configuration"
  echo ">>> that was used during the performance data collection." 
  echo
};


### END

echo
echo "!!! Processing of DS4000 Performance Statistics completed !!!"
echo
