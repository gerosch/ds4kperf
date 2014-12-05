# README ds4kperf

## Abstract

The IBM System Storage DS3000/DS4000/DS5000 disk subsystems are capable of collecting simple I/O performance statistics over a given time period (specified by interval time and number of iterations) which provide basic I/O statistics for the Total Subsystem, Controller A, Controller B and each Logical Drive within a single output file for each interval. In order to evaluate the subsystem performance it is necessary to pre-process this performance statistics file and extract the individual statistics for each of the above components.
Furthermore there are no host / host group or array statistics provided. Especially the *array I/O statistics* are key to evaluate the actual I/O workload on a disk drive level and verify if the amount of I/O workload on a given array is saturating the disk drives (hotspot/bottleneck analysis)! However, such statistics are not provided by default and need to be calculated from the system's performance statistics file using the information provided in the system's profile. The scripts provided in this repository can help to pre-process the performance statistics file and calculate additional host and array I/O statistics if the system's profile is available.

*NOTE*: These scripts were created in a *works-fine-for-me* manner for my own use in order to address the need to evaluate the system performance of DS3k/4k/5k subsystems. They were not intended as a general purpose software solution for the public. These scripts are free to use under the GPL V3.0 license and require an advanced user who knows what he/she is doing and who claims full responsibility for the usage of the scripts and interpretation of the results. The scripts are provided for public download on requests for sharing them as some people have found them useful. The scripts are no longer actively maintained!

**THESE SCRIPTS ARE PROVIDED "AS IS" WITHOUT ANY SUPPORT OR WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. WITH USING THESE SCRIPTS YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT THE USE OF THESE SCRIPTS IS AT YOUR SOLE RISK. NEITHER THE AUTHOR NOR THE IBM CORPORATION CAN BE HELD LIABLE FOR ANY ERRORS OR OTHER CONDITIONS OF ANY KIND WHICH MIGHT ARISE FROM THE USAGE OR THE OUTPUT OF THESE SCRIPTS. THESE SCRIPTS MAY BE USED BY ANYONE AT HIS/HER OWN RISK!**

## Introduction 

The repository provides a set of Linux shell/gawk scripts which help to extract individual I/O statistics from a single DS3k/4k/5k performance statistics file. These scripts create a new set of extended statistics files for the

- Total Subsystem
- Controller A
- Controller B
- all Logical drives
- all Arrays (if the system profile is provided)
- all Hosts / Host Groups (if the system profile is provided)

However, the post-processing of these files still has to be done manually using a plotting tool like GnuPlot (Open Source) or, for example, a spreadsheet in LibreOffice Calc or Microsoft Excel. 

## Basic I/O Performance System Analysis

A basic performance analysis involves taking a look at the average and peak workloads with regard to **IOps (I/O transactions)** and **MBps (I/O bandwidth)** as well as the related **workload characteristics** like average I/O size, read:write ratio and access pattern (random/sequential) on

- Subsystem Totals level (subsystem totals - peak / average)
- Controller A and B level (balanced distribution of the workload across both controllers)
- Array level (balanced distribution of workload across all arrays / identify hot arrays)
- Volume level (identify hot / critical volumes)
- Server level (identify hot / critical server).

As these DS3k/4k/5k performance statistics do not provide any quality of service information such as I/O service times it is generally necessary to compare the monitored workloads on **subsystem** level and **array** level based on their *access pattern* with appropriate system, controller and link limits (bandwidth/MBps) and calculated estimates for the maximum number of random access I/O operations (IOps), taking into consideration:
- Manufacturer system specs regarding system, controller, and link bandwidth limitations
- Workload read:write ratios
- Array RAID level, e.g. 
	- RAID-5:  1 random write transaction = 4 backend operations (1x read old data + 1x read old parity + 1x write new data + 1x write new parity)
	- RAID-6:  1 random write transaction = 6 backend operations (1x read old data + 2x read old parity + 1x write new data + 2x write new parity)
	- RAID-10: 1 random write transaction = 2 backend operations (1x write new data + 1x write copy of new data)
- Number of disk drives (only capable of a limited amount of random I/O operations per disk): 100 random IOps per disk drive as a simple rule of thumb for enterprise class disk drives, e.g.
	- FC 15k DDM:     ~160 IOps (e.g., Speed = 15000 rpm, Rotational Latency = 2 ms, Avg. Seek Time = 4 ms)
 	- FC 10k DDM :	  ~120 IOps (e.g., Speed = 10000 rpm, Rotational Latency = 3 ms, Avg. Seek Time = 5 ms)
 	- SATA2 7.2k DDM: ~75 IOps  (e.g., Speed =  7200 rpm, Rotational Latency = 4.2 ms, Avg. Seek Time = 9 ms)

## Collecting Data For System Performance Evaluation

### Data Collection

To evaluate DS3k/4k/5k system performance you need to collect at least the following data:

1. Latest **Storage Subsystem Profile** -> as part of the 'All Support Data' zip archive (*storageSubsystemProfile.txt*)
2. Collect system **performance statistics** over time while the problem or the peak I/O workload is present with running the following SMcli script on the DS3k/4k/5k system:

```
-- perfmon.scr --
on error stop; 
set performanceMonitor interval=30 iterations=240; 
upload storageSubsystem file="c:\perfstats01.txt" content=performanceStats;
-- perfmon.scr --
```

You need to choose appropriate values for *interval=a* (seconds, 3<=a<=3600) and *iterations=b* (no. of iterations, 1<=b<=3600) depending on the overall time of the monitoring period. The above example will monitor 240 intervals of 30s giving a overall runtime of 240x30s=120min (overall runtime = a x b seconds). If you want to run it for several hours consider using a 60s or even larger interval time and an appropriate no. of iterations. 

