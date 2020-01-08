#!/usr/bin/env bash                                                                                                                                                                  
echo $BASH_VERSION

     project="isb-cgc"

     declare -A ary
     
     while IFS="=" read -r key value; do
         ary[$key]=$value
     done < "Source_Labels.txt"

    for k in "${!ary[@]}"; do
      bq update --set_label "${ary[$k]}" "$project:$k"
    done
