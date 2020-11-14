#!/usr/bin/env python3
# coding: utf-8

"""
Small cli to manage build and versioning
"""

import argparse
import os
import subprocess
import sys
from packaging import version # pip(3) install packaging

def syscall(command: str) -> str:
    """Excute `command` and returns stdout"""
    process = subprocess.Popen([command], stdout=subprocess.PIPE, shell=True)
    return process.stdout.read().decode().lower()

def create_version(new_version: str) -> bool:
    """Create a git tag with `new_version` and replace version number in .pbxproj"""
    # Ensure `version` does not exist and is superior to previous one
    all_git_tags = syscall("git tag").split('\n')
    pv = version.parse(new_version)
    for t in all_git_tags:
        if pv <= version.parse(t):
            print(f"[!] ERROR: Version {new_version} <= {t}")
            return False

    # Edit pbxproj
    os.system(f"xcrun agvtool new-marketing-version {new_version}")
    # Commit
    os.system("git add rsrc/ios/Info.plist rsrc/widget/Info.plist Shinobu.xcodeproj")
    os.system(f"git commit -m 'version {new_version}'")
    # git tag
    os.system(f'git tag -a {new_version} -m "Version {new_version}"')

    return True

def push_to_git():
    """git push --follow-tags"""
    os.system("git push --follow-tags")

def create_ipa(configuration='Release') -> bool:
    """Execute xcodebuild to create an IPA"""
    # Use libmpdclient distrib lib (only arm64 arch with bitcode)
    os.system("mv src/common/libmpdclient/src/liblibmpdclient-ios.a src/common/libmpdclient/src/liblibmpdclient-ios.a.bak")
    os.system("mv src/common/libmpdclient/src/liblibmpdclient-ios-prod.a src/common/libmpdclient/src/liblibmpdclient-ios.a")
    # Create xcarchive
    path_build = "build"
    path_xcarchive = f"{path_build}/Shinobu.xcarchive"
    os.system(f"xcodebuild -project Shinobu.xcodeproj -scheme Shinobu_App -sdk iphoneos -configuration {configuration} archive -archivePath {path_xcarchive}")
    # create ipa from the xcarchive
    os.system(f"xcodebuild -exportArchive -archivePath {path_xcarchive} -exportOptionsPlist utils/export_options.plist -exportPath {path_build}")
    # Re-swap libmpdclient
    os.system("mv src/common/libmpdclient/src/liblibmpdclient-ios.a src/common/libmpdclient/src/liblibmpdclient-ios-prod.a")
    os.system("mv src/common/libmpdclient/src/liblibmpdclient-ios.a.bak src/common/libmpdclient/src/liblibmpdclient-ios.a")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--version", action="store", dest="version", type=str, help="Create a new version (git tag and edit pbxproj)")
    parser.add_argument("-e", "--export", action="store_true", dest="export", default=False, help="Create the .ipa")
    parser.add_argument("-p", "--push", action="store_true", dest="push", default=False, help="Push the version to git")
    args = parser.parse_args()

    if os.path.exists("Shinobu.xcodeproj") is False:
        print("[!] ERROR: This script must be executed from the shinobu root directory (ie: utils/cli.py -v x.y.z)")
        sys.exit(-1)

    if args.version is not None and len(args.version) >= 1:
        create_version(args.version)
        if args.push is True:
            push_to_git()

    if args.export is True:
        create_ipa()
