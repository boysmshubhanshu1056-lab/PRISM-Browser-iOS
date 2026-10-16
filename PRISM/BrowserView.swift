
import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct BrowserView: View {
    @StateObject private var model = BrowserWebViewModel()
    @State private var address = "https://www.google.com"
    @State private var showZIPPicker = false
    @State private var selectedZIPName = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "sparkle")
                    .font(.title2.bold())
                    .foregroundStyle(.blue)

                Text("PRISM")
                    .font(.title2.bold())

                Spacer()

                Button {
                    showZIPPicker = true
                } label: {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.title3)
                }
                .accessibilityLabel("Import extension ZIP")
            }
            .padding()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search or enter website", text: $address)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit {
                        model.loadAddress(address)
                    }

                Button {
                    model.loadAddress(address)
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)

            HStack {
                Button {
                    model.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!model.canGoBack)

                Spacer()

                Button {
                    model.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!model.canGoForward)

                Spacer()

                Button {
                    model.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Spacer()

                Button {
                    address = "https://www.google.com"
                    model.loadAddress(address)
                } label: {
                    Image(systemName: "house")
                }
            }
            .buttonStyle(.plain)
            .font(.title3)
            .padding()

            if !selectedZIPName.isEmpty {
                Text("Selected ZIP: \(selectedZIPName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
            }

            WebViewContainer(webView: model.webView)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .onAppear {
            if model.webView.url == nil {
                model.loadAddress("https://www.google.com")
            }
        }
        .fileImporter(
            isPresented: $showZIPPicker,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedZIPName = url.lastPathComponent
                }
            case .failure(let error):
                selectedZIPName = "Import failed: \(error.localizedDescription)"
            }
        }
    }
}

final class BrowserWebViewModel: NSObject, ObservableObject {
    let webView: WKWebView

    override init() {
        webView = WKWebView(frame: .zero)
        super.init()
        webView.navigationDelegate = self
    }

    func loadAddress(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let url: URL?

        if trimmed.contains(" "),
           let encoded = trimmed.addingPercentEncoding(
               withAllowedCharacters: .urlQueryAllowed
           ) {
            url = URL(string: "https://www.google.com/search?q=\(encoded)")
        } else if let directURL = URL(string: trimmed),
                  let scheme = directURL.scheme,
                  ["http", "https"].contains(scheme.lowercased()),
                  directURL.host != nil {
            url = directURL
        } else if trimmed.contains("."),
                  let directURL = URL(string: "https://" + trimmed),
                  directURL.host != nil {
            url = directURL
        } else {
            let query = trimmed.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? trimmed
            url = URL(string: "https://www.google.com/search?q=\(query)")
        }

        guard let url else { return }
        webView.load(URLRequest(url: url))
    }

    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    func reload() {
        webView.reload()
    }

    var canGoBack: Bool {
        webView.canGoBack
    }

    var canGoForward: Bool {
        webView.canGoForward
    }
}

extension BrowserWebViewModel: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
