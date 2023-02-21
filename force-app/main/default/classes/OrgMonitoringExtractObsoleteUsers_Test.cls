/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMoniotoringExtractObsoleteUsers
History
12/05/2022     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public with sharing class OrgMonitoringExtractObsoleteUsers_Test {
 
    @isTest
    public static void OrgMonitoringExtractObsoleteUsers_Test() {
          
        Test.startTest();
        
        OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
        OrgToMonitor__mdt mdt = new OrgToMonitor__mdt();
        mdt.DeveloperName                = 'Playground';
        mdt.Org_Id__c                    = '00Dxxxxxxxxxxxx';
        mdt.Org_Name__c                  = 'Playground';
        mdt.Country__c                   = 'France';
        mdt.Business_Unit__c             = 'B2B';
        mdt.ObsoleteUserDelay__c         = 2;
        mdt.DisplayObsoleteLoginUsers__c = true;
        mdt.apiVersion__c                = '57';

        orgmonitor = OrgMonitoringExtractObsoleteUsers.execute(mdt);

        mdt.DeveloperName                = 'Inexistent_org';
        mdt.DisplayObsoleteLoginUsers__c = false;
        mdt.ObsoleteUserDelay__c         = 0;

        orgmonitor = OrgMonitoringExtractObsoleteUsers.execute(mdt);
        
        Test.stopTest();

    }
    
}