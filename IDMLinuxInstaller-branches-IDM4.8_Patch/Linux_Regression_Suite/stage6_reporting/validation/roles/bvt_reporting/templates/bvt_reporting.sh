#!/bin/bash
#Create temporary file

set -x 
touch /tmp/Automation/reporting.html
touch /tmp/Automation/result

pass=0
fail=0
unknown=0

true>reporting.html

################ Fetch third party library versions ###################

path='/opt/novell/eDirectory/lib/dirxml/classes/'

declare -A defvers
{% for key, value in rpt.items() %}
defvers["{{ key }}"]={{ value }}
{% endfor %}

echo "   <h2>Identity Reporting jars versions check</h2>
            <span id="generated">Generated on: {{ ansible_date_time.date }} {{ ansible_date_time.time }}</span>
            <hr>
            <div id="bvt-version">
                <div id="bvt-version-table">
                    <table id="version-table" class="table table-striped table-bordered" cellspacing="0" width="100%" class="tablesorter">
                        <thead>
                            <tr>
                                <th>Sl.No</th>
                                <th>Jar name</th>
                                <th>Expected Version</th>
                                <th>Current version</th>
                                <th>Status</th>
                            </tr>
                        </thead>">>reporting.html
j=1

for jarf in "${!defvers[@]}"; do
  curr=$path$jarf
  version=$(unzip -p $curr META-INF/MANIFEST.MF | grep -m 1 'Bundle-Version\|Implementation-Version\|Product-Version\|Specification-Version'|awk '{ print $2  }')
  version=`echo $version | tr -d '[:space:]' `
  res=${jarf%".jar"}
  res=$(echo "$res" | sed 's/-[0-9].*//')
  res=$res".jar"
  if [[ -z "$version" ]];then
    printf "<tr><td>$j</td><td>$jarf</td><td>-</td><td>-</td><td><span style='color: orange'>Version not found</span></td></tr>\n" >> reporting.html
    unknown=$((unknown+1))
  elif [[ ${defvers[$jarf]} == $version ]]; then
    printf "<tr><td>$j</td><td>$res</td><td>${defvers[$jarf]}</td><td>$version</td><td>PASS</td></tr>\n" >> reporting.html
    pass=$((pass+1))
  else
    printf "<tr><td>$j</td><td>$res</td><td>${defvers[$jarf]}</td><td>$version</td><td><span style='color: red'>FAIL</span></td></tr>\n" >> reporting.html
    fail=$((fail+1))
  fi
  j=$((j+1))
done
printf "\n\n" >> reporting.html

total=$((pass + fail + unknown))

################# Print results #########################
echo "$total Test cases Total" > result
echo "$pass Test cases Passed" >> result
echo "$unknown Test cases Version not found" >> result
echo "$fail Test cases Failed" >> result
echo "***************************" >> result
echo "Reporting $total $pass $fail $unknown" > bvt_result






