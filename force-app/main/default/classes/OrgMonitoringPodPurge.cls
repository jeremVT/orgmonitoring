/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to purge records of the lowest month from OrgMonitoringPod__c object
Test Class:    OrgMoniotoringPurge_Test
Version:       1.0
History
01/03/2024     Salvatore Aversano    Create version
----------------------------------------------------------------------------------------*/

global with sharing class OrgMonitoringPodPurge implements Schedulable, Database.Batchable<sObject> 

{
    Global  String sQuery;
    Global  DateTime lowestDate = DateTime.now();
    Global  Integer minMonth = 0;
    Global  Integer minYear = 0;
    
    public class Subtotals 
    {
        public integer nbOK { get; set; }
        public Decimal nbKO { get; set; }
    
        public Subtotals() {
            nbOK = 0;
            nbKO = 0;
        }
    }
    global OrgMonitoringPodPurge() 
    { 
     
        // Search for the lowest Month and Year in Records
        sQuery = 'SELECT id, BusinessUnit__c, Country__c, OrgId__c, OrgName__c, Pod__c, MasterPod__c, Status__c, Createddate FROM OrgMonitoringPod__c where ';
        AggregateResult[] results = [Select min(CreatedDate) minDate from OrgMonitoringPod__c];
        if (results.size() > 0 && results[0].get('minDate') != null)
        { 
            lowestDate = (DateTime)results[0].get('minDate');
            minYear = lowestDate.year();
            minMonth = lowestDate.month();    
        } else {
            minMonth = 12; // A date without records
            minYear = 2099; // A date without records
            System.debug ('There is nothing to purge for the moment');
        }
        // System.debug ('Minimum Date ' + lowestDate + ' Month = ' +minMonth + ' Year = ' + minYear);   
       
        if (Test.isRunningTest())
        { 
           sQuery = sQuery + 'Pod__c = \'TEST\''; // See Test Class 
        } else {
              // Query all records having the same month and the same year
              sQuery = sQuery + 'CALENDAR_MONTH(CreatedDate) = :minMonth AND CALENDAR_YEAR(CreatedDate) = :minYear';   
        }
       
        // System.debug ('Query = ' +sQuery );    
    }
    
    global Database.QueryLocator start( Database.BatchableContext BC ) {
        return Database.getQueryLocator( sQuery );
    }

    global void execute( Database.BatchableContext BC, List<OrgMonitoringPod__c> scope ) {
        try { 
             // Historization of records to delete
           processRecords(scope);           
           delete scope;
        } catch ( Exception e ) {
            System.debug('#### Exception : ' + e);
        }
    }
    
    private void processRecords(List<OrgMonitoringPod__c> records)
    {
        // Method to historize records before delete
        Map<String, Subtotals> valueToSubtotalsMap = new Map<String, Subtotals>();

        // Iterate over the records to prepare a Map with subtotals of nbOK and nbKO
        for (OrgMonitoringPod__c om : records) 
        {
            if (om.masterpod__c) // Only records with masterpod = true will be historized
            {
                 String groupkey = om.BusinessUnit__c + '#' 
                + om.Country__c + '#'
                + om.OrgId__c + '#' 
                + om.OrgName__c + '#'
                + om.Pod__c + '#'
                + String.valueOf(om.CreatedDate.month()) + '#'
                + String.valueOf(om.CreatedDate.year());
                // Check if the grouping value exists in the map
                if (!valueToSubtotalsMap.containsKey(groupkey)) 
                {
                    valueToSubtotalsMap.put(groupkey, new Subtotals());
                }      
                // Update the subtotals for the group
                Subtotals subtotals = valueToSubtotalsMap.get(groupkey);
                if (om.status__c == 'OK') 
                { 
                    subtotals.nbOK++;
                } else {
                    subtotals.nbKO++;
                  }
            }
        }
        
        // Iterate the Map to create and historize OrgMonitoringPod__c records
        List<OrgMonitoringPodHistory__c> histPod = new List<OrgMonitoringPodHistory__c>();
        for (String grkey : valueToSubtotalsMap.keySet())
        {
            Subtotals subtotals = valueToSubtotalsMap.get(grkey);
            List<String> splitgroup = grkey.split('#');
            if (splitgroup.size() > 0) 
            {
                OrgMonitoringPodHistory__c orgPod = new OrgMonitoringPodHistory__c();
                orgPod.BusinessUnit__c = splitgroup[0];
                orgPod.Country__c      = splitgroup[1];
                orgPod.OrgId__c        = splitgroup[2];
                orgPod.OrgName__c      = splitgroup[3];      
                orgPod.Pod__c          = splitgroup[4];
                orgPod.Month__c        = Integer.valueOf(splitgroup[5]);
                orgPod.Year__c         = Integer.valueOf(splitgroup[6]);
                orgPod.nbOK__c         = subtotals.nbOK;
                orgPod.nbKO__c         = subtotals.nbKO;
                orgPod.Availability__c = (orgPod.nbOK__c  / (orgPod.nbOK__c + orgPod.nbKO__c)) * 100;  
                histPod.add(orgPod);
            }
        }  
        if(histPod!=null && !histPod.isEmpty())
        {
            try {
            insert histPod;
            } catch (DMLException f){
              System.debug('#### DML Exception when inserting historical records: ' + f);
            }
        }
    }
    global void finish( Database.BatchableContext BC ) {}
    global void execute( SchedulableContext SC ) { Database.executeBatch( new OrgMonitoringPodPurge(), 2000 );}
}