#This script was used to update the BQ tables with schemas that contain newly added field descriptions to each field. As part of the BQ Ecosystem project we wanted to ensure that all fields were well described and annotated. Using "the python script",field names and their corresponding dataset and table information were dumped into a large csv file. Manually, the field descriptions were added to the csv  and had to be individually added to the schemas of each table. The following steps go through how the fields from the large CSV were added to the individual schemas of the tables. 

#1-The starting large CSV FILE was converted into individual csv files with dataset and tableID, field name & newly added descriptions. Each new CSV file was named in the following way: projectID.dataset_name.tableID. 
awk -F ',' 'NR==1{h=$0; next};!seen[$1]++{f=$1".csv"; print h > f};{f=$1".csv"; print >> f; close(f)}' NewFieldDescriptions-BQTables.csv

#2 -To convert the individual csv files into json format (prettyjson format) to match the existing BQ schema format, used the Miller commandline tool which converts csv to json and the jq commandline tool which converts the csv files to prettyjson format to match the BQ schema output format. 
#The jq commandline tool is available through here: https://stedolan.github.io/jq/
#The mlr commandline tool is available here: https://github.com/johnkerl/miller

ls *.csv > list_csv_to_convert_to_json
sed -i ' ' '/NewFieldDescriptions-BQTables.csv/d' list_csv_to_convert_to_json

for file in $(<list_csv_to_convert_to_json) 
do
LC_CTYPE=C && LANG=C cut -d ',' -f 2- $file > out.$file
mlr --c2j --jlistwrap cat out.$file | jq . > field_description.$file.json
rm out.$file
done

#3-dump the current schemas for the BQ tables (they don't have field descriptions). The BQ schemas and the new schemas created with the field name and field description will be merged. 
sed 's/.csv//g' list_csv_to_convert_to_json | sed 's/isb-cgc./isb-cgc:/g' > list_of_tables
for file in $(<list_of_tables)
do 
    bq show --schema --format=prettyjson $file >$file.json
done


#4-Use an associcative array to first combine the 2 json files so that field descriptions are added to the correct field name in each table's schema. 

ls isb-cgc:* > list_of_current_schemas_for_each_BQ_table.txt
ls field_description.* > list_of_files_with_new_field_descriptions.txt
paste list_of_current_schemas.txt list_of_field_descriptions.txt | tr '\t' '=' > KeyValuePairs_Jsons.txt

#4-Use an associcative array to first combine the 2 json files so that field descriptions are added to the correct field name in each table's schema.
declare -A ary
     
    while IFS="=" read -r key value; do
        ary[$key]=$value
    done < "KeyValuePairs_Jsons.txt"

for k in "${!ary[@]}"; do
jq -s 'flatten | group_by(.name) | map(reduce .[] as $x ({}; . * $x))' "$k" "${ary[$k]}" > out.$k

done

#5 -Read all newly create combined json files to a file to read into the next associcative array below.  This array is used to update the bq tables with the updated schemas created in the output from the above array.
ls *out.* > list_to_update_field_descriptions_in_BQ.txt

declare -A ary

    while IFS="=" read -r key value; do
        ary[$key]=$value
    done < "list_to_update_field_descriptions_in_BQ.txt"

for k in "${!ary[@]}"; do

    bq update "$k" "${ary[$k]}"                                                                                                                                                         
done




