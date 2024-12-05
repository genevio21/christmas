#! /bin/sh
region=$1
mongouser=$2
mongopass=$3
services=(aota uact fota lifecycle service-package-mapping  service-provisioning m2m)
echo "#! /bin/sh" > run.sh
echo "## Running commands  " >> run.sh
for val in "${services[@]}";
do
    echo $val
    CM=$(kubectl get cm | egrep "$val" | awk '{print $1}')    
    while IFS= read -r p
    do
        CMD="kubectl get cm $p -o yaml | egrep 'url|http:|https:|server' | egrep -v 'svc|-XX|CATALINA_OPTS|wget|server_port|server.port|virtual-server' | awk '{print \"$p,\", \"GSDP,\",\"$val,\", \$1, \$2}' | sed 's/: /,/g'"
        echo $CMD  >> run.sh
        echo "sleep 1" >> run.sh
        #sleep 1
    done <<< "$CM"
done


if [ $region == "EMEA" ]
then
    echo " Checking for Bpilot components "
    #! /bin/sh
    services=(workflow orchestrator zeebe trino majestic  proxy globalorch orange ota-adapter)
    # echo "#! /bin/sh" > run.sh
    # echo "## Running commands  " >> run.sh
    for val in "${services[@]}";
    do
        echo $val
        CM=$(kubectl get cm | egrep "$val" | awk '{print $1}')    
        while IFS= read -r p
        do
            CMD="kubectl get cm $p -o yaml | egrep 'url|http:|https:|server' | egrep -v 'svc|-XX|CATALINA_OPTS|wget|server_port|server.port|virtual-server' | awk '{print \"$p,\", \"BPILOT,\",\"$val,\", \$1, \$2}' | sed 's/: /,/g'"
            echo $CMD  >> run.sh
            echo "sleep 1" >> run.sh
            #sleep 1
        done <<< "$CM"
    done

    # chmod a+x run.sh
    # echo "Executing run.sh"
    # ./run.sh >> output.csv

    services=(fca-navauth privacymode fota fca-trip phev bcall backend-integrator fca-api-gateway ro-api settingsmgmt campaign-management)
    # echo "#! /bin/sh" > run.sh
    # echo "## Running commands  " >> run.sh
    for val in "${services[@]}";
    do
        echo $val
        CM=$(kubectl get cm | egrep "$val" | awk '{print $1}')    
        while IFS= read -r p
        do  
            CMD="kubectl get cm $p -o yaml | egrep 'url|http:|https:|server' | egrep -v 'svc|-XX|CATALINA_OPTS|wget|server_port|server.port|virtual-server' | awk '{print \"$p,\", \"BPILOT|GSDP,\",\"$val,\", \$1, \$2}' | sed 's/: /,/g'"
            echo $CMD  >> run.sh
            echo "sleep 1" >> run.sh
            #sleep 1
        done <<< "$CM"
    done

    # chmod a+x run.sh
    # echo "Executing run.sh"
    # ./run.sh >> output.csv
fi    

if [ $region == "NAFTA" ]
then
    echo "Checking for L2+ Components"
    services=(api-gateway datalogger hdmaps dff-high gpscorrections auth cchk datalogger-user-sp notifications datalogger-web-portal)
    # echo "#! /bin/sh" > run.sh
    # echo "## Running commands  " >> run.sh
    for val in "${services[@]}";
    do
        echo $val
        CM=$(kubectl get cm | egrep "$val" | awk '{print $1}')    
        while IFS= read -r p
        do
            CMD="kubectl get cm $p -o yaml | egrep 'url|http:|https:|server' | egrep -v 'svc|-XX|CATALINA_OPTS|wget|server_port|server.port|virtual-server' | awk '{print \"$p,\", \"L2Plus,\",\"$val,\", \$1, \$2}' | sed 's/: /,/g'"
            echo $CMD  >> run.sh
            echo "sleep 1" >> run.sh
            #sleep 1
        done <<< "$CM"
    done

    # chmod a+x run.sh
    # echo "Executing run.sh"
    # ./run.sh >> output.csv

    services=(notification-api notification-sp dff-https-highpr cchk-sp cchk-api api-gateway)
    # echo "#! /bin/sh" > run.sh
    # echo "## Running commands  " >> run.sh
    for val in "${services[@]}";
    do
        echo $val
        CM=$(kubectl get cm | egrep "$val" | awk '{print $1}')    
        while IFS= read -r p
        do  
            CMD="kubectl get cm $p -o yaml | egrep 'url|http:|https:|server' | egrep -v 'svc|-XX|CATALINA_OPTS|wget|server_port|server.port|virtual-server' | awk '{print \"$p,\", \"L2Plus|GSDP,\",\"$val,\", \$1, \$2}' | sed 's/: /,/g'"
            echo $CMD  >> run.sh
            echo "sleep 1" >> run.sh
            #sleep 1
        done <<< "$CM"
    done

    # chmod a+x run.sh
    # echo "Executing run.sh"
    # ./run.sh >> output.csv
fi    

# For Convergence Namespace
services=(apigw-config-api campaign-management cold-storage-connector dff-api dff-control dff-handler dff-https-highpr-reprocessing dff-https-highpr fca-api-gateway mock-api scheduler noti    fication)
for val in "${services[@]}";
do
    echo $val
    CM=$(kubectl get cm -n convergence| egrep "$val" | awk '{print $1}')    
    while IFS= read -r p
    do  
        CMD="kubectl get cm -n convergence $p -o yaml | egrep 'url|http:|https:|server' | egrep -v 'svc|-XX|CATALINA_OPTS|wget|server_port|server.port|virtual-server' | awk '{print \"$p,\", \"GSDP,\",\"$val,\", \$1, \$2}' | sed 's/: /,/g'"
        echo $CMD  >> run.sh
        echo "sleep 1" >> run.sh
        #sleep 1
    done <<< "$CM"
done

chmod a+x run.sh
echo "Executing run.sh"
./run.sh > output.csv

kubectl exec -i $(kubectl get po  | grep mongo-qr | head -n 1| awk '{print $1}') -- mongo ignite --port 27017 --quiet -u "$mongouser" -p "$mongopass" --authenticationDatabase admin < feed.js > feed-out.txt

while read -r line
do
   echo "db,GSDP,$line" >> output.csv
done < feed-out.txt