#!/usr/bin/ruby

# Information specific to the Toshi app
class Toshi

  # The username for an Apple account that can log in to the Apple Developer portal and iTunes Connect
  Username = "ios@bakkenbaeck.com"

  class TeamId
    # The Apple developer portal team ID for development/distribution via App Store
    Developer = "BH32JXCQWU"
    # The Apple developer portal team ID for Enterprise distribution
    Enterprise = "3TAZ984YN3"
  end

  # The names of build schemes available for build actions
  class BuildScheme
    Tests = "Tests"
    Debug = "Debug"
    Development = "Development"
    Distribution = "Distribution"
  end

  # Information specific to this app's branch and repo for Match.
  class MatchInfo
    RepoUrl = "https://github.com/bakkenbaeck/fastlane-match.git"
    Branch = "toshi"
  end

  # All bundle identifiers for this application and its assorted extensions.
  class BundleIdentifier
    Debug = "org.toshi.debug"
    Development = "no.bakkenbaeck.toshi.enterprise"
    Distribution = "org.toshi.distribution"
  end

  class File
    ProjectFile = "Toshi.xcodeproj"
    WorkspaceFile = "Toshi.xcworkspace"
  end

end
