@IsTest
private class OpportunityTriggerHandlerTest {

    // Minimal Test.Mocks for static method calls
    // If these are virtual, you can mock them. Otherwise, calls will just run for coverage.

    @IsTest
    static void testHandleAfterUpdate_StageChangedToClosedWon_WithProduct() {
        // Create Product with stock
        Product2 prod = new Product2(Name='Test Phone', IsActive=true, Stock__c=10);
        insert prod;

        // Create Account
        Account acct = new Account(Name='Test');
        insert acct;

        // Create Opportunity, not Closed Won yet, with ProductCode__c
        Opportunity opp = new Opportunity(
            Name = 'Deal',
            AccountId = acct.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            ProductCode__c = prod.Id // Assuming this field stores Product2.Id
        );
        insert opp;

        // Capture Opportunity before update using a SOQL query for realism
        Opportunity oppOld = [SELECT Id, StageName, ProductCode__c, AccountId FROM Opportunity WHERE Id = :opp.Id];

        // Update to Closed Won
        opp.StageName = 'Closed Won';
        update opp;

        // Prepare newList and oldMap for after update handler
        Opportunity oppNew = [SELECT Id, StageName, ProductCode__c, AccountId FROM Opportunity WHERE Id = :opp.Id];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => oppOld };
        List<Opportunity> newList = new List<Opportunity>{ oppNew };

        // Run handler
        Test.startTest();
        OpportunityTriggerHandler.handleAfterUpdate(newList, oldMap);
        Test.stopTest();

        // Assert that an Order was created and connected to the opportunity
        List<Order> orders = [SELECT Id, OpportunityId, Serial_Number__c, Status FROM Order WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, orders.size(), 'Should have created one Order');
        System.assertEquals('Draft', orders[0].Status, 'Order Status');

        // Assert Product2 stock decreased by 1
        Product2 updatedProd = [SELECT Id, Stock__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals(9, updatedProd.Stock__c, 'Stock__c was decremented by 1');

        // Note: For full coverage, you can’t assert static method call, but code is covered.
    }

    @IsTest
    static void testHandleAfterUpdate_StageNOTClosedWon_DoesNothing() {
        // Create Product and Account
        Product2 prod = new Product2(Name='Test Phone2', IsActive=true, Stock__c=5);
        insert prod;
        Account acct = new Account(Name='Test2');
        insert acct;

        // Insert Opportunity as Closed Won (already); handler should not fire
        Opportunity opp = new Opportunity(
            Name = 'Deal2',
            AccountId = acct.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            ProductCode__c = prod.Id
        );
        insert opp;

        // Simulate after update (no stage transition)
        Opportunity oppOld = [SELECT Id, StageName, ProductCode__c FROM Opportunity WHERE Id = :opp.Id];
        Opportunity oppNew = oppOld.clone(false, true, false, false);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => oppOld };
        List<Opportunity> newList = new List<Opportunity>{ oppNew };

        Test.startTest();
        OpportunityTriggerHandler.handleAfterUpdate(newList, oldMap);
        Test.stopTest();

        // Assert that NO new orders were created
        List<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.Id];
        System.assertEquals(0, orders.size(), 'No Order should be created');
        // Product2 stock remains unchanged
        Product2 p = [SELECT Stock__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals(5, p.Stock__c);
    }

    @IsTest
    static void testHandleAfterUpdate_ClosedWon_NoProductCode() {
        // Create Account
        Account acct = new Account(Name='NoProductAcct');
        insert acct;

        // Insert Opportunity with null ProductCode
        Opportunity opp = new Opportunity(
            Name = 'NoProductDeal',
            AccountId = acct.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            ProductCode__c = null
        );
        insert opp;
        Opportunity oppOld = [SELECT Id, StageName, ProductCode__c, AccountId FROM Opportunity WHERE Id = :opp.Id];

        // Update to Closed Won
        opp.StageName = 'Closed Won';
        update opp;

        Opportunity oppNew = [SELECT Id, StageName, ProductCode__c, AccountId FROM Opportunity WHERE Id = :opp.Id];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => oppOld };
        List<Opportunity> newList = new List<Opportunity>{ oppNew };

        Test.startTest();
        OpportunityTriggerHandler.handleAfterUpdate(newList, oldMap);
        Test.stopTest();

        // Assert Order was created
        List<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, orders.size());

        // Product update should not happen (as ProductCode__c is null), so nothing to assert there.
    }
}