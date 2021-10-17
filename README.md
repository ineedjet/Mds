## Summary
Source code of a popular (10K downloads in the first three years) iOS application "Модель для Сборки. Архив"

## To build
1. Open `Mds.xcodeproj` in Xcode
2. Set up your own provisioning profile
3. Select Product → Build

## To release a new version
1. Update project version in `project.version` (if necessary)
2. Commit all changes
3. In Xcode, select Product → Archive
  * Custom build script will automatically assign build version, create new git commit and tag it
4. Run `./take-screenshots.sh` to generate screenshots (update the list of devices if necessary)
