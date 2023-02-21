/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMoniotoringExtractPackages
History
12/05/2022     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public with sharing class OrgMonitoringExtractPackages_Test {

    @isTest
    public static void OrgMonitoringExtractPackages_Test() {
          
        Test.startTest();
        
        List<OrgMonitoring__c> lorgmonitoring = new List<OrgMonitoring__c>();
        OrgToMonitor__mdt mdt = new OrgToMonitor__mdt();
        mdt.DeveloperName                = 'TEST';
        mdt.Org_Id__c                    = '00Dxxxxxxxxxxxx';
        mdt.Org_Name__c                  = 'TEST ORG';
        mdt.Country__c                   = 'France';
        mdt.Business_Unit__c             = 'B2B';
        mdt.ObsoleteUserDelay__c         = 2;
        mdt.DisplayObsoleteLoginUsers__c = true;
        mdt.apiVersion__c                = '54';

        lorgmonitoring = OrgMonitoringExtractPackages.execute(mdt);

        Test.stopTest();

    }
    
}