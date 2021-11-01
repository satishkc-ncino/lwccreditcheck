public class EquifaxResponseParser {

    private String response;
    private Id loanId;
    private final String SOAPENV_NAMESPACE = 'http://schemas.xmlsoap.org/soap/envelope/';
    private final String VS_NAMESPACE = 'http://vedaxml.com/vxml2/vedascore-apply-v2-0.xsd';
    private final String CONSUMER_ENQUIRY_TYPE = 'Consumer';
    private final String COMMERCIAL_ENQUIRY_TYPE = 'Commercial';
    public Map<String, Equifax_Genesis_FieldMap__mdt> genesisFields;
    //public String resdata;
    
    {
        this.genesisFields = getGenesisFieldsToCapture();
      system.debug(genesisFields);
    }
    
    // Constructor
    public EquifaxResponseParser(String response, Id loanId){  
        this.response = response;
        this.loanId = loanId;
    }
    
    
////GET FIELD MAP FOR DATA TYPE////


 private Map<String, Equifax_Genesis_FieldMap__mdt> getGenesisFieldsToCapture(){
        Map<String, Equifax_Genesis_FieldMap__mdt> genesisFieldMap = new Map<String, Equifax_Genesis_FieldMap__mdt>();
        
        // get genesis field mdt records
        List<Equifax_Genesis_FieldMap__mdt> genesisFields = [SELECT Id, Label, Genesis_Field_Name__c, Field_Description__c, Data__c, Active__c  
                                                           FROM Equifax_Genesis_FieldMap__mdt];
        
        // loop and get labels, which are the field ids
        for(Equifax_Genesis_FieldMap__mdt genesisField: genesisFields){
            genesisFieldMap.put(genesisField.Label, genesisField);
        }
        
        return genesisFieldMap;
    }    
    
///////DE CONSTRUCT THE RESPONSE    
    public ResponseFields parseXml(){
        ResponseFields responseFields = new ResponseFields();
       
        DOM.Document doc = new DOM.Document();
        doc.load(this.response);
        //system.debug('The response is being parsed'+ response);
        
		DOM.XmlNode productHeader = getProductHeader(doc);
        DOM.XmlNode productData = getProductData(doc);
        
        responseFields.productHeader = parseHeader(productHeader);
        //system.debug(productData);
        //system.debug(productHeader);
    //muting for testing purpose    
        if(productData == null){
            return null;
        }
        
        responseFields.score = parseScore(productData);
        responseFields.primaryMatch = parsePrimaryMatch(productData);
        responseFields.employment = parseEmployment(productData);
        responseFields.characteristics = parseCharacteristics(productData);
      
        return responseFields;

    }  
    
    
// FUNCTION TO EXTRACT THE PRODUCT HEADER    
    private DOM.XmlNode getProductHeader(DOM.Document doc){
        // get envelope
        DOM.XmlNode envelope = doc.getRootElement();
        
        // get body
        DOM.XmlNode body = envelope.getChildElement('Body', SOAPENV_NAMESPACE);
        if(body == null){
            return null;
        }
        
        // check for errors by checking for fault node
        DOM.XmlNode faultNode = body.getChildElement('Fault', SOAPENV_NAMESPACE);
        if(faultNode != null){
            return null;
        }
        
        // get response element
        DOM.XmlNode responseElement = body.getChildElement('response', VS_NAMESPACE);        
        // get productData element
        DOM.XmlNode productHeader = responseElement.getChildElement('product-header', VS_NAMESPACE);
        
        return productHeader;
    }
    
    
//FUNCTION TO EXTRACT THE PRODUCT DATA    
    private DOM.XmlNode getProductData(DOM.Document doc){
     	// get envelope
        DOM.XmlNode envelope = doc.getRootElement();
        
        // get body
        DOM.XmlNode body = envelope.getChildElement('Body', SOAPENV_NAMESPACE);
        if(body == null){
            return null;
        }
        
        // check for errors by checking for fault node
        DOM.XmlNode faultNode = body.getChildElement('Fault', SOAPENV_NAMESPACE);
        if(faultNode != null){
            return null;
        }
        
        // get response element
        DOM.XmlNode responseElement = body.getChildElement('response', VS_NAMESPACE);
        
        // get productData element
        DOM.XmlNode productData = responseElement.getChildElement('product-data', VS_NAMESPACE);
        
        return productData;
    }

    
//////SET PRODUCT HEADER FIELDS//////
    private ProductHeader parseHeader(DOM.XmlNode productHeader){
        ProductHeader proheader = new ProductHeader();
        
        proheader.enquiryId = productHeader.getChildElement('enquiry-id', VS_NAMESPACE).getText();
        proheader.operatorId = productHeader.getChildElement('operator-id', VS_NAMESPACE).getText();
        proheader.datalevel = productHeader.getChildElement('product-data-level', VS_NAMESPACE).getText();
        proheader.clientreference = productHeader.getChildElement('client-reference', VS_NAMESPACE).getText();
        string resdata = productHeader.getChildElement('product-data-level', VS_NAMESPACE).getText();
        proheader.permissiontype = productHeader.getChildElement('product-data-level' , VS_NAMESPACE).getText();
        system.debug(resdata);
        //this.genesisFields = getGenesisFieldsToCapture(resdata);
        
        return proheader;
    }

/* PARSE PRODUCT DATA SECTION */    
    
////////////////////SCORE PARSER///////////
    private ScoreClass parseScore(DOM.XmlNode productData){
        ScoreClass score = new ScoreClass();
        
        // get score data element
        DOM.XmlNode scoreData = productData.getChildElement('score-data', VS_NAMESPACE);
        
        // get score element
        DOM.XmlNode scoreElement = scoreData.getChildElement('score', VS_NAMESPACE);
        
        // populate score wrapper with XML response data
        score.masterscale = scoreElement.getChildElement('score-masterscale', VS_NAMESPACE).getText();
        score.riskOdds = Decimal.valueOf(scoreElement.getChildElement('risk-odds', VS_NAMESPACE).getText());
        
        // set score wrapper scorecard field
       score.scorecard = parseScoreCard(scoreElement);
        
        // get contributing factors
   		score.contributingFactors = parseContributingFactors(scoreElement);
        
        return score;
    }

    
///// EMPLOYMENT FUNCTION//////   
    private List<Employer> parseEmployment(DOM.XmlNode productData){
        List<Employer> employment = new List<Employer>();
        
        // get enquiry-report element
        DOM.XmlNode enquiryReport = productData.getChildElement('enquiry-report', VS_NAMESPACE);
        if(enquiryReport == null){
            return null;
        }
        // get employment element
        DOM.XmlNode employmentElement = enquiryReport.getChildElement('employment', VS_NAMESPACE);
        
        if(employmentElement == null){
            return null;
        }
        
        // get employer nodes
        List<DOM.XmlNode> employers = employmentElement.getChildElements();
        
        // loop over list and parse employer elements
        for(DOM.XmlNode employer: employers){
            employment.add(parseEmployer(employer));
        }
        
        return employment;
    }
//////////EMPLOYER FUNCTION////////
    private Employer parseEmployer(DOM.XmlNode employer){
        Employer emp = new Employer();
        
        // populate primaryMatch wrapper with XML response data
        emp.name = employer.getChildElement('name', VS_NAMESPACE).getText();
        emp.type = employer.getAttribute('type', null);
        emp.firstReportedDate = getDate(employer.getAttribute('first-reported-date', null));
        emp.lastReportedDate = getDate(employer.getAttribute('last-reported-date', null));
        
        return emp;
    }
    
    
////////PRIMARY MATCH FUNCTION///////    
	private PrimaryMatchClass parsePrimaryMatch(DOM.XmlNode productData){
        PrimaryMatchClass primaryMatch = new PrimaryMatchClass();
        
        // get enquiry-report element
        DOM.XmlNode enquiryReport = productData.getChildElement('enquiry-report', VS_NAMESPACE);  
        // get primary-match element
        DOM.XmlNode primaryMatchElement = enquiryReport.getChildElement('primary-match', VS_NAMESPACE);
        // populate primaryMatch wrapper with XML response data
        primaryMatch.bureauReference = primaryMatchElement.getChildElement('bureau-reference', VS_NAMESPACE).getText();
        primaryMatch.gender = primaryMatchElement.getChildElement('gender', VS_NAMESPACE).getText();
  		primaryMatch.dateOfBirth = getDateOfBirth(primaryMatchElement);
        
        // set primaryMatch warpper individualName field
		primaryMatch.individualName = parseIndividualName(primaryMatchElement);
        
        // get drivers licence number
        primaryMatch.driversLicenceNumber = parseDriversLicence(primaryMatchElement);
        
        return primaryMatch;
    }
	
    private Date getDateOfBirth(DOM.XmlNode primaryMatchElement){
        DOM.XmlNode dateOfBirth = primaryMatchElement.getChildElement('date-of-birth', VS_NAMESPACE);
        
        if(dateOfBirth == null){
            return null;
        }
        return getDate(dateOfBirth.getText());
    }
    
	private IndividualNameClass parseIndividualName(DOM.XmlNode primaryMatchElement){
        IndividualNameClass individualName = new IndividualNameClass();
        
        // get individual-name element
        DOM.XmlNode individualNameElement = primaryMatchElement.getChildElement('individual-name', VS_NAMESPACE);
        
        // populate primaryMatch wrapper with XML response data
        individualName.familyName = individualNameElement.getChildElement('family-name', VS_NAMESPACE).getText();
        individualName.firstGivenName = individualNameElement.getChildElement('first-given-name', VS_NAMESPACE).getText();
        individualName.otherGivenName = getOtherGivenName(individualNameElement);
        individualName.firstReportedDate = getDate(individualNameElement.getAttribute('first-reported-date', null));
        individualName.lastCreditReportedDate = getDate(individualNameElement.getAttribute('last-credit-enquiry-date', null));
        individualName.lastReportedDate = getDate(individualNameElement.getAttribute('last-reported-date', null)); 
        
        return individualName;
    }    
////////Function to Get Drivers License/////////    
    private String parseDriversLicence(DOM.XmlNode primaryMatchElement){
        DOM.XmlNode driversLicence = primaryMatchElement.getChildElement('drivers-licence', VS_NAMESPACE);
        
        if(driversLicence == null){
            return null;
        }
        
        String driversLicenceNumber = driversLicence.getChildElement('number', VS_NAMESPACE).getText();
        return driversLicenceNumber;
    }
/////GET Other Name//////////
	private String getOtherGivenName(DOM.XmlNode individualNameElement){
        DOM.XmlNode otherGivenName = individualNameElement.getChildElement('other-given-name', VS_NAMESPACE);
        
        if(otherGivenName == null){
            return null;
        }
        return otherGivenName.getText();
    }

////////////// GET DATE IN RIGHT FORMAT/////////    
    private Date getDate(String data){
        if(data == null){
            return null;
        }
        List<String> dateParts = data.split('-');
        return Date.newInstance(Integer.valueOf(dateParts.get(0)), Integer.valueOf(dateParts.get(1)), Integer.valueOf(dateParts.get(2)));
    }    
    
/////GET SCORECARD /////////NOT SURE IF THIS IS REQUIRED//

    private ScoreCardClass parseScoreCard(DOM.XmlNode scoreElement){
        ScoreCardClass scoreCard = new ScoreCardClass();
        
        // get scoreCard element
        DOM.XmlNode scoreCardElement = scoreElement.getChildElement('scorecard', VS_NAMESPACE);
        
        // populate scoreCard wrapper with XML response data
        scoreCard.name = scoreCardElement.getChildElement('name', VS_NAMESPACE).getText();
        scoreCard.type = scoreCardElement.getChildElement('type', VS_NAMESPACE).getText();
        scoreCard.version = Decimal.valueOf(scoreCardElement.getChildElement('version', VS_NAMESPACE).getText());
        scoreCard.dataLevel = scoreCardElement.getChildElement('data-level', VS_NAMESPACE).getText();
        
        return scoreCard;
    }
    
/////////////////GET Contribution Factors////////////
    private List<ContributingFactorClass> parseContributingFactors(DOM.XmlNode scoreElement){
        List<ContributingFactorClass> contributingFactors = new List<ContributingFactorClass>();
        
        // get key-contributing-factors element
        DOM.XmlNode keyContributingFactors = scoreElement.getChildElement('key-contributing-factors', VS_NAMESPACE);
        
        // get contributing-factor elements
        List<DOM.XmlNode> contributingFactorElements = keyContributingFactors.getChildElements();
        
        // loop over list and parse contributing-factor elements
        for(DOM.XmlNode contributingFactorElement: contributingFactorElements){
        	ContributingFactorClass contributingFactor = new ContributingFactorClass();
            
            contributingFactor.name = contributingFactorElement.getChildElement('name', VS_NAMESPACE).getText();
            contributingFactor.description = contributingFactorElement.getChildElement('description', VS_NAMESPACE).getText();
            contributingFactor.scoreImpactor = contributingFactorElement.getChildElement('score-impactor', VS_NAMESPACE).getText();
            
            contributingFactors.add(contributingFactor);
            
        }
        
        return contributingFactors;
    }    

//////CHARACTERSTICS FUNCTION//////BEST PLACE IS 
	private List<Characteristic> parseCharacteristics(DOM.XmlNode productData){
        List<Characteristic> characteristics = new List<Characteristic>();
        
        // get summary-data element
        DOM.XmlNode summaryData = productData.getChildElement('summary-data', VS_NAMESPACE);
        
        // get data-block element
        DOM.XmlNode dataBlock = summaryData.getChildElement('data-block', VS_NAMESPACE);
        
        // get characteristic elements
        List<DOM.XmlNode> characteristicElements = dataBlock.getChildElements();
        
        // get ids of Genesis fields that need to be captured
        Set<String> genesisFieldIds = this.genesisFields.keySet();
        
        // loop over list and parse characteristic elements
        for(DOM.XmlNode characteristic: characteristicElements){
            Characteristic characteristicToAdd = parseCharacteristic(characteristic, genesisFieldIds);
            
            // prevent nulls being added to list
            if(characteristicToAdd == null){
                continue;
            }
            characteristics.add(characteristicToAdd);
        }
         
        return characteristics;
    }
    
    /*
     * Parse characteristic element of XML response
     * 
     * @param characteristic: XML characteristic element
     * 
     * return Characteristic
     */
    private Characteristic parseCharacteristic(DOM.XmlNode characteristicElement, Set<String> genesisFieldIds){
        Characteristic ch = new Characteristic();
        
        
        // populate primaryMatch wrapper with XML response data
        ch.fieldId = characteristicElement.getAttribute('id', null);
        
        if(genesisFieldIds.contains(ch.fieldId)){
            ch.description = characteristicElement.getChildElement('description', VS_NAMESPACE).getText();
            ch.value = characteristicElement.getChildElement('value', VS_NAMESPACE).getText();
            return ch;
        }
        
        return null; 
    }
    


    
////////////////////////Fields WRAPPER Class/////////////    
  public class ResponseFields {
        public ScoreClass score;
        public PrimaryMatchClass primaryMatch;
        public List<Employer> employment;
        public ProductHeader productHeader;
        
        public List<CreditEnquiry> consumerCreditEnqiries;
        public List<CreditEnquiry> commercialCreditEnqiries;
        public List<DirectorShip> directorShips;
        public List<DirectorShip> disqualifiedDirectorShips;
        public List<Characteristic> characteristics;
    }
    
    public class ScoreClass {
        public String masterscale;
        public Decimal riskOdds;
        public ScoreCardClass scoreCard; 
        public List<ContributingFactorClass> contributingFactors;
    }
    
    public class ScoreCardClass {
        public String name;
        public String type;
        public Decimal version;
        public String dataLevel;
    }
    
    public class ContributingFactorClass {
        public String name;
        public String description;
        public String scoreImpactor;
    }
    
    public class PrimaryMatchClass {
        public String bureauReference;
        public IndividualNameClass individualName;
        public String gender;
        public Date dateOfBirth;
        public String driversLicenceNumber;
    }
    
    public class IndividualNameClass {
        public String familyName;
        public String firstGivenName;
        public String otherGivenName;
        public Date firstReportedDate;
        public Date lastCreditReportedDate;
        public Date lastReportedDate;
    }
    
    public class Employer {
        public String name;
        public String type;
        public Date firstReportedDate;
        public Date lastReportedDate;
    }
    
    public class CreditEnquiry {

        public Date enquiryDate;
        public String accountType; // Account Type
        public String enquiryAmount; 
        public String relationship; // Role
        public String enquirerName;
        public String referenceNumber; //id-reference
        public String classification; 
        public String enquiryType;// Consumer Enquiries /Commercial Enquries
    }
    
    public class ProductHeader {
        public String enquiryId;
        public String operatorId;
        public string datalevel;
        public string clientreference;
        public string permissiontype;
    }
    
    public class DirectorShip {
        
        public String abn;
        public String directorShipType;
        public String bureauId;
        public String referenceId;
        public String name;
        public String organisationNumber;
        public String status;
        public String organisationtype;
        public Date dateAppointed;
        public Date dateCeased;
        public Date dateDisqualified;
        public Date dateDisqualifiedUntil;
        public Date dateLastKnownasDirector;
    }
    public class Characteristic {
        public String fieldId;
        public String description;
        public String value;
    }
       

}