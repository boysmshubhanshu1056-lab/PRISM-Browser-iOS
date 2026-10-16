import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct BrowserTab: Identifiable {
    let id = UUID()
    var title: String
    var url: URL
}

struct BrowserView: View {
    @State private var address = "https://www.google.com"
    @State private var currentURL = URL(string: "https://www.google.com")!
    @State private var tabs: [BrowserTab] = [
        BrowserTab(title: "Google", url: URL(string: "https://www.google.com")!)
    ]
    @State private var selectedTab = 0
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var showImporter = false
    @State private var importedFileMessage: String?
    @State private var webView = BrowserWebViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoBack)
                .accessibilityLabel("Back")

                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)
                .accessibilityLabel("Forward")

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search or enter website", text: $address)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .submitLabel(.go)
                        .onSubmit(loadAddress)
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Button(action: reload) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Reload")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                Button(action: { showImporter = true }) {
                    Image(systemName: "puzzlepiece.extension")
                }
                .accessibilityLabel("Import extension ZIP")
            }
            .font(.system(size: 17, weight: .medium))
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                        Button {
                            selectedTab = index
                            currentURL = tab.url
                            address = tab.url.absoluteString
                            webView.load(tab.url)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "globe")
                                    .font(.caption)
                                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                                    .lineLimit(1)
                                if tabs.count > 1 {
                                    Button {
                                        closeTab(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minWidth: 100, maxWidth: 210)
                            .background(index == selectedTab ? Color(uiColor: .systemBackground) : Color(uiColor: .tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: newTab) {
                        Image(systemName: "plus")
                            .padding(9)
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("New tab")
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            Divider()

            BrowserWebView(model: webView)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .preferredColorScheme(nil)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                importedFileMessage = "Selected \(url.lastPathComponent) (\(size) bytes). ZIP importing is a prototype; this does not install or run the extension."
            case .failure(let error):
                importedFileMessage = "Could not select ZIP: \(error.localizedDescription)"
            }
        }
        .alert("Extension ZIP", isPresented: Binding(
            get: { importedFileMessage != nil },
            set: { if !$0 { importedFileMessage = nil } }
        )) {
            Button("OK", role: .cancel) { importedFileMessage = nil }
        } message: {
            Text(importedFileMessage ?? "")
        }
        .onAppear {
            webView.onStateChange = { back, forward, loading, url, title in
                canGoBack = back
                canGoForward = forward
                isLoading = loading
                if let url {
                    currentURL = url
                    address = url.absoluteString
                    if selectedTab < tabs.count {
                        tabs[selectedTab].url = url
                        tabs[selectedTab].title = title ?? url.host ?? "Tab"
                    }
                }
            }
            webView.load(currentURL)
        }
    }

    private func loadAddress() {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let target: URL
        if let candidate = URL(string: trimmed),
           let scheme = candidate.scheme?.lowercased(),
           ["http", "https"].contains(scheme),
           candidate.host != nil {
            target = candidate
        } else if trimmed.contains("."),
                  let candidate = URL(string: "https://" + trimmed),
                  candidate.host != nil {
            target = candidate
        } else {
            let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            target = URL(string: "https://www.google.com/search?q=" + query)!
        }
        currentURL = target
        webView.load(target)
        if selectedTab < tabs.count { tabs[selectedTab].url = target }
    }

    private func goBack() { webView.goBack() }
    private func goForward() { webView.goForward() }
    private func reload() { webView.reload() }

    private func newTab() {
        let url = URL(string: "https://www.google.com")!
        tabs.append(BrowserTab(title: "New Tab", url: url))
        selectedTab = tabs.count - 1
        address = url.absoluteString
        currentURL = url
        webView.load(url)
    }

    private func closeTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        tabs.remove(at: index)
        if tabs.isEmpty {
            newTab()
            return
        }
        if selectedTab >= tabs.count { selectedTab = tabs.count - 1 }
        let tab = tabs[selectedTab]
        currentURL = tab.url
        address = tab.url.absoluteString
        webView.load(tab.url)
    }
}

final class BrowserWebViewModel: ObservableObject {
    let webView = WKWebView()
    var onStateChange: ((Bool, Bool, Bool, URL?, String?) -> Void)?

    init() {
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
    }

    func load(_ url: URL) { webView.load(URLRequest(url: url)) }
    func goBack() { if webView.canGoBack { webView.goBack() } }
    func goForward() { if webView.canGoForward { webView.goForward() } }
    func reload() { webView.reload() }

    private func report() {
        onStateChange?(
            webView.canGoBack,
            webView.canGoForward,
            webView.isLoading,
            webView.url,
            webView.title
        )
    }
}

extension BrowserWebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { report() }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { report() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { report() }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { report() }
}

struct BrowserWebView: UIViewRepresentable {
    @ObservedObject var model: BrowserWebViewModel

    func makeUIView(context: Context) -> WKWebView { model.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
