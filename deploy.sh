#!/bin/sh

# This shell script simply copies the built plug-in to "~/Library/Graphics/Quartz Composer Plug-Ins" and overrides any previous version at that location

mkdir -p "${HOME}/Library/Graphics/Quartz Composer Plug-Ins"
rm -rf "${HOME}/Library/Graphics/Quartz Composer Plug-Ins/ImageWithKinect.plugin"
cp -rf "build/Release/ImageWithKinect.plugin" "${HOME}/Library/Graphics/Quartz Composer Plug-Ins/"
