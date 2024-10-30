#!/bin/bash
#Create temporary file

set -x 
out_file='/config/Automation/BVT.html'
touch $out_file
touch /config/Automation/result

pass=0
fail=0
unknown=0

true>$out_file

printf "\n" >> $out_file

declare -A defvers
{% for key, value in idconsole.items() %}
defvers["{{ key }}"]={{ value }}
{% endfor %}

echo "   <h2>Build Validation Test For Identity Console rpms</h2>
            <span id="generated">Generated on: {{ ansible_date_time.date }} {{ ansible_date_time.time }}</span>
            <hr>
            <div id="bvt-version">
                <div id="bvt-version-table">
                    <table id="version-table" class="table table-striped table-bordered" cellspacing="0" width="100%" class="tablesorter">
                        <thead>
                            <tr>
                                <th>Sl.No</th>
                                <th>RPM name</th>
                                <th>Expected Version</th>
                                <th>Current version</th>
                                <th>Status</th>
                            </tr>
                        </thead>">>$out_file
                        
                        
j=1                      
for rpmf in "${!defvers[@]}"; do
  version=$(rpm -qa --qf '%{version}' $rpmf)
  version=`echo $version | tr -d '[:space:]' `
  res=$rpmf".rpm"

  if [[ -z "$version" ]];then
    printf "<tr><td>$j</td><td>$rpmf</td><td>-</td><td>-</td><td><span style='color: orange'>Version not found</span></td></tr>\n" >> $out_file
    unknown=$((unknown+1))
  elif [[ ${defvers[$rpmf]} == $version ]]; then
    printf "<tr><td>$j</td><td>$res</td><td>${defvers[$rpmf]}</td><td>$version</td><td>PASS</td></tr>\n" >> $out_file
    pass=$((pass+1))
  else
    printf "<tr><td>$j</td><td>$res</td><td>${defvers[$rpmf]}</td><td>$version</td><td><span style='color: red'>FAIL</span></td></tr>\n" >> $out_file
    fail=$((fail+1))
  fi
  j=$((j+1))
done



total=$((pass + fail + unknown))

################# Print results #########################
#echo "BVT TEST RESULTS" >>result
echo "$total Test cases Total" > /config/Automation/result
echo "$pass Test cases Passed" >> /config/Automation/result
echo "$unknown Test cases Version not found" >> /config/Automation/result
echo "$fail Test cases Failed" >> /config/Automation/result
echo "***************************" >> /config/Automation/result

echo "IDConsole $total $pass $fail $unknown" > /config/Automation/bvt_result