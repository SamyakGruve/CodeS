public class EmailNotificationService {
    @future(callout = true)
    public static void sendOrderConfirmation(Id opportunityId) {
			 System.debug('------------ opportunityId------'+opportunityId);
        try {
            // Step 1: Fetch Opportunity and AccountId
            Opportunity opp = [
                SELECT Id, Name, AccountId, OrderNumber__c 
                FROM Opportunity 
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            
             System.debug('------------ opp------'+opp);

            if (opp.AccountId == null) {
                System.debug('Opportunity has no AccountId - cannot send email');
                return;
            }

            // Step 2: Query one Contact with Email
            List<Contact> contacts = [
                SELECT Id, Email 
                FROM Contact 
                WHERE AccountId = :opp.AccountId 
                AND Email != null
                LIMIT 1
            ];
            
            System.debug('------------ contacts------'+contacts);

            System.debug('Contacts found: ' + contacts);

            if (!contacts.isEmpty()) {
                String toEmail = contacts[0].Email;
				System.debug('Email is Working toEmail'+toEmail);
                // Step 3: Send email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{toEmail});
                String orderNumberPart = opp.OrderNumber__c != null ? ' ' + opp.OrderNumber__c : '';
                mail.setSubject('Your Order' + orderNumberPart + ' Has Been Placed');
                mail.setPlainTextBody('Hi, Your order has been placed for opportunity: ' + opp.Name);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                
                //Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                //mail.toAddresses = new List<String>(toEmail);
                mail.htmlBody = 'Hi, Your order has been placed for opportunity: ' + opp.Name;
                mail.subject = 'Your Order' + orderNumberPart + ' Has Been Placed';
        
                //Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {mail};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
				System.debug('Email is Working results '+results);
                if (results[0].success) {
                    //Logger.dbg('The email was sent successfully.');
                    //output.put('emailSentSuccessfully', true);
                    
                        System.debug('Email sent for Account: ' + opp.AccountId);
                } else {
                    System.debug('No contacts with email found for Account: ' + opp.AccountId);
                } 
            }
        }
        catch (Exception e) {
            System.debug('Exception in sendOrderConfirmation: ' + e.getMessage());
        }
    }
}