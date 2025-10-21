import Foundation

public protocol ClientProvider {
    func get(_ endpoint: String, with state: QuerystringState?) -> Client.Request

    func post<PostModel: Encodable>(_ model: PostModel, to endpoint: String, contentType: Client.ContentType, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy?) throws -> Client.Request

    func put<PutModel: Encodable>(_ model: PutModel, to endpoint: String, contentType: Client.ContentType, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy?) throws -> Client.Request

    func delete(_ endpoint: String, with state: QuerystringState?) -> Client.Request
}

public extension ClientProvider {
    func post<PostModel: Encodable>(_ model: PostModel, to endpoint: String, contentType: Client.ContentType) throws -> Client.Request {
        try post(model, to: endpoint, contentType: contentType,
                 keyEncodingStrategy: .convertToSnakeCase, dateEncodingStrategy: nil)
    }

    func put<PutModel: Encodable>(_ model: PutModel, to endpoint: String, contentType: Client.ContentType) throws -> Client.Request {
        try put(model, to: endpoint, contentType: contentType, keyEncodingStrategy: .convertToSnakeCase, dateEncodingStrategy: nil)
    }
}

public struct Client: ClientProvider {
    /**
     Init Client
     - parameter configuration: Configuration of the Client
     */
    public init(
        configuration: Client.Configuration
    ) {
        self.configuration = configuration
    }

    public init(
        _ configuration: Client.Configuration
    ) {
        self.configuration = configuration
    }

    public let configuration: Client.Configuration

    /**
     makes a GET request
     - parameter endpoint: Path to endpoint
     - parameter with state: Querystring parameter representation
     - returns Model with populated data
     */
    public func get(_ endpoint: String, with state: QuerystringState? = nil) -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
            .setQueryIfNeeded(with: state)
            .setMethod(.get)
            .setAcceptJSON()
            .setConfig(configuration)
    }

    /**
     makes a POST request
     - parameter model: The data to send
     - parameter to endpoint: Path to endpoint
     - parameter contentType: The type of data, json or form.
     - returns Model with populated data
     */
    public func post<PostModel: Encodable>(_ model: PostModel, to endpoint: String, contentType: ContentType = .json, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil) throws -> Request {
        try Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
            .setMethod(.post)
            .setContentType(contentType)
            .setBody(model: model, keyEncodingStrategy: keyEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
            .setAcceptJSON()
            .setConfig(configuration)
    }

    /**
     makes a PUT request
     - parameter model: The data to send
     - parameter to endpoint: Path to endpoint
     - parameter contentType: The type of data, json or form.
     - returns Model with populated data
     */
    public func put<PutModel: Encodable>(_ model: PutModel, to endpoint: String, contentType: ContentType = .json, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil) throws -> Request {
        try Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
            .setMethod(.put)
            .setContentType(contentType)
            .setBody(model: model, keyEncodingStrategy: keyEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
            .setAcceptJSON()
            .setConfig(configuration)
    }

    /**
     makes a DELETE request
     - parameter endpoint: Path to endpoint
     - parameter with state: Querystring parameter representation
     - returns Model with populated data
     */
    public func delete(_ endpoint: String, with state: QuerystringState? = nil) -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
            .setQueryIfNeeded(with: state)
            .setMethod(.delete)
            .setAcceptJSON()
            .setConfig(configuration)
    }

    /**
     returns a request object without making a request
     - parameter endpoint: Path to endpoint
     - returns a Request
     */
    public func endpoint(_ endpoint: String) -> Request {
        Request(url: URL(string: endpoint, relativeTo: configuration.baseURL))
    }
}
