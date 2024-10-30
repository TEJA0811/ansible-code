#!/bin/bash
#Create temporary file

set -x 
touch /config/Automation/current.txt
touch /config/Automation/result

pass=0
fail=0
unknown=0

true>/config/Automation/data

printf ",,\n" >> /config/Automation/data

#Fetch Java Version
java_version="`cat /opt/netiq/common/jre/release  |grep JAVA | cut -d '"' -f2`"
if [[ {{ JAVA_VERSION }} == $java_version ]]; then
  printf "JAVA_VERSION,$java_version,PASS\n" >>/config/Automation/data
  pass=$((pass+1))
else
  printf "JAVA_VERSION,$java_version,FAIL\n" >>/config/Automation/data
  fail=$((fail+1))
fi

#Fetch OpenSSL Version
openssl_version="`rpm -qa --qf '%{version}' netiq-openssl`"
if [[ {{ OPENSSL_VERSION }} == $openssl_version ]]; then
  printf "OPENSSL_VERSION,$openssl_version,PASS\n" >>/config/Automation/data
  pass=$((pass+1))
else
  printf "OPENSSL_VERSION,$openssl_version,FAIL\n" >>/config/Automation/data
  fail=$((fail+1))
fi

#Fetch eDirectory Version
edir_version="`/opt/novell/eDirectory/bin/ndsstat |grep "Product Version"|awk '{print $7}'|sed "s/[^0-9,.,^0-9,.,^0-9x]//g"`"
if [[ {{ EDIR_VERSION }} == $edir_version ]]; then
  printf "EDIR_VERSION,$edir_version,PASS\n" >>/config/Automation/data
  pass=$((pass+1))
else
  printf "EDIR_VERSION,$edir_version,FAIL\n" >>/config/Automation/data
  fail=$((fail+1))
fi

#Fetch NICI Version
nici_version="`rpm -qa --qf '%{version}' nici*`"
if [[ {{ NICI_VERSION }} == $nici_version ]]; then
  printf "NICI_VERSION,$nici_version,PASS\n" >>/config/Automation/data
  pass=$((pass+1))
else
  printf "NICI_VERSION,$nici_version,FAIL\n" >>/config/Automation/data
  fail=$((fail+1))
fi

#Fetch IDM Version
engine_version="`dxcmd -user "{{ ID_VAULT_ADMIN }}" -password "{{ ID_VAULT_PASSWORD }}" -getversion|grep -m 1 DirXML |awk '{print $4}'`"
if [[ {{ ENGINE_VERSION }} == $engine_version ]]; then
  printf "ENGINE_VERSION,$engine_version,PASS\n" >>/config/Automation/data
  pass=$((pass+1))
else
  printf "ENGINE_VERSION,$engine_version,FAIL\n" >>/config/Automation/data
  fail=$((fail+1))
fi

#Fetch ZoomDB Version
zoomdb_version="`rpm -qa --qf '%{version}' netiq-zoomdb`"
if [[ {{ ZOOMDB_VERSION }} == $zoomdb_version ]]; then 
  printf "ZOOMDB_VERSION,$zoomdb_version,PASS\n" >>/config/Automation/data
  pass=$((pass+1))
else
  printf "ZOOMDB_VERSION,$zoomdb_version,FAIL\n" >>/config/Automation/data
  fail=$((fail+1))
fi

#Fetch CEF Processor Version
cef_version="`rpm -qa --qf '%{version}' novell-IDMCEFProcessorx`"
if [[ {{ CEF_VERSION }} == $cef_version ]]; then
  printf "CEF_VERSION,$cef_version,PASS\n" >>/config/Automation/data
  pass=$((pass+1))
else
  printf "CEF_VERSION,$cef_version,FAIL\n" >>/config/Automation/data
  fail=$((fail+1))
fi

column -t -s',' -N Driver,Version,Result /config/Automation/data >/config/Automation/current.txt

################ IDM Drivers versions check ###################

#printf "\n\nDriver versions check\n" >> /config/Automation/current.txt
#printf "**************************************\n" >> /config/Automation/current.txt

declare -A defdriverVersions
declare -A defdriverNames

{% for rpm in drivers %}
defdriverVersions["{{ rpm }}"]={{ drivers[rpm].version }}
defdriverNames["{{ rpm }}"]="{{ drivers[rpm].name }}"
{% endfor %}

true > /config/Automation/data
true > /config/Automation/driver.html

