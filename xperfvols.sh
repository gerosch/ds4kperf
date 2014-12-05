#!/bin/sh

# --------------------------------------------------------------------
#  xperfvols.sh V3.5                                       2008-03-18
# --------------------------------------------------------------------
#  USAGE: xperfvols.sh [DS4000 Performance Statistics File]
# --------------------------------------------------------------------
#  This shell script extracts individual performance statistics from
#  a single performance statistics file that was collected on an
#  IBM System Storage DS4000 subsystem with firmware >= 6.1.
#  It creates individual files with performance statistics for 
#   - each logical drive       (in the directory ./_VOL)
#   - CONTROLLER IN SLOT A     (in the directory ./_SYS)
#   - CONTROLLER IN SLOT B     (in the directory ./_SYS)
#   - STORAGE SUBSYSTEM TOTALS (in the directory ./_SYS)
#  and a SUMMARY.dat file from the last measurement interval.
# --------------------------------------------------------------------
#  This script requires only a DS4000 performance statistics file as 
#  input file. It will process all logical drives which occur in the
#  performance statistics file and does not require an additional
#  DS4000 profile. However without the configuration information from
#  the DS4000 profile no additional server or array statistics 
#  can be calculated.
# --------------------------------------------------------------------
#  This script calls and thus depends on the following additional
#  scripts which must reside in the same current working directory:
#   - xfilter.awk
#   - xtract.awk
# --------------------------------------------------------------------
#  The script should be executed in a newly created working directory 
#  containing only the script files listed above and the DS4000
#  performance statistics file.
# --------------------------------------------------------------------
#  Multiple executions of the script on different DS4000 performance
#  statistics files within the same working directory are possible, 
#  if the _SYS and _VOL directories from each run are just moved into
#  another newly created subdirectory before the next run, 
#  for example:
#  1.RUN   ./xperfvols.sh  DS4k_RZ1_perfstats.txt
#          mkdir DS4k_RZ1
#          mv _SYS _VOL DS4k_RZ1
#  2.RUN   ./xperfvols.sh  DS4k_RZ2_perfstats.txt
#          mkdir DS4k_RZ2
#          mv _??? DS4k_RZ2
# --------------------------------------------------------------------
#  The script will create additional directories called 
#    _SYS
#    _VOL
#  in the current working directory containing the individual volume
#  and system statistics. Existing directories with these file names 
#  in the current working directory will be DELETED prior to 
#  calculating the new performance statistics in order to 
#  clean up remaining files from previous script executions.
# --------------------------------------------------------------------
#  The script execution depends on the creation of some temporary 
#  files ending with .tmp. By executing this script existing files
#  with file names ending in .tmp in the current working directory
#  may be be LOST.
# --------------------------------------------------------------------
#  NOTE: This script may fail if the names of the DS4000 logical 
#  drives do contain special characters which are not suitable for
#  file names.
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

logname="$1"

PID=$$
intervaltime=""
fasttname=""

IFSOLD="${IFS}"
volsfile="vols_${PID}.tmp"
volscount=""
volsperffile="vols_in_perfstats"

VOLDIR="_VOL"
SYSDIR="_SYS"


### User functions

function myexit
{
	echo >&2
	echo ">>> $1" >&2
	echo >&2
	exit 1
}


### Check parameter count

[[ $# != 1 ]] && myexit "Usage: # xperfvols.sh [DS4000 Performance Statistics File]"
[[ ! -f "${logname}" ]] && myexit ">>> Performance Statistics File [${logname}] not found. Please check file name!"


### Start Processing Performance Log

echo "------------------------------"
echo "xperfvols.sh V3.5 (2008-03-18)"
echo "------------------------------"
echo
echo "started at $(date) on performance statistics file [${logname}]"


### Extract DS4000 Performance Statistics Header Information

fasttname=$(grep -m 1 'Performance Monitor Statistics for Storage Subsystem:' "${logname}" | cut -b 55-)
[[ "$fasttname" = "" ]] && fasttname="./."
intervaltime=$(grep -m 1 'Polling interval in seconds:' "${logname}" | cut -b 30-)
starttime=$(grep -m 1 'Date/Time:' "${logname}" | cut -b 12-)

echo
echo "DS4000 Name       : $fasttname"
echo "Date of PerfStats : $starttime"
echo "Sample Interval   : $intervaltime seconds"


### Clean up remaining Files from previous runs

rm -rf "$SYSDIR" 2>/dev/null
rm -rf "$VOLDIR" 2>/dev/null
rm -r  "$volsfile" 2>/dev/null

### Extract DS4000 Logical Volume Names and Volume Performance Data

IFS=","

count=$(grep -m 2 -n 'Capture Iteration' "${logname}" | tail -1 | cut -d ':' -f 1)

head -$count "${logname}" | grep 'Logical Drive' | sort -u -t ',' -k 1,1 | while read a rest
do 
 echo $a >> "$volsfile"
done

volscount=$(cat $volsfile | wc -l)
echo "Logical Drives    : $volscount"
echo


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

mkdir "$VOLDIR" 2>/dev/null
[[ $? != 0 ]] && myexit "ERROR: Could not create directory $VOLDIR !"
cat "$volsfile" | while read a
do
	echo "# Devices,Total,Read [%],Cache [%],Current kB/s,Maximum kB/s,Current IO/s,Maximum IO/s" > "${a}.tmp"
	grep "$a," "${logname}"  >> "${a}.tmp"
	b="$(echo $a | cut -b 15-)"
	echo "...processing data for logical drive [${b}]"
	echo "$b" >> "${SYSDIR}/${volsperffile}.vol"
	./xfilter.awk -v "intvl=${intervaltime}" "${a}.tmp" > "${VOLDIR}/${b}.dat"
	rm -f "${a}.tmp"
done

rm -r  "$volsfile" 2>/dev/null


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


### END

echo
echo "!!! Processing of DS4000 Performance Statistics completed !!!"
echo
