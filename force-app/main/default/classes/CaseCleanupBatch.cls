public class CaseCleanupBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    public Integer recordsProcessed = 0;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime fiveDaysAgo = System.now().addDays(-5);
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, Status, LastModifiedDate
            FROM Case
            WHERE Status = 'Closed' AND LastModifiedDate < :fiveDaysAgo
        ]);
    }
    public void execute(Database.BatchableContext bc, List<Case> scope) {
        if (!scope.isEmpty()) {
            try {
                delete scope;
                recordsProcessed += scope.size();
                System.debug(scope.size() + ' old cases deleted in this batch.');
            } catch (DmlException e) {
                System.debug('Error deleting cases in batch: ' + e.getMessage());
                // You can log errors to a custom object here if required.
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        System.debug('Case Cleanup Batch Job Finished:');
        System.debug('Status: ' + job.Status);
        System.debug('Total Cases Processed: ' + job.JobItemsProcessed);
        System.debug('Number of Errors: ' + job.NumberOfErrors);
        System.debug('Total records deleted: ' + recordsProcessed);
    }
    // Optional utility method to run this batch manually
    /*public static void executeBatch() {
        CaseCleanupBatch batchJob = new CaseCleanupBatch();
        Database.executeBatch(batchJob, 200); // Adjust batch size as needed
    }*/
}