The *performance statistics file* provides the amount of IOps processed and their distribution across the controllers and logical volumes over the time of the monitoring period. However, please bear in mind that the DS3k/4k/5k performance statistics do not provide any counters regarding the *quality of service* like, for example, I/O service times. Here OS supplied tools like *iostat* (linux/UNIX), *filemon* (AIX) or perfmon (Windows) would be required on the attached servers to provide information about average I/O response times in more complex performance situations. In addition, also a mapping of the server's logical volumes to the disk subsystem LUN names would be required.

It is also important to note, that in case of a volume failover between the two subsystem controllers or a bad IP connection from the client (that is running the perfmon.scr script) during the performance monitoring task the performance data collection will be terminated and no data is stored in the specified output file at all! 

The data collection script can easily be run either from the DS Storage Manager *Script Editor* GUI or directly from the command line with *SMcli*. In both cases the data is stored in a local file as a list of comma-separated-values (CSV).

#### Data Collection via DS Storage Manager GUI

Collecting I/O performance statistics over time can be achieved by issuing the script on the server where the DS Storage Manager is installed. By selecting the appropriate DS system in the DS Storage Manager console with the right mouse button you can open the 'Execute Script' box.

Within the 'Execute Script' box you can now issue the following script for the selected DS4000 system to initiate a performance data collection over the time that is saved to your local server as text file in 'csv' format. Please choose appropriate file names (e.g. file="c:\perfstats01.txt" for your OS) and values for 'interval' and 'iterations', e.g. interval=5 and iterations=360 meaning a data collection over 360 x 5sec = 30 min.

	---------- SCRIPT --------
	on error stop;
	set performanceMonitor interval=5 iterations=360;
	upload storageSubsystem file="c:\perfstats01.txt" content=performanceStats;
	---------- SCRIPT ---------

The script execution for the performance monitoring can be started with 'Verify and Execute' or 'Execute Only'.

If the data collection is cancelled or the IP connection to the DS subsystem is lost nothing will be stored in the local file 'perfstats01.txt'.

#### Data Collection via Command Line Interface with SMcli for Windows and AIX

Collecting DS I/O performance statistics over time can also be achieved by issuing the script on a server where the DS Storage Manager client software with the DS command line interface SMcli is installed. Here you need to go to the appropriate DS client directory and start the script from the command line using the SMcli command with option '-f' followed by the script name, here in this example 'perfmon.scr' which contains the appropriate file name for the statistics file, the interval time and no. of iterations for the intended monitoring run.

If the data collection is cancelled (by hitting CTRL-C) or the IP connection to the DS4000 is lost nothing will be stored in the local file 'perfstats01.txt'.

IMPORTANT: You have to specify the IP addresses of both DS3k/4k/5k controllers for this command otherwise the command execution will fail!

##### Windows-Example

	--- file perfmon.scr ---
	on error stop; 
	set performanceMonitor interval=5 iterations=10; 
	upload storageSubsystem file="c:\perfstats01.txt" content=performanceStats;
	--- file perfmon.scr ---

	C:\Program Files\IBM_DS4000\client>smcli [IP-Addr. Ctr.A] [IP-Addr. Ctr.B] -f perfmon.scr
	Performing syntax check...
	Syntax check complete.
	Executing script...
	Script execution complete.
	SMcli completed successfully.

##### AIX-Example

Note: The command 'SMcli' is case sensitive on AIX!

	# lslpp -l | grep SM
	SMclient.aix.rte
	SMruntime.aix.rte

	--- file perfmon.scr ---
	on error stop; 
	set performanceMonitor interval=5 iterations=10; 
	upload storageSubsystem file="/tmp/fastperf.txt" content=performanceStats;
	--- file perfmon.scr ---

	# SMcli [IP-Addr. Ctr.A] [IP-Addr. Ctr.B] -f perfmon.scr
	Performing syntax check...
	Syntax check complete.
	Executing script...
	Script execution complete.
	SMcli completed successfully.


### Obtaining the Storage Subsystem Profile

Together with the performance statistics please also take a snapshot of the current configuration and MEL of the monitored DS3k/4k/5k subsystem by collecting the *All Support Data* file: 

This All-Support-Data zip archive provides the latest DS3k/4k/5k **Storage Subsystem Profile** (*storageSubsystemProfile.txt*) which contains the configuration used during the monitoring and which is required for the pre-processing of the performance statistics and furthermore the MEL (majorEventLog.txt) which might also be useful to see if any error conditions took place during the monitoring which might severely effect I/O performance such as volume ownership transfers. The storage subsystem profile is essential for understanding the configuration of the monitored storage subsystem and identifying the placement of the logical drives in relation to the configured physical disk arrays, thus helping to identify possible disk-related *bottlenecks* or so-called *hotspots*.


## Scripts for Pre-processing the I/O Performance Data

### Data Format

