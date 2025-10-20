import Foundation

public extension Client {
    struct Response<Model> {
        let model: Model
        let status: HttpStatusCode
    }

    struct ErrorResponse: Error {
        public init(message: String? = nil, status: HttpStatusCode, data: Data? = nil) {
            self.message = message
            self.status = status
            self.data = data
        }

        public var message: String?
        public var status: HttpStatusCode
        public var data: Data?
    }

    struct EmptyResponse: Codable {}
}
