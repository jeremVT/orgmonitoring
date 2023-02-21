/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringQueueableRunner
History
17/02/2023     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public with sharing class OrgMonitoringSendMailOnError_Test {
    
    @isTest
    public static void OrgMonitoringSendMailOnError_Test() {
        
       
        Test.startTest();
        String errorMsg = 'This is a test for the Test class';
        OrgMonitoringSendMailOnError.sendEmail (errorMsg);
        Test.stopTest();

    }
}