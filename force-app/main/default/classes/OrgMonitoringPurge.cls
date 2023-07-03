/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to purge 6 months old records from orgmonitor object
Test Class:    OrgMoniotoringPurge_Test
Version:       1.0
History
22/08/2022     Salvatore Aversano    Create version
----------------------------------------------------------------------------------------*/

global with sharing class OrgMonitoringPurge implements Schedulable, Database.Batchable<sObject> 

{
    Global String sQuery;

    global OrgMonitoringPurge()
    { 
      Date sixMonthsAgo = System.today().addMonths(-6); // Keep last 6 months records for historical data
      sQuery = 'SELECT id FROM OrgMonitoring__c where CreatedDate >= ' + sixMonthsAgo + ' AND CreatedDate <= ' + SYSTEM.TODAY();
    }
    
    global Database.QueryLocator start( Database.BatchableContext BC ) {
        return Database.getQueryLocator( sQuery );
    }

    global void execute( Database.BatchableContext BC, List<OrgMonitoring__c> scope ) {
        try { 
            delete scope;
        } catch ( Exception e ) {
            System.debug('#### Exception : ' + e);
        }
    }
    
    global void finish( Database.BatchableContext BC ) {}
   
    global void execute( SchedulableContext SC ) {  
        Database.executeBatch( new OrgMonitoringPurge(), 2000 );
    }
    
}