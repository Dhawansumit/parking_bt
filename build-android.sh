#!/bin/bash

# Parse command-line arguments
while getopts ":f:" opt; do
  case $opt in
    f)
      flavor=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Set default flavor if not provided
if [ -z "$flavor" ]; then
  flavor="development"
fi

# Set target file based on flavor
case $flavor in
  "production")
    target_file="lib/main_production.dart"
    ;;
  "development")
    target_file="lib/main_development.dart"
    ;;
  "staging")
      target_file="lib/main_staging.dart"
      ;;
  # Add more cases for other flavors if needed
  *)
    target_file="lib/main_development.dart"
    ;;
esac

# Display build information
echo "Building Flutter app for flavor: $flavor"
echo "Target File: $target_file"

# Run flutter build command for the specified flavor and target file
flutter build apk --flavor $flavor -t $target_file

# Check if the build was successful
if [ $? -eq 0 ]; then
  echo "Build completed successfully"
else
  echo "Error: Build failed"
  exit 1
fi
