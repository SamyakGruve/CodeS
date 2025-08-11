public with sharing class OpportunityLineItemController {
    @AuraEnabled
    public static void addProductToOpportunity(Id opportunityId, Id productId) {
        if (opportunityId == null || productId == null) {
            throw new AuraHandledException('Opportunity Id and Product Id are required.');
        }
		System.debug('-----------------------------opportunityId------------------------- ' + opportunityId);
        System.debug('-----------------------------productId-------------------------' + productId);
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (opp.Pricebook2Id == null) {
            throw new AuraHandledException('Opportunity does not have an active Pricebook.');
        }
        
		System.debug('-----------------------------opp opportunity-------------------------' + opp);
        // Find active PricebookEntry for this product and pricebook
        PricebookEntry pbe = [
            SELECT Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :opp.Pricebook2Id 
              AND Product2Id = :productId 
              AND IsActive = true 
            LIMIT 1
        ];
        
        System.debug('-----------------------------pbe pricebook-------------------------' + pbe);

        if (pbe == null) {
            throw new AuraHandledException('Product not available in the Opportunity Pricebook.');
        }

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opportunityId;
        oli.PricebookEntryId = pbe.Id;
        oli.Quantity = 1;
        oli.UnitPrice = pbe.UnitPrice;
        System.debug('-----------------------------oli OpportunityLineItem-------------------------' + oli);
        // Optionally, set other fields such as Discount, Description, ServiceDate...
		System.debug('-----------------------------Before insert OpportunityLineItem-------------------------' + oli);
        insert oli;
        System.debug('-----------------------------After insert OpportunityLineItem-------------------------' + oli);
    }
}