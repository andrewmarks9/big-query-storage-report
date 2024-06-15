# big-query-storage-report
Big Query Storage Report

BigQuery Storage Report Script
This Bash script is designed to generate a report on the storage usage and forecast costs for datasets across multiple Google Cloud Platform (GCP) projects. The report is generated using a BigQuery query and the results are appended to a Google Sheets spreadsheet.

The script will perform the following steps:

Log the start time in the specified log file.
Execute a BigQuery query for each project in the projects array. The query retrieves storage usage metrics and forecast costs for datasets in the project.
Extract the query results as CSV rows.
Authenticate with the Google Sheets API using the provided service account key file.
Append the CSV rows to a worksheet in the specified Google Sheets spreadsheet.

Query Details
The BigQuery query used in the script retrieves the following information for each dataset:

Logical and physical storage sizes (active and long-term)
Compression ratios
Forecast costs for logical and physical storage based on predefined prices per GiB

Prerequisites
Before running the script, ensure that you have the following:

Google Cloud SDK: The script uses the bq command-line tool from the Google Cloud SDK to execute BigQuery queries. Install the Google Cloud SDK and initialize it with your GCP project.

Service Account Key: The script requires a service account key file with the necessary permissions to access BigQuery and Google Sheets. Create a service account and download the key file in JSON format.

Dependencies
The script relies on the following external tools and libraries:

bq (Google Cloud SDK)
jq (Command-line JSON processor)

BigQuery Permissions:

bigquery.tables.get - This permission is required to access the INFORMATION_SCHEMA.TABLE_STORAGE_BY_PROJECT system view, which provides storage usage metrics for tables in BigQuery.
bigquery.jobs.create - This permission is needed to create and execute the BigQuery query job.
Google Sheets Permissions:

https://www.googleapis.com/auth/spreadsheets - This scope is required to read and write data in Google Sheets.
https://www.googleapis.com/auth/drive - This scope is needed to access the Google Sheets file in Google Drive.
To grant these permissions to the service account, you can follow these steps:

Go to the Google Cloud Console and navigate to the "IAM & Admin" section.
Click on "Service Accounts" and select the service account you want to use for the script.

Configuration
Before running the script, you need to update the following variables:

SA_KEY_FILE: Set this to the path of your service account key file (e.g., /path/to/sa.json).
LOG: Set this to the path where you want the log file to be created (e.g., /path/to/log.txt).
projects: Update this array with the list of GCP project IDs you want to include in the report.
sheet_id: Set this to the ID of the Google Sheets spreadsheet where you want to append the results.

Usage
To run the script, execute the following command:

bash bq_storage_report.sh


The script will perform the following steps:

Log the start time in the specified log file.
Execute a BigQuery query for each project in the projects array. The query retrieves storage usage metrics and forecast costs for datasets in the project.
Extract the query results as CSV rows.
Authenticate with the Google Sheets API using the provided service account key file.
Append the CSV rows to a worksheet in the specified Google Sheets spreadsheet. The worksheet name will be <project>_results.
Log any errors or success messages.
Query Details
The BigQuery query used in the script retrieves the following information for each dataset:

Logical and physical storage sizes (active and long-term)
Compression ratios
Forecast costs for logical and physical storage based on predefined prices per GiB
The query filters the results to include only base tables, as these typically provide the most accurate storage usage information. The results are ordered by the sum of active logical and physical forecast costs in descending order.


