/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to purge 30 days old records from OrgMonitoringPod__c object
Test Class:    OrgMoniotoringPurge_Test
Version:       1.0
History
01/03/2024     Salvatore Aversano    Create version
----------------------------------------------------------------------------------------*/

global with sharing class OrgMonitoringPodPurge implements Schedulable, Database.Batchable<sObject> 

{
    Global String sOperator;
    Global String sReference;
    Global String sQuery;

    global OrgMonitoringPodPurge() { 
        
        Integer iNb_days=30; /* Number of day to Keep -- All previous records are deleted*/
        Date targetDate = Date.today().addDays(-iNb_days);
        // Convert Date to String in YYYY-MM-DD format
        String dateString = targetDate.year() + '-' + String.valueOf(targetDate.month()).leftPad(2, '0') + '-' + String.valueOf(targetDate.day()).leftPad(2, '0')+ 'T23:59:59Z';
        sQuery = 'SELECT id FROM OrgMonitoringPod__c where CreatedDate = ';
        sQuery = sQuery + dateString;
        
    }
    global Database.QueryLocator start( Database.BatchableContext BC ) {
        return Database.getQueryLocator( sQuery );
    }

    global void execute( Database.BatchableContext BC, List<OrgMonitoringPod__c> scope ) {
        try { 
            delete scope;
        } catch ( Exception e ) {
            System.debug('#### Exception : ' + e);
        }
    }
    
    global void finish( Database.BatchableContext BC ) {}
   
    global void execute( SchedulableContext SC ) {  
        Database.executeBatch( new OrgMonitoringPodPurge(), 2000 );
    }
    
}