The DS3k/4k/5k storage subsystem I/O performance statistics file which is collected with SMcli or Storage Manager running the 'perfmon.scr' script contains the following data:

	Performance Monitor Statistics for Storage Subsystem: DS4800_EXMPL
	Date/Time: 3/20/07 10:28:33 AM
	Polling interval in seconds: 3

	Storage Subsystems,Total,Read,Cache Hit,Current,Maximum,Current,Maximum
	,IOs,Percentage,Percentage,KB/second,KB/second,IO/second,IO/second
	Capture Iteration: 1
	Date/Time: 3/20/07 10:28:34 AM
	CONTROLLER IN SLOT A,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array1_SQL_Log,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array3_SQL_Log,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array5_SQL_Data,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array7_SQL_Data,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array9_Temp,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	CONTROLLER IN SLOT B,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array10_Temp,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array2_SQL_Log,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array4_SQL_Log,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array6_SQL_Data,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	Logical Drive Array8_SQL_Data,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	STORAGE SUBSYSTEM TOTALS,0.0,0.0,0.0,0.0,0.0,0.0,0.0,

	Capture Iteration: 2
	Date/Time: 3/20/07 10:28:37 AM
	CONTROLLER IN SLOT A,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	[...]

	Capture Iteration: 600
	Date/Time: 3/20/07 11:02:31 AM
	CONTROLLER IN SLOT A,138964.0,24.5,28.0,1.0,84163.7,2.0,2837.7,
	Logical Drive Array1_SQL_Log,20911.0,0.0,0.0,0.0,38229.3,0.0,1194.7,
	Logical Drive Array3_SQL_Log,20600.0,0.1,85.7,1.0,42198.3,2.0,1319.0,
	Logical Drive Array5_SQL_Data,50333.0,32.9,26.3,0.0,16416.0,0.0,1170.8,
	Logical Drive Array7_SQL_Data,45955.0,35.9,26.6,0.0,12914.7,0.0,1114.0,
	Logical Drive Array9_Temp,1165.0,82.6,79.6,0.0,3820.0,0.0,119.8,
	CONTROLLER IN SLOT B,140868.0,24.5,26.1,15.0,81600.3,0.8,3189.0,
	Logical Drive Array10_Temp,1275.0,51.8,91.1,15.0,4209.3,0.8,187.0,
	Logical Drive Array2_SQL_Log,20898.0,0.0,0.0,0.0,38229.3,0.0,1194.7,
	Logical Drive Array4_SQL_Log,20493.0,0.0,100.0,0.0,32896.3,0.0,1028.3,
	Logical Drive Array6_SQL_Data,48075.0,34.7,26.0,0.0,18389.3,0.0,1408.7,
	Logical Drive Array8_SQL_Data,50127.0,34.2,23.7,0.0,19136.0,0.0,1649.7,
	STORAGE SUBSYSTEM TOTALS,279832.0,24.5,27.1,16.0,148011.3,2.8,5992.3,

Here the performance statistics for the subsystem totals, both controllers and all logical drives are given in a comma separated list for each measurement interval containing 7 essential I/O statistics columns:

- Total IOs (number of processed IOs since start of data collection) 
- Read Percentage (read percentage of all processed Total IOs)
- Cache Hit Percentage (read cache hit percentage of all processed read IOs)
- Current kB/second (current kB/s for current measurement interval)
- Maximum kB/second (maximum kB/s seen since start of data collection)
- Current IO/second (current IO/s for current measurement interval) 
- Maximum IO/second (maximum IO/s seen since start of data collection)

To allow a simple analysis of these statistics the performance statistics file has to be pre-processed in order to obtain individual statistics for
- Total Storage Subsystem 
- Controller A 
- Controller B 
- All Logical drives 
- All Arrays 
- All Hosts / Host Groups
in separate files which then can be further processed or plotted either by using GnuPlot or, for example, in a spreadsheet.

*Please note*: The *Read Percentage* and the (Read) *Cache Hit Percentage* provided by these native DS3k/4k/5k performance statistics refer to the total number of I/Os (*Total IOs*) which have been processed during the *whole* measurement period so far (i.e. from the *start* of the performance data collection to the current measurement interval). They do *not* solely refer to the current measurement interval. In order to evaluate the *read percentage* and *read cache hit* percentage for the I/O rate of the current measurement interval you need to manually calculate these values from the change in Total Read IOs (= Total IOs x Read Percentage) and Total Read Cache Hits (= Total IOs x Read Percentage x Cache Hit Percentage) derived from the Total IOs counter of the previous and the current interval. Due to the limited decimals for these percentages (only one decimal is available, e.g. XX.Y%) the calculation will lack accuracy with a growing number of Total IOs, which means especially for the last measurement intervals in long time measurements. If the change of Total IOs during a measurement interval becomes less than 0.1% it is not possible to correctly calculate the read and read cache hit percentage for this interval anymore.

### Pre-processing Scripts

The set of Linux bash / gawk scripts which is provided here may help to pre-process the DS system's performance statistics output file and 
- Extract the I/O data for each logical volume, array, host or host group, both controllers and total subsystem
- Calculate avg. I/O size, current read percentage and current read hit ratio columns for each interval (the rough current read and cache hit ratios are derived from the change of the Total IOs statistics of the current and the previous total IOs read / read cache hits statistics) 
- Extract the last measurement interval providing a final summary of all processed IOs, the overall read and read cache hit ratio as well as peak IOps and MBps information for each logical drive.

These scripts will extract the appropriate data columns from the DS3k/4k/5k performance statistics file providing individual files with tabulator separated I/O values of the following scheme:

	# Time [s] Total IOs Read [%] Cache Hit cur. kB/s max. kB/s cur. IO/s max. IO/s c.IOsize c.Read [%] c.CacheHit
	3 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
	6 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
	9 24.0 100.0 79.2 245.3 245.3 8.0 8.0 30.7 100.0 79.2
	12 52.0 46.2 79.2 130.0 245.3 7.0 8.0 18.6 0.0 0.0
	15 55.0 43.6 79.2 8.0 245.3 1.0 8.0 8.0 0.0 0.0
	18 55.0 43.6 79.2 0.0 245.3 0.0 8.0 0.0 0.0 0.0
	21 63.0 50.8 84.4 64.0 245.3 2.0 8.0 32.0 100.0 99.9
	24 63.0 50.8 84.4 0.0 245.3 0.0 8.0 0.0 0.0 0.0
	27 63.0 50.8 84.4 0.0 245.3 0.0 8.0 0.0 0.0 0.0
	30 63.0 50.8 84.4 0.0 245.3 0.0 8.0 0.0 0.0 0.0
	33 63.0 50.8 84.4 0.0 245.3 0.0 8.0 0.0 0.0 0.0
	36 131.0 76.3 93.0 544.0 544.0 17.0 17.0 32.0 99.9 97.1
	39 692.0 54.9 96.8 4209.3 4209.3 187.0 187.0 22.5 49.9 98.2
	42 736.0 57.6 92.2 469.3 4209.3 14.7 187.0 31.9 100.0 52.5
	[...]
	1800 1275.0 51.8 91.1 15.0 4209.3 0.8 187.0 18.8 0.0 0.0

	### Total Runtime : 1800 [s] ( 97.2 percent idle time )
	### Total IO/s : 0.6 [IO/s]
	### Average IO/s : 0.7 [IO/s]
	### Average kB/s : 19.1 [kB/s]
	### Avg. IO Size : 27.0 [kB]

