/*****************************************************************************************************************************
Name: CFI_MessageFactory

Purpose: Helper class to generate JSON and to host wrapper classes

History
-------
VERSION AUTHOR                                DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com            07/03/2016      INITIAL DEVELOPMENT
1.1 -   danny.evans@crowncommercial.gov.uk    03/09/2018      Added On behalf of Customer and Parent Group
*******************************************************************************************************************************/

public class CFI_MessageFactory {
/* No access modifier since is helper class */ 
  
  public static String REPLACE_FOR_RESERVED = '_TO_BE_REPLACE_AS_IT_IS_RESERVE_WORD';
  
  /************************************************************
        Purpose: Method generates JSON string and replace string literals which could 
          not be use in wrapper class as they are reserved words
        Parameters: -
        Returns: notice id
        Throws: -
    *************************************************************/
  public static String generateJSON (Object obj){
    String retVal = JSON.serialize(obj);
    retVal = retVal.replace(REPLACE_FOR_RESERVED, '');
    return retVal;
  }

  /************************************************************
        Purpose: Method for data transformation DATE -> STRING 
          (format supported by Contract Finder)
        Parameters: -
        Returns: Date as string (YYYY-MM-DDT00:00:00)
        Throws: -
    *************************************************************/
  public static String transformDateToString(Date d){
    String retVal = '';
    if (d != null){
      retVal = '' + d.year() + '-' + d.month() + '-' + d.day() + 'T00:00:00';
    }
    return retVal;
  }

  /************************************************************
        Purpose: Method for data transformation ojeuContractType 
          (format supported by Contract Finder)
        Parameters: -
        Returns: Date as string (YYYY-MM-DDT00:00:00)
        Throws: -
    *************************************************************/
  public static String transformToOjeuContractType(String ojeuCT){
    String retVal = 'Products';

    if (ojeuCT == 'Services' || ojeuCT == 'Works'){
      retVal = ojeuCT;
    }
    
    return retVal;
  }

  /************************************************************
        Purpose: Method for getting value for Contact_Finder_Integration_Mapping__c
        Parameters: key
        Returns: String value or default value
        Throws: -
    *************************************************************/
  public static String getCSMapping(String key, String defaultVal){
    String retVal = defaultVal;
    Contact_Finder_Integration_Mapping__c cfim = Contact_Finder_Integration_Mapping__c.getInstance(key);

    if (cfim != null){
      retVal = cfim.Value__c;
    }

    return retVal;
  }

  /************************************************************
        Purpose: Method for getting value for Contact_Finder_Integration_Mapping__c
        Parameters: key
        Returns: String value or default value
        Throws: -
    *************************************************************/
  public static Boolean getCSMapping(String key, Boolean defaultVal){
    Boolean retVal = defaultVal;
    Contact_Finder_Integration_Mapping__c cfim = Contact_Finder_Integration_Mapping__c.getInstance(key);

    if (cfim != null){
      if(cfim.Value__c.toUppercase() == 'TRUE'){
        retVal = true;
      }
      else{
        retVal = false;
      }
    }

    return retVal;
  }

  /***************************************************************************************
  Name: CFI_MessageFactory.TokenResp

  Purpose: Wrapper class for login call responce
  ***************************************************************************************/
  public class TokenResp{
    public String access_token;
    public String token_type;
    public Integer expires_in;
  }

  /***************************************************************************************
  Name: CFI_MessageFactory.ContactDetailsWrap

  Purpose: Wrapper class for contact
  ***************************************************************************************/
  public class ContactDetailsWrap{
    public String name;
    public String email;
    public String address1;
    public String address2;
    public String town;
    public String postcode;
    public String country;
    public String phone;
    public String webAddress;

    public ContactDetailsWrap(Boolean awardedNotice, CCS_Contract__c ccsContract, Case procurement){ //Added for US0537
      if (awardedNotice){
        this.name     = ('Crown Commercial Service on behalf of ' + ccsContract.Customer__r.Name + ' : ' + ccsContract.Customer__r.Parent_Group__c); //Added for US0537
        this.email     = getCSMapping('ON_EMAIL','supplier@crowncommercial.gov.uk');
        this.address1   = getCSMapping('ON_ADDRESS', 'Floor 9, The Capital Building, Old Hall Street');
        this.town     = getCSMapping('ON_TOWN', 'Liverpool');
        this.postcode   = getCSMapping('ON_POSTCODE','L3 9PP');
        this.country   = getCSMapping('ON_COUNTRY', 'England');
        this.phone     = getCSMapping('ON_PHONE','03450103503');
        this.webAddress = getCSMapping('ON_WEBADDRESS', 
        'https://www.gov.uk/government/organisations/crown-commercial-service');

      }
      else {
        this.name     = ('Crown Commercial Service on behalf of ' + procurement.Account.Name + ' : ' + procurement.Account.Parent_Group__c); //Added for US0537
        this.email     = getCSMapping('CN_EMAIL','supplier@crowncommercial.gov.uk');
        this.address1   = getCSMapping('CN_ADDRESS', 'Floor 9, The Capital Building, Old Hall Street');
        this.town     = getCSMapping('CN_TOWN', 'Liverpool');
        this.postcode   = getCSMapping('CN_POSTCODE','L3 9PP');
        this.country   = getCSMapping('CN_COUNTRY', 'England');
        this.phone     = getCSMapping('CN_PHONE','03450103503');
        this.webAddress = getCSMapping('CN_WEBADDRESS', 
        'https://www.gov.uk/government/organisations/crown-commercial-service');

      }
    }
  }

