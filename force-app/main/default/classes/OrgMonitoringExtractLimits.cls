/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to extract limits
Test Class:    OrgMoniotoringExtractLimits_Test
Version:       1.0
History
10/05/2022     Salvatore Aversano    Create version
----------------------------------------------------------------------------------------*/
public with sharing class OrgMonitoringExtractLimits {
    // Wrapper Class form Limits
    public class LimitCollection {
        public Integer Max;
        public Integer Remaining;
    }
    
    public static List<OrgMonitoring__c> execute(OrgToMonitor__mdt org)
    {    
        /* =======================================================================
                                       GET LIMITS
           =======================================================================
        */
        system.debug( '#### Processing Limits ####');
        List<OrgMonitoring__c> lListLimits = new List<OrgMonitoring__c>();
        List<String> lLimits = new list<String>();
        Integer iDataStorage = 0;

        lLimits.add('ConcurrentAsyncGetReportInstances');
        lLimits.add('ConcurrentSyncReportRuns');
        lLimits.add('DailyApiRequests');
        lLimits.add('DailyAsyncApexExecutions');
        lLimits.add('DailyBulkApiBatches');
        lLimits.add('DailyWorkflowEmails');    
        lLimits.add('HourlyAsyncReportRuns');
        lLimits.add('HourlyDashboardRefreshes');
        lLimits.add('HourlyDashboardResults');
        lLimits.add('HourlyDashboardStatuses');
        lLimits.add('MassEmail');
        lLimits.add('SingleEmail');
        lLimits.add('DataStorageMB'); // It is extracted only if the user running the program has right to
        lLimits.add('FileStorageMB'); // It is extracted only if the user running the program has right to
        
        String sEndPoint = 'callout:' + org.DeveloperName + '/services/data/v' + org.Apiversion__c + '.0/limits';
        
        // Get Connexion and Run the EndPointx
        HttpRequest feedRequestLimits = new HttpRequest();
        feedRequestLimits.setEndpoint(sEndPoint);
        feedRequestLimits.setMethod('GET');
        Http http = new Http();
        HTTPResponse feedResponseLimits = new HTTPResponse();
        if (  Test.isRunningTest() ) {
            feedResponseLimits.setStatusCode( 200 );
            feedResponseLimits.setBody ('{"ConcurrentAsyncGetReportInstances":{"Max":200,"Remaining":200},"ConcurrentSyncReportRuns":{"Max":20,"Remaining":20},"DailyApiRequests":{"Max":15000,"Remaining":14772  },"DailyAsyncApexExecutions":{"Max":250000,"Remaining":250000},"DailyBulkApiBatches":{"Max":15000,"Remaining":15000},"Ant Migration Tool":{"Max":0,"Remaining":0},"DailyWorkflowEmails":{"Max":1890,"Remaining":1890},"DataStorageMB":{"Max":5,"Remaining":4},"FileStorageMB":{"Max":20,"Remaining":20},"HourlyAsyncReportRuns":{"Max":1200,"Remaining":1200},"HourlyDashboardRefreshes":{"Max":200,"Remaining":200},"HourlyDashboardResults":{"Max":5000,"Remaining":5000},"HourlyDashboardStatuses":{"Max":999999999,"Remaining":999999999},"MassEmail":{"Max":10,"Remaining":10},"SingleEmail":{"Max":15,"Remaining":15}}' );
        } else { feedResponseLimits = http.send(feedRequestLimits);}

        while (feedResponseLimits.getStatusCode() == 302) {
            feedRequestLimits.setEndpoint(feedResponseLimits.getHeader('Location'));
            feedResponseLimits = new Http().send(feedRequestLimits);
        }

        if ( feedResponseLimits.getStatusCode() == 200 )
        {
            Map<String,LimitCollection> dcMap = (Map<String,LimitCollection>) 
                System.JSON.deserialize(feedResponseLimits.getBody(), Map<String,LimitCollection>.class);

            for ( String sLimit : dcMap.keySet() )
            {
                if (llimits.contains(sLimit))
                { 
                    OrgMonitoring__c orgmonitor = new OrgMonitoring__c();
                    orgmonitor.OrgID__c = org.Org_Id__c;
                    orgmonitor.OrgName__c = org.Label;
                    orgmonitor.OrgDomainName__c = org.Org_Name__c;
                    orgmonitor.Country__c = org.Country__c;
                    orgmonitor.BusinessUnit__c = org.Business_Unit__c;
                    orgmonitor.Timestamp__c = datetime.now();
                    orgmonitor.TimestampText__c = String.valueOf( datetime.now().format('yy-MM-dd HH:mm') );
                    orgmonitor.Type__c = 'Limits';
                    orgmonitor.Name__c = sLimit;
                    orgmonitor.Status__c = 'Active';
                    orgmonitor.Units__c = 'Unit';
                     orgmonitor.Latest__c = true;
                    orgmonitor.put('Total__c', dcMap.get(sLimit).Max);
                    orgmonitor.put('Remaining__c', dcMap.get(sLimit).Remaining);
                    orgmonitor.put('Used__c', dcMap.get(sLimit).Max - dcMap.get(sLimit).Remaining);
                    lListLimits.add(orgmonitor);

                    if ( sLimit == 'DataStorageMB' ) {
                      iDataStorage = (Integer) ( ( dcMap.get(sLimit).Max - dcMap.get(sLimit).Remaining) * 1024 );
                      if ( dcMap.get(sLimit).Max == dcMap.get(sLimit).Remaining ) iDataStorage = (Integer) dcMap.get(sLimit).Max * 1024;
                    }
                }
        }   
        } else {
            System.debug ('#### Error reaching endpoint for Limits ==> ' +sEndPoint);
            System.debug ('#### Error code ==> ' +feedResponseLimits.getStatusCode());
           } 
           
           return lListLimits;   
    }
}