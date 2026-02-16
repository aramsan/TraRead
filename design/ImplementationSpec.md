# 実装仕様書: PDF読み込みとドラッグ＆ドロップ機能

## 1. 機能概要
この機能は、TraReadアプリケーションを拡張し、既存のプレーンテキストファイルに加えて、PDFファイルからテキストコンテンツを読み込むことをサポートします。ユーザーは、標準の「ファイルを開く...」ダイアログまたは、`.txt`または`.pdf`ファイルをアプリケーションウィンドウに直接ドラッグ＆ドロップすることによってファイルを選択できます。抽出されたテキストコンテンツは、アプリケーションの既存の文章区切り、翻訳、および音声合成ロジックに渡されます。

## 2. 関係するコンポーネント

### 2.1. `FileHandler.swift` (新規クラス)
- **目的:** さまざまなファイルタイプからコンテンツを読み込むための一元化されたロジック。
- **主要メソッド:**
    - `loadTextFile(from fileURL: URL) throws -> String`: プレーンテキスト（`.txt`）ファイルの読み込みを処理します。`String(contentsOf:encoding:)`を使用します。
    - `extractText(from pdfURL: URL) throws -> String`: Appleの`PDFKit`フレームワークを使用して、Portable Document Format（`.pdf`）ファイルからテキストを抽出します。ページを反復処理し、`pdfPage.string`コンテンツを連結し、ページ間に改行文字を追加します。
    - `loadFileContent(from fileURL: URL) throws -> String`: ファイルの拡張子に基づいてファイルタイプを判断し、適切な読み込みメソッド（`loadTextFile`または`extractText`）にディスパッチする統一されたエントリーポイント。
- **エラーハンドリング:** 堅牢なエラー報告のためにカスタムの`FileHandlingError`列挙型（例：`.textFileLoadFailed`、`.pdfLoadFailed`、`.unsupportedFileType`）を定義します。

### 2.2. `ContentView.swift` (修正済み)
- **目的:** ファイル選択とドラッグ＆ドロップのためのユーザーインターフェース統合。
- **主要な変更点:**
    - **`import AppKit` および `import UniformTypeIdentifiers`:** それぞれ`NSOpenPanel`および`UTType`に必要です。
    - **「ファイルを開く...」ボタン:** UIに新しい`Button`が追加され、クリックすると`NSOpenPanel`が表示されます。
    - **`openFilePicker()` 関数 (新規):**
        - `NSOpenPanel`を設定し、単一ファイルの選択を許可し、ディレクトリを禁止し、`UTType.text`および`UTType.pdf`（古いmacOSバージョンでは`allowedFileTypes`を使用するフォールバック付き）でファイルをフィルタリングします。
        - ファイル選択が成功すると、`FileHandler`をインスタンス化し、`loadFileContent(from:)`を呼び出し、結果で`viewModel.inputText`を更新します。
        - `viewModel.processInputText(loadedText: content)`を呼び出して、新しいテキストを処理パイプラインに供給します。
        - `viewModel.currentSentence`に`FileHandlingError`を表示して処理します。
    - **`.onDrop(of:types:perform:)` 修飾子:** メインのビューコンテナ（`body`の`ZStack`）に適用されます。
        - `.fileURL`タイプのドロップされたアイテムを受け入れます。
        - ドロップされた`NSItemProvider`を反復処理してファイルURLを抽出します。
        - 各`fileURL`について、`fileURL.startAccessingSecurityScopedResource()`を明示的に呼び出して一時的なアクセス許可を取得します。これは、アプリケーションのサンドボックス外からドラッグされたファイルにとって重要です。
        - `defer { if accessed { fileURL.stopAccessingSecurityScopedResource() } }` を使用して、セキュリティスコープのアクセスが適切に解放されるようにします。
        - `FileHandler.loadFileContent(from:)`にファイルコンテンツの読み込みを委譲します。
        - `viewModel.inputText`を更新し、`viewModel.processInputText(loadedText: content)`を呼び出します。
        - `FileHandlingError`を処理して表示します。

### 2.3. `TraReadViewModel.swift` (修正済み)
- **目的:** 新しいソースからのテキストを受信および処理するように適応します。
- **主要な変更点:**
    - **`processInputText(loadedText: String? = nil)`:** 既存の`processInputText`メソッドは、オプションの`loadedText`パラメータを受け入れるようになりました。
        - `loadedText`が提供された場合、`self.inputText`はこのコンテンツで更新され、手動で入力されたテキストを効果的に置き換えます。
        - これにより、テキストトークナイザーと後続のロジックが新しく読み込まれたファイルコンテンツで動作することが保証されます。
        - 読み込みを試みた後に`inputText`が空のままである場合、「処理するテキストがありません。テキストを入力するか、ファイルを読み込んでください。」というエラーメッセージを表示するようにエラー処理が強化されました。

## 3. テストに関する考慮事項

- **単体テスト:**
    - `FileHandler`: 有効/無効な`.txt`パス、有効/無効な`.pdf`パス（テキストなしまたはスキャンされた画像を含むPDFを含む）で`loadTextFile`、`extractText`、`loadFileContent`をテストし、さまざまなファイルタイプとエラーシナリオをテストします。
    - `TraReadViewModel`: `loadedText`が指定された場合とそうでない場合（`inputText`を使用）に`processInputText`をテストし、正しい文章分割と空の入力の処理を確認します。
- **E2Eテスト:**
    - すべてのシナリオをカバーする手動テスト（ユーザーが実行したもの）：.txtを開く、.pdfを開く、.txtをドラッグする、.pdfをドラッグする。
    - 抽出されたコンテンツが`TextEditor`に表示されることを確認します。
    - 読み込まれたコンテンツに対して、その後のナビゲーション（Prev/Next）および音声/翻訳が正しく機能することを確認します。
    - サポートされていないファイルタイプまたは読み取り不可能なファイルに対してエラーメッセージが表示されることを確認します。
- **セキュリティと権限:** サンドボックス化されたmacOS環境でファイル読み込みが正しく機能することを確認します。

## 4. 未解決の質問/今後の作業
- **進行状況の表示:** 大規模なPDFファイルを読み込む際（`extractText`は時間がかかる場合があるため）、視覚的なフィードバック（例：アクティビティインジケーター）を実装します。
- **リッチテキスト/フォーマット:** 現在、プレーンテキストのみが抽出されます。将来の作業として、基本的なフォーマットを保持したり、リッチテキスト形式をサポートしたりすることを検討できます。
- **複数ファイルのドロップ:** 現在の実装では、ドロップ可能な最初のファイルURLのみを処理します。必要に応じて、複数のドロップされたファイルを処理するように拡張します。
- **エラー回復:** `currentSentence`を更新するだけでなく、ファイル読み込みの失敗に対するエラー回復を改善します。
