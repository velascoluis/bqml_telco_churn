#!/bin/sh
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#........................................................................
# Purpose: Setup demo
#........................................................................

ERROR_EXIT=1

if [ ! "${CLOUD_SHELL}" = true ]; then
    echo "This script needs to run on Google Cloud Shell. Exiting ..."
    exit ${ERROR_EXIT}
fi

if [ "${#}" -ne 1 ]; then
    echo "Illegal number of parameters. Exiting ..."
    echo "Usage: ${0} <gcp_project_id>"
    echo "Exiting ..."
     exit ${ERROR_EXIT}
fi

GCLOUD_BIN=`which gcloud`
if [ ! $? -eq 0 ]; then
    echo  "gcloud not found"
    echo "Exiting ..."
    exit ${ERROR_EXIT}
fi
BQ_BIN=`which bq`
if [ ! $? -eq 0 ]; then
    echo  "bq not found"
    echo "Exiting ..."
    exit ${ERROR_EXIT}
fi
JQ_BIN=`which jq`
if [ ! $? -eq 0 ]; then
    echo  "jq not found"
    echo "Exiting ..."
    exit ${ERROR_EXIT}
fi
SED_BIN=`which sed`
if [ ! $? -eq 0 ]; then
    echo  "sed not found"
    echo "Exiting ..."
    exit ${ERROR_EXIT}
fi

GCP_PROJECT_ID=${1}
REGION_ID_MULTI="US"
REGION_ID="us-central1"
CONN_ID="genai"
DATASET_ID="telco_llm"
TABLE_ID="customer_churn"
MODEL_ID="llm_model"
CFN_ID="batch_inference"
DATA_PATH="../data/telecom_customer_churn.csv"

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Creating BigQuery dataset ..."
"${BQ_BIN}" --location=${REGION_ID_MULTI} mk --dataset ${GCP_PROJECT_ID}:${DATASET_ID}

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Creating BigQuery table and loading records ..."
"${BQ_BIN}" load --autodetect --replace=True --source_format=CSV ${DATASET_ID}.${TABLE_ID} ${DATA_PATH}

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Deleting empty records  ..."
"${BQ_BIN}" query --nouse_legacy_sql "DELETE FROM \`${GCP_PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` WHERE Churn_Reason is NULL;"


LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Creating BigQuery external connection ..."
"${BQ_BIN}" mk --connection --location=${REGION_ID_MULTI} --project_id=${GCP_PROJECT_ID} --connection_type=CLOUD_RESOURCE ${CONN_ID}
CONN_SA_ID=`bq --format=prettyjson show --connection ${GCP_PROJECT_ID}.${REGION_ID_MULTI}.${CONN_ID} | "${JQ_BIN}" -r .cloudResource.serviceAccountId`
echo "Conn ID is ${CONN_SA_ID}"

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Creating BigQuery IAM policy bindings ..."
"${GCLOUD_BIN}" projects add-iam-policy-binding ${GCP_PROJECT_ID} --member=serviceAccount:${CONN_SA_ID} --role=roles/serviceusage.serviceUsageConsumer --condition=None
"${GCLOUD_BIN}" projects add-iam-policy-binding ${GCP_PROJECT_ID} --member=serviceAccount:${CONN_SA_ID} --role=roles/bigquery.connectionUser --condition=None

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Creating BigQuery LLM  ..."
"${BQ_BIN}" query --nouse_legacy_sql "CREATE OR REPLACE MODEL \`${GCP_PROJECT_ID}.${DATASET_ID}.${MODEL_ID}\` REMOTE WITH CONNECTION \`${GCP_PROJECT_ID}.${REGION_ID_MULTI}.${CONN_ID}\` OPTIONS (REMOTE_SERVICE_TYPE = 'CLOUD_AI_LARGE_LANGUAGE_MODEL_V1');"

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Deploying Cloud Function 1  ..."
"${GCLOUD_BIN}" functions deploy ${CFN_ID} --region=${REGION_ID} --runtime="python310" --source=cfn --entry-point="batch_inference" --trigger-http

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Deploying Cloud Function 2  ..."
"${GCLOUD_BIN}" functions deploy ${CFN_ID}_creative --region=${REGION_ID} --runtime="python310" --source=cfn_creative --entry-point="batch_inference_creative" --trigger-http


LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Ammending streamlit file  ..."
"${SED_BIN}"  s=___PROJECT_ID___=${GCP_PROJECT_ID}= frontend.py.template > frontend.py.tmp
"${SED_BIN}"  s=___CFN_TRIGGER___=https://${REGION_ID}-${GCP_PROJECT_ID}.cloudfunctions.net/${CFN_ID}= frontend.py.tmp > frontend.py

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Ammending build file  ..."
"${SED_BIN}"  s=___PROJECT_ID___=${GCP_PROJECT_ID}= build_cloud_run_frontend.sh.template > build_cloud_run_frontend.sh.tmp
"${SED_BIN}" s=___REGION_ID___=${REGION_ID}= build_cloud_run_frontend.sh.tmp > build_cloud_run_frontend.sh

LOG_DATE=`date`
echo "###########################################################################################"
echo "${LOG_DATE} Setup complete!"




