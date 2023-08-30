from google.cloud import bigquery
import time


def batch_inference(request):
    request_json = request.get_json(silent=True)
    table_name = request_json['table_name']
    dataset_name = request_json['dataset_name']
    client = bigquery.Client()
    prompt_creation_query = f"""
     CREATE OR REPLACE TABLE {dataset_name}.{table_name}_prompts AS (
      WITH
          prompts_full AS (
        SELECT
            city,
            CONCAT('Generate a short explanation of around 20 words synthesising all the data into a easy to understand and actionable phrase of why customer are churning from a telecom provider, do not just repeat the most common issue. Output should be in JSON including the city with the following format  churn_reason: <actionable churn explanation here>, city: <city here>. The list of churning reasons is: ',STRING_AGG(Churn_Reason),'. City is: ',city) as prompt
      FROM {dataset_name}.{table_name}
    GROUP BY
      city )
      SELECT
          city,prompt
      FROM
        prompts_full )"""
    
    batch_inference_query = f"""
    CREATE OR REPLACE TABLE {dataset_name}.{table_name}_batch_inference AS 
    SELECT
        ml_generate_text_result['predictions'][0]['content'] AS generated_text,
        ml_generate_text_result['predictions'][0]['safetyAttributes'] AS safety_attributes,
    * EXCEPT (ml_generate_text_result)
FROM
    ML.GENERATE_TEXT(MODEL `{dataset_name}.llm_model`,
      (
          SELECT
            *
          FROM
          `{dataset_name}.{table_name}_prompts`
      ),
      STRUCT(
            0.2 AS temperature,
            120 AS max_output_tokens))"""

    client.query(prompt_creation_query)
    time.sleep(2)
    client.query(batch_inference_query)
    return {"response": "success"}