Note, the additional statistics at the end of each performance file represent:
- Total Runtime: overall runtime of the performance data collection 
- Total IO/s: average total IOps rate is calculated from the total number of processed IOs and the overall runtime 
- Average IO/s: average IOps rate is calculated from non-idle measurement intervals only (intervals with no I/O activity are skipped) 
- Average kB/s: average kBps rate is calculated from non-idle measurement intervals only (intervals with no I/O activity are skipped) 
- Avg. IO Size: average IO size is calculated as an IO weighted average


### Script Requirements

Before you start processing the performance statistics please check the following requirements:

1) Use an *US / english* installation of a Linux system for executing the scripts otherwise the decimal separator which is a '.' (period) might not be interpreted correctly which will lead to wrong calculations!

2) Check that the collected DS4000 performance statistics file is *properly formatted with seven data values per line*, separated by commas and a period used as decimal separator (CSV format).

*Correct format: (7 data values of format XY.Z per line separated by commas)*

	STORAGE SUBSYSTEM TOTALS,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
	STORAGE SUBSYSTEM TOTALS,[TOTAL IOs],[Read Percentage],[Cache Hit Percentage],[cur.kBps],[max.kBps],[cur.IOps],[max.IOps],

*Incorrect formats:*

	(a) 
	wrong:   CONTROLLER IN SLOT A,107429,0,59,0,37,6,23724,8,23724,8,1852,2,1852,2,
	correct: CONTROLLER IN SLOT A,107429.0,59.0,37.6,23724.8,23724.8,1852.2,1852.2,

	(b)
	wrong:   CONTROLLER IN SLOT A,2,533.0,97.8,15.1,8,252.7,8,252.7,422.2,422.2,
	correct: CONTROLLER IN SLOT A,2533.0,97.8,15.1,8252.7,8252.7,422.2,422.2,

If the formatting is not correct as seen in example (a) or (b) you need to pre-process the DS4000 performance statistics file before it can be used with the scripts.

In *example (a)* you see a DS4000 performance statistics file with 14 data values per line separated by commas. Here obviously commas are used not only as separator for the individual data values but also as decimal separator which makes it hard to identify and separate the seven original data columns correctly (...,1234,5,...=...,1234.5,...). Such DS4000 performance statistic files might result, for example, from German locale settings on a Windows based OS host that was collecting the performance data, resulting in comma separated values with commas also used as decimal separator. Here you can use the following script 'xconv.awk' to obtain a properly formatted DS4000 performance statistics file:

```
# ./xconv.awk perfstat_wrong.csv > perfstat_right.dat
```

In *example (b)* you see a DS4000 performance statistics file with a variable number of data values per line separated by commas. Here obviously the period is correctly used as decimal separator but in this case commas are also used as additional separator for the THOUSANDS and MILLIONS of each data value which makes it hard to identify and separate the seven original data columns correctly (...,1,234,567.0,... = ...,1234567.0,...). Such DS4000 performance statistic files might also result from specific locale settings on a Windows based OS host that was collecting the performance data. Here you can use the following script 'xconv2.awk' to obtain a properly formatted DS4000 performance statistics file:

```
# ./xconv2.awk perfstat_wrong.csv > perfstat_right.dat
```

3) These scripts should work fine with DS4000 performance statistics collected with DS4000 firmware levels >= 6.1. However, starting with DS3k/4k/5k firmware levels 7.10 and above the output of the performance data collection changed to a new format where all data values are additionally enclosed by quotation marks:

	"Performance Monitor Statistics for Storage Subsystem: DS4700_PFE1 - Date/Time: 12.02.08 10:29:13 - Polling interval in seconds: 20"

	"Storage Subsystems ","Total IOs ","Read Percentage ","Cache Hit Percentage ","Current KB/second ","Maximum KB/second ","Current IO/second ","Maximum IO/second"

	"Capture Iteration: 1","","","","","","",""
	"Date/Time: 12.02.08 10:29:14","","","","","","",""
	"CONTROLLER IN SLOT A","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Logical Drive Data_1","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Logical Drive Data_3","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Logical Drive Data_5","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Logical Drive Data_7","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"CONTROLLER IN SLOT B","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Logical Drive Data_2","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Logical Drive Data_4","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Logical Drive Data_6","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Logical Drive Data_8","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"STORAGE SUBSYSTEM TOTALS","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	"Capture Iteration: 2","","","","","","",""
	"Date/Time: 12.02.08 10:29:35","","","","","","",""
	"CONTROLLER IN SLOT A","0.0","0.0","0.0","0.0","0.0","0.0","0.0"
	[...]

