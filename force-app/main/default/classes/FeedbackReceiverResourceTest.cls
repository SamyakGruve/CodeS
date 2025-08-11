@isTest
private class FeedbackReceiverResourceTest {

    @isTest
    static void testReceiveFeedback_Success() {
        // Prepare test data as JSON
        String jsonBody = JSON.serialize(
            new Map<String, Object>{
                'records' => new List<Object>{
                    new Map<String, Object>{
                        'Name' => 'Test Feedback 1',
                        'Feedback_From_Customer__c' => 'Great product!',
                        'Product_Code__c' => 'P1001',
                        'Product_Id__c' => 123,
                        'Rating__c' => 'Excellent'
                    },
                    new Map<String, Object>{
                        'Name' => 'Test Feedback 2',
                        'Feedback_From_Customer__c' => 'Needs improvement',
                        'Product_Code__c' => 'P1002',
                        'Product_Id__c' => 234,
                        'Rating__c' => 'Poor'
                    }
                }
            }
        );

        // Set up the REST context for test
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/feedback/';
        RestContext.request = req;
        RestContext.response = res;

        // Call the REST method
        Test.startTest();
        FeedbackReceiverResource.receiveFeedback();
        Test.stopTest();

        // Verify the records were inserted with expected fields/values
        List<Feedback_Archive__c> feedbacks = [
            SELECT Name, Feedback_From_Customer__c, Product_Code__c, Product_Id__c, Rating__c
            FROM Feedback_Archive__c
            WHERE Name IN ('Test Feedback 1','Test Feedback 2')
        ];
        System.assertEquals(2, feedbacks.size(), 'Two records should be inserted.');

        Map<String, Decimal> expectedRatings = new Map<String, Decimal>{
            'Test Feedback 1' => 5, // Excellent
            'Test Feedback 2' => 1  // Poor
        };

        for (Feedback_Archive__c fa : feedbacks) {
            System.assertEquals(expectedRatings.get(fa.Name), fa.Rating__c, 'Ratings should be translated correctly.');
        }
    }

    @isTest
    static void testReceiveFeedback_InvalidPayload() {
        // Prepare an INVALID (malformed) JSON
        String invalidJsonBody = '{ not valid json ]';

        // Set up REST context for test
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(invalidJsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/feedback/';
        RestContext.request = req;
        RestContext.response = res;

        // Call the REST method
        Test.startTest();
        FeedbackReceiverResource.receiveFeedback();
        Test.stopTest();

        // Check that response status is 400, and no new record was inserted
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 for malformed payload.');
        // Should not have inserted a feedback archive record
        Integer count = [SELECT COUNT() FROM Feedback_Archive__c];
        System.assertEquals(0, count, 'No records should be inserted if payload is invalid.');
    }

    @isTest
    static void testReceiveFeedback_NullOrBlankRating() {
        // JSON with blank and missing rating
        String jsonBody = JSON.serialize(
            new Map<String, Object>{
                'records' => new List<Object>{
                    new Map<String, Object>{
                        'Name' => 'NoRating1',
                        'Feedback_From_Customer__c' => 'Neutral',
                        'Product_Code__c' => 'P1005',
                        'Product_Id__c' => 555,
                        'Rating__c' => ''
                    },
                    new Map<String, Object>{
                        'Name' => 'NoRating2',
                        'Feedback_From_Customer__c' => 'Neutral again',
                        'Product_Code__c' => 'P1006',
                        'Product_Id__c' => 556
                        // No Rating__c at all
                    }
                }
            }
        );

        // Set up REST context for test
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/feedback/';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        FeedbackReceiverResource.receiveFeedback();
        Test.stopTest();

        // Verify inserts with null ratings
        List<Feedback_Archive__c> feedbacks = [
            SELECT Name, Rating__c
            FROM Feedback_Archive__c
            WHERE Name IN ('NoRating1','NoRating2')
        ];
        System.assertEquals(2, feedbacks.size());
        for (Feedback_Archive__c fa : feedbacks) {
            System.assertEquals(null, fa.Rating__c, 'Should be null if Rating not provided or blank.');
        }
    }
}