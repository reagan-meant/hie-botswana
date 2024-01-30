#!/bin/bash

# Default values
source_dir="postman"
env_file="postman/bwhie.org.postman_environment.json"
collection_uuids=("1525496-77f89792-c73b-4c75-a450-5cb6f79230d4" "1525496-16a5a3c2-719f-40a6-ad06-a9530d3f2006" "1525496-8be9c19c-9e7b-4316-adea-3604884af5d7" "1525496-e7128a3a-616d-4fc8-8e4a-615990a97756")
collection_names=("Service Status Tests" "Client Registry Workflow" "Laboratory Order Workflow" "Omang, BDRS & Immigration")
publish=false


# Parse command line options
while getopts ":d:e:p" opt; do
  case $opt in
    d) source_dir="$OPTARG"
    ;;
    e) env_file="$OPTARG"
    ;;
    p) publish=true
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Set the default environment file if not specified
if [ -z "$env_file" ]; then
  env_file=$(find "$source_dir" -maxdepth 1 -name "*.postman_environment.json" | head -n 1)
fi

# Exit if no environment file is found
if [ -z "$env_file" ]; then
  echo "No environment file found."
  exit 1
fi

# Run newman for each collection file in the specified directory
for index in "${!collection_uuids[@]}"; do
  collection_uuid=${collection_uuids[$index]}  # Get the actual UUID value
  collection_name=${collection_names[$index]} 

  CYCLENAME="Postman Run on $env_name | collection: $collection_name | date: $(date +%Y%m%d%H%M)"

  # Construct newman command
  newman_cmd="newman run https://api.getpostman.com/collections/$collection_uuid?apikey=\"$POSTMAN_API_KEY\"  -e \"$env_file\" --delay-request 250"

  # Add publishing options if publish is true
  if $publish; then
    echo "Publishing results to Jira"
    newman_cmd+=" -r aiotests \
      --reporter-aiotests-enableReporting true \
      --reporter-aiotests-jiraProjectId 'BOT' \
      --reporter-aiotests-aioApiToken $API_TOKEN \
      --reporter-aiotests-jiraServer 'uwdigi.atlassian.net' \
      --reporter-aiotests-jiraPat $JIRA_PAT \
      --reporter-aiotests-createNewCycle 'true' \
      --reporter-aiotests-newCycleTitle \"$CYCLENAME\" \
      --reporter-aiotests-createNewRun 'true' \
      --reporter-aiotests-createCase 'true' \
      --reporter-aiotests-bddForceUpdateCase 'true'"
  fi

  echo "$newman_cmd"
  # Execute the constructed newman command
  eval "$newman_cmd"
done
