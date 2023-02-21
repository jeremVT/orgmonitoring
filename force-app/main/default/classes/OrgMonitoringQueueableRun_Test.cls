/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringQueueableRun
History
27/10/2022     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public with sharing class OrgMonitoringQueueableRun_Test
{
    @isTest
    public static void OrgMonitoringQueueableRun_Test() {        
       
        Test.startTest();
       
         OrgMonitoring__c om = new OrgMonitoring__c (Latest__c = true);
         insert om;
         List<String> orgs = new List<String>{};
         OrgMonitoringQueueableRun.oldRecords(orgs);
         orgs.add('Playground');
         OrgMonitoringQueueableRun.oldRecords(orgs);
         
         OrgToMonitor__mdt mdt = new OrgToMonitor__mdt();
         mdt.DeveloperName                = 'Playground' ;
         mdt.Org_Id__c                    = '00Dxxxxxxxxxxx';
         mdt.Org_Name__c                  = 'Playground';
         mdt.OrgCreatedDate__c            =  System.today();
         mdt.Country__c                   = 'France';
         mdt.Business_Unit__c             = 'B2B';
         mdt.ObsoleteUserDelay__c         = 2;
         mdt.DisplayObsoleteLoginUsers__c = true;
         mdt.apiVersion__c                = '54';
             
        
        OrgMonitoringQueueableRun.processRecords(mdt);
        Test.stopTest();

    }  
}