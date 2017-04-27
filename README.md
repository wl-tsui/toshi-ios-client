![Token iOS Cover](https://raw.githubusercontent.com/tokenbrowser/token-ios-client/master/GitHub/cover-2.png)

![Screenshots](https://raw.githubusercontent.com/tokenbrowser/token-ios-client/master/GitHub/screenshots-1.png)
## Running the project

- Open `Token.xcworkspace` and run

## Formatting

We use [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to keep a consistent style in our source code. 

The full script can be found here.

```
swiftformat --disable braces,wrapArguments -enable trailingClosures --self insert --indent 4 --allman false --wrapelements beforefirst --exponentcase lowercase --stripunusedargs always --insertlines disabled --binarygrouping none --empty void --ranges spaced --trimwhitespace always --hexliteralcase uppercase --linebreaks lf --decimalgrouping none --commas always --comments indent --octalgrouping none --hexgrouping none --patternlet inline --semicolons inline Tests Token
```
