/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to extract installed packages
Test Class:    OrgMoniotoringExtractPackages_Test
Version:       1.0
History
10/05/2022     Salvatore Aversano    Create version
----------------------------------------------------------------------------------------*/
public with sharing class OrgMonitoringExtractPackages 
{
     // Wrapper Class for Packages
     public class DataToolingAPI {
        public List<ToolingAPIRecords> records {get;set;} 
    }

    public class SubscriberPackage {
        public String Name {get;set;} 
    }

    public class ToolingAPIRecords {
        public SubscriberPackage SubscriberPackage {get;set;} 
    }

    public static List<OrgMonitoring__c> execute(OrgToMonitor__mdt org)
    {
        /* =======================================================================
                                 GET INSTALLED PACKAGE
           =======================================================================
        */
        
        system.debug( '#### Processing Packages ####');
        List<OrgMonitoring__c> lListPackages = new List<OrgMonitoring__c>();
        String sEndPoint = 'callout:' + org.DeveloperName + '/services/data/v' + org.Apiversion__c + '.0/tooling/query/?q=SELECT+SubscriberPackage.NamespacePrefix,+SubscriberPackage.Name+FROM+InstalledSubscriberPackage';
        
        // Get Connexion and Run the EndPoint
        HttpRequest feedRequestPackage = new HttpRequest();
        feedRequestPackage.setEndpoint(sEndPoint);
        feedRequestPackage.setMethod('GET');
        Http http = new Http();
        HTTPResponse feedResponsePackage = new HTTPResponse();
        if (  Test.isRunningTest() ) {
            feedResponsePackage.setStatusCode( 200 );
            feedResponsePackage.setBody('{ "size" : 1, "totalSize" : 1, "done" : true, "queryLocator" : null, "entityTypeName" : "InstalledSubscriberPackage", "records" : [ {"attributes" : { "type" : "InstalledSubscriberPackage", "url" : "/services/data/v53.0/tooling/sobjects/InstalledSubscriberPackage/0A37Q000000TcO7SAK" }, "SubscriberPackage" : { "attributes" : { "type" : "SubscriberPackage", "url" : "/services/data/v53.0/tooling/sobjects/SubscriberPackage/03330000000wDAbAAM"}, "NamespacePrefix" : "sf_com_apps",  "Name" : "Salesforce Connected Apps" } } ]}');
        } else { feedResponsePackage = http.send(feedRequestPackage);}
       
        while (feedResponsePackage.getStatusCode() == 302) {
            feedRequestPackage.setEndpoint(feedResponsePackage.getHeader('Location'));
            feedResponsePackage = new Http().send(feedRequestPackage);
        }
        
        if ( feedResponsePackage.getStatusCode() == 200 )
        {
            DataToolingAPI dta = (DataToolingAPI)JSON.deserialize(feedResponsePackage.getBody(), DataToolingAPI.class);
            for (integer i=0 ; i < dta.records.size() ; i++)
            {
                String sPackageName = dta.records[i].SubscriberPackage.Name;
                OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
                orgmonitor.OrgID__c = org.Org_Id__c;
                orgmonitor.OrgName__c = org.Label;
                orgmonitor.OrgDomainName__c = org.Org_Name__c;
                orgmonitor.Country__c = org.Country__c;
                orgmonitor.BusinessUnit__c = org.Business_Unit__c;
                orgmonitor.Timestamp__c = datetime.now();
                orgmonitor.TimestampText__c = String.valueOf( datetime.now().format('yy-MM-dd HH:mm') );
                orgmonitor.Remaining__c = 0;
                orgmonitor.Used__c = 0; 
                orgmonitor.Total__c = 0;
                orgmonitor.Type__c = 'Package';
                orgmonitor.Name__c = sPackageName;
                orgmonitor.Status__c = 'Active';
                orgmonitor.Units__c = 'Unit';
                orgmonitor.Latest__c = true; 
                lListPackages.add(orgmonitor);
            }          
        }   else {
             String errorMsg = '#### Error code ' + feedResponsePackage.getStatusCode() + ' --> Error reaching endpoint for Package ==> ' + sEndPoint;
             System.debug(errorMsg);
            
             // Prepare for error Message: The error msg is in the field ObsoleteLoginUserList__c
             OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
             
             orgmonitor.OrgName__c = org.DeveloperName;
             orgmonitor.Name__c = 'Error';
             orgmonitor.Latest__c = true;
             orgmonitor.ObsoleteLoginUserList__c = errorMsg;
             lListPackages.add(orgmonitor);
             return lListPackages;
            } 
            
        return lListPackages;
    }
}