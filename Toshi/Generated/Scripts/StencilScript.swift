import Foundation
import Files
import PathKit
import ShellOut
import Stencil

// MARK: - Possible local errors

enum StencilScriptError: Error {
    case
    couldNotLoadDictionary,
    couldNotAccessPluralValues
}

// MARK: - Git Helpers

/// - Returns: An array of Strings representing files that have changed since the last commit. Each string is the path relative to the source root.
/// - Throws: Any error attempting to run the git command.
func changedFiles() throws -> [String] {
    let diff = try shellOut(to: ShellOutCommand(string: "git diff --name-only"))

    // Split the file names into an array
    return diff.components(separatedBy: "\n")
}

/// Determines if a particular file has changed given its file name only.
/// NOTE: Only useful for files with a unique name across the codebase.
///
/// - Parameter fileName: The name of the file, including any extensions
/// - Returns: true if the file has changed, false if not.
/// - Throws: Any error attempting to run the git command.
func hasFileChanged(named fileName: String) throws -> Bool {
    // Take the last path component of each file name
    let fileNamesInDiff = try changedFiles().compactMap { $0.components(separatedBy: "/").last }
    return fileNamesInDiff.contains(fileName)
}

func hasAnyFileChanged(in folder: Folder) throws -> Bool {
    let filesInDiff = try changedFiles()

    let changedInFolder = filesInDiff.filter { return $0.contains(folder.name) }
    return !changedInFolder.isEmpty
}

// MARK: - Filesystem Helpers

/// Loads a dictionary with string keys and string values.
///
/// - Parameter file: The file to load from the filesystem.
/// - Returns: The loaded dictionary
/// - Throws: An error if the dictionary could not be loaded or is of incorrect type.
func loadStringDictionary(from file: File) throws -> [String: String] {
    guard let dictionary = NSDictionary(contentsOfFile: file.path) as? [String: String] else {
        throw StencilScriptError.couldNotLoadDictionary
    }

    return dictionary
}

/// Loads a dictionary with `String` keys and `Any` values.
///
/// - Parameter file: The file to load from the filesystem.
/// - Returns: The loaded dictionary.
/// - Throws: An error if the dictionary could not be loaded or is of incorrect type.
func loadDictionary(from file: File) throws -> [String: Any] {
    guard let dictionary = NSDictionary(contentsOfFile: file.path) as? [String: Any] else {
        throw StencilScriptError.couldNotLoadDictionary
    }

    return dictionary
}

// MARK: - Helper classes for Stencil

struct LocalizedString {
    let key: String
    let value: String
}

struct LocalizedPlural {
    let key: String
    let values: [ String ]
}

struct ImageAsset {
    let name: String
    let variableName: String

