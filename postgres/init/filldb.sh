#!/bin/bash

# Immediately exits if any error occurs during the script execution.
set -o errexit

# Creating an array that defines the environment variables
# that must be set. This can be consumed later via array
# variable expansion ${REQUIRED_ENV_VARS[@]}.
readonly REQUIRED_ENV_VARS=(
  "FILLA_DB_USER"
  "FILLA_DB_PASSWORD"
  "FILLA_DB_DATABASE"
)

# Main execution:
# - verifies if all environment variables are set
# - runs the SQL code to create user and database
main() {
  check_env_vars_set
  init_user_and_db
}

# Checks if all of the required environment
# variables are set. If one of them isn't,
# echoes a text explaining which one isn't
# and the name of the ones that need to be set.
check_env_vars_set() {
  for required_env_var in "${REQUIRED_ENV_VARS[@]}"; do
    if [[ ! -f "${!required_env_var}" ]]; then
      echo "Error:
    Secret file for environment variable '$required_env_var' not set.
    Make sure you have the following secret files set:
      ${REQUIRED_ENV_VARS[@]}
Aborting."
      exit 1
    fi
  done
}

# Performs the initialization in the already-started PostgreSQL
# using the preconfigured POSTGRES_USER user.
init_user_and_db() {
  local filla_db_user=$(cat "$FILLA_DB_USER")
  local filla_db_password=$(cat "$FILLA_DB_PASSWORD")
  local filla_db_database=$(cat "$FILLA_DB_DATABASE")
  local postgres_user=$(cat "$POSTGRES_USER_FILE")

  psql -v ON_ERROR_STOP=1 --username "$postgres_user" <<-EOSQL
     CREATE USER $filla_db_user WITH PASSWORD '$filla_db_password';
     CREATE DATABASE $filla_db_database;
     GRANT ALL PRIVILEGES ON DATABASE $filla_db_database TO $filla_db_user;
EOSQL
}


# Executes the main routine with environment variables
# passed through the command line.
main "$@"