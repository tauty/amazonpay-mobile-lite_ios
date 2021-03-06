//
//  WebViewController.swift
//  amazonpay-mobile-sample_ios
//
//  Created by Uchiumi, Tetsuo on 2019/06/09.
//

import UIKit
import WebKit
import SafariServices

/// MainActivityから起動される、WEBVIEWサンプル用Controller.
/// WebView内で動作するJavaScriptから起動されるCallback関数を登録し、そのCallback関数からSFSafariViewの購入フローを起動する.
class WebViewController : UIViewController {
    
    var webView: WKWebView!
    
    @IBOutlet weak var topButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("WebViewController#viewDidAppear")
        
        if webView == nil {
            // WebViewの画面サイズの設定
            var webViewPadding: CGFloat = 0
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.keyWindow
                webViewPadding = window!.safeAreaInsets.top
            }
            let webViewHeight = topButton.frame.origin.y - webViewPadding
            let rect = CGRect(x: 0, y: webViewPadding, width: view.frame.size.width, height: webViewHeight)
            
            // JavaScript側からのCallback受付の設定
            let userContentController = WKUserContentController()
            userContentController.add(self, name: "jsCallbackHandler")
            let webConfig = WKWebViewConfiguration();
            webConfig.userContentController = userContentController
            
            // WebViewの生成、orderページの読み込み
            webView = WKWebView(frame: rect, configuration: webConfig)
            let webUrl = URL(string: Config.shared.baseUrl + "ios/order")!
            let myRequest = URLRequest(url: webUrl)
            webView.load(myRequest)
            
            // 生成したWebViewの画面への追加
            self.view.addSubview(webView)
        }
    }
    
    func jsCallbackHandler(_ data:NSDictionary) {
        print("WebViewController#jsCallbackHandler")
        
        let token = data["token"] as! String
        let appKey = data["appKey"] as! String
        
        let safariView = SFSafariViewController(url: NSURL(string: Config.shared.baseUrl + "button?token=" + token)! as URL)
        Holder.appToken = token
        Holder.appKey = appKey
        present(safariView, animated: true, completion: nil)
    }
    
    func showThanks(_ token:String) {
        let webUrl = URL(string: Config.shared.baseUrl + "thanks?token=" + token)!
        var myRequest = URLRequest(url: webUrl)
        myRequest.httpMethod = "POST"
        // myRequest.httpBody = ("token=" + token!).data(using: .utf8)! // Note: WKWebViewにはbodyが消えてしまうバグがあるらしいので、URLパラメータで指定。
        webView.load(myRequest)
    }
}

extension WebViewController: WKScriptMessageHandler {
    
    // JavaScript側からのCallback. 
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WebViewController#userContentController")
        switch message.name {
        case "jsCallbackHandler":
            print("jsCallbackHandler")
            
            if let data = message.body as? NSDictionary {
                jsCallbackHandler(data)
            }
        default:
            return
        }
    }
}
