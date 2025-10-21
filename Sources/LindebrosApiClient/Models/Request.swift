import Foundation
import os

public extension Client {
    struct Request: CustomStringConvertible {
        public var urlRequest: URLRequest?

        public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?

        var config: Configuration?

        public init(url: URL?, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) {
            guard let url = url else { return }
            urlRequest = URLRequest(url: url)
            config = nil
            self.dateDecodingStrategy = dateDecodingStrategy
        }

        public init(
            urlRequest: URLRequest,
            config: Configuration? = nil,
            dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil
        ) {
            self.urlRequest = urlRequest
            self.config = config
            self.dateDecodingStrategy = dateDecodingStrategy
        }

        public func setHeader(key: String, value: String) -> Self {
            guard var urlRequest = self.urlRequest else { return self }
            urlRequest.setValue(value, forHTTPHeaderField: key)
            return clone(with: urlRequest, andConfig: config)
        }

        public func setMethod(_ method: HttpMethod) -> Self {
            guard var urlRequest = self.urlRequest else { return self }
            urlRequest.httpMethod = method.rawValue
            return clone(with: urlRequest, andConfig: config)
        }

        public func setBody<Model: Encodable>(model: Model, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil) -> Self {
            guard var urlRequest = self.urlRequest else { return self }

            switch HttpMethod(rawValue: urlRequest.httpMethod ?? "unknown") {
            case .post, .put:
                switch contentType {
                case .json:
                    do {
                        let encoder = JSONEncoder()
                        if let dateEncodingStrategy {
                            encoder.dateEncodingStrategy = dateEncodingStrategy
                        }
                        encoder.keyEncodingStrategy = keyEncodingStrategy
                        urlRequest.httpBody = try encoder.encode(model)
                    } catch {}
                case .form:
                    urlRequest.httpBody = model.asQueryString.data(using: .utf8)
                case .none:
                    break
                }

            case .get, .delete:
                if let newURL = updateURL(with: QuerystringState(queryString: model.asRawQueryString)) {
                    urlRequest.url = newURL
                }
            case .none:
                break
            }

            return clone(with: urlRequest, andConfig: config)
        }

        public func setContentType(_ type: ContentType) -> Self {
            setHeader(key: "Content-Type", value: type.rawValue)
        }

        public func setAcceptJSON() -> Self {
            setHeader(key: "Accept", value: "application/json")
        }

        public func authenticate(by credentials: Credentials?) -> Self {
            guard
                let credential = credentials
            else { return self }
            return setHeader(key: "Authorization", value: "Bearer \(credential.accessToken)")
        }

        public func authenticate(by token: String) -> Self {
            return setHeader(key: "Authorization", value: "Bearer \(token)")
        }

        public func setConfig(_ config: Configuration) -> Self {
            guard let urlRequest = self.urlRequest else { return self }
            return clone(with: urlRequest, andConfig: config)
        }

        public var description: String {
            guard
                let urlRequest = self.urlRequest,
                let url = urlRequest.url,
                let method = HttpMethod(rawValue: urlRequest.httpMethod ?? "unknown")
            else { return "invalid" }

            let token = urlRequest.value(forHTTPHeaderField: "Authorization")

            return "[\(method.rawValue)] \(url.path) \(url.query ?? "") \(token ?? "")"
        }
    }
}
