#!/bin/bash

touch all_data.txt

for sub in *ROI*;
do

base=$(basename $sub _ROIout.csv)
cat $sub | cut -d "," -f 2 > "$base"_out.csv

awk '
{ 
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {    
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' "$base"_out.csv >> all_data.txt

done

