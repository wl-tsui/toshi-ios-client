import UIKit
import AudioToolbox

public struct SoundPlayer {

    enum SoundType: String {
        case messageSent = "messageSent"
        case messageReceived = "messageReceived"
        case requestPayment = "requestPayment"
        case scanned = "scan"
        case addedContact = "addContactApp"
    }

    static let shared = SoundPlayer()

    fileprivate var sounds = [SystemSoundID]()

    fileprivate init() {
        self.sounds = [
            self.soundID(for: .messageSent),
        ]
    }

    func soundID(for type: SoundType) -> SystemSoundID {
        var soundID: SystemSoundID = 0

        guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "m4a") else { fatalError("Could not play sound!") }
        AudioServicesCreateSystemSoundID((url as NSURL), &soundID)

        return soundID
    }

    func playSound(type: SoundType) {
        guard UIApplication.shared.applicationState == .active else { return }

        let id = self.soundID(for: type)
        AudioServicesPlaySystemSound(id)
    }
}
