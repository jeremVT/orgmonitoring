/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringQueueable
History
16/05/2022     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public with sharing class OrgMonitoringQueueable_Test {

    @isTest
    public static void OrgMonitoringQueueable_Test() {
        
       
        Test.startTest();
       
        List<OrgToMonitor__mdt> lorgs = new List<OrgToMonitor__mdt>();
        for (integer i=0 ; i < 11 ; i++) 
        {
         OrgToMonitor__mdt mdt = new OrgToMonitor__mdt();
         mdt.DeveloperName                = 'TEST-' +i ;
         mdt.Org_Id__c                    = '00Dxxxxxxxxxxx' +i;
         mdt.Org_Name__c                  = 'TEST-ORG';
         mdt.OrgCreatedDate__c            =  System.today();
         mdt.Country__c                   = 'France';
         mdt.Business_Unit__c             = 'B2B';
         mdt.ObsoleteUserDelay__c         = 2;
         mdt.DisplayObsoleteLoginUsers__c = true;
         mdt.apiVersion__c                = '56';
         lorgs.add(mdt);
        }      
        OrgMonitoring__c om = new OrgMonitoring__c (Latest__c = true, Name__c = 'Error', ObsoleteLoginUserList__c = 'Error Message');
        insert om;

        System.enqueueJob(new OrgMonitoringQueueable(lorgs));
        Test.stopTest();

    }
    
}