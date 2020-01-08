#!/usr/bin/env bash                                                                                                                                                                  
echo $BASH_VERSION

     project="pancancer-atlas"

     declare -A ary
     
     while IFS="=" read -r key value; do
         ary[$key]=$value
     done < "DataTypeLabels-PanCan.txt"

    for k in "${!ary[@]}"; do
      bq update --set_label "${ary[$k]}" "$project:$k"
    done