As values surrounded by quotation marks are often interpreted as character strings and not as numbers in data processing tools, it can be convenient to convert the data into a regular format *first*. The awk script (```xconv3.awk```) below will remove the quotation marks and convert the file into a regular DS version V6.1 CSV format file:

	#! /usr/bin/gawk -f
	BEGIN {}
	{ gsub("\"", ""); gsub(" - ", "\n"); }
	{ gsub(",,,,,,,", ""); }
	/CONTROLLER IN SLOT/ { print $0 ","; next; }
	/STORAGE SUBSYSTEM TOTALS/ { print $0 ","; next; }
	/Logical Drive/ { print $0 ","; next; }
	{ print $0; }
	END {}

Invoked with the following command line (e.g. on a Linux system with gawk installed)

```
# ./xconv3.awk perfstats_new_CSV.csv > perfstats_regular_CSV.csv
```

the script will just convert the 'perfstats_new_CSV.csv' file with quotation marks around each value into the regular formatted DS subsystem V6.1 CSV file 'perfstats_regular_CSV.csv'. Be aware, that this may not be a good idea if the number format itself contains commas due to local regional settings (e.g. "1,000,000.0" or "1000,0"). In this case you should better adapt the script and probably use a tabulator instead of a comma as separator for the individual data values. However, the other scripts depend on the regular structure with commas and no additional quotation marks.

**Note**: This step is necessary in order to be able to use the other scripts provided in this repository!


4) Make sure that you make all the scripts in this set executable before actually starting to process a DS4000 performance statistics file:

```
# chmod u+x *.sh *.awk
```

5) The names of the DS subsystem *logical drives* and *host / host groups* should be suitable to be used as Linux file names. Otherwise the script execution and proper data processing may fail.


### Script Usage

The available scripts for processing the DS subsystem performance statistics file are:

- **xperf.sh**: which is the main script processing the DS4000 profile and performance statistics file. It creates individual files with tabulator separated values for 
	- each logical drive 
	- each array 
	- each host / host group 
	- CONTROLLER IN SLOT A 
	- CONTROLLER IN SLOT B 
	- STORAGE SUBSYSTEM TOTALS 
	- SUMMARY

This main script also invokes (and thus depends on) the scripts below to calculate the particular statistics:

- **xfilter.awk**: creates logical drive statistics: simply extracts the correct data columns from a DS4000 performance statistics file and additionally tries to calculate the columns 'c. IOsize' (current kB/s : current IO/s), 'c. Read [%]' (current read percentage) and 'c. cache Hit' (current read hit percentage) writing a list of tabulator separated values 
- **xtract.awk**: used for the summary statistics: simply extracts the correct data columns from the last interval of a DS4000 performance statistics file without any additional calculations writing a list of tabulator separated values 
- **xarray.awk**: extracts volume and array information from DS4000 profile 
- **xserver.awk**: extracts volume and server information from DS4000 profile 
- **xsumary.awk**: calculates array statistics from DS4000 performance statistics 
- **xsumsrv.awk**: calculates server statistics from DS4000 performance statistics

For general processing of a DS3k/4k/5k performance statistics file simply follow these steps:

1) Put a copy of the original performance statistics file, the DS3k/4k/5k profile and all the scripts into a newly created local directory. 

2) Enter the newly created directory so it becomes the current working directory. 

3) Make all these script executable using the chmod command:

	# chmod u+x *.sh *.awk

4) Issue the following shell command to clean the EOL settings (CR/LF) if the performance data was collected on Windows systems:

	# dos2unix [DS4000 Performance Statistics File]
	
5) To finally start pre-processing of the performance statistics file just issue the following command:

	# ./xperf.sh [DS4000-Profile] [DS4000 Performance Statistics File]

The **xperf.sh** script requires a **DS system profile** and a **DS performance statistics** file as input. The DS profile needs to meet the current configuration that was used during the performance data collection otherwise **only** the volumes which are present in the DS system profile are extracted from the performance statistics file and used for calculating the additional array and server statistics.

If you do not have the system profile which represents the exact volume configuration during the performance measurement consider to use the **xperfvols.sh** script instead which extracts all volumes from the performance statistics file *without* calculating advanced *array* and *server* statistics based on the DS system configuration.

Without a DS4000 profile the following script will generate subsystem total, controller and logical drive statistics only:

	# ./xperfvols.sh [DS4000 Performance Statistics File]

However, without the DS system profile there is no information available to calculate array or host / host group statistics.

The **xperf.sh** script will create additional directories called 
- **_ARY** -> Array Statistics
- **_SRV** -> Host / Host Group Statistics
- **_SYS** -> Controller / System Totals Statistics
- **_VOL** -> Logical Drive Statistics
in the current working directory containing the individual array, volume, server and system statistics. Existing directories with these file names in the current working directory will be DELETED prior to calculating the new performance statistics in order to clean up remaining files from previous script executions.

The script execution depends also on the creation of some temporary files ending with .tmp and some additional working files which contain the volume information with regard to the servers and arrays which are named *array_XY.ary* and *host_hostname.srv*. By executing this script existing files with names ending in
- .tmp
- .ary
- .srv 
in the current working directory may be be LOST.

**Note**: These scripts may fail if the names of the DS4000 logical drives or the hosts / host groups do contain special characters which are not suitable for file names!

Multiple executions of the script on different DS4000 performance statistics files and appropriate DS4000 profiles within the same working directory are possible, if the _ARY, _SRV, _SYS and _VOL directories from each run are just moved into another newly created subdirectory before the next run, for example:

	# 1.RUN ./xperf.sh DS4k_RZ1_profile.txt DS4k_RZ1_perfstats.txt
	# mkdir DS4k_RZ1
	# mv _ARY _SRV _SYS _VOL DS4k_RZ1

	# 2.RUN ./xperf.sh DS4k_RZ2_profile.txt DS4k_RZ2_perfstats.txt
	# mkdir DS4k_RZ2
	# mv _??? DS4k_RZ2


#### Example of a shell session running xperf.sh

