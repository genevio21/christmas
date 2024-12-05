import pandas as pd
import json

domain_data= pd.read_csv("url_component.csv")

gsdp_domains =  list(domain_data[domain_data["project"]=="GSDP"]["url"].values)
bpilot_common_domains = list(domain_data[domain_data["project"]=="BPILOT|GSDP"]["url"].values)
bpilot_domains= list(domain_data[domain_data["project"]=="BPILOT"]["url"].values)
l2_domains= list(domain_data[domain_data["project"]=="L2Plus"]["url"].values)
l2_common_domains=list(domain_data[domain_data["project"]=="L2Plus|GSDP"]["url"].values)
digital_key_domains=list(domain_data[domain_data["project"]=="DK-DCross"]["url"].values)+list(domain_data[domain_data["project"]=="DK-Atlantis"]["url"].values)

bpilot_convergence_domains = list(domain_data[domain_data["project"]=="BPILOT|Convergence"]["url"].values)
l2_convergence_domains = list(domain_data[domain_data["project"]=="L2Plus|Convergence"]["url"].values)
bpilot_convergence_common_domains = list(domain_data[domain_data["project"]=="BPILOT|GSDP|Convergence"]["url"].values)
l2_convergence_common_domains = list(domain_data[domain_data["project"]=="L2Plus|GSDP|Convergence"]["url"].values)

connected_domains =  open("temp.txt","r")

lines=  connected_domains.readlines()
suc_domains = [line.replace("\n","") for line in lines]
connected_domains.close()

failed_domains =  open("failDomains.txt","r")

lines=  failed_domains.readlines()
fail_domains = [line.replace("\n","") for line in lines]
failed_domains.close()

gsdp_suc_domains=[]
gsdp_fail_domains=[]
for domain in list(set(gsdp_domains)-set(bpilot_domains)-set(l2_domains)-set(l2_common_domains)-set(bpilot_common_domains)):
    if (domain in suc_domains):
        gsdp_suc_domains.append(domain)
    elif(domain in fail_domains):
        gsdp_fail_domains.append(domain)    

