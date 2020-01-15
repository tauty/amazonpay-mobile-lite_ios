//
//  AppDelegate.swift
//  amazonpay-mobile-sample_ios
//
//  Created by Uchiumi, Tetsuo on 2019/06/08.
//

import UIKit
import SafariServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // Universal Linksにより起動されるメソッド.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        print("AppDelegate#application invoked by Universal Links")
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            print(userActivity.webpageURL!)
            // parse URL parameters
            let query = userActivity.webpageURL!.query!
            var urlParams = Dictionary<String, String>.init()
            for param in query.components(separatedBy: "&") {
                let kv = param.components(separatedBy: "=")
                urlParams[kv[0]] = kv[1].removingPercentEncoding
            }
            print(urlParams);
            
            //　windowを生成
            self.window = UIWindow(frame: UIScreen.main.bounds)
            //　Storyboardを指定
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            // token check
            if(isTokenNG(urlParams["token"]!, initial:urlParams["appToken"]!)) {
                return toError(storyboard);
            }
            
            //----------------------
            // 購入処理
            //----------------------
            let url = URL(string: Config.shared.baseUrl + "purchase_rest")
            var request = URLRequest(url: url!)
            // POSTを指定
            request.httpMethod = "POST"
            // POSTするデータをBodyとして設定
            request.httpBody = query.data(using: .utf8)
            
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                if error == nil, let data = data, let response = response as? HTTPURLResponse {
                    print("statusCode: \(response.statusCode)")
                    
                    // 現在表示中の画面(WebViewController)を取得
                    var vc = UIApplication.shared.keyWindow?.rootViewController
                    var wvc:WebViewController? = nil
                    while (vc!.presentedViewController) != nil {
                        if let w = vc as? WebViewController {
                            wvc = w;
                        }
                        vc = vc!.presentedViewController
                    }

                    let result = String(data: data, encoding: .utf8)
                    DispatchQueue.main.async {
                        // 表示中のSFSafariViewControllerを消す
                        (vc as? SFSafariViewController)?.dismiss(animated: false, completion: nil)
                        
                        if result == "OK" {
                            // Thanks画面を起動
                            wvc?.showThanks(urlParams["token"]!)
                        } else {
                            // Validation Error 表示
                            wvc?.jsCallbackHandler(urlParams["token"]!)
                        }
                    }
                }
            }.resume()
        }
        return true
    }
        
    func isTokenNG(_ token:String, initial appToken:String) -> Bool {
        if(appToken != Holder.appToken!) {
            print("appToken doesn't match! app retained token:" + Holder.appToken! + ", conveyed token:" + appToken);
            return true;
        }
        if(token == appToken) {
            print("token has not been refreshed! token:" + token)
            return true;
        }
        return false
    }
    
    func toError(_ storyboard:UIStoryboard) -> Bool {
        // ViewControllerを指定(ThanksControllerのIdentity → Storyboard IDを参照)
        let vc = storyboard.instantiateViewController(withIdentifier: "ErrorVC")
        // rootViewControllerに入れる
        self.window?.rootViewController = vc
        // 表示
        self.window?.makeKeyAndVisible()
        return true;
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

