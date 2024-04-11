/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to purge records of the lowest month from OrgMonitoringPod__c object
Test Class:    OrgMoniotoringPurge_Test
Version:       1.0
History
01/03/2024     Salvatore Aversano    Create version
----------------------------------------------------------------------------------------*/

global with sharing class OrgMonitoringPodPurge implements Schedulable, Database.Batchable<sObject>, Database.stateful
{
    // Those lists are not records and memory expansive
    global List<OrgMonitoringPodHistory__c> summarizeChunk = new List<OrgMonitoringPodHistory__c>(); // Summarize each chunk
    global List<OrgMonitoringPodHistory__c> Allsummarized = new List<OrgMonitoringPodHistory__c>(); // Summarize all summarized chunks
    
    private string sQuery;
    public class Subtotals 
    {
       public integer nbOK { get; set; }
       public integer nbKO { get; set; }

       public Subtotals() {
          nbOK = 0;
          nbKO = 0;
       }
    }

    global Database.QueryLocator start( Database.BatchableContext BC ) 
    {
        // Prepare the query : Records with the lowest month will be summarized, historized then purged

        String sQuery = 'SELECT id, Pod__c, MasterPod__c, Status__c, Createddate FROM OrgMonitoringPod__c where ';
        if (Test.isRunningTest())
        { 
            Integer minYear = 2024;
            Integer minMonth = 4; 
            sQuery = sQuery + 'Pod__c = \'Test Pod\''; // See Test Class 
        } else {
            List<OrgMonitoringPod__c> op = [Select CreatedDate from OrgMonitoringPod__c order by CreatedDate Limit 1];
            if (op.size() > 0) {
               Integer minYear = op[0].CreatedDate.year();
               Integer minMonth = op[0].CreatedDate.month(); 
               sQuery = sQuery + 'CALENDAR_MONTH(CreatedDate) = :minMonth AND CALENDAR_YEAR(CreatedDate) = :minYear' ;
            } else {
                System.debug ('There is nothing to purge for the moment');
                return null;
            }
        }
         return Database.getQueryLocator( sQuery );
    }

    global void execute( Database.BatchableContext BC, List<OrgMonitoringPod__c> scope ) 
    {
       
        // Delete the scope and summarize all scoped records for each chunk
        
        Map<String, Subtotals> valueToSubtotalsMap = new Map<String, Subtotals>();
        for (OrgMonitoringPod__c omp : scope) 
        {
            if (omp.masterpod__c) // Only records with masterpod = true will be historized
            {
                 String groupkey = 
                + omp.Pod__c + '#'
                + omp.CreatedDate.format('MMMM') + '#'
                + String.valueOf(omp.CreatedDate.year());
                // Check if the grouping value exists in the map
                if (!valueToSubtotalsMap.containsKey(groupkey)) 
                {
                    valueToSubtotalsMap.put(groupkey, new Subtotals());
                }      
                // Update the subtotals for the group
                Subtotals subtotals = valueToSubtotalsMap.get(groupkey);
                if (omp.status__c == 'OK') 
                { 
                    subtotals.nbOK++;
                } else {
                    subtotals.nbKO++;
                  }
            }
        }

        for (String grkey : valueToSubtotalsMap.keySet())
        {
            Subtotals subtotals = valueToSubtotalsMap.get(grkey);
            List<String> splitgroup = grkey.split('#');
            if (splitgroup.size() > 0) 
            {
                OrgMonitoringPodHistory__c histPod = new OrgMonitoringPodHistory__c();
                histPod.Pod__c          = splitgroup[0];
                histPod.Month__c        = splitgroup[1];
                histPod.Year__c         = splitgroup[2];
                histPod.nbOK__c         = subtotals.nbOK;
                histPod.nbKO__c         = subtotals.nbKO;
                histPod.Availability__c = (histPod.nbOK__c  / (histPod.nbOK__c + histPod.nbKO__c)) * 100;  
                summarizeChunk.add(histPod);
            }
        }
 
        if (scope != null) {
           try { 
              delete scope;
            } catch ( Exception e ) {
               System.debug('#### Exception while deleting records : ' + e);
            }
        }
    }
    
    global void finish( Database.BatchableContext BC ) {
        if(summarizeChunk != null && !summarizeChunk.isEmpty())
        {
            List<OrgMonitoringPodHistory__c> Allsummarized = summarizeAll(summarizeChunk);
            try {
             insert Allsummarized;
            } catch (DMLException f){
              System.debug('#### DML Exception when inserting historical records: ' + f);
            }
        }  else {
            System.debug('#### There is nothing to historize');
        }

    }

    global void execute( SchedulableContext SC ) { Database.executeBatch( new OrgMonitoringPodPurge(), 2000 );}

    Public static List<OrgMonitoringPodHistory__c>  summarizeAll (List<OrgMonitoringPodHistory__c> scope)
    {
        // Sumarize all the chunks
        
        List<OrgMonitoringPodHistory__c> aggregateAll = new List<OrgMonitoringPodHistory__c>();
        Map<String, Subtotals> valueToSubtotalsMap = new Map<String, Subtotals>();
        // Iterate over the records to prepare a Map with subtotals of nbOK and nbKO
        for (OrgMonitoringPodHistory__c hist : scope) 
        {
             String groupkey = 
            + hist.Pod__c + '#'
            + hist.Month__c + '#'
            + hist.Year__c + '#';
            // Check if the grouping value exists in the map
            if (!valueToSubtotalsMap.containsKey(groupkey)) 
            {
                valueToSubtotalsMap.put(groupkey, new Subtotals());
            }      
            // Update the subtotals for the group
            Subtotals subtotals = valueToSubtotalsMap.get(groupkey);
            subtotals.nbOK += hist.nbOK__c.intValue();
            subtotals.nbKO += hist.nbKO__c.intvalue();
        }

        for (String grkey : valueToSubtotalsMap.keySet())
        {
            Subtotals subtotals = valueToSubtotalsMap.get(grkey);
            List<String> splitgroup = grkey.split('#');
            if (splitgroup.size() > 0) 
            {
                OrgMonitoringPodHistory__c histPod = new OrgMonitoringPodHistory__c();
                histPod.Pod__c          = splitgroup[0];
                histPod.Month__c        = splitgroup[1];
                histPod.Year__c         = splitgroup[2];
                histPod.nbOK__c         = subtotals.nbOK;
                histPod.nbKO__c         = subtotals.nbKO;
                histPod.Availability__c = (histPod.nbOK__c  / (histPod.nbOK__c + histPod.nbKO__c)) * 100;  
                aggregateAll.add(histPod);
            }
        } 
        return aggregateAll;
    }
}