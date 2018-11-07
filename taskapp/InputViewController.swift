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

class InputViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    var task: Task!
    let realm = try!Realm()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //背景をタップしたらdismissKeybordメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dissmissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        //最初から表示する文字
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category
        
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
            self.task.category = self.categoryTextField.text!
            
            self.realm.add(self.task , update: true)
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
    
}//end Class
