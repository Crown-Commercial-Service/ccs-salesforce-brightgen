/*********************************************************************
 Name:  bg_Framework_Lot_Related_List_Test
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Conor Spark      September 2017                        Initial version
   1.1   Conor Spark      October   2017                        Update to include fullscreen test
 *********************************************************************/
@isTest
public class bg_Framework_Lot_Related_List_Test {

    public static bg_Framework_Lot_Related_List_Controller setup(){

        Master_Framework__c fw = UnitTestDataFactory.createMasterFramework();
        insert fw;

        Master_Framework_Lot__c mfl = UnitTestDataFactory.createMasterFrameworkLot(fw.id);
        insert mfl;

        bg_Framework_Lot_Related_List_Controller sc = new bg_Framework_Lot_Related_List_Controller(new ApexPages.StandardController(fw));
        
        PageReference pageRef = Page.bg_Framework_Lot_Related_List;
        pageRef.getParameters().put('id', String.valueOf(fw.Id));
        pageRef.getParameters().put('flid', String.valueOf(mfl.id));
        Test.setCurrentPage(pageRef);

        return sc;
    }

    public static testmethod void testGetFrameworkLots(){
        bg_Framework_Lot_Related_List_Controller sc = setup();

        System.assertEquals(sc.getFrameworkLots().size(), 2);

        Master_Framework__c mf = [select Id from Master_Framework__c limit 1];

        Master_Framework_Lot__c mfl = UnitTestDataFactory.createMasterFrameworkLot(mf.id);
        insert mfl;

        System.assertEquals(sc.getFrameworkLots().size(), 3);


    }

    public static testmethod void testNewFrameworkLot(){
        bg_Framework_Lot_Related_List_Controller sc = setup();

        PageReference pr = sc.newFrameworkLot();

        System.assertNotEquals(pr, null);


    }

    public static testmethod void testEditFrameworkLot(){
        bg_Framework_Lot_Related_List_Controller sc = setup();

        PageReference pr = sc.editFrameworkLot();

        System.assertNotEquals(pr, null);


    }

    public static testmethod void testDeleteFrameworkLot(){
        bg_Framework_Lot_Related_List_Controller sc = setup();

        System.assertEquals(sc.getFrameworkLots().size(), 2);

        PageReference pr = sc.deleteFrameworkLot();

        System.assertEquals(sc.getFrameworkLots().size(), 1);


    }

    public static testmethod void testGetCanDelete(){
        bg_Framework_Lot_Related_List_Controller sc = setup();

        Boolean isDelete = Master_Framework_Lot__c.sObjectType.getDescribe().isDeletable();

        System.assertEquals(sc.getCanDelete(), isDelete);

        


    }
    
    
    public static testmethod void testRedirectFullscreen(){
        bg_Framework_Lot_Related_List_Controller sc = setup();

        PageReference pref = sc.redirectFullscreen();
        System.assert(sc.redirectURL!=null);

        


    }



}