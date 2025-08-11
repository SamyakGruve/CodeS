public with sharing class ProductController {
 
    @AuraEnabled(cacheable=true)
    public static List<Product2> getAvailableProducts() {
        return [SELECT Id, Name, Description FROM Product2 WHERE IsActive = true];
    }
	
 
    @AuraEnabled
    public static void addProductToOpportunity(Id opportunityId, Id productId) {
        // 1. Get which Pricebook the Opportunity is using
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (opp.Pricebook2Id == null) {
            // (OPTIONAL) Set a pricebook if one is not assigned, or return an error
            throw new AuraHandledException('This opportunity has no pricebook assigned.');
        }
    
        // 2. Get a PricebookEntry for this product in the correct pricebook
        PricebookEntry entry = [
            SELECT Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Product2Id = :productId 
            AND Pricebook2Id = :opp.Pricebook2Id
            AND IsActive = true
            LIMIT 1
        ];
    
        // 3. Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opportunityId,
            PricebookEntryId = entry.Id,
            Quantity = 1,
            UnitPrice = entry.UnitPrice
        );
        insert oli;
    }

}