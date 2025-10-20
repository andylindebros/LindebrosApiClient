import Combine
import Foundation
import SwiftUI

extension Client.Request {
    private func logResponse(of url: URL?, with status: Client.HttpStatusCode) {
        let path = url != nil ? "\(url?.path ?? "") " : ""
        Client.ClientLogger.shared.info("✅ [\(status.rawValue)] \(path)")
    }

    @MainActor public func dispatch<Model: Decodable>() async throws -> Model {
        Client.ClientLogger.shared.info(self)

        // Make the request
        do {
            guard let config = config else {
                throw Client.ErrorResponse(message: "Configuration is not provided", status: .unknown)
            }

            let response: Client.Response<Model> = try await asyncRequest(urlSession: config.urlSession)

            logResponse(of: urlRequest?.url, with: response.status)
            return response.model

        } catch let e {
            // If client credentials token has expired, fetch a new token and make the request again.
            if

                let errorResponse = e as? Client.ErrorResponse,
                errorResponse.status == .unauthorized || errorResponse.status == .forbidden,
                let config = config,
                config.credentialsProvider?.provideCredentials()?.isUserCredential ?? false == false,
                let clientCredentials = config.clientCredentials {
                Client.ClientLogger.shared.info("🔑 fetching new token")

                let loginResponse: Client.Response<Client.Credentials> = try await Client(configuration: config)
                    .endpoint("/auth/v1/oauth/tokens")
                    .setMethod(.post)
                    .setContentType(.form)
                    .setBody(model: clientCredentials)
                    .asyncRequest(urlSession: config.urlSession)

                let credentials = loginResponse.model
                Client.ClientLogger.shared.info("✅ Received new token")
                config.credentialsProvider?.setCredentials(to: credentials)

                // Make the requeat again
                let response: Client.Response<Model> = try await authenticate(by: config.credentialsProvider?.provideCredentials()).asyncRequest(urlSession: config.urlSession)
                logResponse(of: urlRequest?.url, with: response.status)
                return response.model
            }

            // Throw it again if error is not handled
            throw e
        }
    }
}

public extension Client.Request {
    func asyncRequest<Model: Decodable>(urlSession: URLSessionProvider) async throws -> Client.Response<Model> {
        guard let urlRequest = urlRequest else {
            throw Client.ErrorResponse(message: "Invalid URL", status: .badRequest)
        }

        let (data, resp) = try await urlSession.data(for: urlRequest)

        let response = resp as? HTTPURLResponse

        let httpStatus = Client.HttpStatusCode(rawValue: response?.statusCode ?? 0) ?? .unknown

        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = config?.keydecodingStrategy ?? .convertFromSnakeCase
        if let dateDecodingStrategy {
            jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
        }

        if httpStatus.isOk() {
            return Client.Response(model: try jsonDecoder.decode(Model.self, from: data), status: httpStatus)
        }

        throw Client.ErrorResponse(message: "Service responded with error", status: httpStatus, data: data)
    }

    func setQueryIfNeeded(with state: QuerystringState? = nil) -> Self {
        guard
            var urlRequest = self.urlRequest,
            let state = state,
            let newURL = updateURL(with: state)
        else {
            return self
        }

        urlRequest.url = newURL

        return clone(with: urlRequest, andConfig: config)
    }
}

extension Client.Request {
    var contentType: Client.ContentType? {
        guard let urlRequest = self.urlRequest else { return nil }
        guard let contentType = urlRequest.allHTTPHeaderFields?.filter({ $0.key == "Content-Type" }).map({ $0.value }).first else { return nil }
        return Client.ContentType(rawValue: contentType)
    }

    func clone(with urlRequest: URLRequest, andConfig config: Client.Configuration?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) -> Self {
        Client.Request(urlRequest: urlRequest, config: config, dateDecodingStrategy: dateDecodingStrategy)
    }

    func updateURL(with newQuery: QuerystringState) -> URL? {
        guard
            let urlRequest = self.urlRequest
        else {
            return nil
        }
        let query = QuerystringState(queryString: urlRequest.url?.query ?? "")
            .clone(overwriteWith: newQuery.keyValues).asQueryString

        if let newURL = URL(
            string: "\(urlRequest.url?.scheme ?? "")://\(urlRequest.url?.host ?? "")\(urlRequest.url?.path ?? "")\(query.count > 0 ? "?" : "")\(query)")
        {
            return newURL
        }

        return nil
    }

    public func setDateDecodingStrategy(to dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?) -> Self {
        guard
            let urlRequest
        else {
            return self
        }
        return clone(with: urlRequest, andConfig: config, dateDecodingStrategy: dateDecodingStrategy)
    }
}
