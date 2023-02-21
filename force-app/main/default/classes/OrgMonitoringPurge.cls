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
    Global String sOperator;
    Global String sReference;
    Global String sQuery;

    global OrgMonitoringPurge() { 
        
        Integer iNb_months=6; /* Number of Months to Purge */
        sOperator = '<= ';
        sReference = 'LAST_N_MONTHS:' + iNb_months;

        if (  Test.isRunningTest() ) {
             sOperator = '= ';
             sReference = 'TODAY';
        } 
       
        sQuery = 'SELECT id FROM OrgMonitoring__c where CreatedDate ';
        sQuery = sQuery + sOperator + sReference;
        
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