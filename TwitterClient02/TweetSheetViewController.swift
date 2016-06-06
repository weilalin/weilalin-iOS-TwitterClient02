//
//  TweetSheetViewController.swift
//  TwitterClient02
//
//  Created by zhuling on 2016/04/22.
//  Copyright © 2016年 mycompany. All rights reserved.
//

import UIKit
import Accounts
import Social


class TweetSheetViewController: UIViewController {

    var twitterAccount = ACAccount()
    private let mainQueue = dispatch_get_main_queue()

    //**
    //**　リクエスト生成メソッド
    //**
    func generateRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json") // 画像なし
        // let url = NSURL(string: "https://api.twitter.com/1.1/statuses/update_with_media.json") // 画像付き
        let params = ["status" : tweetTextView.text] //status

        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: params) // 今回はURLにidStrを含めるのでparametersは不要
        // 画像を付加する場合
        //　let image = UIImage(named: "xcodeIcon.png")
        //　let imageData = UIImagePNGRepresentation(image!) // PNG画像の場合
        //　let imageData = UIImageJPEGRepresentation(image, 1.0) // JPEG画像の場合
        //　request.addMultipartData(imageData,
        //            withName: "media[]",
        //            type: "multipart/form-data",
        //            filename: nil)
        
        return request
    }
    
    //**
    //** リクエストハンドラ作成メソッド
    //**
    func generateRequestHandler() -> SLRequestHandler {
        
        // リクエストハンドラ作成メソッド
        let handler: SLRequestHandler = { postResponseData, urlResponse, error in
            // リクエスト送信エラー発生時
            if let requestError = error {
                print("Request Error: An error occurred while requesting: \(requestError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            // httpエラー発生時（ステータスコードが200番台以外ならエラー）
            if urlResponse.statusCode < 200 || urlResponse.statusCode >= 300 {
                print("HTTP Error: The response status code is \(urlResponse.statusCode)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // JSONシリアライズ
            let objectFromJSON: AnyObject
            do {
                objectFromJSON = try NSJSONSerialization.JSONObjectWithData(
                    postResponseData,
                    options: NSJSONReadingOptions.MutableContainers)
                // JSONシリアライズエラー発生時
            } catch (let jsonError) {
                print("JSON Error: \(jsonError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // Tweet　成功
            print("SUCCESS! Created Tweet with ID: \(objectFromJSON["id_str"] as! String)")
            // インジケータ停止
            self.stopProcessing()
        }
        return handler
    }
    
    //**
    //** インジケータ開始メソッド
    //**
    func startProcessing() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    //**
    //** インジケータ停止メソッド
    //**
    func stopProcessing() {
        dispatch_async(mainQueue, {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }

    @IBOutlet weak var tweetTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // 編集終了時
    @IBAction func endEdit() {
        // キーボードを引っ込める
        tweetTextView.resignFirstResponder()
    }

    
    @IBAction func tweetWithCustomSheet() {
        //**
        //** カスタムツイート手順
        //** 1. リクエスト用のパラメタを設定し、それを使ってリクエストオブジェクトを初期化
        //** 2. リクエストハンドラを作成
        //** 3. リクエストにアカウント情報をセット
        //** 4. リクエストハンドラを使ってリクエスト実行
        //**
        
        //** リクエスト生成
        let request = generateRequest()
        
        //** リクエストハンドラ作成
        let handler = generateRequestHandler()

        //** アカウント情報セット
        request.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        request.performRequestWithHandler(handler)
        
    
        //** モーダルビューのdismiss
        self.dismissViewControllerAnimated(true, completion: {
            print("Tweet Sheet has been dismissed.")
        })
        
    }
   
    @IBAction func cancel() {
        self.dismissViewControllerAnimated(true, completion: {
            print("Tweet Sheet has been dismissed.")
        })

        
        
    }
    
    
    
}
