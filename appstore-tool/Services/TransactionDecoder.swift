import AppStoreServerLibrary

enum TransactionDecoder {
    static func decodeTransaction(
        _ signed: String,
        verifier: SignedDataVerifier
    ) async throws -> JWSTransactionDecodedPayload {
        let result = await verifier.verifyAndDecodeTransaction(signedTransaction: signed)
        switch result {
        case .valid(let payload):
            return payload
        case .invalid(let error):
            throw AppStoreToolError.verificationFailed(error)
        }
    }

    static func decodeTransactions(
        _ signedItems: [String],
        verifier: SignedDataVerifier
    ) async throws -> [JWSTransactionDecodedPayload] {
        var decoded: [JWSTransactionDecodedPayload] = []
        for signed in signedItems {
            let payload = try await decodeTransaction(signed, verifier: verifier)
            decoded.append(payload)
        }
        return decoded
    }

    static func decodeRenewalInfo(
        _ signed: String,
        verifier: SignedDataVerifier
    ) async throws -> JWSRenewalInfoDecodedPayload {
        let result = await verifier.verifyAndDecodeRenewalInfo(signedRenewalInfo: signed)
        switch result {
        case .valid(let payload):
            return payload
        case .invalid(let error):
            throw AppStoreToolError.verificationFailed(error)
        }
    }

    static func decodeNotification(
        _ signed: String,
        verifier: SignedDataVerifier
    ) async throws -> ResponseBodyV2DecodedPayload {
        let result = await verifier.verifyAndDecodeNotification(signedPayload: signed)
        switch result {
        case .valid(let payload):
            return payload
        case .invalid(let error):
            throw AppStoreToolError.verificationFailed(error)
        }
    }
}
