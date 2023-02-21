/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMoniotoringExtractLicense
History
16/05/2022     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public with sharing class OrgMonitoringExtractLicenses_Test {

    @isTest
    public static void OrgMonitoringExtractLicenses_Test() {
          
        Test.startTest();
        
        List<OrgMonitoring__c> lorgmonitoring = new List<OrgMonitoring__c>();
        OrgToMonitor__mdt mdt = new OrgToMonitor__mdt();
        mdt.DeveloperName                = 'Playground';
        mdt.Org_Id__c                    = '00Dxxxxxxxxxxxx';
        mdt.Org_Name__c                  = 'Playground';
        mdt.Country__c                   = 'France';
        mdt.Business_Unit__c             = 'B2B';
        mdt.ObsoleteUserDelay__c         = 2;
        mdt.DisplayObsoleteLoginUsers__c = true;
        mdt.apiVersion__c                = '54';

        lorgmonitoring = OrgMonitoringExtractLicenses.execute(mdt);

        Test.stopTest();

    }
    
}