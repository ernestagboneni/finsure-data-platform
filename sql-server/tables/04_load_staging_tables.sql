PRINT '================================================================'
PRINT 'Load the main staging tables where that will be cleaned or transformed'
PRINT '================================================================'
---=================================================================
---- Load claims table from source table
---=================================================================

INSERT INTO stg.Claims (
	claim_reference    
	,policy_reference   
	,claim_date         
	,claim_type         
	,claim_status       
	,reserve_amount_gbp 
	,paid_amount_gbp    
	,handler_id         
	,days_open          
	,source_system   
	)
SELECT 
	claim_reference    
	,policy_reference   
	,claim_date         
	,claim_type         
	,claim_status       
	,ISNULL(reserve_amount_gbp ,0)
	,ISNULL(paid_amount_gbp , 0)
	,handler_id         
	,days_open          
	,source_system   
FROM stg.fsa_claims_staging ;
---=================================================================
---- Load general ledger table from source table
---=================================================================

INSERT INTO stg.GeneralLedgers (
	gl_entry_id        
	,entry_date         
	,gl_account_code    
	,account_description
	,entry_type         
	,debit_gbp          
	,credit_gbp         
	,policy_reference   
	,period             
	,posted_by          
	,approved           
)

SELECT
	gl_entry_id        
	,entry_date         
	,gl_account_code    
	,account_description
	,entry_type         
	,debit_gbp          
	,credit_gbp         
	,policy_reference   
	,period             
	,posted_by          
	,approved           
FROM stg.fsa_general_ledger;

---=================================================================
---- Load payments table from source table
---=================================================================

INSERT INTO stg.Payments (
	payment_reference    
	,policy_reference     
	,payment_date         
	,payment_timestamp    
	,payment_method       
	,payment_amount_gbp   
	,payment_status       
	,bank_sort_code       
	,bank_account_number  
	,reconciled_flag   
)
SELECT 
	payment_reference    
	,policy_reference     
	,payment_date         
	,payment_timestamp    
	,payment_method       
	,payment_amount_gbp   
	,payment_status       
	,bank_sort_code       
	,bank_account_number  
	,reconciled_flag  
FROM stg.fsa_payments_staging;

---=================================================================
---- Load policies table from source table
---=================================================================

INSERT INTO stg.Policies (
	 policy_id            
	,underwriter_code     
	,policy_type          
	,risk_band            
	,region               
	,agent_id             
	,policy_start_date    
	,policy_end_date      
	,payment_frequency    
	,premium_amount       
	,warehouse_premium_gbp
	,premium_variance_gbp 
	,etl_status           
	,etl_processed_week   
	,source_system        
	,data_quality_flag    
)

SELECT 
	 policy_id            
	,underwriter_code     
	,policy_type          
	,risk_band            
	,region               
	,agent_id             
	,policy_start_date 
	,policy_end_date 
	,payment_frequency    
	,premium_amount       
	,warehouse_premium_gbp
	,premium_variance_gbp 
	,etl_status           
	,etl_processed_week   
	,source_system        
	,data_quality_flag    
FROM stg.fsa_premiums_staging; 

