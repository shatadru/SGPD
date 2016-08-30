# SGPD
Script to Gather Prformance Data

Run the script as :
  ~~~
  # bash perf2.sh 1 300
                  ^  ^
                  |  |
       Interval----  |
                     -----Number of iterations (300 X 1 sec = 5 mins )
  ~~~
  ** Please note that the script needs to be run only when you are facing the issue.

By default the script will run in interval of 2 seconds and 30 times.

This script can be stopped using ctrl+c and still will capture the data.

This will collect data like sar, vmstat, iostat, iotop, ps, top and create a tarball inside current directory which can be helpful finding out reason of high CPU/Memory usage, high load average, high iowait.

This script is tested to work in RHEL/CentOS 5,6,7 and Fedora 23,24. You should have tools like systat, iotop installed for the script to work.

Tools such as collectl are available which does this better, however it was created keeping simplycity in mind.

It does not capture huge ammount of data like collectl and much easier to use.

It is licencesed under GNU Public Licence version 3, refer LICENSE.txt
