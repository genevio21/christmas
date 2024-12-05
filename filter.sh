https_port=443
http_port=80
input_file_path=$1
customer=$2
env=$3
blacklist_found=1

usage () {
        echo "Error ! Invalid arguments"
        echo "Usage :-"
        echo "  Syntax : ./filter.sh <intermidiate output(csv) file> <customer> <environment>"
        echo "  Example : ./filter.sh output.csv emea prod"
}

# comparison () {
#         components=$1
#         for string in "${components[@]}";
#         do      
#           echo $string
# 	  echo $2
#           if echo "$2" | grep -q "$string"
#           then		
#               return 0 
#           fi
#         done
#         return 1    

# }

if [ -z $input_file_path ] || [ -z $customer ] || [ -z $env ]
then
        usage
        exit
fi

blacklist_file_path="$customer/$env/blacklist.txt"
ls -ltrh $blacklist_file_path >/dev/null 2>&1

if [ $? -ne 0 ]
then
        echo "Warning ! $blacklist_file_path not found"
        echo "Assuming no URL is blacklisted for use in prometheus blackbox"
        blacklist_found=0
fi
echo "url,component,qualifier,project" > url_component.csv
bpilot_comps="workflow,orchestrator,zeebe,trino,majestic,proxy,globalorch,orange,ota-adapter,fota"
bpilot_common_comps="fca-navauth,privacymode,fca-trip,phev,bcall,backend-integrator,fca-api-gateway,ro-api,settingsmgmt,campaign-management"
l2_comps="api-gateway,datalogger,hdmaps,dff-high,gpscorrections,cchk,datalogger-user-sp,notifications,auth,datalogger-web-portal"
l2plus_common_comps="notification-api,notification-sp,dff-https-highpr,cchk-sp,cchk-api,api-gateway"
gsdp_convergence_common="apigw-config-api,campaign-management,cold-storage-connector,dff-api,dff-control,dff-handler,dff-https-highpr-reprocessing,dff-https-highpr,fca-api-gateway,mock-api,scheduler,notification"
digital_key="digital-key-sp"
while read -r line
do
        url=$(echo "$line" | sed 's|.*,||' | sed 's|.*http|http|')
        OLDIFS=$IFS
        IFS=','
        read -ra arr <<< "$line"
        component=$(echo ${arr[2]} | xargs)
        echo "identifying project for the component $component"
        if [[ ${arr[0]} != 'db' ]];
        then
            project=$(echo ${arr[1]} | xargs)
        else
            label=$(python get_project.py "$bpilot_comps" "$component")
            if [[ $label == "True" ]] && [ $customer == "emea" ]
            then 
                project="BPILOT"
                echo $component $project
                label=$(python get_project.py "$gsdp_convergence_common" "$component")
                if [[ $label == "True" ]] && [ $customer == "emea" ]
                then
                    project="BPILOT|Convergence"
                    echo $component $project
                fi
            else 
                label=$(python get_project.py "$l2_comps" "$component")
                if  [[ $label == "True" ]] && [ $customer == "nafta" ]
                then
                    project="L2Plus"
                    echo $component $project
                    label=$(python get_project.py "$gsdp_convergence_common" "$component")
                    if [[ $label == "True" ]] && [ $customer == "nafta" ]
                    then
                        project="L2Plus|Convergence"
                        echo $component $project
                    fi

                else
                        label=$(python get_project.py "$bpilot_common_comps" "$component")       
                        if [[ $label == "True" ]] && [ $customer == "emea" ]
                        then
                                project="BPILOT|GSDP"    
                                echo $component $project
                                label=$(python get_project.py "$gsdp_convergence_common" "$component")
                                if [[ $label == "True" ]] && [ $customer == "emea" ]
                                then
                                        project="BPILOT|GSDP|Convergence"
                                        echo $component $project
                                fi
                        else
                                # echo comparison $l2plus_common_comps $component | grep  -q $component
                                label=$(python get_project.py "$l2plus_common_comps" "$component")         
                                if [[ $label == "True" ]]  && [ $customer == "nafta" ]
                                then
                                project="L2Plus|GSDP"
                                echo $component $project
                                label=$(python get_project.py "$gsdp_convergence_common" "$component")
                                if [[ $label == "True" ]] && [ $customer == "nafta" ]
                                then
                                        project="L2Plus|GSDP|Convergence"
                                        echo $component $project
                                fi
                                else
                                        label=$(python get_project.py "$digital_key" "$component")         
                                        if [[ $label == "True" ]]  && [ $customer == "emea" ]
                                        then
                                        project="DK-DCross"
                                        echo $component $project
                                        else
                                                label=$(python get_project.py "$digital_key" "$component")
                                                if [[ $label == "True" ]]  && [ $customer == "nafta" ]
                                                then
                                                project="DK-Atlantis"
                                                echo $component $project
                                                else
                                                project="GSDP"
                                                echo $component $project
                                                fi
                                        fi
                                fi  
                        fi 
                fi  
            fi       
        fi
        if [[ ${arr[0]} == 'db' ]]
        then        
            qualifier=$(echo ${arr[3]} | xargs)
        fi    
        IFS=$OLDIFS
        if [[ -z $url ]]
        then
                continue
        fi
        #echo $url
        if [[ $url == "https://"* ]]; then
                #echo "It's https"
                port=443
        elif [[ $url == "http://"* ]]; then
                #echo "It's http"
                port=80
        elif [[  $url != "http://"* ]] && [[  $url != "https://"* ]] && [[ $url == "://" ]]; then
                #echo "$url neither http nor https"
                continue
        fi
        url_without_protocol=$(echo "$url" | sed 's|https://||' | sed 's|http://||')
        base_url_without_protocol=$(echo "$url_without_protocol" | sed 's|/.*||')
        #echo $url_without_protocol
        echo $base_url_without_protocol | grep ":" > /dev/null
        if [ $? -eq 0 ]
        then
                final_url=$base_url_without_protocol
        else
                final_url=$base_url_without_protocol:$port
        fi

        echo $final_url | grep -E "{|}|'|!|_|\\\|\"|\[|\]|#" >> /dev/null
        if [ $? -eq 0 ]
        then
                continue
        fi

        echo "$final_url" >> temp.txt
        echo "$final_url,$component,$qualifier,$project" >> url_component.csv