    init(name: String) {
        self.name = name
        self.variableName = name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}

// MARK: - Functions taking existing information and preparing it to write

func localizableStrings(from baseLanguageFolder: Folder, fileName: String) throws -> [LocalizedString] {
    let localizableFile = try baseLanguageFolder.file(named: fileName)
    let localizableContents = try loadStringDictionary(from: localizableFile)
    let sortedKeys = localizableContents.keys.sorted()
    let localizedStrings: [LocalizedString] = sortedKeys.map { key in
        let value = localizableContents[key]!
        let valueWithoutNewlineCharacters = value.replacingOccurrences(of: "\n", with: "\\n")
        return LocalizedString(key: key, value: valueWithoutNewlineCharacters)
    }

    return localizedStrings
}

func localizablePlurals(from baseLanguageFolder: Folder, fileName: String) throws -> [LocalizedPlural] {
    let localizablePluralFile = try baseLanguageFolder.file(named: fileName)
    let pluralContents = try loadDictionary(from: localizablePluralFile)
    let sortedKeys = pluralContents.keys.sorted()
    let localizedPlurals: [LocalizedPlural] = try sortedKeys.map { key in
        guard
            let dictForCurrent = pluralContents[key] as? [String: Any],
            var valuesDict = dictForCurrent["value"] as? [String: String] else {
                throw StencilScriptError.couldNotAccessPluralValues
        }
        valuesDict.removeValue(forKey: "NSStringFormatSpecTypeKey")
        valuesDict.removeValue(forKey: "NSStringFormatValueTypeKey")
        let values = valuesDict.map { "\($0): \"\($1)\"" }
        return LocalizedPlural(key: key, values: values)
    }

    return localizedPlurals
}

func recursiveAssets(from folder: Folder) -> [ImageAsset] {
    let assetFolders = folder.subfolders.filter { $0.name.hasSuffix(".imageset") }
    let otherFolders = folder.subfolders.filter { !assetFolders.contains($0) }

    var assets = assetFolders.map { ImageAsset(name: $0.name.replacingOccurrences(of: ".imageset", with: "")) }
    otherFolders.forEach { assets.append(contentsOf: recursiveAssets(from: $0)) }

    return assets
}

func loadAssets(from assetCatalogFolder: Folder) -> [ImageAsset] {
    let assets = recursiveAssets(from: assetCatalogFolder)
    return assets.sorted(by: { $0.variableName.lowercased() < $1.variableName.lowercased() })
}

// MARK: - Functions to generate the code

func writeLocalizableFile(withLocalized localizedStrings: [LocalizedString],
                          inFolder codeFolder: Folder,
                          environment: Environment) throws {

}

func renderThenWrite(context: [String: Any],
                     withEnvironment environment: Environment,
                     fileName: String,
                     outputFolder codeFolder: Folder) throws {
    let fileContents = try environment.renderTemplate(name: "\(fileName).stencil", context: context)

    let file = try codeFolder.createFileIfNeeded(withName: fileName)
    try file.write(string: fileContents)
    print("Rendered \(file.name)")
}

// MARK: - Actual Script

guard let sourceRootPath = ProcessInfo.processInfo.environment["SRCROOT"] else {
    fatalError("Could not access source root!")
}

let rootFolder = try Folder(path: sourceRootPath)
let toshiFolder = try rootFolder.subfolder(named: "Toshi")
let resourcesFolder = try toshiFolder.subfolder(named: "Resources")
let baseLanguageFolder = try resourcesFolder.subfolder(named: "Base.lproj")
let generatedFolder = try toshiFolder.subfolder(named: "Generated")
let templatesFolder = try generatedFolder.subfolder(named: "Templates")
let codeFolder = try generatedFolder.subfolder(named: "Code")

let fileSystemLoader = FileSystemLoader(paths: [ Path(templatesFolder.path) ])
let environment = Environment(loader: fileSystemLoader)

// MARK: Localized strings

let localizableFileName = "Localizable.strings"
let localizableOutputName = "LocalizedStrings.swift"

if try hasFileChanged(named: localizableFileName) {
    let localizedStrings = try localizableStrings(from: baseLanguageFolder, fileName: localizableFileName)
    try renderThenWrite(context: [
                            "developer_language": "en",
                            "localized_strings": localizedStrings
                        ],
                        withEnvironment: environment,
                        fileName: localizableOutputName,
                        outputFolder: codeFolder)
} else {
    print("\(localizableFileName) hasn't changed, not regenerating \(localizableOutputName)")
}

// MARK: Localized plurals

let localizablePluralsFileName = "Localizable.stringsdict"
let localizablePluralOutputName = "LocalizedPluralStrings.swift"

if try hasFileChanged(named: localizablePluralsFileName) {
    let localizedPlurals = try localizablePlurals(from: baseLanguageFolder, fileName: localizablePluralsFileName)
    try renderThenWrite(context: [
                            "developer_language": "en",
                            "localized_plurals": localizedPlurals
                        ],
                        withEnvironment: environment,
                        fileName: localizablePluralOutputName,
                        outputFolder: codeFolder)
} else {
    print("\(localizablePluralsFileName) hasn't changed, not regenerating \(localizablePluralOutputName)")
}

let assetCatalogFolder = try resourcesFolder.subfolder(named: "Assets.xcassets")
let assetCatalogOutputName = "AssetCatalog.swift"

if try hasAnyFileChanged(in: assetCatalogFolder) {
    let assets = loadAssets(from: assetCatalogFolder)
    try renderThenWrite(context: [
                            "assets": assets
                        ],
                        withEnvironment: environment,
                        fileName: assetCatalogOutputName,
                        outputFolder: codeFolder)
} else {
    print("Nothing in \(assetCatalogFolder.name) has changged, not regenerating \(assetCatalogOutputName)")
}
