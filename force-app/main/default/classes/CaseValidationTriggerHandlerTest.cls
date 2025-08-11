@isTest
private class CaseValidationTriggerHandlerTest {

    // Use @testSetup to create common test data once for all test methods.
    @testSetup
    static void makeData() {
        // Create an Account, which is required for creating an Order.
        Account testAcct = new Account(Name='Test Account');
        insert testAcct;

        // An Order must be associated with a Pricebook.
        Id pricebookId = Test.getStandardPricebookId();

        // Create a valid Order with a specific serial number.
        // Cases will be validated against this Order's serial number.
        Order validOrder = new Order(
            AccountId = testAcct.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = pricebookId,
            Serial_Number__c = 'VALID-SN-12345' // The serial number to be used in the success test
        );
        insert validOrder;
    }

    @isTest
    static void testValidate_Success_ValidSerial() {
        // Arrange: Create a case that should pass validation.
        Case successCase = new Case(
            Type = 'Warranty Claim',
            Status = 'New',
            Origin = 'Web',
            Serial_Number__c = 'VALID-SN-12345' // This serial exists on the Order
        );
        List<Case> caseList = new List<Case>{ successCase };

        Test.startTest();
            // Act: Call the validation method.
            CaseValidationTriggerHandler.validateSerialNumbers(caseList);
        Test.stopTest();

        // Assert: Verify that no error message was added to the case.
        System.assertEquals(0, successCase.getErrors().size(), 'A valid serial number should not produce an error.');
    }

    @isTest
    static void testValidate_Error_MissingSerial() {
        // Arrange: Create a case with a relevant Type but a blank serial number.
        Case missingSerialCase = new Case(
            Type = 'Device Repair',
            Status = 'New',
            Origin = 'Phone',
            Serial_Number__c = '' // Blank serial number
        );
        List<Case> caseList = new List<Case>{ missingSerialCase };

        Test.startTest();
            // Act: Call the validation method.
            CaseValidationTriggerHandler.validateSerialNumbers(caseList);
        Test.stopTest();

        // Assert: Verify that the correct error message was added.
        System.assertEquals(1, missingSerialCase.getErrors().size(), 'A missing serial number should produce one error.');
        System.assert(
            missingSerialCase.getErrors()[0].getMessage().contains('Serial number is required'),
            'The error message for a missing serial number is incorrect.'
        );
    }

    @isTest
    static void testValidate_Error_InvalidSerial() {
        // Arrange: Create a case with a serial number that does not exist in any Order.
        Case invalidSerialCase = new Case(
            Type = 'Warranty Claim',
            Status = 'New',
            Origin = 'Email',
            Serial_Number__c = 'INVALID-SN-99999' // This serial does not exist
        );
        List<Case> caseList = new List<Case>{ invalidSerialCase };

        Test.startTest();
            // Act: Call the validation method.
            CaseValidationTriggerHandler.validateSerialNumbers(caseList);
        Test.stopTest();

        // Assert: Verify that the correct error message was added.
        System.assertEquals(1, invalidSerialCase.getErrors().size(), 'An invalid serial number should produce one error.');
        System.assert(
            invalidSerialCase.getErrors()[0].getMessage().contains('Invalid serial number'),
            'The error message for an invalid serial number is incorrect.'
        );
    }

    @isTest
    static void testValidate_NoValidation_OtherCaseType() {
        // Arrange: Create a case with a Type that doesn't require validation.
        Case ignoredCase = new Case(
            Type = 'Question', // This type is not 'Warranty Claim' or 'Device Repair'
            Status = 'New',
            Origin = 'Web',
            Serial_Number__c = 'ANY-VALUE-DOES-NOT-MATTER'
        );
        List<Case> caseList = new List<Case>{ ignoredCase };

        Test.startTest();
            // Act: Call the validation method.
            CaseValidationTriggerHandler.validateSerialNumbers(caseList);
        Test.stopTest();

        // Assert: Verify that no error was added because the validation logic should be skipped.
        System.assertEquals(0, ignoredCase.getErrors().size(), 'Cases with other types should not be validated.');
    }

    @isTest
    static void testValidate_BulkProcessing_MixedScenarios() {
        // Arrange: Create a list of cases with a mix of conditions.
        List<Case> caseList = new List<Case>{
            // 1. Case that should pass
            new Case(
                Type = 'Warranty Claim', 
                Serial_Number__c = 'VALID-SN-12345'
            ),
            // 2. Case with an invalid serial
            new Case(
                Type = 'Device Repair', 
                Serial_Number__c = 'INVALID-SN-99999'
            ),
            // 3. Case with a missing serial
            new Case(
                Type = 'Warranty Claim', 
                Serial_Number__c = null
            ),
            // 4. Case that should be ignored
            new Case(
                Type = 'Feedback', 
                Serial_Number__c = 'ANYTHING'
            )
        };

        Test.startTest();
            // Act: Call the validation method on the entire list.
            CaseValidationTriggerHandler.validateSerialNumbers(caseList);
        Test.stopTest();

        // Assert: Check each case for the expected outcome.
        System.assertEquals(0, caseList[0].getErrors().size(), 'Bulk Test: The valid case should have no errors.');
        
        System.assertEquals(1, caseList[1].getErrors().size(), 'Bulk Test: The invalid serial case should have one error.');
        System.assert(caseList[1].getErrors()[0].getMessage().contains('Invalid serial number'));

        System.assertEquals(1, caseList[2].getErrors().size(), 'Bulk Test: The missing serial case should have one error.');
        System.assert(caseList[2].getErrors()[0].getMessage().contains('Serial number is required'));
        
        System.assertEquals(0, caseList[3].getErrors().size(), 'Bulk Test: The ignored case type should have no errors.');
    }
}