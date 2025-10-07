import SwiftUI
import WebKit

struct HTMLReportViewer: View {
  let htmlContent: String
  let reportTitle: String

  @Environment(\.dismiss)
  private var dismiss
  @State private var webView: WKWebView?
  @State private var errorMessage: String?
  @State private var showError = false
  @State private var pdfURL: URL?
  @State private var isGeneratingPDF = false

  var body: some View {
    NavigationView {
      HTMLWebView(htmlContent: htmlContent, webView: $webView, onLoadComplete: generatePDF)
        .navigationTitle(reportTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") {
              dismiss()
            }
          }

          ToolbarItem(placement: .navigationBarTrailing) {
            if let pdfURL {
              ShareLink(item: pdfURL) {
                Image(systemName: "square.and.arrow.up")
                  .accessibilityLabel("Share PDF")
              }
            } else {
              Button(action: generatePDF) {
                Image(systemName: "square.and.arrow.up")
                  .accessibilityLabel("Generate PDF")
              }
            }
          }
        }
        .alert("Error", isPresented: $showError) {
          Button("OK", role: .cancel) {}
        } message: {
          if let errorMessage {
            Text(errorMessage)
          }
        }
    }
  }

  private func generatePDF() {
    guard let webView else {
      return
    }

    guard !isGeneratingPDF else {
      return
    }

    isGeneratingPDF = true

    // Use UIPrintPageRenderer with viewPrintFormatter - this properly applies @media print CSS
    let printFormatter = webView.viewPrintFormatter()
    let renderer = UIPrintPageRenderer()
    renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)

    // US Letter page size (8.5" x 11" at 72 DPI)
    let pageSize = CGRect(x: 0, y: 0, width: 8.5 * 72, height: 11 * 72)
    let printableRect = pageSize.insetBy(dx: 36, dy: 36)  // 0.5" margins
    renderer.setValue(pageSize, forKey: "paperRect")
    renderer.setValue(printableRect, forKey: "printableRect")

    let pdfData = NSMutableData()
    UIGraphicsBeginPDFContextToData(pdfData, pageSize, nil)

    for i in 0..<renderer.numberOfPages {
      UIGraphicsBeginPDFPage()
      renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
    }

    UIGraphicsEndPDFContext()

    let result: Result<Data, Error>
    if pdfData.length > 0 {
      result = .success(pdfData as Data)
    } else {
      result = .failure(
        NSError(
          domain: "PDFGeneration",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Failed to generate PDF"]
        )
      )
    }

    DispatchQueue.main.async {
      switch result {
        case .success(let data):
          let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(reportTitle + ".pdf")

          do {
            try data.write(to: tempURL)
            pdfURL = tempURL
          } catch {
            errorMessage = "Failed to save PDF: \(error.localizedDescription)"
            showError = true
          }

        case .failure(let error):
          errorMessage = "Failed to create PDF: \(error.localizedDescription)"
          showError = true
      }
    }
  }
}

struct HTMLWebView: UIViewRepresentable {
  let htmlContent: String
  @Binding var webView: WKWebView?
  var onLoadComplete: (() -> Void)?

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    self.webView = webView
    return webView
  }

  func updateUIView(_ uiView: WKWebView, context _: Context) {
    let baseURL = URL(string: "https://example.com")
    uiView.loadHTMLString(htmlContent, baseURL: baseURL)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(onLoadComplete: onLoadComplete)
  }

  class Coordinator: NSObject, WKNavigationDelegate {
    var onLoadComplete: (() -> Void)?

    init(onLoadComplete: (() -> Void)?) {
      self.onLoadComplete = onLoadComplete
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
      // Wait a bit for content to fully render and layout
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.onLoadComplete?()
      }
    }
  }
}
