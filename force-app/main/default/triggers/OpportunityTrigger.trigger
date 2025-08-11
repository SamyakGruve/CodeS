// Trigger: OpportunityTrigger
trigger OpportunityTrigger on Opportunity (after update) {
    OpportunityTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}