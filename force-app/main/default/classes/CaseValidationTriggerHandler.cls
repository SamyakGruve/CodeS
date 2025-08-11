public class CaseValidationTriggerHandler {
    public static void validateSerialNumbers(List<Case> caseList) {
        Set<String> serialsToCheck = new Set<String>();

        // Collect serial numbers from cases that need validation
        for (Case c : caseList) {
            if ((c.Type == 'Warranty Claim' || c.Type == 'Device Repair')
                && String.isNotBlank(c.Serial_Number__c)) {
                serialsToCheck.add(c.Serial_Number__c);
            } else if ((c.Type == 'Warranty Claim' || c.Type == 'Device Repair') 
                     && String.isBlank(c.Serial_Number__c)) {
                c.addError('Serial number is required for Warranty Claim or Device Repair cases.');
            }
        }

        if (serialsToCheck.isEmpty()) {
            return; // No serial numbers to validate
        }

        // Query orders with these serial numbers once
        Set<String> validSerials = new Set<String>();
        for (Order o : [SELECT Serial_Number__c FROM Order WHERE Serial_Number__c IN :serialsToCheck]) {
            validSerials.add(o.Serial_Number__c);
        }

        // Validate serial numbers again after querying
        for (Case c : caseList) {
            if ((c.Type == 'Warranty Claim' || c.Type == 'Device Repair')
                && String.isNotBlank(c.Serial_Number__c)
                && !validSerials.contains(c.Serial_Number__c)) {
                c.addError('Invalid serial number for warranty or repair case.');
            }
        }
    }
}