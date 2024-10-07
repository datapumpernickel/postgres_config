#!/bin/bash

# Immediately exits if any error occurs during the script execution.
set -o errexit

# Creating an array that defines the environment variables
# that must be set. This can be consumed later via array
# variable expansion ${REQUIRED_ENV_VARS[@]}.
readonly REQUIRED_ENV_VARS=(
  "DB_USER"
  "DB_PASSWORD"
  "DB_DATABASE"
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
  # local db_user=$(cat "$DB_USER")
  # local password=$(cat "$DB_PASSWORD")
  # local database=$(cat "$DB_DATABASE")
  # local postgres_user=$(cat "$POSTGRES_USER_FILE")

  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER_FILE" <<-EOSQL
     CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
     CREATE DATABASE $DB_DATABASE;
     GRANT ALL PRIVILEGES ON DATABASE $DB_DATABASE TO $DB_USER;
     GRANT USAGE ON SCHEMA public TO $DB_USER;
     GRANT CREATE ON SCHEMA public TO $DB_USER;
     ALTER DATABASE $DB_DATABASE OWNER TO $DB_USER;
EOSQL
}



# Executes the main routine with environment variables
# passed through the command line.
main "$@"