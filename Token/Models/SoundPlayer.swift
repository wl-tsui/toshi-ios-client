import UIKit
import AudioToolbox

public struct SoundPlayer {

    enum SoundType: String {
        case messageSent = "messageSent"
        case messageReceived = "messageReceived"
        case scanned = "scan"
        case addedContact = "addContactApp"
        case requestPayment = "requestPayment"
        case paymentSend = "paymentSend"
        case menuButton = "menuButton"
    }

    static let shared = SoundPlayer()

    fileprivate var sounds = [SystemSoundID]()

    fileprivate init() {
        self.sounds = [
            self.soundID(for: .messageSent),
        ]
    }

    static func playSound(type: SoundType) {
        self.shared.playSound(type: type)
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
