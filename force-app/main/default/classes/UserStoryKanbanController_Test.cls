@isTest
public class UserStoryKanbanController_Test {
    
    @testSetup
    static void createGlobalTestData() {
        
    }
    
    @isTest 
    static void testController() {
        Workstream__c workstream;
        Sprint__c sprint;
        User_Story__c userStory;
        
        // Create an account for the product manager user. 
        User productManagerUser   = [SELECT Id FROM User WHERE Name != 'portal Site Guest User' AND isActive = true LIMIT 1]; 
        System.debug('Product Manager User' + ' '+ productManagerUser.Id);
        String prodAccountName  = 'Test Account ' + UnitTestDataFactory.getRandomString(8);
        Account prodAcc = UnitTestDataFactory.createSupplierAccount(prodAccountName);
        System.debug('ACCOUNT' + ' ' + prodAcc);
        prodAcc.OwnerId = productManagerUser.Id;
        insert prodAcc;
        
        // Create an account for the delivery manager user. 
        User deliveryManagerUser   = [SELECT Id FROM User WHERE Name != 'portal Site Guest User' AND isActive = true LIMIT 1]; 
        String deliverAccountName  = 'Test Account ' + UnitTestDataFactory.getRandomString(8);
        Account deliverAcc = UnitTestDataFactory.createSupplierAccount(deliverAccountName);
        deliverAcc.OwnerId = deliveryManagerUser.Id;
        insert deliverAcc;
        
        // Create Workstream
        workstream = new Workstream__c();
        workstream.Name ='TestWorkstream';
        workstream.Product_Manager__c = productManagerUser.Id;
        workstream.Delivery_Manager__c = deliveryManagerUser.Id;
        insert workstream;
        
        // Create Sprint
        sprint = new Sprint__c();
        sprint.Name = 'TestSprint';
        sprint.Sprint_Workstream__c = workstream.Id;
        sprint.Sprint_Status__c = 'Planning';
        insert sprint;
        
        // Create an account for the business owner user. 
        User accountOwnerUser   = [SELECT Id FROM User WHERE Name != 'portal Site Guest User' AND isActive = true LIMIT 1]; 
        String testAccountName  = 'Test Account ' + UnitTestDataFactory.getRandomString(8);
        Account testAcc = UnitTestDataFactory.createSupplierAccount(testAccountName);
        testAcc.OwnerId = accountOwnerUser.Id;
        insert testAcc;
       
        
        // Create the  contact
        Contact busOwnerContact = UnitTestDataFactory.createContact(testAcc.Id); 
        insert busOwnerContact;     
        
        
        // Create User Story
        userStory = new User_Story__c();
        userStory.US_Sprint__c = sprint.Id;
        userStory.US_MOSCOW__c = 'Must';
        userStory.US_Subject__c = 'TestSubject';
        userStory.US_Story_Detail__c = 'TestDetail';
        userStory.US_Status__c = 'In-Development';
        userStory.Stage__c = 'Working';
        userStory.US_Tester__c = 'John Denford';
        userStory.US_Category__c = 'Tweak';
        
        userStory.US_Business_Owner__c = busOwnerContact.Id;
        
        insert userStory;
        
        PageReference pageRef = Page.KanbanUserStory;
        Test.setCurrentPage(pageRef);
        test.startTest();
        
        ApexPages.currentPage().getParameters().put('sprintid', sprint.Id);
        UserStoryKanbanController controller;
        controller = new UserStoryKanbanController();
        
        List<User_Story__c> devStories;
        
        devStories = controller.allStories.get('In-Development');
        
        System.assertEquals(devStories[0].US_Subject__c,'TestSubject');
        
        UserStoryKanbanController.UpdateStatus result;
        result = UserStoryKanbanController.updateStoryStatus(devStories[0].Id,'Deployed');
        
        System.assert(result.isSuccess, 'Failed to move a user story');
        
        delete devStories[0];
        
        result = UserStoryKanbanController.updateStoryStatus(devStories[0].Id,'Deployed');
        System.assert(!result.isSuccess, 'User story should have been deleted');
        test.stopTest();
    }
    
}