#! /bin/sh

sed -i 's/- //g' prometheusconfig.txt
touch temp.txt
touch failDomains.txt

cat prometheusconfig.txt | while read domain 
do 
   kubectl exec $(kubectl get po -n monitoring | grep prometheus-k8s* | head -n 1| awk '{print $1}') -c prometheus -n monitoring -- nc -zv -w 5 $domain
   if [ $? -eq 0 ]
   then
        echo $domain >> temp.txt
   else
        echo $domain >> failDomains.txt     
   fi    
done

python generate_json.py
# for pod in $(kubectl get po -n monitoring | grep prometheus-k8s* | awk '{print $1}')
# do
#      kubectl cp externalEndpoints.json monitoring/$pod:/prometheus/external_targets.json
# done   
# awk '{ print "\""$0"\""}' temp.txt > externalEndpoints.txt
# awk '{ print "\""$0"\""}' failDomains.txt > failedDomains.txt

# jq --slurpfile targets externalEndpoints.txt '.[].targets=$targets' <targets.json> externalEndpoints.json
# jq '.[].labels.job = "a-blackbox-tcp-external-endpoint-failed"' targets.json > failed.json
# jq --slurpfile targets failedDomains.txt '.[].targets=$targets' <failed.json> external_targets_failed.json

kubectl cp monitoring/$(kubectl get po -n monitoring | grep prometheus-k8s* | head -n 1| awk '{print $1}'):/prometheus/external_targets.json .
if [ $? -eq 0 ]
then
     cmp external_targets.json externalEndpoints.json
     if [ $? -ne 0 ]
     then
          diff -y external_targets.json externalEndpoints.json > output_diff.txt
          #copy the generated file to the pod.
          echo "Copy the Targets file to prometheus"
          for pod in $(kubectl get po -n monitoring | grep prometheus-k8s* | awk '{print $1}')
          do
               kubectl cp externalEndpoints.json monitoring/$pod:/prometheus/external_targets.json
          done     
     fi 
else
     echo "Copy the Targets file to prometheus"
     for pod in $(kubectl get po -n monitoring | grep prometheus-k8s* | awk '{print $1}')
     do
          kubectl cp externalEndpoints.json monitoring/$pod:/prometheus/external_targets.json
          kubectl cp external_targets_failed.json monitoring/$pod:/prometheus/external_targets_failed.json
     done 
fi  
echo "Copy the failed targets file to prometheus"
for pod in $(kubectl get po -n monitoring | grep prometheus-k8s* | awk '{print $1}')
do
     kubectl cp external_targets_failed.json monitoring/$pod:/prometheus/external_targets_failed.json
done