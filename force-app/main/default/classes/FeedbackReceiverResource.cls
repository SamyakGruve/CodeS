// You DO NOT need this class for your current setup. This is only an example.

@RestResource(urlMapping='/feedback')
global with sharing class FeedbackReceiverResource {

    // This method would be called when a POST request is sent to .../services/apexrest/feedback/
    @HttpPost
    global static void receiveFeedback() {
        // Get the request that was sent
        RestRequest req = RestContext.request;
        
        Map<String, Decimal> ratingConversionMap = new Map<String, Decimal>{
            'Poor' => 1,
            'Average' => 2,
            'Good' => 3,
            'Very Good' => 4,
            'Excellent' => 5
        };
        
        // The body of the request contains the JSON payload
        Blob body = req.requestBody;
        String bodyString = body.toString();
        
        // Create a list to hold the new archive records
        List<Feedback_Archive__c> archivesToInsert = new List<Feedback_Archive__c>();

        try {
            // Apex has a built-in JSON parser. We can de-serialize the JSON
            // into a wrapper class or a generic Map.
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(bodyString);
            
            // The sending system sent a list of records in a 'records' key
            List<Object> incomingRecords = (List<Object>) payload.get('records');

            for (Object obj : incomingRecords) {
                Map<String, Object> recordMap = (Map<String, Object>) obj;

                Feedback_Archive__c newArchive = new Feedback_Archive__c();
                newArchive.Name = (String) recordMap.get('Name');
                newArchive.Feedback_From_Customer__c = (String) recordMap.get('Feedback_From_Customer__c');
                newArchive.Product_Code__c = (String) recordMap.get('Product_Code__c');
                newArchive.Product_Id__c = (Decimal) recordMap.get('Product_Id__c');
                //newArchive.Rating__c = (Decimal) recordMap.get('Rating__c');
                String textRating = (String) recordMap.get('Rating__c');
                if (String.isNotBlank(textRating)) {
                    // Look up the text rating in the map to get the number
                    newArchive.Rating__c = ratingConversionMap.get(textRating);
                }
                
                // Here you could add more complex logic if needed
                
                archivesToInsert.add(newArchive);
            }

            if (!archivesToInsert.isEmpty()) {
                insert archivesToInsert;
            }

        } catch (Exception e) {
            // Set up error handling if the request fails
            RestContext.response.statusCode = 400; // Bad Request
            RestContext.response.responseBody = Blob.valueOf('Error processing request: ' + e.getMessage());
        }
    }
}