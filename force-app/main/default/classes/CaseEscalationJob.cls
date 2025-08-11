global class CaseEscalationJob implements Schedulable {
    /*CaseEscalationJob job = new CaseEscalationJob();
	job.execute(null);*/
    global void execute(SchedulableContext ctx) {
        //System.now().addMinutes(-1);
        //Date.today().addDays(-2);
        Date thresholdDate = Date.today().addDays(-1);
        List<Case> casesToEscalate = [
            SELECT Id, Status, Priority, CreatedDate 
            FROM Case 
            WHERE Status = 'New' AND CreatedDate <= :thresholdDate
        ];

        for (Case c : casesToEscalate) {
            if (c.Priority == 'Low') {
                c.Priority = 'Medium';
            } else if (c.Priority == 'Medium') {
                c.Priority = 'High';
            }
            // If Priority is already 'High' or something else, do nothing
        }

        if (!casesToEscalate.isEmpty()) {
            update casesToEscalate;
        }
    }
}