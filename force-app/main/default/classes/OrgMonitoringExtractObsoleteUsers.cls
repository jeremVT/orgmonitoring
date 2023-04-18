/*----------------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to extract the number of users not logged in since a 
               parametrized days in the CMT OrgToMonitor
Test Class:    OrgMonitoringExtractObsoleteUsers_Test
Version:       1.0
History
               10/05/2022     Salvatore Aversano    Create version
-----------------------------------------------------------------------------------------------*/
   


public with sharing class OrgMonitoringExtractObsoleteUsers {
    
    // Wrapper Class for Obsolete Logins
    public class JSONObsoleteUsersQuery {

        public Integer totalSize;
        public Boolean done;
        public List<Records> records;
    }
    public class Attributes {
        public String type;
        public String url;
    }
    
    public class Records {
        public Attributes attributes;
        public String Id;
    }
        
    public static JSONObsoleteUsersQuery parse(String json) {
        return (JSONObsoleteUsersQuery) System.JSON.deserialize(json, JSONObsoleteUsersQuery.class);
    }

    public static boolean checkNamedCredential(String namedCredential) {
        try
        {
            NamedCredential namedCred = [SELECT Endpoint FROM NamedCredential WHERE DeveloperName = :namedCredential LIMIT 1];
        }   catch (Exception ex)
            {
              return false;  
             }
        return true;
      }

    public static OrgMonitoring__c execute (OrgToMonitor__mdt org)
    {
        /* =======================================================================
                GET USERS NOT LOGGED SINCE MORE THAN X TIME OR NEVER LOGGED IN
                         ONLY FOR USERS WITH Salesforce LICENSE.
           =======================================================================
        */
        
        // Get limit date of last login
        datetime dt = system.today().addDays( -Integer.valueOf( org.ObsoleteUserDelay__c ) );
        String d = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        OrgMonitoring__c orgmonitor = new OrgMonitoring__c(); 

        system.debug ('#### Processing Org: ' + org.DeveloperName +  ' Obsolete users not logged-in since: ' + d);

        // Check if Named credential exists 
        if(!checkNamedCredential (org.DeveloperName) ) {
            String errorMsg = '#### Named Credential ' + org.DeveloperName + ' has not been added in configuration';
            System.debug(errorMsg);
            // Prepare for error Message: The error msg is in the field ObsoleteLoginUserList__c
            orgmonitor.OrgName__c = org.DeveloperName;
            orgmonitor.Name__c = 'Error';
            orgmonitor.Latest__c = true;
            orgmonitor.ObsoleteLoginUserList__c = errorMsg;
            return orgmonitor;
        }
       
        // Prepare EndPoint 
        String sEndPoint = 'callout:' + org.DeveloperName + '/services/data/v' + org.Apiversion__c + '.0/query?q=SELECT+Id+FROM+User+WHERE+(LastLoginDate+<+' +d + '+OR+LastLoginDate+=+NULL)+and+IsActive+=+true+and+UserType+=+\'Standard\'+and+Profile.UserLicense.Name+=+\'Salesforce\'';
        sEndPoint = sEndPoint.replace('<','%3C');
        
        // Get Connexion and Run the EndPoint
        HttpRequest feedRequestUsers = new HttpRequest();
        feedRequestUsers.setEndpoint(sEndPoint);
        feedRequestUsers.setMethod('GET');
        Http http = new Http();
        HTTPResponse feedResponseUser = new HTTPResponse();
        
        if (  Test.isRunningTest() ) {
              feedResponseUser.setStatusCode( 200 );
              feedResponseUser.setBody('{"totalSize" : 1, "done" : true, "records" : [ { "attributes" : { "type" : "User", "url" : "/services/data/v53.0/sobjects/User/0057Q000003aUpqQAE" }, "Id" : "0057Q000003aUpqQAE" } ]}');
        } else 
        { 
            try {
              feedResponseUser = http.send(feedRequestUsers);
            } catch(System.UnexpectedException ex)
            {
                system.debug('Unexpected Exception in Obsolete User Class : ' + ex.getMessage());
                return null;
            }
        }
       
        while (feedResponseUser.getStatusCode() == 302) {
              feedRequestUsers.setEndpoint(feedResponseUser.getHeader('Location'));
              feedResponseUser = new Http().send(feedRequestUsers);
          }
        
          
          if ( feedResponseUser.getStatusCode() == 200 )
          {
            // system.debug( '#### Processing Obsolete Users ####');

                      
            orgmonitor.OrgID__c = org.Org_Id__c;
            orgmonitor.OrgName__c = org.Label;
        
            orgmonitor.OrgDomainName__c = org.Org_Name__c;
            orgmonitor.Country__c = org.Country__c;
            orgmonitor.BusinessUnit__c = org.Business_Unit__c;
            orgmonitor.Timestamp__c = datetime.now();
            orgmonitor.TimestampText__c = String.valueOf( datetime.now().format('yy-MM-dd HH:mm') );
            orgmonitor.Type__c = 'Users';
            orgmonitor.Name__c = 'Obsolete Logins';
            orgmonitor.Units__c = 'Unit';
            orgmonitor.Status__c = 'Active';
            orgmonitor.Latest__c = true;

            JSONObsoleteUsersQuery obsoleteUsers = (JSONObsoleteUsersQuery)JSON.deserialize(feedResponseUser.getBody(), JSONObsoleteUsersQuery.class);
            orgmonitor.Total__c = obsoleteUsers.records.size();
            system.debug( '#### There are ' + orgmonitor.Total__c + ' Obsolete Users on ' + org.DeveloperName + ' ####');
                
            //GET OBSOLETE USERS LIST ONLY IF REQUESTED IN CONFIGURATION
            if ( org.DisplayObsoleteLoginUsers__c  ) {
                String sObsoleteLoginUsers = '';
                for (integer i=0 ; i < obsoleteUsers.records.size() ; i++) 
                { 
                    String sUserId = obsoleteUsers.records[i].Id;
                    if ( sObsoleteLoginUsers == '' ) 
                    {
                        sObsoleteLoginUsers = sUserId;
                    } else {
                        sObsoleteLoginUsers += ',' + sUserId;
                    }
                }
                orgmonitor.ObsoleteLoginUserList__c = sObsoleteLoginUsers;
                orgmonitor.Total__c=obsoleteUsers.records.size();
              }       
            } else {
                String errorMsg = '#### Error code ' + feedResponseUser.getStatusCode() + ' --> Error reaching endpoint for Obsolete Users ==> ' + sEndPoint;
                System.debug(errorMsg);
                // Prepare for error Message: The error msg is in the field ObsoleteLoginUserList__c
                orgmonitor.OrgName__c = org.DeveloperName;
                orgmonitor.Name__c = 'Error';
                orgmonitor.Latest__c = true;
                orgmonitor.ObsoleteLoginUserList__c = errorMsg;
                return orgmonitor;
               } 
            return orgmonitor; 
        }
}
