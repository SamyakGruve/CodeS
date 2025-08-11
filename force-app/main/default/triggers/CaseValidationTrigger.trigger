trigger CaseValidationTrigger on Case (before insert, before update) {
    CaseValidationTriggerHandler.validateSerialNumbers(Trigger.new);
}