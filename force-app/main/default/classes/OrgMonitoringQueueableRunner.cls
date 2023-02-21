public with sharing class OrgMonitoringQueueableRunner implements Queueable, Database.AllowsCallouts{
    public void execute(QueueableContext context) 
    {
        integer counter=0;
        try
        {
            List<OrgToMonitor__mdt> lorgs = new List<OrgToMonitor__mdt>([SELECT DeveloperName, Org_Id__c, Label, Org_Name__c, OrgCreatedDate__c, Country__c, Business_Unit__c, ObsoleteUserDelay__c, DisplayObsoleteLoginUsers__c, apiVersion__c FROM OrgToMonitor__mdt order by label]);
            system.debug('record to process...'+lorgs.size());
            
            if (lorgs !=null && !lorgs.isEmpty()) {
                List<String> orgs = new List<String>{};
                OrgMonitoringQueueableRun.oldRecords(orgs);
                OrgMonitoringQueueable esync = new OrgMonitoringQueueable(lorgs);
                System.enqueueJob(esync);
            }
        }
        catch(Exception ex)
        {
            system.debug('Exception in OrgMonitoringQueueableRunner:'+ex.getMessage());
        }
    }
}