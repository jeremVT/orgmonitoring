/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringPodPurge
History
11/04/2024     Salvatore Aversano    Create version
------------------------------------------------------------*/

@isTest
private class OrgMonitoringPodPurge_Test {
    // Test method to cover the start method
    @isTest
    static void testStart() {
        // Insert test data
        OrgMonitoringPod__c testRecord = new OrgMonitoringPod__c(Pod__c = 'Test Pod', Status__c = 'OK', Masterpod__c = true);
        insert testRecord;

        // Call the start method
        Test.startTest();
        Database.QueryLocator queryLocator = new OrgMonitoringPodPurge().start(null);
        Test.stopTest();
        
        // Assert that the query locator is not null
        System.assertNotEquals(null, queryLocator, 'Query locator should not be null');
    }

    // Test method to cover the execute method
    @isTest
    static void testExecute() {
        // Insert test data
        OrgMonitoringPod__c testRecord = new OrgMonitoringPod__c(Pod__c = 'Test Pod', Status__c = 'OK', Masterpod__c = true);
        insert testRecord;

        // Call the execute method
        Test.startTest();
        new OrgMonitoringPodPurge().execute(null, new List<OrgMonitoringPod__c>{testRecord});
        Test.stopTest();
        
        // Verify that the test record has been deleted
        List<OrgMonitoringPod__c> remainingRecords = [SELECT Id FROM OrgMonitoringPod__c WHERE Id = :testRecord.Id];
        System.assertEquals(0, remainingRecords.size(), 'Test record should have been deleted');

    }

    // Test method to cover the finish method
    @isTest
    static void testFinish() {
        // Insert test data
        OrgMonitoringPodHistory__c testHistoryRecord = new OrgMonitoringPodHistory__c(Pod__c = 'Test Pod', Month__c = 'April', Year__c = String.valueOf(Date.today().year()), nbOK__c = 1, nbKO__c = 0, Availability__c = 100);
        insert testHistoryRecord;

        // Call the finish method
        Test.startTest();
        new OrgMonitoringPodPurge().finish(null);
        Test.stopTest();
        
        // Verify that historical records have been inserted
        List<OrgMonitoringPodHistory__c> insertedHistoryRecords = [SELECT Id FROM OrgMonitoringPodHistory__c WHERE Id = :testHistoryRecord.Id];
        System.assertNotEquals(0, insertedHistoryRecords.size(), 'Historical records should have been inserted');

    }

    // Test method to cover the execute method when called by the scheduler
    @isTest
    static void testExecuteScheduler() {
        
        String CRON_EXP = '0 0 0 31 12 ? 2029';

        // Insert test data
        OrgMonitoringPod__c testRecord = new OrgMonitoringPod__c(Pod__c = 'Test Pod', Status__c = 'OK', Masterpod__c = true);
        insert testRecord;
        
        Test.startTest();
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
        System.assertEquals('2029-12-31 00:00:00',  String.valueOf(ct.NextFireTime));
        
        Test.stopTest();
        
    }
}