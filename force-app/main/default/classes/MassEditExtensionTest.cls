@isTest
public class MassEditExtensionTest {

    static testMethod void singleUpdateTest() {
    	Opportunity o = new Opportunity();
    	List<Opportunity> oppList = [SELECT name FROM Opportunity LIMIT 20];
    	
    	ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(oppList);
    	setCtr.setSelected(new Opportunity[]{o});
        MassEditExtension controller = new MassEditExtension(setCtr);
		
		String value = 'test';
	    o.Name = 'test';
        controller.save();
        
	    System.assertEquals(o.Name, value);
    }
}