done < $input_file_path

ls -ltrh $customer/$env/additionallist.txt >/dev/null 2>&1
if [ $? -ne 0 ]
then
        echo -e "\n$customer/$env/additionallist.txt not found."
        echo "Assuming no additional endpoints needs to be appended"
else
        echo -e "\n$customer/$env/additionallist.txt found."
        echo "Appending it to main list of endpoints"
        list=cat $customer/$env/additionallist.txt
        for line in $list 
        do      
             OLDIFS=$IFS
             IFS=","
             echo $line
             read -ra arr <<< "$line"
             domain=$(echo ${arr[0]} | xargs)
             echo "$domain"
             echo "$domain" >> temp.txt
             IFS=$OLDIFS

        #      echo "$j,,,GSDP" >> url_component.csv 
        done 
        cat $customer/$env/additionallist.txt >>  url_component.csv
        # done  
fi


LC_ALL=C sort -u temp.txt -o temp.txt
#echo $blacklist_found
if [ $blacklist_found -eq 1 ]
then
        echo -e "\n$blacklist_file_path found."
        echo -e "Removing blacklisted endpoints from the main list"
        LC_ALL=C sort -u $blacklist_file_path -o $blacklist_file_path
        LC_ALL=C comm -23 temp.txt $blacklist_file_path > final_output.txt
        echo -e "\nNew endpoint list :-\n"
        LC_ALL=C comm -23 temp.txt $blacklist_file_path
else
        cp temp.txt final_output.txt
        echo -e "\nNew endpoint list :-\n"
        cat final_output.txt
fi
sed 's|^|- |'  final_output.txt > prometheusconfig.txt
rm temp.txt final_output.txt

LC_ALL=C sort -u $customer/$env/prometheusconfig.txt -o $customer/$env/prometheusconfig.txt
ls -ltrh $customer/$env/prometheusconfig.txt >/dev/null 2>&1
if [ $? -ne 0 ]
then
        echo -e "\n$customer/$env/prometheusconfig.txt not found.\n"
        echo "This might be as it is the first time execution or prometheusconfig.txt from last execution is not checked-in"
        echo "Skipping comparison of new prometheusconfig.txt with the last one"
        echo "Further action required, Please follow below steps :- "
        echo "  1. Update Prometheus additional configuration (https://svn.ahanet.net/svn/repos/haa/deployments/devops/oem/fca/monitoring/config/exporters/$customer/$env/prometheus-additional.yaml)  with targets of job "a-blackbox-tcp-external-endpoint" with content of prometheusconfig.txt"
        echo "  2. Check in prometheusconfig.txt in  https://svn.ahanet.net/svn/repos/haa/deployments/devops/oem/fca/scripts/external-endpoint-connectivity/$customer/$env"
else
        md5sum prometheusconfig.txt | awk -v prometheusconfig="$customer/$env/prometheusconfig.txt" '{print $1,prometheusconfig}'  > checksum.txt
        md5sum -c checksum.txt >/dev/null 2>&1

        if [ $? -ne 0 ]
        then
                echo -e "\nGenerated prometheusconfig.txt not matching with $customer/$env/prometheusconfig.txt"
                echo "Further action required, Please follow below steps :- "
                echo "  1. Update Prometheus additional configuration (https://svn.ahanet.net/svn/repos/haa/deployments/devops/oem/fca/monitoring/config/exporters/$customer/$env/prometheus-additional.yaml)  with targets of job "a-blackbox-tcp-external-endpoint" with content of prometheusconfig.txt"
                echo "  2. Check in prometheusconfig.txt in  https://svn.ahanet.net/svn/repos/haa/deployments/devops/oem/fca/scripts/external-endpoint-connectivity/$customer/$env"

                echo -e "\nSide by side diff :"
                diff -y prometheusconfig.txt $customer/$env/prometheusconfig.txt
        else
                echo -e "\nGenerated prometheusconfig.txt matching with $customer/$env/prometheusconfig.txt"
                echo "No further action required."
        fi
fi

rm -rf checksum.txt