/**
 * @description       : 
 * @author            : Satish Chandrashekar
 * @group             : 
 * @last modified on  : 08-24-2021
 * @last modified by  : Satish Chandrashekar
 * Modifications Log 
 * Ver   Date         Author                 Modification
 * 1.0   03-15-2021   Satish Chandrashekar   Initial Version
**/
public with sharing class CreditController {

    // Initial Related List Loading SOQL
    @AuraEnabled(cacheable=true)
    public static List<LLC_BI__Legal_Entities__c> getContacts(id loanid){
    List<LLC_BI__Legal_Entities__c> entlist;
    try{
        entlist =  [SELECT Id,LLC_BI__Account__c, Associated_Relationship__c, LLC_BI__Account__r.Name,LLC_BI__Borrower_Type__c,LLC_BI__Is_Borrower__c,LLC_BI__Is_CoBorrower__c,LLC_BI__Is_Grantor__c,LLC_BI__Is_Guarantor__c,LLC_BI__Loan__c,LLC_BI__Loan__r.LLC_BI__Amount__c, LLC_BI__Account__r.LLC_BI__Credit_Stats__c  FROM LLC_BI__Legal_Entities__c WHERE LLC_BI__Loan__c =: loanid WITH SECURITY_ENFORCED ];
    }
    catch(System.QueryException e){
        System.debug(e.getMessage());
    }
    system.debug(entlist);  
    return entlist;
    } 

    @AuraEnabled
    Public Id accid {get;set;}
    @AuraEnabled
    Public String entype {get;set;}
    @AuraEnabled
    Public Id loanid {get;set;}
    

    // Pass the Values from AuraJS / LWCJS to APEX class
    @AuraEnabled(cacheable=false)
    public Static String creditController(id accid, string entype, id loanid){
        
        system.debug('Received from Controller: ' + accid);
        system.debug('Received Borrower Type: '+ entype);
        system.debug('Received LoanId: '+ loanid);
        
        string vcrdId = entype;
        Id vloanId = loanid;
        Id vacctId = accid;
        string rtype;
       //CreditRequestProcess.notify(vacctId, vloanId, vcrdId, rtype);
        
        Id accrecid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeID();
        Id conrecid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('EMEA - Individual').getRecordTypeID();

        List<LLC_BI__Loan__c> loan;
        List<Account> acc;
        List<Contact> con;

        try{
            loan = [SELECT LLC_BI__Amount__c FROM LLC_BI__Loan__c WHERE Id = :loanid WITH SECURITY_ENFORCED LIMIT 1];
            acc = [SELECT Id, RecordTypeId, ABN_Number__c  FROM Account WHERE Id = :accid WITH SECURITY_ENFORCED LIMIT 1];
            con = [SELECT Id, BirthDate, LLC_BI__Primary_Contact__c FROM CONTACT WHERE AccountId = :accid AND LLC_BI__Primary_Contact__c = TRUE WITH SECURITY_ENFORCED LIMIT 1];
        }
        catch(System.QueryException qe){
            System.Debug(qe.getMessage());
        }

        
        string amt = String.ValueOf(loan[0].LLC_BI__Amount__c);
        string abncheck = acc[0].ABN_Number__c;
        Id rectype = acc[0].RecordTypeId;
		string bdate = String.valueOf(con[0].BirthDate);        
        try{       	
            //Consumer and Commercial Split
            IF(rectype == accrecid){
                    IF(amt != NULL && abncheck !=NULL){
                        system.debug('Invoke the Equifax Business Request ');
                        //Call the Commercial Equifax Report Request Class
                        //string type = 'Business';
                        //CreditRequestProcess.notify(vacctId, vloanId, vcrdId);
                    }
                    ELSE{
                        system.debug('Loan Amount or ABN is NULL');
                    }
            }  
            ELSE IF(rectype == conrecid){
                IF(amt != NULL && bdate !=NULL){
                   //Call the Consumer Equifax Report Request Class
                    rtype = 'Consumer';
                    CreditRequestProcess.notify(vacctId, vloanId, vcrdId, rtype);
                }
                ELSE{
                    system.debug('Loan Amount OR BirthDate is Null');
                }
            }
        }	
        Catch(exception e){
            system.debug('Error' + e.getMessage());
        } 
        
        return Null;
    } 
}