public class WarrantyReminderHandler {
    public static void createReminders() {
       List<Order> orders = [
    		SELECT Id, Name, Warranty_Expiring_Date__c, AccountId
    		FROM Order
    		WHERE Warranty_Expiring_Date__c >= :Date.today()
      		AND Warranty_Expiring_Date__c <= :Date.today().addDays(30)
		];

        List<Task> reminders = new List<Task>();
        for (Order order : orders) {
            reminders.add(new Task(
                Subject = 'Warranty Expiring Soon',
                WhatId = order.Id,
                ActivityDate = Date.today(),
                Status = 'Not Started',
                Priority = 'High',
                Description = 'Call the customer for expiring warranty',
                OwnerId = UserInfo.getUserId()
            ));
        }

        if (!reminders.isEmpty()) {
            insert reminders;
        }
    }
}