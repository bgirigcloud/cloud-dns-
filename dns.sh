Launch client VMs, one in each region
Launch server VMs, one in each region except REGION3
Create a private zone, for example.com
Create a Geolocation routing policy using gcloud commands
Test the configuration

#Task 1. Enable APIs

gcloud services enable compute.googleapis.com

#Enable Cloud DNS API
gcloud services enable dns.googleapis.com

#Verify that the APIs are enabled
gcloud services list | grep -E 'compute|dns'
#Task 2. Configure the firewall
gcloud compute firewall-rules create fw-default-iapproxy \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:22,icmp \
--source-ranges=35.235.240.0/20

#To allow HTTP traffic on the web servers, each web server will have a "http-server" tag associated with it. You will use this tag to apply the firewall rule only to your web servers:
gcloud compute firewall-rules create allow-http-traffic --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

#Task 3. Launch client VMs

gcloud compute instances create us-client-vm --machine-type e2-medium --zone ZONE1

#Launch client in REGION2

gcloud compute instances create europe-client-vm --machine-type e2-medium --zone ZONE2

##Launch client in REGION3

gcloud compute instances create asia-client-vm --machine-type e2-medium --zone ZONE3

#Task 4. Launch Server VMs

gcloud compute instances create us-web-vm \
--zone=ZONE1 \
--machine-type=e2-medium \
--network=default \
--subnet=default \
--tags=http-server \
--metadata=startup-script='#! /bin/bash
 apt-get update
 apt-get install apache2 -y
 echo "Page served from: REGION1" | \
 tee /var/www/html/index.html
 systemctl restart apache2'



#Launch server in REGION2


gcloud compute instances create europe-web-vm \
--zone=ZONE2 \
--machine-type=e2-medium \
--network=default \
--subnet=default \
--tags=http-server \
--metadata=startup-script='#! /bin/bash
 apt-get update
 apt-get install apache2 -y
 echo "Page served from: REGION2" | \
 tee /var/www/html/index.html
 systemctl restart apache2'




#Task 5. Setting up environment variables




#Command to save IP address for the vm in ZONE1:

export US_WEB_IP=$(gcloud compute instances describe us-web-vm --zone=ZONE1 --format="value(networkInterfaces.networkIP)")



#Command to save the IP address for vm in ZONE2:



export EUROPE_WEB_IP=$(gcloud compute instances describe europe-web-vm --zone=ZONE2 --format="value(networkInterfaces.networkIP)")




#Task 6. Create the private zone



gcloud dns managed-zones create example --description=test --dns-name=example.com --networks=default --visibility=private



#Task 7. Create Cloud DNS Routing Policy



gcloud beta dns record-sets create geo.example.com \
--ttl=5 --type=A --zone=example \
--routing_policy_type=GEO \
--routing_policy_data="REGION1=$US_WEB_IP;REGION2=$EUROPE_WEB_IP"


#Verify

gcloud beta dns record-sets list --zone=example

#Task 8. Testing
#Testing from the client VM in REGION2#
#Use curl to access the web server
for i in {1..10}; do echo $i; curl geo.example.com; sleep 6; done



gcloud compute ssh europe-client-vm --zone ZONE2 --tunnel-through-iap



#Testing from the client VM in REGION1


gcloud compute ssh us-client-vm --zone ZONE1 --tunnel-through-iap




#Use the curl command to access geo.example.com:


for i in {1..10}; do echo $i; curl geo.example.com; sleep 6; done



#Testing from the client VM in REGION3


gcloud compute ssh asia-client-vm --zone ZONE3 --tunnel-through-iap


#Then access geo.example.com:

for i in {1..10}; do echo $i; curl geo.example.com; sleep 6; done



#Task 9. Delete lab resources



#delete VMS
gcloud compute instances delete -q us-client-vm --zone ZONE1

gcloud compute instances delete -q us-web-vm --zone ZONE1

gcloud compute instances delete -q europe-client-vm --zone ZONE2

gcloud compute instances delete -q europe-web-vm --zone ZONE2

gcloud compute instances delete -q asia-client-vm --zone ZONE3

#delete FW rules
gcloud compute firewall-rules delete -q allow-http-traffic

gcloud compute firewall-rules delete fw-default-iapproxy

#delete record set
gcloud beta dns record-sets delete geo.example.com --type=A --zone=example

#delete private zone
gcloud dns managed-zones delete example






