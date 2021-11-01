public class EquifaxPayloadGen {

    private Account acc;
    private LLC_BI__Loan__c loan;
    private Equifax_Cred__mdt cred;
    private Contact con;
    private String usr;
    
    public EquifaxPayloadGen(Account acc, LLC_BI__Loan__c loan, Equifax_Cred__mdt cred, Contact con, String usr){
        this.acc = acc;
        this.loan = loan;
        this.cred = cred;
        this.con = con;
        this.usr = usr;
    }
    
    public string genXMLPayload(){
        string payload = genXMLHeader();
        	payload += genXMLBody();
        //system.debug(payload);
        return payload;
     
    }
    
    private string genXMLHeader(){
        
        string Header = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:vh="http://vedaxml.com/soap/header/v-header-v1-10.xsd" xmlns:ved="http://vedaxml.com/vxml2/vedascore-apply-v2-0.xsd">';
   			Header += 	'<soapenv:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">';
     		Header +=	'<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">';
        	Header +=	'<wsse:UsernameToken>';
        	Header +=	'<wsse:Username>'+ this.cred.username__c +'</wsse:Username>';
        	Header +=   '<wsse:Password>'+ this.cred.password__c +'</wsse:Password>';
        	Header +=   '</wsse:UsernameToken>';
      		Header +=   '</wsse:Security>';
      		Header +=   '<wsa:To>' + this.cred.endpoint__c + '</wsa:To>';
      		Header +=   '<wsa:Action>' + this.cred.actionurl__c + '</wsa:Action>';
  			Header +=   '</soapenv:Header>';
     
        return Header;
        
    }
    
    private string genXMLBody(){
        String loanId = this.loan.Id;
        String loanAmount =this.loan.LLC_BI__Amount__c!=null? String.valueOf(Integer.valueOf(this.loan.LLC_BI__Amount__c)):'0'; // convert Decimal to Integer, then String
    
    	string body = '<soapenv:Body>';
      			body +=   '<ved:request>';
         		body +=   '<ved:enquiry-header>';
            	body +=   '<ved:client-reference>' + this.con.AccountId +'</ved:client-reference>';
            	body +=   '<ved:operator-id>' + this.con.AccountId + '</ved:operator-id>'; //UserID of the person who clicks the button
        		body +=   '<ved:operator-name>' + this.con.AccountId + '</ved:operator-name>'; // User Name of the person who Clicks the button
            	body +=   '<ved:permission-type-code>'+ this.cred.PermissionType__c +'</ved:permission-type-code>';
                body +=   '<ved:product-data-level-code>'+ this.cred.DataLevel__c +'</ved:product-data-level-code>';
        /*    <ved:requested-scores>
               <ved:scorecard-id>VSA_2.0_XY_NR</ved:scorecard-id>
            </ved:requested-scores> */
            	body +=   '<ved:custom-input-parameters>';
               	body +=     '<ved:custom-input-parameter>';
                body +=    		'<ved:key>ITH</ved:key>';
                body +=         '<ved:value>true</ved:value>';
          		body +=      '</ved:custom-input-parameter>';
            	body +=   '</ved:custom-input-parameters>';
          	    body +=  '</ved:enquiry-header>';
        		body +=    '<ved:enquiry-data>';
            	body += 		'<ved:individual>';
                body +=     		'<ved:current-name>';
                body +=					'<ved:family-name>'+ this.con.LastName +'</ved:family-name>';
                body +=					'<ved:first-given-name>'+ this.con.FirstName +'</ved:first-given-name>';
                body +=					'<ved:other-given-name>'+this.con.Middle_Name__c+'</ved:other-given-name>'; // this needs to be verified as unable to find middle name in the Relationship Object.
            	body +=  			'</ved:current-name>';
               	body += 			getaddress();
    			body +=  			'<ved:drivers-licence>';
                body +=	 				'<ved:number>'+ this.con.LLC_BI__Drivers_License__c+'</ved:number>';
                body +=  			'</ved:drivers-licence>';
        		body +=  			getGenderCode();
               	body += 			getbirthdate();
               	body += 			'<ved:employment>';
                body +=					'<ved:employer type="C">';
                body +=    				 '<ved:name>'+ this.con.Employer__c +'</ved:name>';
                body +=					'</ved:employer>';
                body +=				'</ved:employment>';
            	body += 		'</ved:individual>';
            	body += 		'<ved:enquiry>';
                body +=          	'<ved:account-type-code>TF</ved:account-type-code>'; //This needs to be automated based on what type of Loan Type Retail Loan / Business Loan
                body +=				'<ved:enquiry-amount currency-code="AUD">'+ loanAmount +'</ved:enquiry-amount>';
                body +=				'<ved:relationship-code>'+ getrelationcode() +'</ved:relationship-code>'; // Get the relational Code based on the Entity Relationship
               	body +=				'<ved:enquiry-client-reference>'+ this.loan.Id +'</ved:enquiry-client-reference>';
            	body +=			'</ved:enquiry>';
         		body +=			'</ved:enquiry-data>';
      			body +=		'</ved:request>';
   				body +=		'</soapenv:Body>';
				body +=	'</soapenv:Envelope>';
    return body;
    }
    
    private String getAddress(){
       //Approach with Maps and Set
       /* Map<String, String> scode = New Map<String, String>{
            'New South Wales' => 'NSW',
            'Queensland' => 'QLD',
            'Australian Capital Territory' => 'ACT',
            'Victoria' => 'VIC',
            'South Australia' => 'SA',
            'Western Australia' => 'WA',
            'Tasmania' => 'TAS',
            'Northern Territory' => 'NT' 
        };
       string state = this.con.LLC_BI__Home_State__c;
       Set<String> sc = scode.KeySet();
        FOR(String scc :sc){
            
        } */
	//Converting the State Name to State Code	
       string state = this.con.LLC_BI__Home_State__c;
       string scode;
        switch on state {
            when 'New South Wales'{
                scode = 'NSW';
            }
            when 'Queensland'{
                scode = 'QLD';
            }
            when 'Australian Capital Territory'{
                scode = 'ACT';
            }
            when 'Victoria'{
                scode = 'VIC';
            }
            when 'South Australia'{
                scode = 'SA';
            }
            when 'Western Australia'{
                scode = 'WA';
            }
            when 'Tasmania'{
                scode = 'TAS';
            }
            when 'Northern Territory'{
                scode = 'NT';
            }
            when Else{
                scode = '';
            }
           
        }
        
        String ctry = this.con.Country__c;
        String Country;
        switch on ctry{
            When 'Australia'{
                Country = 'AUS';
            }
            When 'New Zealand'{
                Country = 'NZL';
            }
            When Else{
                Country ='';
            }
        }
        
       string address = '<ved:addresses>';
           address += 		'<ved:address type="C">';
           address +=			'<ved:street-number>'+''+'</ved:street-number>';
           address +=		     '<ved:street-name>'+ this.con.LLC_BI__Home_Address__c +'</ved:street-name>';
           address +=		     '<ved:street-type>'+ '' +'</ved:street-type>'; //Need to add new Type to identify the type
           address +=		     '<ved:suburb>'+ this.con.LLC_BI__Home_City__c + '</ved:suburb>';
           address +=		     '<ved:state>'+ scode +'</ved:state>';
           address +=		     '<ved:postcode>'+ this.con.LLC_BI__Home_ZipCode__c  +'</ved:postcode>';
           address +=		     '<ved:country-code>'+ Country +'</ved:country-code>';
           address +=		 '</ved:address>';
           address +=	'</ved:addresses> ';
        return address;
    }
    
    private string getGenderCode(){
        String gender = this.con.LLC_BI__Gender__c!=null?this.con.LLC_BI__Gender__c:'';
        string gencode;
        IF(gender == 'Male'){
             gencode = 'M';
        }
        ELSE{
            IF(gender == 'Female'){
                 gencode = 'F';
            }
            ELSE{
                 gencode = '';
            }
        }
        string gendercode =  '<ved:gender-code>'+ gencode +'</ved:gender-code>';
        return gendercode;
    }
    
    private string getBirthDate(){
        string bdate = string.valueOf(this.con.Birthdate);
        IF(bdate == null){
            return '';
        }
        ELSE{
        return '<ved:date-of-birth>'+ bdate +'</ved:date-of-birth>';
        }
            
    }
    
   private Integer getrelationcode(){
 		Integer relcode;
        string relc = this.usr;
       switch on relc{
           When 'Borrower'{
               relcode =1;
           }
           When 'Co-Borrower'{
               relcode = 2;
           }
           When 'Guarantor'{
               relcode = 3;
           }
           When 'Director'{
               relcode = 4;
           }
           When Else{
               relcode=1;
           }
       }
       return relcode;
     }
}