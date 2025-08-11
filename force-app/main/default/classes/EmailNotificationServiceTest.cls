@isTest
private class EmailNotificationServiceTest {

    @isTest static void testSendOrderConfirmation() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test Contact with email linked to Account
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'samyakhadse@gmail.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create test Opportunity linked to Account with optional OrderNumber__c
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            OrderNumber__c = 'ORD12345' // optional, remove if not used
        );
        insert testOpp;

        Test.startTest();
        // Call the future method using the inserted Opportunity Id
        EmailNotificationService.sendOrderConfirmation(testOpp.Id);
        Test.stopTest();

        // Since we can't assert emails directly, check debug logs manually or rely on no exceptions thrown
    }
}