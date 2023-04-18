public with sharing class OrgMonitoringQueueable implements Queueable, Database.AllowsCallouts{
    final Integer MAX_RECORD = 10; // number of orgs to process in an unique enqueued job
    public Integer processingCount = 0;
    List<OrgToMonitor__mdt> lorgm = new List<OrgToMonitor__mdt>();
    public OrgMonitoringQueueable(List<OrgToMonitor__mdt> lorgs) {
        this.lorgm = lorgs; 
    }
     
    public void execute(QueueableContext context) {
        integer counter=0;
        boolean startNewQueue=false;
        List<OrgMonitoring__c> lorgmonitoring = new List<OrgMonitoring__c>();
        List<OrgToMonitor__mdt> lorgm_next = new List<OrgToMonitor__mdt>(lorgm);
        try
        {
            for ( OrgToMonitor__mdt oOrg : lorgm ) {
                if(!startNewQueue)
                {
                    if(oOrg!=null)
                    {
                        try
                        {
                            List<OrgMonitoring__c> lorgmon = (OrgMonitoringQueueableRun.processRecords(oOrg));
                            if(lorgmon!=null) {lorgmonitoring.addAll(lorgmon);}
                        }
                        catch(Exception ex)
                        {
                            system.debug('Exception when executing the queueable : ' +ex.getMessage());
                        }
                    
                        counter=counter+1;
                        lorgm_next.remove(0);
                        // System.debug ('Current lorgm size is : ' + lorgm_next.size());
                    }
                    if(counter==MAX_RECORD)
                    {
                        startNewQueue=true;
                        break;
                    }                    
                }
            }
            if(startNewQueue)
            { 
                processTargets(lorgmonitoring);
                OrgMonitoringQueueable esync = new OrgMonitoringQueueable(lorgm_next);
                counter=0;
                lorgmonitoring.clear();
                System.enqueueJob(esync);
            }
            processTargets(lorgmonitoring);
            
            // Are there errors during the extract? (If any they are stored in the OrgMonitor object under these conditions)
            // orgmonitor.Name__c = 'Error';
            // orgmonitor.ObsoleteLoginUserList__c = errorMsg;
            
            // Prepare the errors message if any.
            String msgError = ' ';
            List<OrgMonitoring__c> lorgerrors = new List<OrgMonitoring__c>([SELECT Id, OrgName__c, ObsoleteLoginUserList__c from OrgMonitoring__c where Latest__c = true and Name__c = 'Error']);
            for ( OrgMonitoring__c errors : lorgerrors ) {
                msgError = msgError + '\n\nOrg Name = ' + errors.OrgName__c + '   ' + + errors.ObsoleteLoginUserList__c;
            }
            if (msgError != ' ')
            {
                OrgMonitoringSendMailOnError.sendEmail(msgError);
            }
            // Delete obsolete errors.
            try { 
              delete lorgerrors;
            } catch ( Exception e ) {
              System.debug('#### Exception during delete of obsolete errors: ' + e);
            }
        }
        catch(Exception ex)
        {
            system.debug('Exception in execute method:'+ex.getMessage());
        }
    }
        public void processTargets(List<OrgMonitoring__c> orgmonitors){
             if(orgmonitors!=null && !orgmonitors.isEmpty())
             {
                try {
                    insert orgmonitors;
                    } catch (DMLException f){
                    System.debug('#### DML Exception during insert orgmonitors: ' + f);
                   }
            }
        }
}