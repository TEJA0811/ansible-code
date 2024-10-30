#!/bin/bash

declare -A xpoz_files=( ["Engine"]="{{ results_dir }}/Regression_Engine/xpoz_result" ["FanOut Agent"]="{{ results_dir }}/Regression_FOA/xpoz_result" ["Driver"]="{{ results_dir }}/Regression_Drivers/xpoz_result")
declare -a items
declare -A rest_files=( ["Identity Reporting"]="{{ results_dir }}/Regression_Reporting/RESTAPI_result" ["Identity Console"]="{{ results_dir }}/Regression_IDConsole/RESTAPI_result" )


total_tc=0
total_pass=0
total_fail=0
total_unknown=0
out_file='{{ results_dir }}/consolidated_XPOZ_pre.html'
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
                                <th>NYI-TCs</th>
                            </tr>
                        </thead>
                        <tbody style='text-align:center;'>">> $out_file

for stage in "${!xpoz_files[@]}"; do
  ipfile=${xpoz_files[$stage]}
  if [ -s "$ipfile" ]
  then 
    printf "<tr>\n" >> $out_file
    echo `awk 'NR >= 4 && NR <= 7' $ipfile | awk '{print $1}'`>$ipfile
    while read line; do
      items=($line)
      printf "<td>$stage</td> <td>${items[0]}</td> <td>${items[1]}</td> <td>${items[2]}</td> <td>${items[3]}</td>\n" >> $out_file
      total_tc=$((total_tc+$((10#${items[0]}))))
      total_pass=$((total_pass+$((10#${items[1]}))))
      total_fail=$((total_fail+$((10#${items[2]}))))
      total_unknown=$((total_unknown+$((10#${items[3]}))))
    done < $ipfile
    printf "</tr>\n" >> $out_file
    rm -rf $ipfile
  else
    printf "<tr>\n" >> $out_file
    printf "<td>$stage</td> <td colspan="4"> Staging Failed   :( </td>\n" >> $out_file
    printf "</tr>\n" >> $out_file    
  fi
done

for stage in "${!rest_files[@]}"; do
  ipfile=${rest_files[$stage]}
  if [ -s "$ipfile" ]
  then 
    items=(`cat "$ipfile"`)
    printf "<tr>\n" >> $out_file
    sum=$((${items[0]} + ${items[1]}))
    printf "<td>$stage</td> <td>$sum</td> <td>${items[0]}</td> <td>${items[1]}</td> <td>${items[2]}</td>\n" >> $out_file
    total_tc=$((total_tc+$((10#$sum))))
    total_pass=$((total_pass+$((10#${items[0]}))))
    total_fail=$((total_fail+$((10#${items[1]}))))
    total_unknown=$((total_unknown+$((10#${items[2]}))))
    rm -rf $ipfile
    printf "</tr>\n" >> $out_file
  else
    printf "<tr>\n" >> $out_file
    printf "<td>$stage</td> <td colspan="4"> Staging Failed   :( </td>\n" >> $out_file
    printf "</tr>\n" >> $out_file
  fi  
done


 printf "<tr><td><b>Total</b></td> <td><b>$total_tc</b></td> <td><b>$total_pass</b></td> <td><b>$total_fail</b></td> <td><b>$total_unknown</b></td></tr>\n" >> $out_file
 printf "</tbody></table>" >> $out_file