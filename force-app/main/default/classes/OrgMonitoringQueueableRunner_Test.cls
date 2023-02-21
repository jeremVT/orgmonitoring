/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringQueueableRunner
History
16/05/2022     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public with sharing class OrgMonitoringQueueableRunner_Test {

    @isTest
    public static void OrgMonitoringQueueableRunner_Test() {
          
        Test.startTest();
        
        System.enqueueJob(new OrgMonitoringQueueableRunner());

        Test.stopTest();

    }
    
}