  /***************************************************************************************
  Name: CFI_MessageFactory.NoticeLocation

  Purpose: Wrapper class for notice location
  ***************************************************************************************/
  public class NoticeLocation{
    public Decimal lat;
    public Decimal lon;

    public NoticeLocation(){
      lat = 0;
      lon = 0;
    }
  }

  /***************************************************************************************
  Name: CFI_MessageFactory.Notice

  Purpose: Wrapper class for notice
  ***************************************************************************************/
  public class Notice{
    public String id;
    public String parentId;
    public String parentIdentifier;
    public String linkReason;
    public Integer version;
    public ContactDetailsWrap contactDetails;

    public String identifier;
    public String title;
    public String description;
    public String cpvDescription;
    public String publishedDate;
    public String approachMarketDate;
    public String deadlineDate;
    public Decimal valueLow;
    public Decimal valueHigh;
    public String postcode;
    public String region;
    public String nationwide;

    public NoticeLocation location;

    public String start;
    public String end_TO_BE_REPLACE_AS_IT_IS_RESERVE_WORD;
    public String type;
    public List<String> cpvCodes;

    public String spendProfile;
    public String status;
    public Boolean isSuitableForSme;
    public Boolean isSuitableForVco;
    public String lastNotifiableUpdate;
    public String organisationName;
    public String sector;
    public String procedureType;
    public String ojeuContractType;
    public Boolean isFrameworkAgreement;
    public Boolean isExtensionPossible;
    public String annexDOption;
    public String reasonContractLawful;

    public Notice(CCS_Contract__c ccsContract, List<String> liCPVCodes){
      this.identifier = ccsContract.Contract_Reference__c + getCSMapping('CN_REFERENCE_SUFFIX', '.');
      this.title = ccsContract.name;
      this.contactDetails = new ContactDetailsWrap(true, ccsContract, null); //Added for US0537
      this.location = new NoticeLocation();
      this.start = transformDateToString(ccsContract.Start_Date__c);
      this.end_TO_BE_REPLACE_AS_IT_IS_RESERVE_WORD = 
        transformDateToString (ccsContract.End_Date__c);
      this.deadlineDate = transformDateToString (ccsContract.Deadline_Date__c);
      this.publishedDate = transformDateToString (Date.today());
      this.valueLow = ccsContract.Contract_Value__c;
      this.ojeuContractType = transformToOjeuContractType (ccsContract.Contract_Type__c);
      this.procedureType = ccsContract.OJEU_Procedure_Type__c;
      this.region = String.isBlank(ccsContract.Regions__c) ? '' : ccsContract.Regions__c.replace(';', ',');
      this.isSuitableForSme = ccsContract.Is_Suitable_For_SME__c;
      this.isSuitableForVco = ccsContract.Is_Suitable_for_VCSE__c;
      this.isExtensionPossible = ccsContract.Extension_Options__c;
      this.description = ccsContract.Description__c;
      this.cpvCodes = liCPVCodes;

      // Hardcoded values
      this.type = getCSMapping('ON_TYPE','Contract');
      this.organisationName = (ccsContract.Customer__r.Name + ' : ' + ccsContract.Customer__r.Parent_Group__c); //Added for US0537
      this.isFrameworkAgreement = false;

      this.status = getCSMapping('ON_STATUS', 'Awarded');
      this.lastNotifiableUpdate = getCSMapping('ON_LAST_NOTIFABLE_UPDATE','0001-01-01T00:00:00');  
    }

    public Notice(Case procurement, List <String> liCPVCodes){
      this.identifier = procurement.Procurement_Reference__c;
      this.title = procurement.Contract_Finder_Title__c;      
      this.contactDetails = new ContactDetailsWrap(false, null, procurement); //Added for US0537
      this.location = new NoticeLocation();
      this.start = transformDateToString(procurement.Contract_Start_Date__c);
      this.end_TO_BE_REPLACE_AS_IT_IS_RESERVE_WORD = 
        transformDateToString (procurement.Contract_End_Date__c);
      this.deadlineDate = transformDateToString (procurement.Tender_End_Date__c);
      this.publishedDate = transformDateToString (Date.today());
      this.valueLow = procurement.Contract_Low_Value__c;
      this.valueHigh = procurement.Contract_High_Value__c;
      this.ojeuContractType = transformToOjeuContractType(procurement.Contract_Type__c);
      this.region = String.isBlank(procurement.Regions__c) ? '' : procurement.Regions__c.replace(';', ',');
      this.isSuitableForSme = procurement.SME_Suitable__c;
      this.isSuitableForVco = procurement.VCSE_Suitable__c;
      this.description = procurement.Contract_Finder_Desc__c;
      this.cpvDescription = procurement.Contract_Finder_Desc__c;

      // Hardcoded values
      this.organisationName = (procurement.Account.Name + ' : ' + procurement.Account.Parent_Group__c); //Added for US0537     
      this.type = getCSMapping('CN_TYPE','Contract');
      this.procedureType = getCSMapping('ON_PROCEDURE_TYPE','Other');
      this.isFrameworkAgreement = getCSMapping('ON_IS_FRAMEWORK_AGREEEMENT',false);
      this.isExtensionPossible = getCSMapping('ON_IS_EXTENSION_POSSIBLE',false);
      this.cpvCodes =  liCPVCodes;

      this.status = getCSMapping('CN_STATUS', 'Open');
      this.lastNotifiableUpdate = getCSMapping('CN_LAST_NOTIFABLE_UPDATE','0001-01-01T00:00:00');  
    }
  }