1) Create new working directory with scripts, DS3k/4k/5k performance statistics and system profile:

	[me@localhost TEST33b04]# ll
	-rw-r--r-- 1 me me 3914160 Jun 5 10:09 DS4800_perfstats.txt
	-rw-r--r-- 1 me me 352109 Jun 5 10:09 DS4800_profile.txt
	-rwxr-xr-x 1 me me 3136 May 31 12:00 xarray.awk
	-rwxr-xr-x 1 me me 3410 May 31 12:00 xconv.awk
	-rwxr-xr-x 1 me me 5365 May 31 12:00 xfilter.awk
	-rwxr-xr-x 1 me me 12349 May 31 12:00 xperf.sh
	-rwxr-xr-x 1 me me 8525 May 31 12:00 xperfvols.sh
	-rwxr-xr-x 1 me me 3316 May 31 12:00 xserver.awk
	-rwxr-xr-x 1 me me 6421 May 31 12:00 xsumary.awk
	-rwxr-xr-x 1 me me 6623 May 31 12:00 xsumsrv.awk
	-rwxr-xr-x 1 me me 3138 May 31 12:00 xtract.awk

2) Run DS3k/4k/5k performance statistics file through **dos2unix** command (if collected on Windows):

	[me@localhost TEST33b04]# dos2unix DS4800_perfstats.txt
	dos2unix: converting file DS4800_perfstats.txt to UNIX format ...

	[me@localhost TEST33b04]# ll
	-rw-r--r-- 1 me me 3796074 Jun 5 10:09 DS4800_perfstats.txt
	-rw-r--r-- 1 me me 352109 Jun 5 10:09 DS4800_profile.txt
	-rwxr-xr-x 1 me me 3136 May 31 12:00 xarray.awk
	-rwxr-xr-x 1 me me 3410 May 31 12:00 xconv.awk
	-rwxr-xr-x 1 me me 5365 May 31 12:00 xfilter.awk
	-rwxr-xr-x 1 me me 12349 May 31 12:00 xperf.sh
	-rwxr-xr-x 1 me me 8525 May 31 12:00 xperfvols.sh
	-rwxr-xr-x 1 me me 3316 May 31 12:00 xserver.awk
	-rwxr-xr-x 1 me me 6421 May 31 12:00 xsumary.awk
	-rwxr-xr-x 1 me me 6623 May 31 12:00 xsumsrv.awk
	-rwxr-xr-x 1 me me 3138 May 31 12:00 xtract.awk

3) Start processing of DS3k/4k/5k performance statistics file using **xperf.sh** script:

	[me@localhost TEST33b04]# ./xperf.sh DS4800_profile.txt DS4800_perfstats.txt

	--------------------------
	xperf.sh V3.3 (2007-05-31)
	--------------------------

	Started at Tue Jun 5 10:10:11 CEST 2007
	on performance statistics file [DS4800_perfstats.txt]
	with subsystem profile [DS4800_profile.txt].

	DS4000 Name : DS4800_RZ3
	Date of PerfStats : 24.05.07 20:03:06
	Sample Interval : 30 seconds

	### Array 5 - (RAID 1)
	### Array 6 - (RAID 1)
	### Array 7 - (RAID 5)
	### Array 1 - (RAID 5)
	### Array 2 - (RAID 5)
	### Array 3 - (RAID 5)
	### Array 4 - (RAID 5)
	### Array 8 - (RAID 5)
	### Array 9 - (RAID 5)

	=> 9 arrays found with 78 logical drives

	### SERVER n00_n01
	### SERVER n02_n03
	### SERVER n04_n05
	### SERVER n06_n07

	=> 4 servers found with 78 assigned logical drives

	...processing data for STORAGE SUBSYSTEM TOTALS
	...processing data for CONTROLLER IN SLOT A
	...processing data for CONTROLLER IN SLOT B
	...processing data for array 1 and logical drive [BW_DX1_A]
	...processing data for array 1 and logical drive [BW_DX1_B]
	[...]
	...processing data for array 9 and logical drive [WORK_n00_A]
	...processing data for array 9 and logical drive [WORK_n00_B]
	...calculating totals for array 1 on array_1.ary
	[...]
	...calculating totals for array 9 on array_9.ary
	...calculating totals for server n00_n01 on host_n00_n01.srv
	[...]
	...calculating totals for server n06_n07 on host_n06_n07.srv
	...processing last capture iteration for summary: Interval No. 720

	### SUMMARY: logical drives
	=> 78 logical drives processed as found in DS4000 profile (for list see <vols_in_profile.vol>)
	=> 78 logical drives found in DS4000 performance statistics file (for list see <vols_in_perfstats.vol>)

	!!! Processing of DS4000 Performance Statistics completed !!!

