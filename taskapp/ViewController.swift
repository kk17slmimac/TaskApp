//
//  ViewController.swift
//  taskapp
//
//  Created by 久保田慧 on 2018/11/01.
//  Copyright © 2018年 KeiKubota. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate,
    UITableViewDataSource,UIPickerViewDelegate,UIPickerViewDataSource
    //    ,UISearchBarDelegate
{
    
    @IBOutlet weak var pickerLayout: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var search: UIBarButtonItem!
    @IBOutlet weak var cancel: UIBarButtonItem!
    
    
    
    //ピッカービュー
    //    let pickerView = UIPickerView()
    //    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var pickerView: UIPickerView!
    
    // pickerViewが表示されているかどうか判定
    var showView :Bool!
    
    
    
    var selectedCategory:Category!
    
    //Realmインスタンス取得開始
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    //データを取得する
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    
    /* DB内のタスクが格納されるリスト。
     日付近い順\順でソート：降順:false
     以降内容をアップデートするとリスト内は自動的に更新される。*/
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    //--- Realm取得終了ここまで
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //RealmBrowser用
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        //デリゲート
        tableView.delegate = self
        tableView.dataSource = self
        //【追加】不足していたデリゲート
        pickerView.delegate = self
        pickerView.dataSource = self
        
        //【追加】tableViewの高さ分下に下げる
        self.pickerLayout.constant = +self.tableView.frame.height
        
        self.pickerLayout.constant = +self.tableView.frame.height
        
        self.showView = false
        if categoryArray.count >= 1{
            self.selectedCategory = categoryArray[0]
        }
        
        //【追加】Viewのありかがわかりやすいように色をつけている
        pickerView.backgroundColor = UIColor.white
        
        
        //        self.showView = false
        
    }
    
    @objc func dissmissKeyboard(){
        //キーボードを閉じる
        view.endEditing(true)
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
        let labelStr = dateString + ":" + (task.category?.categoryName)!
        //セルにカテゴリー : 日付を追加
        cell.detailTextLabel?.text = labelStr
        
        
        return cell
    }
    
    //UITableViewDelegateプロトコルのメソッド
    //各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //遷移
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
        taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
        categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
        tableView.reloadData()
        pickerView.reloadAllComponents()
    }
    
    
    //BarButtonItemのsearchボタンを押した時の動作
    @IBAction func searchButton(_ sender: Any) {
        print("サーチボタン")
        
        // 初期値とpickerviewを押したときにはfalseになる
        if !self.showView {
            // tableviewの高さ分-pickerViewが最初から持っている高さを引いた分上に引き上げて表示する
            self.pickerLayout.constant = +self.tableView.frame.height-self.pickerView.frame.height
            self.showView = true
            
            //tableViewが絞り込み時も全部見れる様にする。
            
            
            // アニメーションの設定。この処理を削ると下からスッとでてこない
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                // レイアウト更新の時にアニメーションをかける、といういみ。対象はこれだけではなく
                // 普通のviewとかも指定できる
                self.view.layoutIfNeeded()
            })
        }else{
            //欄外に引っ込める
            self.pickerLayout.constant = self.view.frame.height
            self.showView = false
            //アニメーションの設定
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                // レイアウト更新の時にアニメーションをかける、といういみ。対象はこれだけではなく
                // 普通のviewとかも指定できる
                self.view.layoutIfNeeded()
                self.cancel.isEnabled = true
                
            })
        }
    }
    
    
    // UIPickerViewの列の数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // UIPickerViewの行数、要素の全数
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        let categoryClass = Category.self
        let allCategories = realm.objects(categoryClass)
        return allCategories.count
    }
    
    // UIPickerViewに表示する配列
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        
        let category: String!
        category = categoryArray[row].categoryName
        
        return category
    }
    
    // UIPickerViewのRowが選択された時の挙動
    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        self.selectedCategory = categoryArray[row]
        
        //検索メソッド
        searchCategory()
    }
    
    func searchCategory(){
        //検索&フィルター
        let predicate = NSPredicate(format: "category = %@", self.selectedCategory ?? "")
        let searchResult = realm.objects(Task.self).filter(predicate)
        
        if searchResult.count > 0 {
            taskArray = searchResult
            print("==================検索成功==================")
            
        }else{
            let alert: UIAlertController = UIAlertController(title: "検索結果無し", message: "検索したカテゴリのタスクはありません", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
        tableView.reloadData()
    }
    
    
//    【追加】
    @IBAction func cancelButton(_ sender: Any) {
        self.taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
        self.tableView.reloadData()
        
        cancel.isEnabled = false
        
    }
    
    
    
    
    
}//endClass
