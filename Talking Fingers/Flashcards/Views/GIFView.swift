//
//  GIFView.swift
//  Talking Fingers
//
//  Created by Ria on 2/23/26
//
import SwiftUI
import WebKit

/// Builds an HTML wrapper that renders the GIF centred and, when `fill` is true,
/// scaled to cover the full view bounds.
private func gifHTML(src: String, fill: Bool) -> String {
    let imgStyle = fill
        ? "width:100%;height:100%;object-fit:contain;"
        : "max-width:100%;max-height:100%;object-fit:contain;"
    return """
    <!DOCTYPE html>
    <html>
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
    *{margin:0;padding:0;box-sizing:border-box}
    html,body{width:100%;height:100%;background:transparent;display:flex;justify-content:center;align-items:center;overflow:hidden}
    img{\(imgStyle)}
    </style>
    </head>
    <body><img src="\(src)"></body>
    </html>
    """
}

#if canImport(UIKit)
struct GIFView: UIViewRepresentable {
    let gifFileName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let remoteURL = URL(string: gifFileName), remoteURL.scheme?.hasPrefix("http") == true {
            uiView.loadHTMLString(gifHTML(src: gifFileName, fill: false), baseURL: nil)
        } else if let url = Bundle.main.url(forResource: gifFileName, withExtension: nil) {
            uiView.loadHTMLString(gifHTML(src: url.absoluteString, fill: false),
                                  baseURL: url.deletingLastPathComponent())
        } else {
            print("GIF not found: \(gifFileName)")
        }
    }
}
#elseif canImport(AppKit)
struct GIFView: NSViewRepresentable {
    let gifFileName: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let remoteURL = URL(string: gifFileName), remoteURL.scheme?.hasPrefix("http") == true {
            nsView.loadHTMLString(gifHTML(src: gifFileName, fill: true), baseURL: nil)
        } else if let url = Bundle.main.url(forResource: gifFileName, withExtension: nil) {
            nsView.loadHTMLString(gifHTML(src: url.absoluteString, fill: true),
                                  baseURL: url.deletingLastPathComponent())
        } else {
            print("GIF not found: \(gifFileName)")
        }
    }
}
#endif

#Preview("Zero GIF Only") {
    GIFView(gifFileName: "zero.gif")
        .frame(width: 200, height: 150)
        .padding()
}
