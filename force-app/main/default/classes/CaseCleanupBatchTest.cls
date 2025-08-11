@isTest
private class CaseCleanupBatchTest {
    @isTest
    static void testBatchDeletesOldClosedCasesOnly() {
        // Closed cases: should be deleted
        Case closed1 = new Case(Status='Closed', Origin='Web', Subject='Old Closed 1');
        Case closed2 = new Case(Status='Closed', Origin='Web', Subject='Old Closed 2');
        // Open/Working: should NOT be deleted
        Case open1 = new Case(Status='New', Origin='Email', Subject='Open');
        Case working1 = new Case(Status='Working', Origin='Phone', Subject='Working');

        insert new List<Case>{closed1, closed2, open1, working1};

        Set<Id> closedIds = new Set<Id>{closed1.Id, closed2.Id};
        Set<Id> notClosedIds = new Set<Id>{open1.Id, working1.Id};

        Test.startTest();
            Database.executeBatch(new CaseCleanupBatch(), 2);
        Test.stopTest();

        // Query which cases remain
        List<Case> remainingCases = [SELECT Id, Status FROM Case WHERE Id IN :closedIds];
        System.assertEquals(0, remainingCases.size(), 'Closed cases should be deleted.');

        List<Case> notClosedCases = [SELECT Id, Status FROM Case WHERE Id IN :notClosedIds];
        System.assertEquals(2, notClosedCases.size(), 'Open/Working cases should remain.');
        for (Case c : notClosedCases) {
            System.assertNotEquals('Closed', c.Status, 'Non-closed cases should not be deleted.');
        }
    }

    @isTest
    static void testBatchDoesNotDeleteNonClosedCases() {
        // Only open/working cases inserted
        Case openCase = new Case(Status='New', Origin='Web', Subject='Open A');
        Case workingCase = new Case(Status='Working', Origin='Web', Subject='Working B');
        insert new List<Case>{openCase, workingCase};

        Test.startTest();
            Database.executeBatch(new CaseCleanupBatch(), 2);
        Test.stopTest();

        List<Case> results = [SELECT Id FROM Case WHERE Id IN :new List<Id>{openCase.Id, workingCase.Id}];
        System.assertEquals(2, results.size(), 'Open and working cases should not be deleted.');
    }

    @isTest
    static void testBatchFinishMethodAndRecordsProcessed() {
        // Insert closed case to be deleted
        Case closed = new Case(Status='Closed', Origin='Web', Subject='ClosedForFinish');
        insert closed;

        // Track initial count (for stateful coverage)
        Integer countBefore = [SELECT COUNT() FROM Case];

        Test.startTest();
            Id jobId = Database.executeBatch(new CaseCleanupBatch(), 1);
        Test.stopTest();

        // One less case should exist now
        Integer countAfter = [SELECT COUNT() FROM Case];
        System.assertEquals(countBefore - 1, countAfter, 'Record should be deleted by batch.');

        // Check AsyncApexJob created
        AsyncApexJob job = [SELECT Status, NumberOfErrors, JobItemsProcessed FROM AsyncApexJob WHERE Id=:jobId];
        System.assertNotEquals(null, job, 'AsyncApexJob should exist for batch (finish coverage).');
    }
}