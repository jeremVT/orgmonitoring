/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to check the availability of all Pods used by ENGIE instances
Test Class:    OrgMonitoringPodAvailabilityChecker_Test
Version:       0.1
History
23/02/2024     Salvatore Aversano    Create version

Version 0.1    Created
----------------------------------------------------------------------------------------*/

public with sharing class OrgMonitoringPodAvailabilityChecker implements Schedulable
{
    public void execute (SchedulableContext sc )
    {
        System.enqueueJob (new QueueableExtraction());
    }
    
    public class QueueableExtraction implements Queueable, Database.AllowsCallouts
    {
        public void execute(QueueableContext context) 
        {
            List<OrgMonitoringPod__c> podToInsert = new List<OrgMonitoringPod__c>();
            List<OrgMonitoring__c> orgslist = extractPods();
            Set <String> SetPodToCheck = new Set<String>();
            
            for ( OrgMonitoring__c oOrg : orgslist ) 
            {
                checkPodAvailability(SetPodToCheck, podToInsert, oOrg);
            }

            // insert records 
            if(podToInsert!=null && !podToInsert.isEmpty())
            {
                try {
                insert podToInsert;
                } catch (DMLException f){
                  System.debug('#### DML Exception : ' + f);
                }
            }
        }
    }
        // Method to check the availability of a POD
        public static void checkPodAvailability(Set <String> Pods, List<OrgMonitoringPod__c> podToInsert, OrgMonitoring__c  org) 
        {
            String apiUrl = 'https://api.status.salesforce.com/v1/instances/';
            apiUrl += org.OrgInstance__c + '/status/preview';
            // Prepare a new record for OrgMonitoringPod
            OrgMonitoringPod__c orgPod = new OrgMonitoringPod__c();
            String podStatus = ' ';
            orgPod.MasterPod__c = false;
            orgPod.OrgId__c = org.OrgId__c;
            orgPod.OrgName__c = org.OrgName__c;      
            orgPod.Country__c = org.Country__c;
            orgPod.BusinessUnit__c = org.BusinessUnit__c;
            orgPod.Pod__c = org.OrgInstance__c;
            orgPod.Status__c = podstatus;

            if (alreadyCheckedPod(Pods, org.OrgInstance__c)) 
            { 
                podToInsert.add(orgPod); // POD has been already checked
            }   else 
                {  
                    // Make HTTP request to the Salesforce status API
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(apiUrl);
                    request.setMethod('GET');
                    Http http = new Http();
                    HttpResponse response = http.send(request);

                    // Check if the request was successful
                    if (response.getStatusCode() == 200) 
                    {
                        // Parse the response JSON
                        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());                  
                        // Get the availability status
                        podStatus = (String)jsonResponse.get('status');
                        // Insert a new record into OrgMonitoringPod
                        orgPod.MasterPod__c = true;
                        orgPod.Status__c = podstatus;
                        podToInsert.add(orgPod);
                        // system.debug ('Pod Controlé :' + org.OrgInstance__c + ' Org Id : ' + orgPod.OrgId__c + ' Status = ' +podStatus + ' Date : '+ orgPod.Datetime__c  + ' Time : ' +orgPod.Time__c + ' MasterPOd = ' +orgPod.MasterPod__c);
                    } else 
                      {
                         // If request was not successful, return an error message
                         orgPod.Status__c = 'NA';
                         podToInsert.add(orgPod);
                      } 
                }
        }  

        // Method to extract the PODs list for all configured Orgs
        private static List<OrgMonitoring__c> extractPods()
        {
            return [SELECT OrgId__c, OrgName__c, OrgInstance__c, Country__c, BusinessUnit__c FROM OrgMonitoring__c where latest__c = true and Type__c = 'License' and Units__c = 'UserLicense' and Name__c = 'Salesforce'];
        }
    
        // Method to check if a numPOD has already been checked 
        public static Boolean alreadyCheckedPod (Set <String> Pods, String podToCheck)
        {
         if (Pods.contains(podToCheck))
          {
            // system.debug ('Contient : ' +podToCheck);
            return true;
          } else {
                // system.debug ('Ne Contient pas : ' +podToCheck);
                Pods.add(podToCheck);
                return false;
            }
        }
}   