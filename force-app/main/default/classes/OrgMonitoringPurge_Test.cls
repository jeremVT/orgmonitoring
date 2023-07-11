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
   
    public static String CRON_EXP = '0 0 0 31 12 ? 2023';

    @isTest
    public static void OrgMonitoringPurge_Test() {

        Test.startTest();
        OrgMonitoring__c om = new OrgMonitoring__c (Latest__c = true);
        insert om;
        Database.executeBatch( new OrgMonitoringPurge(), 2000 );

        // Schedule the test job
        String jobId = System.schedule('Test class for OrgMonitoringPurge', CRON_EXP, new OrgMonitoringPurge());
       
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
        NextFireTime
        FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2023-12-31 00:00:00', 
        String.valueOf(ct.NextFireTime));
        Test.stopTest();

    }
public void execute (SchedulableContext context) {
    // Implement the execute method of the Schedulable interface
    // This method will be called by the test method
    } 
}