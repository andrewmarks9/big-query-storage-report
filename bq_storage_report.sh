#!/bin/bash

# Update the script to use the correct path to the service account key file.
SA_KEY_FILE="/path/to/sa.json"
# Update the script to use the correct path to the log file.
LOG="/path/to/log.txt"

# Log message function
log() {
  echo "$(date) - $1" >> "$LOG"
}

log "starting"

# List of projects
projects=(project1 project2 project3)

# BigQuery query
query="
DECLARE active_logical_gib_price FLOAT64 DEFAULT 0.02;
DECLARE long_term_logical_gib_price FLOAT64 DEFAULT 0.01;
DECLARE active_physical_gib_price FLOAT64 DEFAULT 0.04;
DECLARE long_term_physical_gib_price FLOAT64 DEFAULT 0.02;

WITH
 storage_sizes AS (
   SELECT
     table_schema AS dataset_name,
     -- Logical
     SUM(active_logical_bytes) / power(1024, 3) AS active_logical_gib,
     SUM(long_term_logical_bytes) / power(1024, 3) AS long_term_logical_gib,
     -- Physical
     SUM(active_physical_bytes) / power(1024, 3) AS active_physical_gib,
     SUM(active_physical_bytes - time_travel_physical_bytes) / power(1024, 3) AS active_no_tt_physical_gib,
     SUM(long_term_physical_bytes) / power(1024, 3) AS long_term_physical_gib,
     -- Restorable previously deleted physical
     SUM(time_travel_physical_bytes) / power(1024, 3) AS time_travel_physical_gib,
     SUM(fail_safe_physical_bytes) / power(1024, 3) AS fail_safe_physical_gib,
   FROM
     `region-us-region`.INFORMATION_SCHEMA.TABLE_STORAGE_BY_PROJECT
   WHERE total_logical_bytes > 0
     AND total_physical_bytes > 0
     -- Base the forecast on base tables only for highest precision results
     AND table_type  = 'BASE TABLE'
     GROUP BY 1
 )
SELECT
  dataset_name,
  -- Logical
  ROUND(active_logical_gib, 2) AS active_logical_gib,
  ROUND(long_term_logical_gib, 2) AS long_term_logical_gib,
  -- Physical
  ROUND(active_physical_gib, 2) AS active_physical_gib,
  ROUND(time_travel_physical_gib, 2) AS time_travel_physical_gib,
  ROUND(long_term_physical_gib, 2) AS long_term_physical_gib,
  -- Compression ratio
  ROUND(SAFE_DIVIDE(active_logical_gib, active_no_tt_physical_gib), 2) AS active_compression_ratio,
  ROUND(SAFE_DIVIDE(long_term_logical_gib, long_term_physical_gib), 2) AS long_term_compression_ratio,
  -- Forecast costs logical
  ROUND(active_logical_gib * active_logical_gib_price, 2) AS forecast_active_logical_cost,
  ROUND(long_term_logical_gib * long_term_logical_gib_price, 2) AS forecast_long_term_logical_cost,
  -- Forecast costs physical
  ROUND((active_no_tt_physical_gib + time_travel_physical_gib + fail_safe_physical_gib) * active_physical_gib_price, 2) AS forecast_active_physical_cost,
  ROUND(long_term_physical_gib * long_term_physical_gib_price, 2) AS forecast_long_term_physical_cost,
  -- Forecast costs total
  ROUND(((active_logical_gib * active_logical_gib_price) + (long_term_logical_gib * long_term_logical_gib_price)) -
     (((active_physical_gib + fail_safe_physical_gib) * active_physical_gib_price) + (long_term_physical_gib * long_term_physical_gib_price)), 2) AS forecast_total_cost_difference
FROM
  storage_sizes
ORDER BY
  (forecast_active_logical_cost + forecast_active_physical_cost) DESC;
"

# Output sheet
# Set this value to a single sheet name to update a single sheet.
sheet_id="sheet_id_value"

# Set project in query
for project in "${projects[@]}"; do
  project_query="${query//project/$project}"

  # Run query
  result=$(bq query --use_legacy_sql=false --credential_file="$SA_KEY_FILE" "$project_query")

  # Extract rows
  rows=$(echo "$result" | jq -r '.[] | @csv')

  # Get worksheet name
  worksheet_name="${project}_results"

  # Sheets API scopes
  SCOPES=(
    'https://www.googleapis.com/auth/spreadsheets'
    'https://www.googleapis.com/auth/drive'
  )

  # Initialize Sheets API client
  credentials=$(service_account.Credentials.from_service_account_file(
    "$SA_KEY_FILE",
    scopes=SCOPES,
  ))

  service=$(build('sheets', 'v4', credentials=credentials))

  # Append rows
  response=$(service.spreadsheets().values().append(
    spreadsheetId="$sheet_id",
    range="${worksheet_name}!A1",
    valueInputOption='RAW',
    body={
      'values': ["${rows}"]
    }
  ).execute())

  # Check response
  if [ $? -ne 0 ]; then
    echo "Error appending rows: ${response}"
    exit 1
  fi

  echo "Rows appended successfully for project ${project}"
done
