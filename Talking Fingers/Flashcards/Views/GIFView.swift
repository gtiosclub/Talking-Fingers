//
//  GIFView.swift
//  Talking Fingers
//
//  Created by Ria on 2/23/26
//

import SwiftUI
import WebKit

#if canImport(UIKit)
import UIKit

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
        if let url = Bundle.main.url(forResource: gifFileName, withExtension: nil) {
            print("GIF found at: \(url)")
            if let data = try? Data(contentsOf: url) {
                uiView.load(data, mimeType: "image/gif", characterEncodingName: "", baseURL: url)
            }
        } else {
            print("GIF not found: \(gifFileName)")
        }
    }
}

#elseif canImport(AppKit)
import AppKit

struct GIFView: NSViewRepresentable {
    let gifFileName: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: gifFileName, withExtension: nil) {
            print("GIF found at: \(url)")
            if let data = try? Data(contentsOf: url) {
                nsView.load(data, mimeType: "image/gif", characterEncodingName: "", baseURL: url)
            }
        } else {
            print("GIF not found: \(gifFileName)")
        }
    }
}

#endif
