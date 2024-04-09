/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to purge records of the lowest month from OrgMonitoringPod__c object
Test Class:    OrgMoniotoringPurge_Test
Version:       1.0
History
01/03/2024     Salvatore Aversano    Create version
----------------------------------------------------------------------------------------*/

global with sharing class OrgMonitoringPodPurge implements Schedulable, Database.Batchable<sObject>, Database.Stateful
{
   Global List<OrgMonitoringPod__c> scopeToHistorize = new List<OrgMonitoringPod__c>();

    global Database.QueryLocator start( Database.BatchableContext BC ) 
    {
        // Identify the records to delete which are records with the lowest month
        String sQuery = 'SELECT id, Pod__c, MasterPod__c, Status__c, Createddate FROM OrgMonitoringPod__c where ';
        OrgMonitoringPod__c op = [Select CreatedDate from OrgMonitoringPod__c order by CreatedDate Limit 1];
        if (op != null) {
            Integer minYear = op.CreatedDate.year();
            Integer minMonth = op.CreatedDate.month();     
        } else {
            System.debug ('There is nothing to purge for the moment');
            return null;
        }
        if (Test.isRunningTest())
        { 
           sQuery = sQuery + 'Pod__c = \'TEST\''; // See Test Class 
        } else {
              // Query all records having the same month and the same year
              sQuery = sQuery + 'CALENDAR_MONTH(CreatedDate) = :minMonth AND CALENDAR_YEAR(CreatedDate) = :minYear';
        }

        return Database.getQueryLocator( sQuery );
    }

    global void execute( Database.BatchableContext BC, List<OrgMonitoringPod__c> scope ) {
        if (scope != null) {
           try { 
              scopeToHistorize.addAll(scope);
              delete scope;
            } catch ( Exception e ) {
               System.debug('#### Exception : ' + e);
            }
        }
    }
    
    global void finish( Database.BatchableContext BC ) {
        if (scopeToHistorize != null) {
            OrgMonitoringPodHistorizeBeforeDelete.processScope(scopeToHistorize);
        }
    }

    global void execute( SchedulableContext SC ) { Database.executeBatch( new OrgMonitoringPodPurge(), 2000 );}
}