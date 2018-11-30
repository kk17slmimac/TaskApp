//
//  ViewController.swift
//  taskapp
//
//  Created by 久保田慧 on 2018/11/01.
//  Copyright © 2018年 KeiKubota. All rights reserved.
//

/*
 このクラスで実行できていないこと
 【pickerView問題】
実装したい動き：tabBarItemの検索ボタンを押した際にpickerViewを下から登場させる。
 
 <現状の問題>
桑原さんから教えてもらったコードの不明点を解決できていない。
 
 ①TableView上に、初めからPickerViewを配置した際に
　 制約を指定できないのでNSLayoutで紐付けができない。
 
 */

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate,
    UITableViewDataSource,UIPickerViewDelegate,UIPickerViewDataSource
    //    ,UISearchBarDelegate
{

    @IBOutlet weak var pickerViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var search: UIBarButtonItem!
    
    //ピッカービュー
//    let pickerView = UIPickerView()
//    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var pickerView: UIPickerView!
    
    // pickerViewが表示されているかどうか判定
    var showView :Bool!
    
    
    
    var selectedCategory:Category!
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    /* DB内のタスクが格納されるリスト。
     日付近い順\順でソート：降順:false
     以降内容をアップデートするとリスト内は自動的に更新される。*/
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //RealmBrowser用
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        //デリゲート
        tableView.delegate = self
        tableView.dataSource = self
        
        self.pickerViewConstraint.constant = +self.view.frame.height
        
        
        self.showView = false
        
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
        tableView.reloadData()
    }
    
    
    //BarButtonItemのsearchボタンを押した時の動作
    @IBAction func searchButton(_ sender: Any) {
        print("サーチボタン")
        
        // 初期値とpickerviewを押したときにはfalseになる
        if !self.showView {
            // constantの値は適当に
            self.pickerViewConstraint.constant = 1000+self.pickerView.frame.height
            // constantの値は適当に
            self.showView = true
            
            // アニメーションの設定。この処理を削ると下からスッとでてこない
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                // レイアウト更新の時にアニメーションをかける、といういみ。対象はこれだけではなく
                // 普通のviewとかも指定できる
                self.view.layoutIfNeeded()
            })
        }
        
        
        
//        //pickerViewが下から出てきて選択されたCategoryで絞り込めるようにする。
//        pickerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: pickerView.bounds.size.height)
//        pickerView.delegate   = self
//        pickerView.dataSource = self
//
//        // 1.ここでpickerViewの大きさのuiviewを作成する（この時点ではまだ大きさと色を設定しているだけのuiview)
//        let vi = UIView(frame: pickerView.bounds)
//        vi.backgroundColor = UIColor.white
//        // 2.uiviewの上にpikerviewを乗っける
//        vi.addSubview(pickerView)
//
        
        // ここがポイント。1で作ったUIViewをtextFieldのinputView（本来はキーボードが表示されるはずのview）にのせる
        // そうすると、pikerが表示されるようになる
//        textField.inputView = vi
        
        
        
        //pickerViewがいくつも出てきたり、予期せぬ動きを防ぐために2回連続で押せない様にする。
//        self.search.isEnabled = false
        
//        let toolBar = UIToolbar()
//        toolBar.barStyle = UIBarStyle.default
//        toolBar.isTranslucent = true
//        toolBar.tintColor = UIColor.black
//        // pikerを終わらせる時のぼたん　donePressedを呼んでる
//        let doneButton   = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(ViewController.donePressed))
//
//        // キャンセルボタン cancelPressedを呼んでる
//        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ViewController.cancelPressed))
//        // スペースを押したとき、のイベントは今回はないので何も設定しない
////        let spaceButton  = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
//        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
//
//        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
//        toolBar.isUserInteractionEnabled = true
//        toolBar.sizeToFit()
        // pikerview（本来はキーボードが表示されるはずの場所だが、pikerviewで上書きしているので）にツールバーを設定する
//        textField.inputAccessoryView = toolBar
        
        
        
       }
    // Done
//    @objc func donePressed() {
//        view.endEditing(true)
//        self.search.isEnabled = true
//
//    }
//    
//    // Cancel
//    @objc func cancelPressed() {
////        textField.text = ""
//        view.endEditing(true)
//        self.search.isEnabled = true
//    }
    
    
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
   
}//endClass



