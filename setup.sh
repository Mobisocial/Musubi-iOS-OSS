#!/bin/bash

#this script initializes a clean checkout of musubi and builds the libraries
#that are bundled in source code form.  after you checkout for the first time


echo FETCHING DEPENDENCIES
git submodule update --init

echo FETCHING SHAREKIT DEPENDENCIES
pushd Submodules/ShareKit
git submodule update --init --recursive
popd

echo BUILDING 320 LIBRARY
xcodebuild -scheme Three20 -sdk iphoneos -configuration Release build
xcodebuild -scheme Three20 -sdk iphoneos build
xcodebuild -scheme Three20 -sdk iphonesimulator build