printf ",,\n" >> /config/Automation/data
echo "   <h2>Drivers versions check</h2>
            <span id="generated">Generated on: {{ ansible_date_time.date }} {{ ansible_date_time.time }}</span>
            <hr>
            <div id="bvt-version">
                <div id="bvt-version-table">
                    <table id="version-table" class="table table-striped table-bordered" cellspacing="0" width="100%"
                        class="tablesorter">
                        <thead>
                            <tr>
                                <th>Sl.No</th>
                                <th>Driver</th>
                                <th>Expected Version</th>
                                <th>Current version</th>
                                <th>Status</th>
                            </tr>
                        </thead>">>/config/Automation/driver.html
j=1                        
for curr in "${!defdriverVersions[@]}"; do
  version="`rpm -qa --qf '%{version}' $curr`"
  if [[ ${defdriverVersions[$curr]} == $version ]]; then
    printf "<tr><td>$j</td><td>${defdriverNames[$curr]}</td><td>${defdriverVersions[$curr]}</td><td>$version</td><td>PASS</td></tr>\n" >> /config/Automation/driver.html
    pass=$((pass+1))
  else
    printf "<tr><td>$j</td><td>${defdriverNames[$curr]}</td><td>${defdriverVersions[$curr]}</td><td>$version</td><td><span style='color: red'>FAIL</span></td></tr>\n" >> /config/Automation/driver.html
    fail=$((fail+1))
  fi
  j=$((j+1))
done
printf "\n\n" >> /config/Automation/driver.html
#sort -k1 -n /config/Automation/data|column -t -s',' -N Driver,Version,Result >> /config/Automation/current.txt

################ Fetch third party library versions ###################

#printf "\n\nThird party library versions check\n" >> /config/Automation/current.txt
#printf "**************************************\n" >> /config/Automation/current.txt
path='/opt/novell/eDirectory/lib/dirxml/classes/'

declare -A defvers
{% for key, value in others.items() %}
defvers["{{ key }}"]={{ value }}
{% endfor %}

echo "   <h2>Third Party jars versions check</h2>
            <span id="generated">Generated on: {{ ansible_date_time.date }} {{ ansible_date_time.time }}</span>
            <hr>
            <div id="bvt-version">
                <div id="bvt-version-table">
                    <table id="version-table" class="table table-striped table-bordered" cellspacing="0" width="100%" class="tablesorter">
                        <thead>
                            <tr>
                                <th>Sl.No</th>
                                <th>Driver</th>
                                <th>Expected Version</th>
                                <th>Current version</th>
                                <th>Status</th>
                            </tr>
                        </thead>">>/config/Automation/third.html
j=1
for jarf in "${!defvers[@]}"; do
  curr=$path$jarf
  version=$(unzip -p $curr META-INF/MANIFEST.MF | grep -m 1 'Bundle-Version\|Implementation-Version\|Product-Version\|Specification-Version'|awk '{ print $2  }')
  version=`echo $version | tr -d '[:space:]' `
  res=${jarf%".jar"}
  res=$(echo "$res" | sed 's/-[0-9].*//')
  res=$res".jar"
  if [[ -z "$version" ]];then
    printf "<tr><td>$j</td><td>$jarf</td><td>-</td><td>-</td><td><span style='color: orange'>Version not found</span></td></tr>\n" >> /config/Automation/third.html
    unknown=$((unknown+1))
  elif [[ ${defvers[$jarf]} == $version ]]; then
    printf "<tr><td>$j</td><td>$res</td><td>${defvers[$jarf]}</td><td>$version</td><td>PASS</td></tr>\n" >> /config/Automation/third.html
    pass=$((pass+1))
  else
    printf "<tr><td>$j</td><td>$res</td><td>${defvers[$jarf]}</td><td>$version</td><td><span style='color: red'>FAIL</span></td></tr>\n" >> /config/Automation/third.html
    fail=$((fail+1))
  fi
  j=$((j+1))
done
printf "\n\n" >> /config/Automation/third.html

#sort -k1 -n /config/Automation/data |column -t -s',' -N 'Third Party jar',Version,Result>> /config/Automation/current.txt
total=$((pass + fail + unknown))

################# Print results #########################
#echo "BVT TEST RESULTS" >>result
echo "$total Test cases Total" > /config/Automation/result
echo "$pass Test cases Passed" >> /config/Automation/result
echo "$unknown Test cases Version not found" >> /config/Automation/result
echo "$fail Test cases Failed" >> /config/Automation/result
echo "***************************" >> /config/Automation/result

echo "Engine $total $pass $fail $unknown" > /config/Automation/bvt_result