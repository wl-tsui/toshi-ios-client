![Token iOS Cover](https://raw.githubusercontent.com/tokenbrowser/token-ios-client/master/GitHub/cover.png)

## Running the project

- Open `Toshi.xcworkspace` and run

### Code formatting

We use [SwiftLint](https://github.com/realm/SwiftLint) and [Danger](https://github.com/danger/danger) to keep our code consistent and our PR's mergeable.

Check our SwiftLint [installation guide](https://github.com/toshiapp/toshi-ios-client/blob/master/installation-guide.md) to setup SwiftLint.

### Code Generation

We're using [Marathon](https://github.com/JohnSundell/Marathon) and [Stencil](https://github.com/kylef/Stencil). 

You should install Marathon using the Swift Package Manager, since installation with Homebrew isn't working correctly. Please use following steps, based on [Marathon's SPM instructions](https://github.com/JohnSundell/Marathon#on-macos), at the command line: 

1. `cd` into any directory where you would like to check out the Marathon source code. It does **not** need to be a sub-directory of Toshi (and probably shouldn't be so the Marathon source doesn't get checked in to git). 
2. `git clone https://github.com/JohnSundell/Marathon.git` - This will check out the source code into the current working directory.
3. `cd Marathon` - This will put you inside Marathon's main source code folder. 
4. `swift build -c release -Xswiftc -static-stdlib` - This will build Marathon for release as a static library. 
5. `cp -f .build/release/Marathon /usr/local/bin/marathon` - This will copy the static library into `/usr/local/bin/` so that it can be called from anywhere in the filesystem.  

Once this final step is complete, feel free to delete the folder where you checked Marathon out and built it, since you will be relying on the copied compiled binary instead of anything in that folder.

Additionally, there's some [weirdness going on with Stencil's test dependencies](https://github.com/kylef/Spectre/pull/34), so using a `Marathonfile` results in weird installation issues. In order to actually get Marathon to work for this project, please follow the following steps, IN THIS ORDER: 

1. Remove your macOS user's `~/.marathon` folder - this will remove all caches. [**NOTE**: This folder may not exist if you've never run Marathon before]
2. run `marathon add https://github.com/johnsundell/Files.git`
3. run `marathon add https://github.com/johnsundell/shellout.git`
4. run `marathon add https://github.com/kylef/Stencil.git`
5. **DO NOT** use `marathon update` until the issue with Stencil's dependencies is resolved.  

Once you've got Marathon set up, here's what you need to change to cause generated code to update when you build the **Debug** target: 

| Changes to File or Folder | Cause Marathon To Regenerate File |
|---|---|
| `Resources/Base.lproj/Localizable.strings` | `LocalizedStrings.swift`|
| `Resources/Base.lproj/Localizable.stringsdict` | `LocalizedPluralStrings.swift` |
| `Resources/Assets.xcassets` [recursive] | `AssetCatalog.swift` |

If you are making changes in any of these places and do NOT have Marathon installed, you will not be able to use the new assets or strings you're using with our fancy generated helpers. Please install Marathon using the steps above if you want to make changes. 
