@isTest
private class CaseEscalationJobTest {

    @isTest
    static void testCaseEscalationJob() {
        // Create test Cases:
        // Eligible for escalation (status 'New', insert time == test run time)
        Case cLow    = new Case(Status='New', Priority='Low',    Origin='Phone');
        Case cMedium = new Case(Status='New', Priority='Medium', Origin='Web');
        Case cHigh   = new Case(Status='New', Priority='High',   Origin='Email'); // Should not change

        // Not eligible: wrong status
        Case cClosed = new Case(Status='Closed', Priority='Low', Origin='Phone');
        insert new List<Case>{cLow, cMedium, cHigh, cClosed};

        // Capture original priorities for later checking
        Map<Id, String> origPriorities = new Map<Id, String>{
            cLow.Id    => 'Low',
            cMedium.Id => 'Medium',
            cHigh.Id   => 'High',
            cClosed.Id => 'Low'
        };

        Test.startTest();
            // Schedulable classes run synchronously when scheduled in test context
            String cron = '0 0 0 1 1 ? 2099'; // arbitrary future date
            System.schedule('CaseEscalationTest', cron, new CaseEscalationJob());
        Test.stopTest();

        // Query all cases again
        Map<Id, Case> updatedCases = new Map<Id, Case>(
            [SELECT Id, Status, Priority FROM Case WHERE Id IN :origPriorities.keySet()]
        );

        // Assertions:
        System.assertEquals('Medium', updatedCases.get(cLow.Id).Priority,   'Low => Medium');
        System.assertEquals('High',   updatedCases.get(cMedium.Id).Priority, 'Medium => High');
        System.assertEquals('High',   updatedCases.get(cHigh.Id).Priority,   'High remains High');
        System.assertEquals('Low',    updatedCases.get(cClosed.Id).Priority, 'Closed status, should not change');
    }
}