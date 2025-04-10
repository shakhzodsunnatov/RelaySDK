//
//  NatsClient+Publish.swift
//  RelaySDK
//

import Foundation
import Dispatch

extension NatsClient: NatsPublish {

    // MARK: - Implement NatsPublish Protocol

    open func publish(_ payload: String, to subject: String) {
        LoggerManager.shared.logger.info("publish \(payload.count) characters to subject \(subject)")
        sendMessage(NatsMessage.publish(payload: payload, subject: subject))
    }

    open func publish(_ payload: String, to subject: NatsSubject) {
        publish(payload, to: subject.subject)
    }

    open func reply(to message: NatsMessage, withPayload payload: String) {
        guard let replySubject = message.replySubject else { return }
        LoggerManager.shared.logger.info("reply \(payload.count) characters to subject \(replySubject.subject)")
        publish(payload, to: replySubject.subject)
    }

    open func publishSync(_ payload: String, to subject: String) throws {

        let group = DispatchGroup()
        group.enter()

        var response: NatsEvent?

        self.on([.response, .error], autoOff: true) { e in
            response = e
            group.leave()
        }

        publish(payload, to: subject)

        group.wait()

        if response == .error {
            throw NatsPublishError("Error response from server")
        }

    }

    open func publishSync(_ payload: String, to subject: NatsSubject) throws {
        try publishSync(payload, to: subject.subject)
    }

    open func replySync(to message: NatsMessage, withPayload payload: String) throws {
        guard let replySubject = message.replySubject else { return }
        try publishSync(payload, to: replySubject.subject)
    }

}
