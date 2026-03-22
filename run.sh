#!/bin/bash
# Build and run MyOffGridAI Client — macOS native app connecting to 192.168.1.200:8080
flutter build macos "$@" && open build/macos/Build/Products/Release/myoffgridai_client.app
