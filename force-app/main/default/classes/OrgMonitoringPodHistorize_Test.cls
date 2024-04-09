/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMoniotoringPodHistorize
History
09/04/2024     Salvatore Aversano    Create version
------------------------------------------------------------*/
@isTest
public class OrgMonitoringPodHistorize_Test {
    @isTest
    static void testProcessScope() {
        // Create test data
        List<OrgMonitoringPod__c> scope = new List<OrgMonitoringPod__c>();
        OrgMonitoringPod__c pod1 = new OrgMonitoringPod__c();
        pod1.Pod__c = 'TestPod1';
        pod1.CreatedDate = Date.today();
        pod1.status__c = 'OK';
        pod1.masterpod__c = true;
        scope.add(pod1);

        OrgMonitoringPod__c pod2 = new OrgMonitoringPod__c();
        pod2.Pod__c = 'TestPod2';
        pod2.CreatedDate = Date.today();
        pod2.status__c = 'KO';
        pod2.masterpod__c = true;
        scope.add(pod2);

        // Call the method under test
        Test.startTest();
        OrgMonitoringPodHistorize.processScope(scope);
        Test.stopTest();

        // Query the historized records and assert the results
        List<OrgMonitoringPodHistory__c> histPods = [SELECT Pod__c, Month__c, Year__c, nbOK__c, nbKO__c, Availability__c FROM OrgMonitoringPodHistory__c];
        System.assertEquals(2, histPods.size(), 'Number of historized records should be 2');

        OrgMonitoringPodHistory__c histPod = histPods[0];
        System.assertEquals('TestPod1', histPod.Pod__c, 'Pod assert error');
        Datetime today = Date.today();
        System.assertEquals(today.format('MMMM'), histPod.Month__c,'Month assert error');
        System.assertEquals(String.valueOf(Date.today().year()), histPod.Year__c, 'Year assert error');
        System.assertEquals(1, histPod.nbOK__c, 'nbOK assert error');
        System.assertEquals(100.0000, histPod.Availability__c, 'Availability assert error');
    }
}
