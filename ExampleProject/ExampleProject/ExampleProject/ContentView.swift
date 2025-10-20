import LindebrosApiClient
import SwiftUI

struct ContentView: View {
    let client: Client
    init() {
        client = Client(
            configuration: Client.Configuration(
                baseURL: URL(string: "https://example.com/somapi")!
            )
        )
    }

    @State var state: ViewState = .notLoaded

    func testClient() {
        state = .loading
        Task {
            do {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

                self.state = try .success(
                    await client.get(
                        "/latest-summary",
                        with: .init().set("channel", value: ["p1"])
                    )

                    .setDateDecodingStrategy(to: .formatted(formatter))
                        .dispatch()
                )

            } catch {
                print("❌", error)
                self.state = .error(error)
            }
        }
    }

    var body: some View {
        VStack {
            switch state {
            case .notLoaded:
                EmptyView()
            case .loading:
                ProgressView()
            case let .success(model):
                Text(model.shortSummary ?? "unknown")
            case let .error(error):
                Text(error.localizedDescription)
            }
            Button(action: {
                testClient()
            }) {
                Text("Load")
            }
        }
        .frame(width: 400, height: 300)
    }

    struct TestModel: Codable {
        var shortSummary: String?
        var timestamp: Date?
    }

    enum ViewState {
        case notLoaded
        case loading
        case success(TestModel)
        case error(Error)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
