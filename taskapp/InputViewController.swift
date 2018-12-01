//
//  InputViewController.swift
//  taskapp
//
//  Created by 久保田慧 on 2018/11/03.
//  Copyright © 2018年 KeiKubota. All rights reserved.
//
import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController , UIPickerViewDelegate , UIPickerViewDataSource{
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var picker: UIPickerView!
    //    @IBOutlet weak var categoryTextField: UITextField!
    var task: Task!
    let realm = try!Realm()
    var selectedCategory:Category!
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    var category: String!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate設定
        picker.delegate = self
        picker.dataSource = self
        
        //背景をタップしたらdismissKeybordメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dissmissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        //最初から表示する文字
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        
        if categoryArray.count >= 1{
        self.selectedCategory = categoryArray[0]
        }
    }
    
    @objc func dissmissKeyboard(){
        //キーボードを閉じる
        view.endEditing(true)
    }
    
    //遷移元に戻る際にタスクの内容をデータベースに保存する
    override func viewWillDisappear(_ animated: Bool) {
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            //選択されているpickerViewの保存方法
            self.task.category = self.selectedCategory
            self.realm.add(self.task, update: true)
        }
        setNotification(task: task)
        super.viewWillDisappear(animated)
    }
    
    //タスクのローカル通知を登録する
    func setNotification(task: Task){
        let content = UNMutableNotificationContent()
        //タイトルと内容を設定
        if task.title == ""{
            content.title = "(タイトルなし)"
        }else{
            content.title = task.title
        }
        
        if task.contents == ""{
            content.body = task.contents
        }
        
        content.sound = UNNotificationSound.default()
        
        
        //ローカル通知が発動するtrigger(日付マッチ)を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: dateComponents, repeats: false)
        
        //identifier,content,triggerからローカル通知を作成(identifierが同じだとローカル通知を上書き保存)
        let request = UNNotificationRequest.init(identifier: String(task.id),content:content,trigger:trigger)
        
        //ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request){(error)in
            print(error ?? "ローカル通知登録 OK")//errorがnilならローカル通知の登録に成功したと表示する
        }
        
        //未登録のローカル通知一覧をログ出力
        center.getPendingNotificationRequests{(requests: [UNNotificationRequest])in
            for request in requests{
                print("/-------------------")
                print(request)
                print("/-------------------")
            }
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
        
        print("==========titleForRowの中身＝＝＝＝＝＝＝＝＝＝＝")
        print(row)
        category = categoryArray[row].categoryName
        return category
    }
    
    // UIPickerViewのRowが選択された時の挙動
    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        
        self.selectedCategory = categoryArray[row]
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        //画面が再度表示される時
        /*実装したい動き
         ・現在Realmに入っている値の更新をしてpickerの更新をする
         */
 
        super.viewWillAppear(animated)
        
        //Realmの値を取得
//         categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    
        picker.reloadAllComponents()
        
        if categoryArray.count >= 1{
            self.selectedCategory = categoryArray[0]
        }
        
        print("============戻ってきた時===============")
        print(categoryArray)
        
    }
    
}//end Class
