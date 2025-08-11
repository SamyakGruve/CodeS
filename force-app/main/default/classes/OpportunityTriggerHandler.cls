// Handler Class: OpportunityTriggerHandler
public class OpportunityTriggerHandler {
    
    public static void handleAfterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        List<Order> ordersToInsert = new List<Order>();
        List<Product2> productsToUpdate = new List<Product2>();
        System.debug('------------ OpportunityTriggerHandler  handleAfterUpdate------');
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
				String serialnum = SerialNumberGenerator.generateDateBasedSerialNumber();
                Order ord = new Order(
                    AccountId = opp.AccountId,
                    OpportunityId = opp.Id,
                    Status = 'Draft',
                    EffectiveDate = Date.today(),
                    Serial_Number__c = serialnum
                );
                ordersToInsert.add(ord);
				System.debug('------------ ordersToInsert------'+ordersToInsert);
                System.debug('------------ Before Mail------'+ordersToInsert);
                EmailNotificationService.sendOrderConfirmation(opp.Id);
                System.debug('------------ After Mail------'+ordersToInsert);
                
                if (opp.ProductCode__c != null) {
                    List<Product2> prods = [SELECT Id, Stock__c FROM Product2 WHERE Id = :opp.ProductCode__c LIMIT 1];
                    if (!prods.isEmpty()) {
                        Product2 prod = prods[0];
                        prod.Stock__c = prod.Stock__c != null ? prod.Stock__c - 1 : 0;
                        productsToUpdate.add(prod);
                    }
                }
            }
        }

        if (!ordersToInsert.isEmpty()) insert ordersToInsert;
        if (!productsToUpdate.isEmpty()) update productsToUpdate;
    }
}