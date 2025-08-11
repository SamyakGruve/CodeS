public class CasePriorityEscalationTriggerHandler {
    public static void escalateUnattendedCases(List<Case> newCases, Map<Id, Case> oldMap) {
    for (Case c : newCases) {
        Case oldC = oldMap.get(c.Id);
        // Check if status hasn't changed and case is at least 2 days old
        if (c.Status == oldC.Status && Date.today().daysBetween(c.CreatedDate.date()) >= 2) {
            // Check current priority and escalate accordingly
            if (c.Priority == 'Low') {
                c.Priority = 'Medium';
            } else if (c.Priority == 'Medium') {
                c.Priority = 'High';
            }
        }
    }
    }
}