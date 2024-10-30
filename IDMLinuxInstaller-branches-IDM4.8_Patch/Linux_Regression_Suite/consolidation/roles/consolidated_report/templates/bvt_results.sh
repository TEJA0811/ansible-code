#!/bin/bash
set -x
rslt_dir="{{ results_dir }}"
declare -a bvt_files=('BVT_Engine' 'BVT_RL' 'BVT_FOA' 'BVT_IDConsole' 'BVT_Reporting')

total_tc=0
total_pass=0
total_fail=0
total_unknown=0
out_file='{{ results_dir }}/consolidated_BVT_pre.html'
touch $out_file
> $out_file


echo "
            <hr>
            <div id=bvt-version>
                <div id=bvt-version-table>
                    <table id=version-table class='table table-striped table-bordered table-hover' cellspacing=0 width=100% style='text-align=center;'
                        class=tablesorter>
                        <thead>
                            <tr>
                                <th>STAGE</th>
                                <th>TOTAL-TCs</th>
                                <th>PASSED-TCs</th>
                                <th>FAILED-TCs</th>
                                <th>Versions Not Found</th>
                            </tr>
                        </thead>
                        <tbody style='text-align:center;'>">> $out_file


for stage in "${bvt_files[@]}"
do
  file=$rslt_dir"/"$stage"/bvt_result"
  if [ -s "$file" ]
  then 
    printf "<tr>\n" >> $out_file
    items=(`cat "${file}"`)
    printf "<td>${items[0]}</td> <td>${items[1]}</td> <td>${items[2]}</td> <td>${items[3]}</td> <td>${items[4]}</td>\n" >> $out_file
    
    total_tc=$((total_tc+${items[1]}))
    total_pass=$((total_pass+${items[2]}))
    total_fail=$((total_fail+${items[3]}))
    total_unknown=$((total_unknown+${items[4]}))
    
    printf "</tr>\n" >> $out_file
    rm -rf $file
  else
    printf "<tr>\n" >> $out_file
    stage=${stage:4}
    printf "<td>${stage}</td> <td colspan="4"> Staging Failed :( </td>\n" >> $out_file    
    printf "</tr>\n" >> $out_file
  fi
done
 printf "<tr><td><b>Total</b></td> <td><b>$total_tc</b></td> <td><b>$total_pass</b></td> <td><b>$total_fail</b></td> <td><b>$total_unknown</b></td></tr>\n" >> $out_file
 printf "</tbody></table>" >> $out_file