  /***************************************************************************************
  Name: CFI_MessageFactory.ErrorMessage

  Purpose: Wrapper class for error responce
  ***************************************************************************************/
  public class ErrorMessage{
    public String code;
    public String property;
    public String message;
  }

  /***************************************************************************************
  Name: CFI_MessageFactory.Award

  Purpose: Wrapper class for error responce
  ***************************************************************************************/
  public class Award{
    public String noticeId;
    public String parentId;
    public Decimal value;
    public String supplierName;
    public String supplierAddress;
    public String contact;
    public String dunsNumber;
    public String startDate;
    public String endDate;
    public String awardedDate;
    public String awardedProcedureType;
    public String annexDOptionType;
    public String reasonContractLawful;
    public String additionalDetails;
    public Boolean awardedToSME;
    public Boolean awardedToVCSO;
    public String awardGuid;

    public Award (CCS_Contract__c ccsContract, String notice_ID){
      this.noticeId = notice_ID;
      this.value = ccsContract.Contract_Value__c;
      this.supplierName = ccsContract.Supplier__r.name;
      
      // build supplier address
      this.supplierAddress =  '';
      this.supplierAddress += String.isBlank(ccsContract.Supplier__r.BillingStreet) ? '' : ccsContract.Supplier__r.BillingStreet;
      this.supplierAddress += String.isBlank(ccsContract.Supplier__r.BillingPostalCode) ? '' : ' ' + ccsContract.Supplier__r.BillingPostalCode;
      this.supplierAddress += String.isBlank(ccsContract.Supplier__r.BillingCity) ? '' : ' ' + ccsContract.Supplier__r.BillingCity;
      this.supplierAddress += String.isBlank(ccsContract.Supplier__r.BillingCountry) ? '' : ' ' + ccsContract.Supplier__r.BillingCountry;
      this.supplierAddress = this.supplierAddress.trim();

      this.contact = ccsContract.Supplier_Contact__r.name;
      this.dunsNumber = '' + ccsContract.Supplier__r.DUNS_Number__c;
      this.startDate = transformDateToString(ccsContract.Start_Date__c);
      this.endDate = transformDateToString(ccsContract.End_Date__c);
            if ((ccsContract.Supplier__r.SME_Status__c == 'Micro') || 
                (ccsContract.Supplier__r.SME_Status__c == 'Small') ||
                (ccsContract.Supplier__r.SME_Status__c == 'Medium') ||
                (ccsContract.Supplier__r.SME_Status__c == 'SME (Unclassified)')){
                    this.awardedToSME = true;
                }else{
                    this.awardedToSME = false;
                }
      this.awardedToVCSO = ccsContract.Supplier__r.Voluntary_Sector_Organisation__c;
      this.awardedDate = transformDateToString(ccsContract.Date_Contract_Awarded__c);
      this.awardedProcedureType = ccsContract.OJEU_Procedure_Type__c;
    }
  }  

  /***************************************************************************************
  Name: CFI_MessageFactory.Publish

  Purpose: Wrapper class for publish call responce
  ***************************************************************************************/
  public class Publish{
    public String noticeId;
    public String comment;
    public Boolean visibleToPublic;

    public Publish(String notice_ID, String publishComment, Boolean isVisibleToPublic){
      this.noticeId = notice_ID;
      this.comment = publishComment;
      this.visibleToPublic = isVisibleToPublic;
    }
  }

  /***************************************************************************************
  Name: CFI_MessageFactory.AdditionalDetails

  Purpose: Wrapper class for publish call responce
  ***************************************************************************************/
  public class AdditionalDetails{
    public String noticeId;
    public String description;
    public String dataType;
    public String textData;
    public String link;
    public String mimeType;
    public String filename;
    public String fileContent;
    public String awardGuid;

    public AdditionalDetails (String notice_Id, String text){
      noticeId = notice_Id;
      description = getCSMapping('ADDITIONAL_DETAIL_DESC','Additional text');
      dataType = 'AdditionalText';
      textData = text;
    }
  }
}