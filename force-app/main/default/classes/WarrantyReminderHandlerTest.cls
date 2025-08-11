@isTest
public class WarrantyReminderHandlerTest {
    @isTest
    static void testCreateReminders() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Orders within 30 days of warranty expiring
        Date today = Date.today();
        Order o1 = new Order(
            Name = 'Order1',
            AccountId = acc.Id,
            EffectiveDate = today, // Required field for insert
            Status = 'Draft', // Required
            Warranty_Expiring_Date__c = today.addDays(10)
        );
        Order o2 = new Order(
            Name = 'Order2',
            AccountId = acc.Id,
            EffectiveDate = today,
            Status = 'Draft',
            Warranty_Expiring_Date__c = today.addDays(29)
        );
        insert new List<Order>{o1, o2};

        Test.startTest();
        WarrantyReminderHandler.createReminders();
        Test.stopTest();

        // Check that tasks have been created
        List<Task> tasks = [SELECT Id, WhatId, Subject, Description, Status, Priority FROM Task WHERE WhatId IN :new List<Id>{o1.Id, o2.Id}];
        System.assertEquals(2, tasks.size(), 'Should create one Task per qualifying Order');

        for (Task t : tasks) {
            System.assertEquals('Warranty Expiring Soon', t.Subject);
            System.assertEquals('Call the customer for expiring warranty', t.Description);
            System.assertEquals('High', t.Priority);
            System.assertEquals('Not Started', t.Status);
            System.assertNotEquals(null, t.OwnerId);
        }
    }

    @isTest
    static void testNoRemindersIfNoOrders() {
        // Clean up - Do NOT create any Orders

        Test.startTest();
        WarrantyReminderHandler.createReminders();
        Test.stopTest();

        // Check no tasks created
        List<Task> tasks = [SELECT Id FROM Task];
        System.assertEquals(0, tasks.size(), 'Should not create tasks when there are no qualifying orders');
    }
}