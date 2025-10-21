import Foundation

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(self)

        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }

    var asQueryString: String {
        do {
            return try asDictionary().queryString
        } catch {
            return ""
        }
    }

    var asRawQueryString: String {
        do {
            return try asDictionary().rawQueryString
        } catch {
            return ""
        }
    }
}

extension Dictionary {
    private func convertToQueryStringArray(key: String, value: Any, doPerentageEncoding: Bool = true) -> [String] {
        var strings = [String]()

        switch value {
        case let items as [Any]:
            for item in items {
                strings.append(contentsOf: convertToQueryStringArray(key: key, value: item, doPerentageEncoding: doPerentageEncoding))
            }
        default:
            if let escaped = "\(value)".addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                strings.append("\(key)=\(doPerentageEncoding ? escaped : "\(value)")")
            }
        }
        return strings
    }

    var queryString: String {
        var output = [String]()

        forEach { key, value in
            if let key = key as? String {
                output.append(contentsOf: convertToQueryStringArray(key: key, value: value))
            }
        }

        return output.joined(separator: "&")
    }

    var rawQueryString: String {
        var output = [String]()

        forEach { key, value in
            if let key = key as? String {
                output.append(contentsOf: convertToQueryStringArray(key: key, value: value, doPerentageEncoding: false))
            }
        }

        return output.joined(separator: "&")
    }
}

public protocol URLSessionProvider {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProvider {
    @available(iOS, deprecated: 15.0, message: "This extension is no longer necessary. Use API built into SDK")
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}

extension JSONDecoder {
    func decodeIfEmpty<T: Decodable>(_: T.Type) throws -> T {
        if let emptyInit = T.self as? (any ExpressibleByNilLiteral.Type) {
            return emptyInit.init(nilLiteral: ()) as! T
        }
        let emptyData = "{}".data(using: .utf8)!
        return try decode(T.self, from: emptyData)
    }
}
