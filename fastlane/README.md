fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios match_fetch_all_the_things
```
fastlane ios match_fetch_all_the_things
```
Fetches all available keys and certs for this project
### ios itc
```
fastlane ios itc
```
Builds and uploads a signed version of the app to iTunes Connect
### ios beta
```
fastlane ios beta
```
Builds and uploads an enterprise-signed app to...somewhere!
### ios ci_test
```
fastlane ios ci_test
```
Builds and tests the application in development

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
