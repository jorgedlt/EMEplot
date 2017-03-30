#!/bin/bash

#. EMEplot - a script to plot out the EME.

[ $# -lt 1 ] && { cat $0 | grep "^#\." ; exit 1; } || :

ActiveLOG=$(sudo lsof | grep eme.log | awk '{print $9}' | sort | uniq | head -$3 | tail -1)
#ActiveLOG=/Users/jdelatorre/work/CNNgo/livegear10/job_57/20140829T223605_eme.log

# OS Type Login

  if [[ "$OSTYPE" == "linux-gnu" ]]; then
          datebin='/bin/date'
  elif [[ "$OSTYPE" == "darwin"* ]]; then
          datebin='/usr/local/bin/gdate'
  else
          echo "Unsupported Platform"; exit 2;
  fi

sHOUR=${1:-6}  # Start Hour  -- default 6 hours ago
eHOUR=${2:-0}  # End Hour    -- default 0 hours ago (now)

echo "$(hostname) -- Active Log : $ActiveLOG"
echo "Report Time [ $( ${datebin} | ${datebin} +"%Y-%m-%d %H:00" -d -${sHOUR}hours ) ] \
-- [ $( ${datebin} | ${datebin} +"%Y-%m-%d %H:00" -d -${eHOUR}hours ) ] UTC"

echo "lc  utctime             raw      scte     sdi      disc     recv     c56M     cCOP     cAKA    lvoX     DNSf     PrbX     fdrp"

for k in $(eval echo {${sHOUR}..${eHOUR}}); do

i=$( ${datebin} -d -${k}hours +"%Y-%m-%d.%H" )
j=$( ${datebin} -d -${k}hours +"%Y-%m-%dT%H:00" )

loctim=$( TZ=DST+4 ${datebin} -d "$(echo ${i} | tr '.' ' '):00:00-0000" +"%Y-%m-%d %H" | cut -d' ' -f2)

#
   rLOG=$(grep "${i}" "$ActiveLOG" | wc -l)
   SCTE=$(grep "${i}" "$ActiveLOG" | grep -i SCTE | wc -l)
   Hsdi=$(grep "${i}" "$ActiveLOG" | grep -i HD-SDI.Input.Not.Detected | wc -l)
   disc=$(grep "${i}" "$ActiveLOG" | grep -i discontinuity | wc -l)
   recv=$(grep "${i}" "$ActiveLOG" | grep -i recovered | wc -l)

   #seta=$(grep "${i}" "$ActiveLOG" | grep -i setting.alert | wc -l)

   clr5=$(grep "${i}" "$ActiveLOG" | grep -i clearing.alert | grep -i 56m | wc -l)
   clrc=$(grep "${i}" "$ActiveLOG" | grep -i clearing.alert | grep -i cop | wc -l)
   clra=$(grep "${i}" "$ActiveLOG" | grep -i clearing.alert | grep -i aka | wc -l)

   urlx=$(grep "${i}" "$ActiveLOG" | grep -i Unable.to.deliver.content.for.URL | wc -l)
   dnsf=$(grep "${i}" "$ActiveLOG" | grep -i Couldn.t.resolve.host.name | wc -l)

   prob=$(grep "${i}" "$ActiveLOG" | grep -i Probe.info.for.input | wc -l)

   fDRP=$(grep "${i}" "$ActiveLOG" | grep -i frames.dropped | wc -l)

  #[ $disc -gt 0 ] && disc=$(echo "$(tput setaf 1)${disc}$(tput sgr0)" | tr -d ' ') || :

  echo -en "$loctim $j"; printf "   : %-8d %-8d %-8d %-8d %-8d %-8d %-8d %-8d %-8d %-8d %-8d %-8d\n" $rLOG $SCTE $Hsdi $disc $recv $clr5 $clrc $clra $urlx $dnsf $prob $fDRP
done

echo -en "\n===[ last 4 found ]=============================\n"
grep "${i}" "$ActiveLOG" | egrep -i 'D-SDI.Input.Not.Detected|Unable.to.deliver.content.for.URL|Couldn.t.resolve.host.name|discontinuity|recovered|.alert|frames.dropped' | tail -6

# sshpass -p "elemental" scp -rp work/emeplot/EMEplot.lvo   elemental@livecertve8:scripts/EMEplot.lvo

#.
#. USAGE : EMEplot ## .... where ## = number-of-hours
#.
#. raw     Raw Logs Lines
#. scte    SCTE Any Kind
#. sdi     HD-SDI.Input.Not.Detected
#. disc    discontinuity errors, LWS related, generally serious
#. recv    recovered (from Error)
#.
#. clra    clearing.alert  -- old version v1
#.  c56M    setup/clearing.alert pair for 56M
#.  cCOP    setup/clearing.alert pair for COP
#.  cAKA    setup/clearing.alert pair for Akamai
#.
#. lvoX    LVO Unable to deliver content for URL (Generally Serious)
#. DNSf    DNS ERROR or  Couldn't resolve host name  (Generally Serious)
#.
#. prbX    SDI input change, commonly seen ~70/hr RightRail - >1-2 other system serious
#. fdrp    frames.dropped
#.

