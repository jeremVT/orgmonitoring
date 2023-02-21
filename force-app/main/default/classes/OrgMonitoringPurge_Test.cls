/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringPurge
History
12/05/2022     Salvatore Aversano    Create version
------------------------------------------------------------*/

@isTest
public with sharing class OrgMonitoringPurge_Test {

    @isTest
    public static void OrgMonitoringPurge_Test() {

        Test.startTest();
        OrgMonitoring__c om = new OrgMonitoring__c (Latest__c = true);
        insert om;
        Database.executeBatch( new OrgMonitoringPurge(), 2000 );
        Test.stopTest();

    }
    
}