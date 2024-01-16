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

# Display build information
echo "Building Flutter app for flavor: $flavor"

# Run flutter build command for the specified flavor and iOS
flutter build ios --flavor $flavor

# Check if the build was successful
if [ $? -eq 0 ]; then
  echo "Build completed successfully"

  # Archive the app
  xcodebuild archive -workspace ios/Runner.xcworkspace -scheme Runner -archivePath build/Runner.xcarchive

  # Export IPA
  xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/ -exportOptionsPlist exportOptions.plist

  # Check if the export was successful
  if [ $? -eq 0 ]; then
    echo "IPA export completed successfully"
    # Rename the generated IPA with a timestamp
    mv build/Runner.ipa "build/Runner_$(date '+%Y%m%d%H%M%S').ipa"
  else
    echo "Error: IPA export failed"
    exit 1
  fi
else
  echo "Error: Build failed"
  exit 1
fi
