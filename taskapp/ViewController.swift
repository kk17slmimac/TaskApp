//
//  ViewController.swift
//  taskapp
//
//  Created by 久保田慧 on 2018/11/01.
//  Copyright © 2018年 KeiKubota. All rights reserved.
//
//【追加要件】
//一覧画面に文字列検索用の入力欄を設置し、categoryと合致するTaskのみ絞込み表示させてください
//Auto Layoutを使用して、iPhone SE, iPhone 8, iPhone 8 Plus, iPhone Xの各画面サイズでレイアウトが崩れないようにしてください
//【問題点】
//・絞り込み表示のロジックが設定されていない。
//・searchBarのAutolayout(上のItemBarを消して、そこに表示させたい&searchbarは横いっぱいに広げる)
//・画面をタッチしたらsearchBarが消える&ItemBar復活の動き

//【質問】
//・コード内でのAutoLayoutの設定方法
//・SearchBarの検索用メソッドの設定方法
//・SearchBarの消し方+上のBarの再出現の仕方
//・Categoryの一致したものの表示の仕方



import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate  {
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var search: UIBarButtonItem!
    
    //作成したカテゴリを入れるリスト
    var categoryList = [String]()
    
    //検索の際に使用するリスト
    var searchList:Results<Task>?;

    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。
    // 日付近い順\順でソート：降順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //デリゲート
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //UITableViewDataSourceプロトコルのメソッド
    //データの数(セルの数)を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
   
    
    
    //各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Cellに値を設定する.
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
       
        // ここで カテゴリー : 日付　の文字列を作成
        let labelStr = dateString + ":" + task.category
        //セルにカテゴリー : 日付を追加
        cell.detailTextLabel?.text = labelStr
        
        //作成されたカテゴリを配列に追加。検索する際に使用
        categoryList.append(task.category)
        
       return cell
    }
    
    //UITableViewDelegateプロトコルのメソッド
    //各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    //セル削除が可能なことを知らせるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    //Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            //ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            // データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
    
    // segue で画面遷移するに呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            task.date = Date()
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
           inputViewController.task = task
        }
    }
    
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    //BarButtonItemのsearchボタンを押した時の動作
    @IBAction func searchButton(_ sender: Any) {
        //Navigationバーを消す
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        //searchBarに関する設定
        let searchBar = UISearchBar()
        //Delegateをselfに設定
        searchBar.delegate = self
        //searchBarの位置とサイズを設定
        
        //可能であればコード内でAutoLayoutを設定
//        searchBar.frame = CGRect(x:self.view.frame.width / 2 - 150, y:self.view.frame.height / 2 - 20, width:300, height:40)
        
        //コードでAutoLayout
        let subView = searchBar(frame: CGRect.zero) // AutoLayoutを使うと制約でframeが決まるので値は何でも良いです。
        subView.backgroundColor = UIColor.blue // わかりやすいように青色にします
        
        // サンプルのViewを準備します
        subView.translatesAutoresizingMaskIntoConstraints = false // Autoresizingを無効にしないとAutoLayoutが有効になりません。
        self.view.addSubview(subView) // AutoLayoutを設定する前に、必ずaddSubViewする必要があります。
        
        
        //元々入力されている文字
        searchBar.placeholder = "検索したいカテゴリを入力してください"
        //ViewにsearchBarをSubViewとして追加
        self.view.addSubview(searchBar)
        
        //キャンセルボタン
        searchBar.showsCancelButton = true
        
        //背景をタップしたらsearchBarが消える様に
        
    }
    
    //serchボタンの処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        
        searchBar.endEditing(true)
    
        
        print(taskArray)
        
        
        let filterdArray = searchList?.filter("category = 'searchBar.text'")
        
        try! Realm().objects(Task.self).filter("category = 'searchBar.text'")
        
        
//        let filteredArray = array.filter("条件")
        

        searchList = taskArray

        let filteredArray = taskArray.filter("category = 'searchBar.text'")
        
        
        //キーボードを閉じる
        self.view.endEditing(true)
        
        if searchBar.text == "" {
        //検索文字列が空の場合は全て表示する
                       //画面に表示されているセルの中身
        searchList = taskArray

        }else if searchBar.text == filterdArray//検索文字とセルの中のカテゴリが一致したら
        {
            searchList = filterdArray
        }
        //テーブルを再読み込みする
       tableView.reloadData()
        
    }
    
    

    
    
    
    
}
