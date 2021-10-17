xcodebuild -scheme 'MdsUITests' -destination 'platform=iOS Simulator,name=iPhone 13 Pro Max,OS=15.0' test || exit 1
xcodebuild -scheme 'MdsUITests' -destination 'platform=iOS Simulator,name=iPhone 6 Plus,OS=11.4' test || exit 1
xcodebuild -scheme 'MdsUITests' -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (5th generation),OS=15.0' test || exit 1
xcodebuild -scheme 'MdsUITests' -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (2nd generation),OS=11.4' test || exit 1
