/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to extract the usage of Licenses from following objects:
               - UserLicenses
               - PermissionSetLicenses
               - PackageLicense (-- retired)
Test Class:    OrgMoniotoringExtractLicenses_Test
Version:       1.0
History
10/05/2022     Salvatore Aversano    Create version
----------------------------------------------------------------------------------------*/

public with sharing class OrgMonitoringExtractLicenses 
{
   // Wrapper Class for Licenses User
   public class LicenseCollection 
   {
      public Integer totalSize;
      public Boolean done;
      public List<LicenseRecords> records;
   }
   public class LicenseAttributes {
       public String type;
       public String url;
   }

   public class LicenseRecords {
       public LicenseAttributes attributes;
       public String Status;
       public String MasterLabel;
       public Integer TotalLicenses;
       public Integer UsedLicenses;
   }

   public static LicenseCollection parselicense (String json) {
      return (LicenseCollection) System.JSON.deserialize(json, LicenseCollection.class);
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

   public static List<OrgMonitoring__c> execute (OrgToMonitor__mdt org)
   {
     
      // GET THE DEFAULT PICKLIST VALUE FOR LICENSE CATGORY
      String defaultCategory;
      Schema.DescribeFieldResult F = LicenseList__mdt.LicenseCategory__c.getDescribe();
      List <Schema.PicklistEntry> pickVals = F.getPicklistValues();        
      for (Schema.PicklistEntry pv: pickVals) {
          if (pv.isDefaultValue()) {
            defaultCategory = pv.getValue();
          }    
      }

      List<OrgMonitoring__c> lorgmonitoring = new List<OrgMonitoring__c>();
      List<OrgMonitoring__c> lorgmon = new List<OrgMonitoring__c>();
      
      // GET LICENSES UTILIZATION FROM USER LICENSE OBJECT
      lorgmon = processLicenses(org,defaultCategory);
      lorgmonitoring.addAll(lorgmon);
       
      // GET LICENSES UTILIZATION FROM PERMISSION SET LICENSE
      lorgmon.clear();
      lorgmon = processLicensesfromPset(org,defaultCategory);
      lorgmonitoring.addAll(lorgmon);

      // GET LICENSES UTILIZATION FROM PACKAGE LICENSE
      // SAV : August 22, 200
         // These licences are PER SITE. They are assigned via Permission Set licence. 
         // This extract is not needed ! 
     // lorgmon.clear();
     // lorgmon = processLicensesfromPackage(org,defaultCategory);
     // lorgmonitoring.addAll(lorgmon);

      return lorgmonitoring;
   }   
           
   public static List<OrgMonitoring__c> processLicenses (OrgToMonitor__mdt org, String defaultCategory)
   {
      system.debug( '#### Processing Licenses from User License ####');
   
      /*   =======================================================================
                     GET LICENSES USAGE FROM USER LICENSES OBJECT
        ======================================================================= */

      List<OrgMonitoring__c> lListLicenses = new List<OrgMonitoring__c>();
      String sEndPoint = 'callout:' + org.DeveloperName + '/services/data/v' + org.Apiversion__c + '.0/query/?q=SELECT+Status,+MasterLabel,+TotalLicenses,+UsedLicenses+FROM+UserLicense+where+Status+=+\'Active\'';
            
      // Get Connexion and Run the EndPoint
      HttpRequest feedRequestLicense = new HttpRequest();
      feedRequestLicense.setEndpoint(sEndPoint);
      feedRequestLicense.setMethod('GET');
      Http http = new Http();
      HTTPResponse feedResponseLicense = new HTTPResponse();
        if (  Test.isRunningTest() ) {
         feedResponseLicense.setStatusCode( 200 );
         feedResponseLicense.setBody ('{"totalSize":24,"done":true,"records":[{"attributes":{"type":"UserLicense","url":"/services/data/v53.0/sobjects/UserLicense/1007Q000002DbsLQAS"},"Status":"Active","MasterLabel":"Salesforce Platform","TotalLicenses":3,"UsedLicenses":0},{"attributes":{"type":"UserLicense","url":"/services/data/v53.0/sobjects/UserLicense/1007Q000002DbsKQAS"},"Status":"Active","MasterLabel":"Cloud Integration User","TotalLicenses":1,"UsedLicenses":0} ]}');
        } else { feedResponseLicense = http.send(feedRequestLicense);}
      
        while (feedResponseLicense.getStatusCode() == 302) {
            feedRequestLicense.setEndpoint(feedResponseLicense.getHeader('Location'));
            feedResponseLicense = new Http().send(feedRequestLicense);
      }
        
      if ( feedResponseLicense.getStatusCode() == 200 )
      {
         LicenseCollection license = (LicenseCollection)JSON.deserialize(feedResponseLicense.getBody(), LicenseCollection.class); 
         
         for (integer i=0 ; i < license.records.size() ; i++) {
           
            OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
            orgmonitor.OrgID__c = org.Org_Id__c;
            orgmonitor.OrgName__c = org.Label;
            orgmonitor.OrgDomainName__c = org.Org_Name__c;
            orgmonitor.Country__c = org.Country__c;
            orgmonitor.BusinessUnit__c = org.Business_Unit__c;
            orgmonitor.Timestamp__c = datetime.now();
            orgmonitor.TimestampText__c = String.valueOf( datetime.now().format('yy-MM-dd HH:mm') );
            orgmonitor.Type__c = 'License';
            orgmonitor.Name__c = license.records[i].MasterLabel;
            orgmonitor.TranslatedLicenseName__c = license.records[i].MasterLabel;
            orgmonitor.LicenseCategory__c = defaultCategory;
            orgmonitor.Total__c = license.records[i].TotalLicenses;
            orgmonitor.Used__c = license.records[i].UsedLicenses;
            orgmonitor.Remaining__c = license.records[i].TotalLicenses - license.records[i].UsedLicenses;
            orgmonitor.Status__c = license.records[i].Status;
            orgmonitor.Units__c = 'UserLicense';
            orgmonitor.Latest__c = true;
            String LicenseDeveloperName = getLicenseDeveloperName(orgmonitor.Name__c);
            LicenseList__mdt tln = LicenseList__mdt.getInstance(LicenseDeveloperName );
            if (tln != null) {
                 orgmonitor.TranslatedLicenseName__c = tln.TranslatedLicenseName__c;
                 orgmonitor.LicenseCategory__c = tln.LicenseCategory__c;
            }

            // When license name is Salesforce, then store the value of organization created date
            if (orgmonitor.Name__c == 'Salesforce') {
               orgmonitor.OrgCreatedDate__c = org.OrgCreatedDate__c;
            }
            
            lListLicenses.add(orgmonitor);
         }
      } else {
          System.debug ('#### Error reaching endpoint for Licenses ==> ' +sEndPoint);
          System.debug ('#### Error code ==> ' +feedResponseLicense.getStatusCode());
         } 
      return lListLicenses;
    }
    
    public static List<OrgMonitoring__c> processLicensesfromPset (OrgToMonitor__mdt org, String defaultCategory)
    {
        /* =======================================================================
                        GET LICENSES USAGE FROM PERMISSION SET LICENSE
           =======================================================================
        */
        
        system.debug( '#### Processing Licenses from Permission Set Licenses ####');
        List<OrgMonitoring__c> lListLicensesPset = new List<OrgMonitoring__c>();
        String sEndPoint = 'callout:' + org.DeveloperName + '/services/data/v' + org.Apiversion__c + '.0/query/?q=SELECT+Status,+MasterLabel,+TotalLicenses,+UsedLicenses+FROM+PermissionSetLicense+where+Status+=+\'Active\'';
        
        // Get Connexion and Run the EndPoint
        HttpRequest feedRequestLicense = new HttpRequest();
        feedRequestLicense.setEndpoint(sEndPoint);
        feedRequestLicense.setMethod('GET');
        Http http = new Http();
        HTTPResponse feedResponseLicense = new HTTPResponse();
        if (  Test.isRunningTest() ) {
         feedResponseLicense.setStatusCode( 200 );
         feedResponseLicense.setBody ('{"totalSize":24,"done":true,"records":[{"attributes":{"type":"UserLicense","url":"/services/data/v53.0/sobjects/UserLicense/1007Q000002DbsLQAS"},"Status":"Active","MasterLabel":"Salesforce Platform","TotalLicenses":3,"UsedLicenses":0},{"attributes":{"type":"UserLicense","url":"/services/data/v53.0/sobjects/UserLicense/1007Q000002DbsKQAS"},"Status":"Active","MasterLabel":"Cloud Integration User","TotalLicenses":1,"UsedLicenses":0} ]}');
        } else { feedResponseLicense = http.send(feedRequestLicense);}
      
        while (feedResponseLicense.getStatusCode() == 302) {
            feedRequestLicense.setEndpoint(feedResponseLicense.getHeader('Location'));
            feedResponseLicense = new Http().send(feedRequestLicense);
      }
        
        if ( feedResponseLicense.getStatusCode() == 200 )
        {
           LicenseCollection license = (LicenseCollection)JSON.deserialize(feedResponseLicense.getBody(), LicenseCollection.class); 
           
           for (integer i=0 ; i < license.records.size() ; i++) {
              // system.debug( 'lListLicensesPset: ' +license.records[i].MasterLabel);
              OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
              orgmonitor.OrgID__c = org.Org_Id__c;
              orgmonitor.OrgName__c = org.Label;
              orgmonitor.OrgDomainName__c = org.Org_Name__c;
              orgmonitor.Country__c = org.Country__c;
              orgmonitor.BusinessUnit__c = org.Business_Unit__c;
              orgmonitor.Timestamp__c = datetime.now();
              orgmonitor.TimestampText__c = String.valueOf( datetime.now().format('yy-MM-dd HH:mm') );
              orgmonitor.Type__c = 'License';
              orgmonitor.Name__c = license.records[i].MasterLabel;
              orgmonitor.TranslatedLicenseName__c = license.records[i].MasterLabel;
              orgmonitor.LicenseCategory__c = defaultCategory;
              orgmonitor.Total__c = license.records[i].TotalLicenses;
              orgmonitor.Used__c = license.records[i].UsedLicenses;
              orgmonitor.Remaining__c = license.records[i].TotalLicenses - license.records[i].UsedLicenses;
              orgmonitor.Status__c = license.records[i].Status;
              orgmonitor.Units__c = 'PsetLicense';
              orgmonitor.Latest__c = true;
              String LicenseDeveloperName = getLicenseDeveloperName(orgmonitor.Name__c);
              LicenseList__mdt tln = LicenseList__mdt.getInstance(LicenseDeveloperName);
              if (tln != null) {
                 orgmonitor.TranslatedLicenseName__c = tln.TranslatedLicenseName__c;
                 orgmonitor.LicenseCategory__c = tln.LicenseCategory__c;
              }
              lListLicensesPset.add(orgmonitor);
           }
        } else {
            System.debug ('#### Error reaching endpoint for Permission Set Licenses ==> ' +sEndPoint);
            System.debug ('#### Error code ==> ' +feedResponseLicense.getStatusCode());
           } 
        return lListLicensesPset;
    }
    
   public static String getLicenseDeveloperName (String LicenseName)
   {
   // Transform LicenseName into a DeveloperName in order to fetch the value in MDT
    
   // Remplace tous les caractères non alphanumériques par des tirets bas
      String LicenseDeveloperName = LicenseName.replaceAll('[^a-zA-Z0-9]+', '_');
   // Si le nom de LicenseDeveloperName commence par un chiffre, ajoute un préfixe de caractère "X_"
      Matcher m = Pattern.compile('^[0-9]').matcher(LicenseDeveloperName); 
      if (m.find()) {
         LicenseDeveloperName = 'X' + LicenseDeveloperName;
      }
   // Tronque le nom de développeur à 40 caractères maximum
      LicenseDeveloperName = LicenseDeveloperName.substring(0, Math.min(LicenseDeveloperName.length(), 40));
      system.debug ('LicenseName : ' + LicenseName + '  LicenseDeveloperName: ' + LicenseDeveloperName);
   
      return LicenseDeveloperName;
   }

}