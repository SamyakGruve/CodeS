public with sharing class LowStockProductController {
    @AuraEnabled(cacheable=true)
    public static List<Product2> getLowStockProducts() {
        // Query active products from Smartphones family (adjust family name as needed)
        List<Product2> allProducts = [
            SELECT Id, Name, Stock__c, Threshold__c
            FROM Product2
            WHERE IsActive = true AND Family = 'Smartphones'
            ORDER BY Stock__c ASC
        ];
        
        List<Product2> lowStockProducts = new List<Product2>();
        
        for (Product2 prod : allProducts) {
            if (prod.Stock__c != null && prod.Threshold__c != null && prod.Stock__c < prod.Threshold__c) {
                lowStockProducts.add(prod);
            }
        }
        return lowStockProducts;
    }
}