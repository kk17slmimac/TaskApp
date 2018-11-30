//
//  CategoryViewController.swift
//  taskapp
//
//  Created by 久保田慧 on 2018/11/11.
//  Copyright © 2018年 KeiKubota. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryViewController: UIViewController {
    /*【このクラスでやりたいこと】
     ・TextFieldに入力された文字列をカテゴリ(Categroy.swift)に保存する
     【実装方法】
     ・Category.swiftのcategoryNameに入力された文字列を、idにid(現在保持している最大値に+1 0の時は0)を書き込む
     ・realm.add...でrealmに保存
     ・保存ボタンを押したらポップアップで「カテゴリが追加されました」と表示してInputViewControllerに遷移
     */
    
    
    
    
    let realm = try!Realm()
    
    @IBOutlet weak var categoryTextField: UITextField!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func saveButton(_ sender: Any) {
        
        //TextFieldの文字列を取得
        let getTextField: String? = self.categoryTextField.text!

        
        //書き込み
        try! realm.write {
            //インスタンス生成
            let category = Category()
            
            //引数に設定用に宣言
            let categoryClass = Category.self
            //全てのカテゴリ一覧を出している
            let allCategories = realm.objects(categoryClass)
            
            //上書きにならない様にidを新しく作っている
            if allCategories.count != 0 {
                category.id = allCategories.max(ofProperty: "id")! + 1
            }
            //Category.swiftのcategoryName(String型)に代入
            category.categoryName = getTextField!
            
            //Category.swiftに保存
            self.realm.add(category, update: true)
    }
        if getTextField == ""{
            nilAlert()
        }else{
            saveAlert()
        }
        
        //保存ボタンを押したら入力された文字列を消す
        categoryTextField.text = nil
    }
    
    

//        //backボタン押下時の処理
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//
//    }
    
    
    func saveAlert() {
        // アラートを作成
        let alert = UIAlertController(
            title: "カテゴリが追加されました",
            message: "続けて追加することもできます",
            preferredStyle: .alert)
        
        // アラートにボタンをつける
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // アラート表示
        self.present(alert, animated: true, completion: nil)
    }

    func nilAlert() {
        // アラートを作成
        let alert = UIAlertController(
            title: "何も入力されていません",
            message: "追加するカテゴリを入力してください",
            preferredStyle: .alert)
        
        // アラートにボタンをつける
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // アラート表示
        self.present(alert, animated: true, completion: nil)
    }

    
    
    
    
    
    
}