4) Results can be found in the following directories _ARY, _SRV, _SYS, _VOL:

	[me@localhost TEST33b04]# ll
	drwxr-xr-x 2 me me 4096 Jun 5 10:10 _ARY
	drwxr-xr-x 2 me me 4096 Jun 5 10:10 _SRV
	drwxr-xr-x 2 me me 4096 Jun 5 10:10 _SYS
	drwxr-xr-x 2 me me 4096 Jun 5 10:10 _VOL
	-rw-r--r-- 1 me me 3796074 Jun 5 10:09 DS4800_perfstats.txt
	-rw-r--r-- 1 me me 352109 Jun 5 10:09 DS4800_profile.txt
	-rwxr-xr-x 1 me me 3136 May 31 12:00 xarray.awk
	-rwxr-xr-x 1 me me 3410 May 31 12:00 xconv.awk
	-rwxr-xr-x 1 me me 5365 May 31 12:00 xfilter.awk
	-rwxr-xr-x 1 me me 12349 May 31 12:00 xperf.sh
	-rwxr-xr-x 1 me me 8525 May 31 12:00 xperfvols.sh
	-rwxr-xr-x 1 me me 3316 May 31 12:00 xserver.awk
	-rwxr-xr-x 1 me me 6421 May 31 12:00 xsumary.awk
	-rwxr-xr-x 1 me me 6623 May 31 12:00 xsumsrv.awk
	-rwxr-xr-x 1 me me 3138 May 31 12:00 xtract.awk

	[me@localhost TEST33b04]# ll _ARY/
	-rw-r--r-- 1 me me 73 Jun 5 10:10 array_1.ary
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 array_1.dat
	[...]
	-rw-r--r-- 1 me me 107 Jun 5 10:10 array_9.ary
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 array_9.dat

	[me@localhost TEST33b04]# ll _SRV/
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 host_n00_n01.dat
	-rw-r--r-- 1 me me 413 Jun 5 10:10 host_n00_n01.srv
	[...]
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 host_n06_n07.dat
	-rw-r--r-- 1 me me 113 Jun 5 10:10 host_n06_n07.srv

	[me@localhost TEST33b04]# ll _SYS/
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 CONTROLLER IN SLOT A.dat
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 CONTROLLER IN SLOT B.dat
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 STORAGE SUBSYSTEM TOTALS.dat
	-rw-r--r-- 1 me me 7332 Jun 5 10:10 SUMMARY.dat
	-rw-r--r-- 1 me me 818 Jun 5 10:10 vols_in_perfstats.vol
	-rw-r--r-- 1 me me 818 Jun 5 10:10 vols_in_profile.vol

	[me@localhost TEST33b04]# ll _VOL/
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 1_BW_DX1_A.dat
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 1_BW_DX1_B.dat
	[...]
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 9_WORK_n00_A.dat
	-rw-r--r-- 1 me me 87455 Jun 5 10:10 9_WORK_n00_B.dat

#### Example of a shell session running xperfvols.sh

1) Create new working directory with scripts and DS3k/4k/5k performance statistics:

	[me@localhost TEST33b04]# ll
	-rw-r--r-- 1 me me 3914160 Jun 5 10:09 DS4800_perfstats.txt
	-rwxr-xr-x 1 me me 3136 May 31 12:00 xarray.awk
	-rwxr-xr-x 1 me me 3410 May 31 12:00 xconv.awk
	-rwxr-xr-x 1 me me 5365 May 31 12:00 xfilter.awk
	-rwxr-xr-x 1 me me 12349 May 31 12:00 xperf.sh
	-rwxr-xr-x 1 me me 8525 May 31 12:00 xperfvols.sh
	-rwxr-xr-x 1 me me 3316 May 31 12:00 xserver.awk
	-rwxr-xr-x 1 me me 6421 May 31 12:00 xsumary.awk
	-rwxr-xr-x 1 me me 6623 May 31 12:00 xsumsrv.awk
	-rwxr-xr-x 1 me me 3138 May 31 12:00 xtract.awk

2) Run DS4000 performance statistics file through dos2unix command (if file was collected on Windows):

	[me@localhost TEST33b04]# dos2unix DS4800_perfstats.txt
	dos2unix: converting file DS4800_perfstats.txt to UNIX format ...

	[me@localhost TEST33b04]# ll
	-rw-r--r-- 1 me me 3796074 Jun 5 10:09 DS4800_perfstats.txt
	-rwxr-xr-x 1 me me 3136 May 31 12:00 xarray.awk
	-rwxr-xr-x 1 me me 3410 May 31 12:00 xconv.awk
	-rwxr-xr-x 1 me me 5365 May 31 12:00 xfilter.awk
	-rwxr-xr-x 1 me me 12349 May 31 12:00 xperf.sh
	-rwxr-xr-x 1 me me 8525 May 31 12:00 xperfvols.sh
	-rwxr-xr-x 1 me me 3316 May 31 12:00 xserver.awk
	-rwxr-xr-x 1 me me 6421 May 31 12:00 xsumary.awk
	-rwxr-xr-x 1 me me 6623 May 31 12:00 xsumsrv.awk
	-rwxr-xr-x 1 me me 3138 May 31 12:00 xtract.awk

