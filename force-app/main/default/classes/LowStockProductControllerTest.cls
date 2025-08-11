@isTest
private class LowStockProductControllerTest {
    @isTest
    static void testGetLowStockProducts() {
        List<Product2> testProducts = new List<Product2>{
            // Should be returned (below threshold)
            new Product2(Name='LowProd1', IsActive=true, Family='Smartphones', Stock__c=4, Threshold__c=5),
            new Product2(Name='LowProd2', IsActive=true, Family='Smartphones', Stock__c=0, Threshold__c=1),
            // Should NOT be returned (stock >= threshold)
            new Product2(Name='OkProd1', IsActive=true, Family='Smartphones', Stock__c=10, Threshold__c=5),
            new Product2(Name='EqualProd', IsActive=true, Family='Smartphones', Stock__c=5, Threshold__c=5),
            // Should NOT be returned (Inactive)
            new Product2(Name='InactiveLow', IsActive=false, Family='Smartphones', Stock__c=1, Threshold__c=99),
            // Should NOT be returned (wrong family)
            new Product2(Name='TabletLow', IsActive=true, Family='Tablets', Stock__c=1, Threshold__c=5),
            // Should NOT be returned (null stock/threshold)
            new Product2(Name='NullStock', IsActive=true, Family='Smartphones', Stock__c=null, Threshold__c=2),
            new Product2(Name='NullThresh', IsActive=true, Family='Smartphones', Stock__c=1, Threshold__c=null)
        };
        insert testProducts;

        Test.startTest();
        List<Product2> result = LowStockProductController.getLowStockProducts();
        Test.stopTest();

        Set<String> resultNames = new Set<String>();
        for (Product2 p : result) {
            resultNames.add(p.Name);
        }

        // Only LowProd1 and LowProd2 should be returned
        System.assertEquals(2, result.size(), 'Only two products should be reported as low stock.');
        System.assert(resultNames.contains('LowProd1'), 'LowProd1 should be in result.');
        System.assert(resultNames.contains('LowProd2'), 'LowProd2 should be in result.');

        // Negative checks
        System.assert(!resultNames.contains('OkProd1'),    'High stock should not appear');
        System.assert(!resultNames.contains('EqualProd'),   'Equal stock/threshold should not appear');
        System.assert(!resultNames.contains('InactiveLow'), 'Inactive product should not appear');
        System.assert(!resultNames.contains('TabletLow'),   'Non-Smartphones should not appear');
        System.assert(!resultNames.contains('NullStock'),   'Null stock should not appear');
        System.assert(!resultNames.contains('NullThresh'),  'Null threshold should not appear');
    }
}