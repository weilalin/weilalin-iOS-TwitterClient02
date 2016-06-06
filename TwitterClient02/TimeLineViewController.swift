//
//  TimeLineViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/04/25.
//  Copyright © 2016年 mycompany. All rights reserved.
//

import UIKit
import Accounts
import Social


class TimeLineViewController: UITableViewController {
    
    var twitterAccount = ACAccount() // 選択されたTwitterタイプのアカウント
    private var timeLineArray: [AnyObject] = []// タイムレイン行の配列
    private var statusArray: [Status] = [] // パース済みの配列
    private var httpMessage = ""// 接続待ち時及び接続エラー時のメッセージ
    private let mainQueue = dispatch_get_main_queue()// メインキュー
    private let imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)// グローバルキュー
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //　テーブルビューのセルの高さを自動計算する
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // リフレッシュコントロールの初期化
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                  action: #selector(TimeLineViewController.refreshTableView),
                                  forControlEvents: UIControlEvents.ValueChanged)
        
        // tableViewの中身が空の場合でもリフレッシュコントロールを使えるようにする
         tableView.alwaysBounceVertical = true
        
        // タイムラインリクエスト
        requestTimeLine()

    }
    
    //**
    //** タイムラインリクエストメソッド
    //**
    private func requestTimeLine() {
        //**
        //** ホームタイムライン取得手順
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
    }
    
    
        //**
        //** リクエスト生成メソッド
        //**
        private func generateRequest() -> SLRequest {
            // リクエストに必要なパラメタを用意
            let url = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")
            let params = ["include_rts" : "0",
                          "trim_user" : "0",
                          "count" : "20"]// "count" : "1"]「count」部分を1から20に変更する。
            
            
            // リクエスト初期化
            let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                    requestMethod: SLRequestMethod.GET,
                                    URL: url,
                                    parameters: params)
            return request
        }

        //**
        //** リクエストハンドラ作成メソッド
        //**
        func generateRequestHandler() -> SLRequestHandler {
            // リクエストハンドラ作成
            let handler: SLRequestHandler = { getResponseData, urlResponse, error in
                
                // リクエスト送信エラー発生時
                if let requestError = error {
                    print("Request Error: An error occurred while requesting: \(requestError)")
                    self.httpMessage = "HTTPエラー発生"
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
                do {
                    self.timeLineArray = try NSJSONSerialization.JSONObjectWithData(
                        getResponseData,
                        options: NSJSONReadingOptions.AllowFragments) as? [AnyObject] ?? []
                    
                    // JSONシリアライズエラー発生時
                } catch (let jsonError) {
                    print("JSON Error: \(jsonError)")
                    // インジケータ停止
                    self.stopProcessing()
                    return
                }
                
                // TimeLine出力
                print("TimeLine Response: \(self.timeLineArray)")
                
                // TimeLineの配列のパース
                self.statusArray = self.parseJSON(self.timeLineArray)
                
                // インジケータ停止
                self.stopProcessing()
                
                //** 接続後テーブルビューの再描画をしないとセルのメッセージが書き変わらない。
                // テーブルビューの再描画
                dispatch_async(self.mainQueue, {
                    self.tableView.reloadData()
                })

            }
            return handler
        }
        
        //**
        //** インジケータ開始メソッド
        //**
        private func startProcessing() {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
        
    
    //**
    //** インジケータ停止メソッド
    //**
    private func stopProcessing() {
        dispatch_async(self.mainQueue, {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            // 接続後テーブルビューの再描画をしないとセルのメッセージが書き変わらない。
            self.tableView.reloadData() // テーブルビューの再描画
            
            // refreshActionの終了処理をこちらに移動
            // リフレッシュ終了　インジケータ停止
            if self.refreshControl!.refreshing {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    //**
    //** タイムラインJSONパースメソッド
    //** （タイムライン配列をパースして必要なデータのみ返す）
    //** （パースに失敗したらfatal error）
    //**
    private func parseJSON(json: [AnyObject]) -> [Status] {
        return json.map { result in
            guard let text = result["text"] as? String else { fatalError("Parse error!") }
            guard let user = result["user"] as? NSDictionary else { fatalError("Parse error!") }
            guard let screenName = user["screen_name"] as? String else { fatalError("Parse error!") }
            guard let profileImageUrlHttps = user["profile_image_url_https"] as? String else { fatalError("Prase error!") }
            guard let idStr = result["id_str"] as? String else { fatalError("Prase error!") }
            return Status(text: text, screenName: screenName, profileImageUrlHttps: profileImageUrlHttps,idStr: idStr)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //**
    //** リフレッシュコントロール表示メソッド
    //**
    @objc private func refreshTableView() {
        // リフレッシュ開始　インジケータ開始
        refreshControl?.beginRefreshing()
        
        // タイムラインリクエスト
        requestTimeLine()
        
        // リフレッシュ終了　インジケータ停止
        // 通常以下の処理はこのメソッド内で良いが、今回の更新処理は非同期なので
        // dispatch_async()のメインキュー処理ブロック内に記述する必要がある。
        // if self.refreshControl!.refreshing {
        //     self.refreshControl?.endRefreshing()
        // }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if timeLineArray.count == 0 {
            return 1 // タイムラインがサーバから送られてくるまでは1行メッセージを表示
        } else {
            return timeLineArray.count // タイムラインが得られたら件数分セルを確保
        }
        
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TimeLineCell
        
        // Configure the cell...
        
        // デフォルトのセルは空白表示
        var cellText = ""
        var cellUserName = ""
        var cellImageViewImage = UIImage()
        
        if timeLineArray.count == 0 { // タイムラインが返ってこない時
            if httpMessage != "" { // HTTPエラーがあれば
                cellText = httpMessage
            } else { // まだ通信中なら
                cellText = "Loading..."
            }
        } else {
            // タイムラインが返っていれば
            // パース済みのデータをセットする
            let status = statusArray[indexPath.row]
            cellText = status.text
            cellUserName = status.screenName
            
            //　ユーザ画像の取得処理（グローバルキューで並列処理）
            dispatch_async(self.imageQueue, {
                // パース済みデータのデータから画像URLを生成
                guard let imageUrl = NSURL(string: status.profileImageUrlHttps) else {
                    fatalError("URL Error!")
                }
                // 画像URLを利用してアイコン画像取得
                do {
                    let imageData = try NSData(
                        contentsOfURL: imageUrl,
                        options:NSDataReadingOptions.DataReadingMappedIfSafe)
                    cellImageViewImage = UIImage(data: imageData)!
                } catch (let imageError) {
                    print("Image loading Error: (\(imageError))")
                }
                // 画像が取得できたらセルにセットしてセルの再描画
                dispatch_async(self.mainQueue, {
                    cell.profileImageView!.image = cellImageViewImage
                    cell.setNeedsLayout() // セルのみ再描画
                })
            })
        }
        
        cell.tweetTextLabel?.text = cellText
        cell.nameLabel?.text = cellUserName
        cell.profileImageView?.image = UIImage(named:"blank.png") // デフォルトは空白画像
        
//        // UITableViewCellのstyleを「subtitle」にした場合
//        // textLabelとdetailTextLabelが上下に並ぶ
//        cell.textLabel?.font = UIFont.systemFontOfSize(14)
//        cell.detailTextLabel?.font = UIFont.systemFontOfSize(12)
//        cell.textLabel?.numberOfLines = 0 // UILabelの行数を文字数によって変える
        
        return cell
    }

//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return 140.0;
//    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        switch segue.destinationViewController {
        // パターンマッチングでセグエ処理を分ける
        case let detailVC as DetailViewController:
            // 選択されたセルの行番号を得る
            let indexPath = tableView.indexPathForSelectedRow
            // パース済みデータから該当セル分を得る
            let status = statusArray[indexPath!.row]
            
            // セルの内容を次のVCへ引き渡す
            detailVC.text = status.text
            detailVC.screenName = status.screenName
            detailVC.idStr = status.idStr
            detailVC.twitterAccount = twitterAccount
            
            // ユーザアイコン画像はStatus構造体に含まれないので、該当セルの画像を使う
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! TimeLineCell
            detailVC.profileImage = cell.profileImageView.image!
            
        default:
            print("Segue has no parameters.")
        }

    }
    

}
