// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

final class MessageFetcherJob: NSObject {

    enum MessageResponseKeys {
        static let messages = "messages"
        static let more = "more"
        static let type = "type"
        static let relay = "relay"
        static let timestamp = "timestamp"
        static let source = "source"
        static let sourceDevice = "sourceDevice"
        static let message = "message"
        static let content = "content"
    }

    private let networkManager: TSNetworkManager
    private let messageReceiver: OWSMessageReceiver
    private let signalService: OWSSignalService

    init(messageReceiver: OWSMessageReceiver, networkManager: TSNetworkManager, signalService: OWSSignalService) {
        self.messageReceiver = messageReceiver
        self.networkManager = networkManager
        self.signalService = signalService
    }

    public func run() {

        fetchUndeliveredMessages { [weak self] envelopes, more, _ in

            guard let strongSelf = self else { return }

            for envelope in envelopes {
                strongSelf.messageReceiver.handleReceivedEnvelope(envelope)
                strongSelf.acknowledgeDelivery(envelope: envelope)
            }

            if more {
                return strongSelf.run()
            }
        }
    }

    private func parseMessagesResponse(responseObject: Any?) -> (envelopes: [OWSSignalServiceProtosEnvelope], more: Bool)? {
        guard let responseObject = responseObject,
            let responseDict = responseObject as? [String: Any],
            let messageDicts = responseDict[MessageResponseKeys.messages] as? [[String: Any]] else {
                return nil
        }

        let moreMessages = { () -> Bool in
            if let responseMore = responseDict[MessageResponseKeys.more] as? Bool {
                return responseMore
            } else {
                return false
            }
        }()

        let envelopes = messageDicts.map { buildEnvelope(messageDict: $0) }.filter { $0 != nil }.map { $0! }

        return (
            envelopes: envelopes,
            more: moreMessages
        )
    }

    private func buildEnvelope(messageDict: [String: Any]) -> OWSSignalServiceProtosEnvelope? {
        let builder = OWSSignalServiceProtosEnvelopeBuilder()

        guard let typeInt = messageDict[MessageResponseKeys.type] as? Int32 else { return nil }
        guard let type = OWSSignalServiceProtosEnvelopeType(rawValue: typeInt) else { return nil }

        builder.setType(type)

        if let relay = messageDict[MessageResponseKeys.relay] as? String {
            builder.setRelay(relay)
        }

        guard let timestamp = messageDict[MessageResponseKeys.timestamp] as? UInt64 else { return nil }
        builder.setTimestamp(timestamp)

        guard let source = messageDict[MessageResponseKeys.source] as? String else { return nil }
        builder.setSource(source)

        guard let sourceDevice = messageDict[MessageResponseKeys.sourceDevice] as? UInt32 else { return nil }
        builder.setSourceDevice(sourceDevice)

        if let encodedLegacyMessage = messageDict[MessageResponseKeys.message] as? String {
            if let legacyMessage = Data(base64Encoded: encodedLegacyMessage) {
                builder.setLegacyMessage(legacyMessage)
            }
        }

        if let encodedContent = messageDict[MessageResponseKeys.content] as? String {
            if let content = Data(base64Encoded: encodedContent) {
                builder.setContent(content)
            }
        }

        return builder.build()
    }

    private func fetchUndeliveredMessages(completion: @escaping ([OWSSignalServiceProtosEnvelope], Bool, Error?) -> Void) {

        let messagesRequest = OWSGetMessagesRequest()

        networkManager.makeRequest(
            messagesRequest,
            success: { [weak self] (_: URLSessionDataTask?, responseObject: Any?) -> Void in
                guard let strongSelf = self else { return }
                guard let (envelopes, more) = strongSelf.parseMessagesResponse(responseObject: responseObject) else {
                    return completion([], false, OWSErrorMakeUnableToProcessServerResponseError())
                }

                completion(envelopes, more, nil)
        },
            failure: { (_: URLSessionDataTask?, error: Error?) in
                guard let error = error else {
                    return completion([], false, OWSErrorMakeUnableToProcessServerResponseError())
                }

                completion([], false, error)
        })
    }

    private func acknowledgeDelivery(envelope: OWSSignalServiceProtosEnvelope) {
        let request = OWSAcknowledgeMessageDeliveryRequest(source: envelope.source, timestamp: envelope.timestamp)
        networkManager.makeRequest(request,
                                   success: { _, _ -> Void in },
                                   failure: { _, _ in })
    }
}
