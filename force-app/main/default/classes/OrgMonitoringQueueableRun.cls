public with sharing class OrgMonitoringQueueableRun {
      
    public static void oldRecords (List<String> lorgs)
    {
        /* =======================================================================
                            UPDATE OLD RECORDS TO NON LATEST EXTRACT
           =======================================================================
        */
        List<OrgMonitoring__c> orgmonitorList = new List<OrgMonitoring__c>();
        if ( lorgs.size() == 0 ) // Proceed for ALL Orgs
        {
            orgmonitorList = new List<OrgMonitoring__c>([SELECT Id FROM OrgMonitoring__c where Latest__c = true ]); 
        } else {
            orgmonitorList = new List<OrgMonitoring__c>([SELECT Id FROM OrgMonitoring__c where OrgName__c in :lorgs and Latest__c = true ]);
             }
          
        system.debug( '#### Processing Old Records #### : ' +orgmonitorList.size() );  
        for ( OrgMonitoring__c oorgmonitor : orgmonitorList ) {
            oorgmonitor.Latest__c = false;
        }
            try {
            update orgmonitorList;
            } catch (DMLException f){
            System.debug('#### DML Exception : ' + f);
           }
        
    }

    public static List<OrgMonitoring__c> processRecords(OrgToMonitor__mdt org)
    {           
       // This is the list containing the monitored records for each org
        List<OrgMonitoring__c> lorgmonitoring = new List<OrgMonitoring__c>();
        
       // GET USERS NOT LOGGED SINCE MORE THAN X TIME 
       OrgMonitoring__c orgmon = OrgMonitoringExtractObsoleteUsers.execute(org);
       lorgmonitoring.add(orgmon);
       // Check if this method raised an error, if true then no need to execute the other methods
       if (orgmon.Name__c == 'Error') {
          return lorgmonitoring;
       }

       // GET LICENCES UTILIZATION
       List<OrgMonitoring__c> lorgmon = OrgMonitoringExtractLicenses.execute(org);  
       lorgmonitoring.addAll(lorgmon);
       
       // GET INSTALLED PACKAGES 
       lorgmon.clear();
       lorgmon = OrgMonitoringExtractPackages.execute(org);
       lorgmonitoring.addAll(lorgmon);
       
       // GET LIMITS 
       lorgmon.clear();
       lorgmon = OrgMonitoringExtractLimits.execute(org);
       lorgmonitoring.addAll(lorgmon);

       // Return the complete list of records for the analyzed org
       return lorgmonitoring;
    }  
   
}