import RealmSwift

class Task: Object {
    //  Realmとは：オープンソースのデータベースライブラリ。1DBにつき1ファイル
    //  RealmのモデルはSwiftのクラスとして定義する。MVCのM(モデル)
    //  @objc dynamicはでDBのライブラリであるRealmがKVO(Key Value Observing)という仕組みを利用している為必要。
    //  KVOはプロパティの変更を監視するための仕組み
    
    //TaskクラスにcategoryというStringプロパティを追加してください
    @objc dynamic var category = ""
    
    // 管理用 ID。プライマリーキー。それぞれのデータを一意に識別するためのID
    @objc dynamic var id = 0
    
    // タイトル
    @objc dynamic var title = ""
    
    // 内容
    @objc dynamic var contents = ""
    
    /// 日時
    @objc dynamic var date = Date()
    
    /**
     id をプライマリーキーとして設定
     */
    override static func primaryKey() -> String? {
        return "id"
    }
}
