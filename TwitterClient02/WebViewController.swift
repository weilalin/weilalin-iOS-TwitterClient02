//
//  WebViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/13.
//  Copyright © 2016年 mycompany. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {// WKNavigationDelegate代理器

    var openURL = NSURL()
    private var webView = WKWebView()
    private var progressView = UIProgressView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //　WKWebViewインスタンス化
        webView = WKWebView(frame: view.bounds, configuration: WKWebViewConfiguration())
        
        // デリゲートにこのビューコントローラを設定する
        webView.navigationDelegate = self
        
        // プリップで戻る、進むを有効にする
        webView.allowsBackForwardNavigationGestures = true
        
        // WKWebView　インスタンスの生成
        view = webView
//         view.addSubview(webView) // 普通はこちらの方法でUIパーツを追加する
        
        // DetailViewControllerから引き渡されたURLを開く
        let request = NSURLRequest(URL:openURL)
    
        webView.loadRequest(request)
        // プログレスビューの生成、描画
//        print("status bar height = \(UIApplication.sharedApplication().statusBarFrame.height)")
//        print("navigation bar height = \(navigationController?.navigationBar.frame.size.height ?? 44)")
        
        progressView = UIProgressView(progressViewStyle : UIProgressViewStyle.Bar)
        progressView.frame = CGRectMake(0, calcBarHeight(), view.bounds.size.width, 2)
        view.addSubview(progressView)
        
        // Webページ読み込みの監視スタート
        webView.addObserver(self, forKeyPath:"estimatedProgress", options:.New, context:nil)
    }
    
    // WebViewController解放時に監視をストップするための以下のメソッドを追加する。
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    // 監視対象が変化した時のデリゲートメソッド等を以下の通り追加する。
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {// 監視対象が変化したら

        switch keyPath! {
        case "estimatedProgress":
            if let progress = change![NSKeyValueChangeNewKey] as? Float {
                progressView.progress = progress
            }
        default: break
        }
    }
    
    override func viewWillLayoutSubviews() {
        // 画面回転するときにバーの高さを計算し直す
        progressView.frame = CGRectMake(0, calcBarHeight(), view.bounds.size.width, 2)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        // 横長表示（Protrait画面）でもステータスバーを表示したいときにfalseを表示する
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //**
    //** WKWKNavigationDelegate デリゲートメソット
    //**
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        startProcessing()
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        progressView.progress = 0.0
        stopProcessing()
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        progressView.progress = 0.0
        stopProcessing()
        print("Request Error : An error occured while requesting: \(error)")
    }
    
    //**
    //** インジケータ開始メソッド
    //**
    private func startProcessing() {
        // インジケータ開始
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    //**
    //** インジケータ停止メソッド
    //**
    private func stopProcessing() { // インジケータ停止
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    //**
    //** ステータスバー＆ナビゲーションバー高さ計算メソッド
    //**
    private func calcBarHeight() -> CGFloat {
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let navigationBarHeight = navigationController?.navigationBar.frame.size.height ?? 0
        return statusBarHeight + navigationBarHeight
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