if len(digital_key_domains)>0:
    digital_key_suc_domains=[]
    digital_key_fail_domains=[]
    digital_key_suc_domains_json=[]
    digital_key_fail_domains_json=[]
    for domain in list(set(digital_key_domains)):
        if (domain in suc_domains):
            digital_key_suc_domains.append(domain)
        elif(domain in fail_domains):
            digital_key_fail_domains.append(domain)
    if len(digital_key_suc_domains)>0:
        digital_key_suc_domains_json.append(
            {
            "targets": list(set(digital_key_suc_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint",
                "project": "Digital-Key",
                "service": "blackbox-exporter"
                }
        }
        )
    if len(digital_key_fail_domains)>0:
        digital_key_fail_domains_json.append(
            {
        "targets": list(set(digital_key_fail_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint-failed",
            "project": "Digital-Key",
            "service": "blackbox-exporter"
            }
            }
        )

if(len(bpilot_domains) > 0 ):
    bpilot_suc_domains=[]
    bpilot_fail_domains=[]
    for domain in list(set(bpilot_domains)-set(gsdp_domains)-set(bpilot_common_domains)):
        if (domain in suc_domains):
            bpilot_suc_domains.append(domain)
        elif(domain in fail_domains):
            bpilot_fail_domains.append(domain)   

    bpilot_com_suc_domains=[]
    bpilot_com_fail_domains=[]
    for domain in bpilot_common_domains+list(set(bpilot_domains) & set(gsdp_domains)):
        if (domain in suc_domains):
            bpilot_com_suc_domains.append(domain)
        elif(domain in fail_domains):
            bpilot_com_fail_domains.append(domain)

    bpilot_convergence_suc_domains=[]
    bpilot_convergence_fail_domains=[]
    for domain in list(set(bpilot_convergence_domains)-set(bpilot_domains)-set(gsdp_domains)-set(bpilot_common_domains)):
        if(domain in suc_domains):
            bpilot_convergence_suc_domains.append(domain)
        elif(domain in fail_domains):
            bpilot_convergence_fail_domains.append(domain)

    bpilot_convergence_com_suc_domains=[]
    bpilot_convergence_com_fail_domains=[]
    for domain in list(set(bpilot_convergence_common_domains)-set(bpilot_common_domains)):
        if(domain in suc_domains):
            bpilot_convergence_com_suc_domains.append(domain)
        elif(domain in fail_domains):
            bpilot_convergence_com_fail_domains.append(domain)

    success_data_dict= [{
        "targets": list(set(gsdp_suc_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint",
            "project": "GSDP",
            "service": "blackbox-exporter"
            }
    },
    {
        "targets": list(set(bpilot_suc_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint",
            "project": "BPILOT",
            "service": "blackbox-exporter"
            }
    },
    {
        "targets": list(set(bpilot_com_suc_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint",
            "project": "BPILOT|GSDP",
            "service": "blackbox-exporter"
            }
    },
    {
        "targets": list(set(bpilot_com_suc_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint",
            "project": "BPILOT|Convergence",
            "service": "blackbox-exporter"
            }
    },
    {
        "targets": list(set(bpilot_convergence_suc_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint",
            "project": "BPILOT|Convergence",
            "service": "blackbox-exporter"
            }
    },
    {
        "targets": list(set(bpilot_convergence_com_suc_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint",
            "project": "BPILOT|GSDP|Convergence",
            "service": "blackbox-exporter"
            }
    }]
    success_data_dict.extend(digital_key_suc_domains_json)

    failed_data_dict= [{
            "targets": list(set(gsdp_fail_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint-failed",
                "project": "GSDP",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(bpilot_fail_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint-failed",
                "project": "BPILOT",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(bpilot_com_fail_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint-failed",
                "project": "BPILOT|GSDP",
                "service": "blackbox-exporter"
                }
        },
        {
        "targets": list(set(bpilot_convergence_fail_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint-failed",
            "project": "BPILOT|Convergence",
            "service": "blackbox-exporter"
            }
    },
    {
        "targets": list(set(bpilot_convergence_com_fail_domains)),
        "labels":{
            "job": "a-blackbox-tcp-external-endpoint-failed",
            "project": "BPILOT|GSDP|Convergence",
            "service": "blackbox-exporter"
            }
    }]
    failed_data_dict.extend(digital_key_fail_domains_json)


if(len(l2_domains) > 0 ):
    L2_suc_domains=[]
    L2_fail_domains=[]
    for domain in list(set(l2_domains)-set(gsdp_domains)-set(l2_common_domains)):
        if (domain in suc_domains):
            L2_suc_domains.append(domain)
        elif(domain in fail_domains):
            L2_fail_domains.append(domain)  

    L2_com_suc_domains=[]
    L2_com_fail_domains=[]
    for domain in l2_common_domains+ list(set(gsdp_domains) & set(l2_domains)):
        if (domain in suc_domains):
            L2_com_suc_domains.append(domain)
        elif(domain in fail_domains):
            L2_com_fail_domains.append(domain) 

    l2_convergence_suc_domains=[]
    l2_convergence_fail_domains=[]
    for domain in list(set(l2_convergence_domains)-set(l2_domains)-set(l2_common_domains)):
        if(domain in suc_domains):
            l2_convergence_suc_domains.append(domain)
        elif(domain in fail_domains):
            l2_convergence_fail_domains.append(domain)
    
    l2_convergence_com_suc_domains=[]
    l2_convergence_com_fail_domains=[]
    for domain in list(set(l2_convergence_common_domains)-set(l2_domains)-set(l2_common_domains)):
        if(domain in suc_domains):
            l2_convergence_com_suc_domains.append(domain)
        elif(domain in fail_domains):
            l2_convergence_com_fail_domains.append(domain)

    success_data_dict= [{
            "targets": list(set(gsdp_suc_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint",
                "project": "GSDP",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(L2_suc_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint",
                "project": "L2Plus",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(L2_com_suc_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint",
                "project": "L2Plus|GSDP",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(l2_convergence_suc_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint",
                "project": "L2Plus|Convergence",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(l2_convergence_com_suc_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint",
                "project": "L2Plus|GSDP|Convergence",
                "service": "blackbox-exporter"
                }
        }]
    success_data_dict.extend(digital_key_suc_domains_json)


    failed_data_dict= [{
            "targets": list(set(gsdp_fail_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint-failed",
                "project": "GSDP",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(L2_fail_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint-failed",
                "project": "L2Plus",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(L2_com_fail_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint-failed",
                "project": "L2Plus|GSDP",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(l2_convergence_fail_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint-failed",
                "project": "L2Plus|Convergence",
                "service": "blackbox-exporter"
                }
        },
        {
            "targets": list(set(l2_convergence_com_fail_domains)),
            "labels":{
                "job": "a-blackbox-tcp-external-endpoint-failed",
                "project": "L2Plus|GSDP|Convergence",
                "service": "blackbox-exporter"
                }
        }]
    failed_data_dict.extend(digital_key_fail_domains_json)

out_file = open("externalEndpoints.json", "w")
json.dump(success_data_dict, out_file, indent = 6)
out_file.close()


out_file = open("external_targets_failed.json", "w")
json.dump(failed_data_dict, out_file, indent = 6)
out_file.close()