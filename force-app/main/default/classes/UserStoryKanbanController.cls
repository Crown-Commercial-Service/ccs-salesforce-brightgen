/*****************************************************************************************************************************
Name: UserStoryKanbanController

Purpose: Apex Controller for Visualforce Page (Kanban)

History
-------
VERSION AUTHOR                                   DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   danny.evans@crowncommercial.gov.uk       28/09/2017      INITIAL DEVELOPMENT
2.0 -   danny.evans@crowncommercial.gov.uk       02/09/2018      Updated to include new features of Sprint 2.0
*******************************************************************************************************************************/


public class UserStoryKanbanController {
    public static String Story_MOVED = '{0} was moved successfully to {1}';
    
    public List<Schema.PicklistEntry> storyStatuses  { get; set; }
    public Map<String, List<User_Story__c>> allStories         { get; set; }
    private string sprintId;
    public Sprint__c sprint { get; set;}
    
    public class UpdateStatus {
        public Boolean isSuccess;
        public String message;
    }
    
    public UserStoryKanbanController() {
        sprintId = ApexPages.currentPage().getParameters().get('sprintid');
        storyStatuses = User_Story__c.US_Status__c.getDescribe().getPicklistValues();
        fetchSprint();
        fetchStories();
    }
    
    @RemoteAction
    public static UpdateStatus updateStoryStatus( Id storyId, String newStoryStatus ) {
        User_Story__c storyDetails;
        try{    
            storyDetails = [
                SELECT  Id
                ,Name
                FROM    User_Story__c
                WHERE   Id = :storyId
            ];
            
            
            storyDetails.US_Status__c = newStoryStatus;
            UPDATE storyDetails;
        }catch(Exception e){
            UpdateStatus failureDetails = new UpdateStatus();
            failureDetails.isSuccess    = false;
            failureDetails.message      = 'failed to move story : ' + e.getMessage();
            
            return failureDetails;
        }
        
        UpdateStatus updatedStoryDetails = new UpdateStatus();
        updatedStoryDetails.isSuccess    = true;
        updatedStoryDetails.message      = String.format( Story_MOVED, new List<String>{ storyDetails.Name, newStoryStatus } );
        
        return updatedStoryDetails;
    }
    
    private void fetchSprint(){
        sprint = [
            SELECT  Id
            ,Name
            ,Sprint_Days_to_Completion__c
            ,Sprint_Deployment_Date__c
            ,Sprint_End_Date__c
            ,Sprint_Plan_Estimate__c
            ,Sprint_Stories__c
            ,Sprint_Workstream__r.Name
            ,Sprint_Workstream__r.Id
            ,Sprint_Status__c
            ,Sprint_Start_Date__c
            FROM    Sprint__c
            Where Id = :sprintId
        ];
    }
    
    private void fetchStories() {
        List<User_Story__c> stories = [
            SELECT  Id
            ,Name
            ,US_Subject__c
            ,US_Status__c
            ,US_Plan_Estimate__c
            ,US_MOSCOW__c
            ,US_Developer__r.Name
            ,US_Blocked__c
            ,Stage__c
            ,US_Tester__c
            ,US_Category__c
            FROM    User_Story__c
            Where US_Sprint__c = :sprintId //AND US_Category__c != 'EPIC' // Code for v.2.1
        ];
        
        allStories = new Map<String, List<User_Story__c>>();
        
        for (Schema.PicklistEntry status : storyStatuses){
            allStories.put(status.getLabel(), new List<User_Story__c>());
        }
        
        for( User_Story__c story : stories ) {
            allStories.get( story.US_Status__c ).add( story );
        }
    }
}