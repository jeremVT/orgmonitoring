/*-------------------------------------------------------------------------------------
Author:        Salvatore Aversano
Company:       Salesforce.com
Description:   Apex class used to Historize Records before delete
Test Class:    OrgMonitoringPodHistorizeBeforeDelete_Test
Version:       0.1
History
08/04/2024     Salvatore Aversano    Create version

Version 0.1    Created
----------------------------------------------------------------------------------------*/

public class OrgMonitoringPodHistorize 
{
    public class Subtotals 
    {
       public integer nbOK { get; set; }
       public Decimal nbKO { get; set; }

       public Subtotals() {
          nbOK = 0;
          nbKO = 0;
       }
    }
    public static void processScope(List<OrgMonitoringPod__c> scope)
   {

        List<OrgMonitoringPodHistory__c> histPods = new List<OrgMonitoringPodHistory__c>();  // Collection to store Historized records
        Map<String, Subtotals> valueToSubtotalsMap = new Map<String, Subtotals>();
        // Iterate over the records to prepare a Map with subtotals of nbOK and nbKO
        for (OrgMonitoringPod__c om : scope) 
        {
            if (om.masterpod__c) // Only records with masterpod = true will be historized
            {
                 String groupkey = 
                + om.Pod__c + '#'
                + om.CreatedDate.format('MMMM') + '#'
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
                histPods.add(histPod);
            }
        }
        if(histPods != null && !histPods.isEmpty())
        {
            try {
            insert histPods;
            } catch (DMLException f){
              System.debug('#### DML Exception when inserting historical records: ' + f);
            }
        }   
    }
}