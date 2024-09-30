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
        public String NamespacePrefix {get;set;} 
        public String Name {get;set;} 
    }

    public class ToolingAPIRecords {
        public SubscriberPackage SubscriberPackage {get;set;} 
    }

    // Wrapper Class for Licenses Package 
    public class LicensePackageCollection {
      public Integer totalSize;
      public Boolean done;
      public List<LicensePackageRecords> records;
    }
    public class LicensePackageAttributes {
      public String type;
      public String url;
    }

    public class LicensePackageRecords {
      public LicensePackageAttributes attributes;
      public String NamespacePrefix;
      public Integer AllowedLicenses;
      public Integer UsedLicenses;
      public String Status;
    }

    public static LicensePackageCollection parselicensepackage (String json) {
       return (LicensePackageCollection) System.JSON.deserialize(json, LicensePackageCollection.class);
    }
    
    
    public static List<OrgMonitoring__c> execute(OrgToMonitor__mdt org)
    {
        /* ==========================================================================
                GET INSTALLED PACKAGE
                This code require the "Download AppExchange Packages" permission 
                which is a HUGE one because it allow automatically the Modify All also
           ============================================================================
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
                orgmonitor.Name__c = dta.records[i].SubscriberPackage.Name;
                orgmonitor.Status__c = 'Active';
                orgmonitor.Units__c = dta.records[i].SubscriberPackage.NamespacePrefix;
                orgmonitor.Latest__c = true; 
                lListPackages.add(orgmonitor);
            }          
        }   else {
             String errorMsg = '#### Error code ' + feedResponsePackage.getStatusCode() + ' --> Error reaching endpoint for Package ==> ' + sEndPoint;
             System.debug(errorMsg);
             if(feedResponsePackage.getStatusCode() == 400) {
                errorMsg = ' --> Missing Download AppExchange Packages permission for the user';
            }
             // Prepare for error Message: The error msg is in the field ObsoleteLoginUserList__c
             OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
             
             orgmonitor.OrgName__c = org.DeveloperName;
             orgmonitor.Name__c = 'Error';
             orgmonitor.Latest__c = true;
             orgmonitor.ObsoleteLoginUserList__c = errorMsg;
             lListPackages.add(orgmonitor);
             // Comment the next line in order to continue the process
             // return lListPackages;
            } 
        /* =======================================================================
                         GET INSTALLED PACKAGE WITH LICENSE
                         This code require the "Manage Package Licenses" permission
           =======================================================================
        */    

        system.debug( '#### Processing Packages with licenses ####');
        List<OrgMonitoring__c> lListLicensesPackage = new List<OrgMonitoring__c>();
        sEndPoint = 'callout:' + org.DeveloperName + '/services/data/v' + org.Apiversion__c + '.0/query/?q=SELECT+NamespacePrefix,+AllowedLicenses,+UsedLicenses,+Status+FROM+PackageLicense+where+Status+=+\'Active\'';

        // Get Connexion and Run the EndPoint
        HttpRequest RequestPLicense = new HttpRequest();
        RequestPLicense.setEndpoint(sEndPoint);
        RequestPLicense.setMethod('GET');
        http = new Http();
        HTTPResponse ResponsePLicense = new HTTPResponse();
        if (  Test.isRunningTest() ) {
            ResponsePLicense.setStatusCode( 200 );
            ResponsePLicense.setBody ('{"totalSize":26,"done":true,"records":[ {"attributes":{"type":"PackageLicense","url" : "/services/data/v53.0/sobjects/PackageLicense/050090000019dsEAAQ"},"NamespacePrefix":"FSL","AllowedLicenses": -1,"UsedLicenses":0,"Status":"Active"},{"attributes":{"type":"PackageLicense","url":"/services/data/v53.0/sobjects/PackageLicense/050090000019dsXAAQ"},"NamespacePrefix":"einsteinplay","AllowedLicenses":-1,"UsedLicenses":0,"Status":"Active"} ]}');
        } else { ResponsePLicense = http.send(RequestPLicense);}
      
        while (ResponsePLicense.getStatusCode() == 302) {
            RequestPLicense.setEndpoint(ResponsePLicense.getHeader('Location'));
            ResponsePLicense = new Http().send(RequestPLicense);
        }
        
        if ( ResponsePLicense.getStatusCode() == 200 )
        {
           LicensePackageCollection license = (LicensePackageCollection)JSON.deserialize(ResponsePLicense.getBody(), LicensePackageCollection.class); 
           
           // Remove Package Name from lListPackages list if it exists in Package License 
           removefromlist(lListPackages,license);

           for (integer i=0 ; i < license.records.size() ; i++) {
              OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
              orgmonitor.OrgID__c = org.Org_Id__c;
              orgmonitor.OrgName__c = org.Label;
              orgmonitor.OrgDomainName__c = org.Org_Name__c;
              orgmonitor.Country__c = org.Country__c;
              orgmonitor.BusinessUnit__c = org.Business_Unit__c;
              orgmonitor.Timestamp__c = datetime.now();
              orgmonitor.TimestampText__c = String.valueOf( datetime.now().format('yy-MM-dd HH:mm') );
              orgmonitor.Remaining__c = license.records[i].AllowedLicenses - license.records[i].UsedLicenses;
              orgmonitor.Used__c = license.records[i].UsedLicenses; 
              orgmonitor.Total__c = license.records[i].AllowedLicenses;
              orgmonitor.Type__c = 'Package';
              orgmonitor.Name__c = license.records[i].NamespacePrefix;
              orgmonitor.Status__c = 'Active';
              orgmonitor.Units__c = 'PackageLicense';
              orgmonitor.Latest__c = true; 
              lListPackages.add(orgmonitor);
           }
        } else {
            String errorMsg = '#### Error code ' + ResponsePLicense.getStatusCode() + ' --> Error reaching endpoint for Package Licenses ==> ' + sEndPoint;
            System.debug(errorMsg);
            if(ResponsePLicense.getStatusCode() == 400) {
                errorMsg = ' --> Missing Manage Package Licenses permission for the user';
            }
            // Prepare for error Message: The error msg is in the field ObsoleteLoginUserList__c
            OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
            orgmonitor.OrgName__c = org.DeveloperName;
            orgmonitor.Name__c = 'Error';
            orgmonitor.Latest__c = true;
            orgmonitor.ObsoleteLoginUserList__c = errorMsg;
            lListPackages.add(orgmonitor);
        } 
        return lListPackages;
    }
    
    // This method remove a package record from package extracted list if it exists in the package license list
    Public static void removefromlist (List<OrgMonitoring__c> lListPackages, LicensePackageCollection license )
    {
        for (integer i=0 ; i < license.records.size() ; i++)
        {
            for (integer j=0; j<lListPackages.size(); j++) 
            {
                if (lListPackages[j].Units__c == license.records[i].NamespacePrefix)
                {
                   // Get the name of the package (not the NamespacePrefix)
                   license.records[i].NamespacePrefix = lListPackages[j].Name__c;
                   lListPackages.remove(j);
                   break;
                }
            }
        }
    }    
}