import SwiftUI
@preconcurrency import WebKit

struct WebViewElement: UIViewRepresentable {
    let urlString: String
    let username: String
    let password: String
    var id: UUID
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            addBasicAuth(to: &request)
            uiView.load(request)
        }
    }
    
    private func addBasicAuth(to request: inout URLRequest) {
        let credentials = "\(username):\(password)"
        debugPrint("Loading Webview \(self.urlString) with Basic Auth Credentials: \(username):\(password)")

        if let credentialData = credentials.data(using: .utf8) {
            let base64Credentials = credentialData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebViewElement
        
        init(_ parent: WebViewElement) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

            // Handle the Basic Auth challenge
            let credential = URLCredential(user: parent.username, password: parent.password, persistence: .forSession)
            completionHandler(.useCredential, credential)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            debugPrint("Error loading page: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            debugPrint("Error starting the loading of the page: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            debugPrint("Page successfully loaded.")
        }
    }
}
