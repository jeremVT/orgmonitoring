/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringPodPurge
History
28/02/2024     Salvatore Aversano    Create version
------------------------------------------------------------*/

@isTest
public with sharing class OrgMonitoringPodPurge_Test {
   
    public static String CRON_EXP = '0 0 0 31 12 ? 2024';

    @isTest
    public static void OrgMonitoringPodPurge_Test() {
        
        Test.startTest();
        OrgMonitoringPod__c om = new OrgMonitoringPod__c (Pod__c = 'TEST', MasterPod__c = true, Status__c = 'OK');
        insert om;
        Database.executeBatch( new OrgMonitoringPodPurge(), 2000 );

        // Schedule the test job
        String jobId = System.schedule('Test class for OrgMonitoringPodPurge', CRON_EXP, new OrgMonitoringPodPurge());
       
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
        NextFireTime
        FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2024-12-31 00:00:00',  String.valueOf(ct.NextFireTime));
        Test.stopTest();

    }
}