3) Start processing of DS3k/4k/DS5k performance statistics file using xperfvols.sh script:

	[me@localhost TEST33b04]# ./xperfvols.sh DS4800_perfstats.txt

	------------------------------
	xperfvols.sh V3.3 (2007-05-31)
	------------------------------

	started at Tue Jun 5 10:14:36 CEST 2007 on performance statistics file [DS4800_perfstats.txt]

	DS4000 Name : DS4800_RZ3
	Date of PerfStats : 24.05.07 20:03:06
	Sample Interval : 30 seconds
	Logical Drives : 78

	...processing data for STORAGE SUBSYSTEM TOTALS
	...processing data for CONTROLLER IN SLOT A
	...processing data for CONTROLLER IN SLOT B
	...processing data for logical drive [ADSMDB_A]
	...processing data for logical drive [ADSMDB_B]
	[...]
	...processing data for logical drive [WORK_n01_A]
	...processing data for logical drive [WORK_n01_B]
	...processing last capture iteration for summary: Interval No. 720

	!!! Processing of DS4000 Performance Statistics completed !!!

	4. Results can be found in the following directories _SYS and _VOL:

	[me@localhost TEST33b04]# ll
	drwxr-xr-x 2 me me 4096 Jun 5 10:14 _SYS
	drwxr-xr-x 2 me me 4096 Jun 5 10:14 _VOL
	-rw-r--r-- 1 me me 3796074 Jun 5 10:09 DS4800_perfstats.txt
	-rwxr-xr-x 1 me me 3136 May 31 12:00 xarray.awk
	-rwxr-xr-x 1 me me 3410 May 31 12:00 xconv.awk
	-rwxr-xr-x 1 me me 5365 May 31 12:00 xfilter.awk
	-rwxr-xr-x 1 me me 12349 May 31 12:00 xperf.sh
	-rwxr-xr-x 1 me me 8525 May 31 12:00 xperfvols.sh
	-rwxr-xr-x 1 me me 3316 May 31 12:00 xserver.awk
	-rwxr-xr-x 1 me me 6421 May 31 12:00 xsumary.awk
	-rwxr-xr-x 1 me me 6623 May 31 12:00 xsumsrv.awk
	-rwxr-xr-x 1 me me 3138 May 31 12:00 xtract.awk

	[me@localhost TEST33b04]# ll _SYS/
	-rw-r--r-- 1 me me 87455 Jun 5 10:14 CONTROLLER IN SLOT A.dat
	-rw-r--r-- 1 me me 87455 Jun 5 10:14 CONTROLLER IN SLOT B.dat
	-rw-r--r-- 1 me me 87455 Jun 5 10:14 STORAGE SUBSYSTEM TOTALS.dat
	-rw-r--r-- 1 me me 7332 Jun 5 10:14 SUMMARY.dat
	-rw-r--r-- 1 me me 818 Jun 5 10:14 vols_in_perfstats.vol

	[me@localhost TEST33b04]# ll _VOL/
	-rw-r--r-- 1 me me 87455 Jun 5 10:14 ADSMDB_A.dat
	-rw-r--r-- 1 me me 87455 Jun 5 10:14 ADSMDB_B.dat
	[...]
	-rw-r--r-- 1 me me 87455 Jun 5 10:14 WORK_n01_A.dat
	-rw-r--r-- 1 me me 87455 Jun 5 10:14 WORK_n01_B.dat


### Script Results

The **xperf.sh** script will create the following directories in the current working directory:

- _ARY -> Array Statistics
- _SRV -> Host / Host Group Statistics
- _SYS -> Controller / System Totals Statistics
- _VOL -> Logical Drive Statistics

which contain the individual array, volume, server and system statistics. 

After processing the DS3k/4k/5k performance statistics file with **xperf.sh** you obtain
- an I/O statistics file for each logical drive (all data columns versus time in seconds) with filename *XX_LogicalDrive.dat* (in _VOL/) where XX represents the array number 
- an I/O statistics file for each array with filename *array_XX.ary* (in _ARY/) 
- an I/O statistics file for each server group or server with filename *host_hostname.dat* (in _SRV/) 
- an I/O statistics file for STORAGE SUBSYSTEM TOTALS with filename *STORAGE SUBSYSTEM TOTALS.dat* (in _SYS/) 
- an I/O statistics file for CONTROLLER IN SLOT A with filename *CONTROLLER IN SLOT A.dat* (in _SYS/) 
- an I/O statistics file for CONTROLLER IN SLOT B with filename *CONTROLLER IN SLOT B.dat* (in _SYS/) 
- an overall I/O statistics SUMMARY file with all volumes, providing the no. of total IOs, the total avg. Read Percentage, the total avg. Read Hit Ratio and the maximum IOps and maximum kBps values for all logical drives over the whole measurement time period (simply the data from the last measurement interval) with filename *SUMMARY.dat* (in _SYS/)

First you would start taking an initial look at the subsystem total statistics and the *SUMMARY.dat* file to get an idea of the subsystem's overall utilization and I/O workload as well as identifying the busiest volumes. However, as most I/O performance problems are related to saturated disk arrays and hot spots the probably most important view when investigating in performance problems is the average and maximum *IOps rate per array** because here we have the essential correlation between physical disk drives (which are only capable of a limited number of random I/O operations per second with reasonable I/O response times) and the IOps workload! Also check that the workload is evenly balanced across the arrays and both subsystem controllers. Consider redistributing busy volumes from hot arrays to less utilized arrays. If the random IOps workload shows a considerably amount of writes (>>30%) even a RAID10 might be worth considering instead of a RAID5 due to the RAID5 write penalty (which involves four disk operation for one random write operation) if the number of disks stays unchanged.

Using tools like GnuPlot, for example, you can easily and quickly create a variety of charts for data visualization and exploration in order to evaluate the overall system performance.

## Version History

- V3.5 - 2008-09-24: added xconv3.awk to format perf stats from DS4000 with firmware level >= V7.1, minor bug fixes, e.g. logical drive names with similar base names but non-letter extensions were mixed up, e.g. basename005, basename005-1, basename005-R1
- V3.4 - 2007-07-04: included additional 'xconv2.awk' script to convert improper formatted DS4000 performance statistics files with data values showing comma separated THOUSANDS and MILLIONS
- V3.3 - 2007-05-31: initial release of the scripts, improvements, bugs fixed, added 'xperfvols.sh' for analysis of statistics files without a DS4000 profile available

## LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

## DISCLAIMER OF WARRANTY

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
  APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
  HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
  OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
  IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
  ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

## LIMITATION OF LIABILITY

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
  WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
  THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
  GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
  USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
  DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
  PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
  EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGES.

## TRADEMARKS

The following terms are trademarks of the International Business Machines Corporation in the United States and/or other countries:

AIX, IBM, IBM Logo, pSeries, RS/6000, xSeries, zSeries, DS4000, System Storage

For a complete list of IBM Trademarks, see www.ibm.com/legal/copytrade.shtml

The following are trademarks or registered trademarks of other companies:

LINUX is a registered trademark of Linux Torvalds
UNIX is a registered trademark of The Open Group in the United States and other countries.
Microsoft, Excel, Windows and Windows NT are registered trademarks of Microsoft Corporation.

Other company product and service names may be trademarks or service marks of their respective owners.

