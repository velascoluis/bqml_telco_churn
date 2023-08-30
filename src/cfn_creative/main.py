from google.cloud import bigquery



def batch_inference_creative(request):
    request_json = request.get_json(silent=True)
    table_name = request_json['table_name']
    dataset_name = request_json['dataset_name']
    customer_id = request_json['customer_id']
    client = bigquery.Client()
   

    batch_inference_query = f"""SELECT
  ml_generate_text_result['predictions'][0]['content'] AS generated_text

FROM 
  ML.GENERATE_TEXT(MODEL `{dataset_name}.llm_model`,
    (  SELECT
   CONCAT('The following list contains customer information for a telecom company, the customer is churning, based on the facts the supplied data provide 5 ideas to prevent the churn. Use the provided data.',
  ' Gender: ', COALESCE(CAST(Gender AS STRING),'N/A'),
  ' , Age: ', COALESCE(CAST(Age AS STRING),'N/A'),
  ' , Married: ', COALESCE(CAST(Married AS STRING),'N/A'),
  ' , Number_of_Dependents: ', COALESCE(CAST(Number_of_Dependents AS STRING),'N/A'),
  ' , City: ', COALESCE(CAST(City AS STRING),'N/A'),
  ', Zip_Code: ', COALESCE(CAST(Zip_Code AS STRING),'N/A'),
   ', Latitude: ', COALESCE(CAST(Latitude AS STRING),'N/A'),
    ', Longitude: ', COALESCE(CAST(Longitude AS STRING),'N/A'),
     ', Number_of_Referrals: ', COALESCE(CAST(Number_of_Referrals AS STRING),'N/A'),
      ', Tenure_in_Months: ', COALESCE(CAST(Tenure_in_Months AS STRING),'N/A'),
       ', Offer: ', COALESCE(CAST(Offer AS STRING),'N/A'),
    ', Phone_Service: ', COALESCE(CAST(Phone_Service AS STRING),'N/A'),
    ', Avg_Monthly_Long_Distance_Charges: ', COALESCE(CAST(Avg_Monthly_Long_Distance_Charges AS STRING),'N/A'),
     ', Multiple_Lines: ', COALESCE(CAST(Multiple_Lines AS STRING),'N/A'),
      ', Internet_Service: ', COALESCE(CAST(Internet_Service AS STRING),'N/A'),
       ', Internet_Type: ', COALESCE(CAST(Internet_Type AS STRING),'N/A'),
        ', Avg_Monthly_GB_Download: ', COALESCE(CAST(Avg_Monthly_GB_Download AS STRING),'N/A'),
         ', Online_Security: ', COALESCE(CAST(Online_Security AS STRING),'N/A'),
          ', Online_Backup: ', COALESCE(CAST(Online_Backup AS STRING),'N/A'),
           ', Device_Protection_Plan: ', COALESCE(CAST(Device_Protection_Plan AS STRING),'N/A'),
            ', Premium_Tech_Support: ', COALESCE(CAST(Premium_Tech_Support AS STRING),'N/A'),
             ', Streaming_TV: ', COALESCE(CAST(Streaming_TV AS STRING),'N/A'),
              ', Streaming_Movies: ', COALESCE(CAST(Streaming_Movies AS STRING),'N/A'),
               ', Streaming_Music: ', COALESCE(CAST(Streaming_Music AS STRING),'N/A'),
                ', Unlimited_Data: ', COALESCE(CAST(Unlimited_Data AS STRING),'N/A'),
                 ', Contract: ', COALESCE(CAST(Contract AS STRING),'N/A'),
                  ', Paperless_Billing: ', COALESCE(CAST(Paperless_Billing AS STRING),'N/A'),
                   ', Payment_Method: ', COALESCE(CAST(Payment_Method AS STRING),'N/A'),
                    ', Monthly_Charge: ', COALESCE(CAST(Monthly_Charge AS STRING),'N/A'),
                     ', Total_Charges: ', COALESCE(CAST(Total_Charges AS STRING),'N/A'),
                      ', Total_Refunds: ', COALESCE(CAST(Total_Refunds AS STRING),'N/A'),
                       ', Total_Extra_Data_Charges: ', COALESCE(CAST(Total_Extra_Data_Charges AS STRING),'N/A'),
                        ', Total_Long_Distance_Charges: ', COALESCE(CAST(Total_Long_Distance_Charges AS STRING),'N/A'),
                         ', Total_Revenue: ', COALESCE(CAST(Total_Revenue AS STRING),'N/A')) AS prompt
  
   FROM `{dataset_name}.{table_name}`
  WHERE
    Customer_ID = "{customer_id}"),

      STRUCT( 0.2 AS temperature,
        120 AS max_output_tokens))"""

    df = client.query(batch_inference_query).to_dataframe()
    return df['generated_text'].astype(str)[0] 
