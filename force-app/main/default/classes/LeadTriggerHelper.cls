/***********************************************************************************************
* Name              : SalesOfficeTriggerHelper                                                 
* Description       : Helper class for triggers related to Leads.Adaptation of the lead Round Robin 
                      Package                                           
* Created Date      : 17/04/2018                                                    
* Created By        : Divya Chary (divya.chary@were4c.com)    
* Jira/Req By       :                                                                                                                                         
* ----------------------------------------------------------------------------------------------
* VERSION   Developer   Date        Description     Ticket/Reference                                                                    
* 1.0       Divya       17/04/2018  Created                              
************************************************************************************************/
public class LeadTriggerHelper{
    /************************************************************************************
    Method  :         LeadRoundRobin Method
    Description :     Round Robin Assignment of leads
    Version :         1.0
    ************************************************************************************/
    public static void leadRoundRobin(List<Lead> lstLead, Map<Id,Lead> oldMap){
        Map<Integer,Id> queueIds = new Map<Integer,Id>();   //Trigger index --> Queue ID
        Integer idx = 0;
        for (Lead cs : lstLead){
            //cs.EGY_Assignment_Rule__c=True; 
            if(cs.OwnerId <>oldMap.get(cs.id).OwnerId) {
                if (cs.EGY_TempOwnerId__c == 'SKIP') {
                    lstLead[idx].EGY_TempOwnerId__c = '';
                } else {
                    queueIds.put(idx, cs.OwnerId);
                }
            } 
            idx++;
        }
        if (queueIds.isEmpty()) return;
        Map<Integer,Id> asgnGroupNameIds = new Map<Integer,Id>();   //Trigger index --> Assignment_Group_Name ID
        Map<Id,EGY_Sales_Office__c> asgnGroupQueues = new Map<Id,EGY_Sales_Office__c>(); //Queue ID --> Sales Office Names
        for(EGY_Sales_Office__c[] agq : [SELECT EGY_Sales_Office_Name__c, QueueId__c
                                          FROM EGY_Sales_Office__c 
                                          WHERE QueueId__c in :queueIds.values()
                                        ]){
            for (Integer i = 0; i < agq.size() ; i++) {
                asgnGroupQueues.put(agq[i].QueueId__c, agq[i]);
            }                                           
        }
        if (asgnGroupQueues.isEmpty()) return;
        for (Integer i : queueIds.keySet()) {
            EGY_Sales_Office__c agq = asgnGroupQueues.get(queueIds.get(i));
            
            if (agq <> null) {
                asgnGroupNameIds.put(i, agq.Id);
            }
            //else no active assignment group queue error
        }
        if (asgnGroupNameIds.isEmpty()) return;
        //
        //Determine next valid user in Queue/Assignment Group for round robin
        //User with earliest last assignment date wins.
        //
        Map<Id,Assignment_Groups__c[]> asgnGroups = new Map<Id,Assignment_Groups__c[]>(); // Assignment Group Name ID --> User ID
        for(Assignment_Groups__c[] ags : [SELECT EGY_Sales_Office__c, User__c, Last_Assignment__c, Millisecond__c 
                                       FROM Assignment_Groups__c 
                                       WHERE EGY_Sales_Office__c in :asgnGroupNameIds.values() 
                                       AND Active__c = 'True' AND User_Active__c = 'True'
                                       ORDER BY Last_Assignment__c, Millisecond__c]){
            if (ags.size()>0) {
                asgnGroups.put(ags[0].EGY_Sales_Office__c, ags);
            }
        }  
        if (asgnGroups.isEmpty()) return;
        Map<Id,Assignment_Groups__c> updateAssignmentGroups = new Map<Id,Assignment_Groups__c>();
        Map<Id, datetime> latestAGDateTime = new Map<Id,datetime>();
        idx = 0;    
        for (Integer i : queueIds.keySet()){
            Assignment_Groups__c[] ags = asgnGroups.get(asgnGroupNameIds.get(i));
            if (ags.size()>0)
            {   
                //Choose next user in line if user ID has already been used but not committed in this trigger batch 
                Assignment_Groups__c ag = ags[math.mod(idx, ags.size())];
                lstLead[i].OwnerId = ag.User__c; 
                lstLead[i].Property_Advisor__c = ag.User__c;    
                lstLead[i].EGY_TempOwnerId__c = ''; 
                //Set last assignment datetime
                datetime now = datetime.now();
                ag.Last_Assignment__c = now;
                ag.Millisecond__c = now.millisecondGMT();
                //update only latest Assignment Groups per ID
                if (latestAGDateTime.containsKey(ag.id)) {
                    if(latestAGDateTime.get(ag.id) < now) {
                        updateAssignmentGroups.put(ag.id, ag);
                        latestAGDateTime.put(ag.id, now);
                    }
                } else {
                    updateAssignmentGroups.put(ag.id, ag);
                    latestAGDateTime.put(ag.id,now);
                }
                
                idx++;
            }
        }
        //Map --> List/Array for DML update
        List<Assignment_Groups__c> updateAG = new List<Assignment_Groups__c>();
        for (Id agId : updateAssignmentGroups.keySet()) {
            updateAG.add(updateAssignmentGroups.get(agId));
        }
        //
        //Update last assignment for Assignment Group in batch
        //
        if (updateAG.size()>0) {
            try {
                update updateAG;
                for (Lead oLead : lstLead){
                    oLead.EGY_Send_Notification_To_Owner__c =True;
                }
            } catch (Exception e){
                for (Integer i : queueIds.keySet())
                {
                    lstLead[i].addError('ERROR: Could not update Assignment Group records ' + ' DETAIL: '+e.getMessage());  
                }
            }
        }    
    }

    /************************************************************************************
    Method  :         updateOpportunityFields
    Description :     Method to set leads fields on opportunity upon conversion
    Version :         1.0
    ************************************************************************************/
    public static void updateOpportunityFields(LIST<Lead> newList){
        MAP<Id, Lead> oppIdToLeadMap = new MAP<Id, Lead>();
        LIST<Opportunity> updateableOpps = new LIST<Opportunity>();
        for(Lead l : newList){
            if(l.isConverted && l.convertedOpportunityId != null){
                oppIdToLeadMap.put(l.convertedOpportunityId, l);
            }
        }
        if(!oppIdToLeadMap.isEmpty()){
            for(Opportunity opp : [SELECT Id FROM Opportunity WHERE Id IN:oppIdToLeadMap.keySet()]){
                if(oppIdToLeadMap.get(opp.Id) != null){
                    Opportunity op = new Opportunity(Id=opp.Id);
                    op.Lead_Id__c = oppIdToLeadMap.get(op.Id).Id;
                    op.Lead_Conversion_Date__c = System.today();
                    op.Lead_Converted_By__c = UserInfo.getName();
                    updateableOpps.add(op);
                }
            }

            if(updateableOpps.size() > 0){
                upsert updateableOpps;
            }
        }


    }

}