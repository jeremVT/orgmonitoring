/*------------------------------------------------------------
Author:         Salvatore Aversano
Company:        Salesforce.com
Description:    Test Class
Test Class for  OrgMonitoringPodAvailabilityChecker
History
28/02/2024     Salvatore Aversano    Create version
------------------------------------------------------------*/

@isTest
public with sharing class OrgMonitoringPodAvailabilityChecker_Test 
{
    // Mock callout implementation to simulate the callout response
    public class MockHttpResponseGenerator implements HttpCalloutMock
    {
        public HTTPResponse respond(HTTPRequest req) 
        {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"mockResponse": {"key":"EU17","location":"EMEA","environment":"production","releaseVersion":"Spring Patch 10.7","releaseNumber":"248.10.7","status":"OK"}}');
            return res;
        }
    }
    
    @isTest
    static void OrgMonitoringPodAvailabilityChecker_Test() {
        Test.startTest();
        // Schedule the job
        String schedule = '0 0 0 15 3 ? 2029'; // Every day at midnight on March 15, 2029
        String jobId = System.schedule('Test Job', schedule, new OrgMonitoringPodAvailabilityChecker());
        Test.stopTest();
        
        // Verify that the job has been scheduled
        System.assertNotEquals(null, jobId, 'Job should be scheduled');
    }
    @isTest
    static void testExecute() {
        // Instantiate the schedulable class directly to test execute method
        
        Test.startTest();
        // Prepare Data record 1
        OrgMonitoring__c om = new OrgMonitoring__c();
        om.OrgId__c = '00D123456789012';
        om.OrgName__c = 'Test';
        om.OrgInstance__c = 'EU40';
        om.Country__c = 'France';
        om.BusinessUnit__c = 'B2B';
        om.latest__c = true;
        om.Type__c = 'License';
        om.Units__c = 'UserLicense';
        om.Name__c = 'Salesforce';
        insert om;
        // 2repare Data record 2
        OrgMonitoring__c om2 = new OrgMonitoring__c();
        om2.OrgId__c = '00D123456789013';
        om2.OrgName__c = 'Test';
        om2.OrgInstance__c = 'EU40';
        om2.Country__c = 'France';
        om2.BusinessUnit__c = 'B2B';
        om2.latest__c = true;
        om2.Type__c = 'License';
        om2.Units__c = 'UserLicense';
        om2.Name__c = 'Salesforce';
        insert om2;
        // Prepare Data record 3
        OrgMonitoring__c om3 = new OrgMonitoring__c();
        om3.OrgId__c = '00D123456789014';
        om3.OrgName__c = 'Test';
        om3.OrgInstance__c = 'XYZ';
        om3.Country__c = 'France';
        om3.BusinessUnit__c = 'B2B';
        om3.latest__c = true;
        om3.Type__c = 'License';
        om3.Units__c = 'UserLicense';
        om3.Name__c = 'Salesforce';
        insert om3;
       
        
        // Set the mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        OrgMonitoringPodAvailabilityChecker myScheduledInstance = new OrgMonitoringPodAvailabilityChecker();
        // Call the execute method directly
        myScheduledInstance.execute(null);
        Test.stopTest();
        
        // Add assertions for the logic within the execute method if applicable
        // Example:
        // System.assertEquals(expectedResult, actualResult, 'Message describing assertion');
    }
}