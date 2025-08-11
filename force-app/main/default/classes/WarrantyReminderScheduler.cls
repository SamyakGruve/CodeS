global class WarrantyReminderScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        WarrantyReminderHandler.createReminders();
    }
}