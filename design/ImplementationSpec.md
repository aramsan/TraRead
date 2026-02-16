# 実装仕様書: TraRead UI・インタラクション

## 0. 動作環境
- **macOS**: 15.0 以降 (Translation フレームワーク API 要件)
- **iOS**: 18.0 以降 (Translation フレームワーク API 要件)

## 1. テキスト入力方式

### 1.1. ドラッグ＆ドロップ
- `.txt` / `.pdf` ファイルをウィンドウにドロップするとテキストを読み込む
- `FileHandler.loadFileContent(from:)` でコンテンツを抽出し、`viewModel.processInputText(loadedText:)` に渡す
- セキュリティスコープ付きリソースに対応（`startAccessingSecurityScopedResource()`）

### 1.2. ファイルピッカー（Open File）
- 「ファイルを開く...」ボタンから `NSOpenPanel` を表示
- `UTType.text` / `UTType.pdf` でフィルタリング

### 1.3. ⌘V ペースト入力
- ウィンドウにフォーカスした状態で `Command-V` を押すとクリップボードからテキストを読み込む
- `NSPasteboard.general.string(forType: .string)` でテキストを取得
- 空白のみのペーストは無視

## 2. テキスト表示

### 2.1. プレースホルダー（テキスト未読込時）
- アプリアイコン（透過率50%）を中央に表示
- 「ドロップして読み込み」等のガイダンスを表示
- 「ファイルを開く...」ボタンを表示

### 2.2. 文章表示（テキスト読込済み）
- **現在の文**: 大きいフォント（28pt, Bold）で中央配置
- **日本語翻訳**: Accent Orange で表示（20pt, Medium）
- **前の文**: 現在の文の上に小さく灰色で表示（16pt）
- **次の文**: 現在の文の下に小さく灰色で表示（16pt）
- プログレスバーで現在位置 (`n / total`) を表示

## 3. 次文進行インタラクション

読み上げ中も **⏩（FF）ボタン** によるスキップが可能（即座に再生停止し次へ移動）。それ以外の進行操作、および最終行到達時の **再生ボタン** は無効化される。最終行到達時は "End of text" 表示は行わず停止する。

## 4. コピー機能

- 右下のコピーボタン（📋アイコン）をタップ
- **すべての文章ペア**（これまでに翻訳された英文 + 日本語翻訳）をクリップボードにコピー
- 「コピーしました」のフィードバックを1.5秒間表示

## 5. 関連コンポーネント

### 5.1. `FileHandler.swift`
- `loadTextFile(from:)`: `.txt` ファイル読み込み
- `extractText(from:)`: `PDFKit` による `.pdf` テキスト抽出
- `loadFileContent(from:)`: ファイル拡張子に応じたディスパッチ
- `FileHandlingError` 列挙型でエラー管理

### 5.2. `TraReadViewModel.swift`
- `processInputText(loadedText:)`: テキスト受信・文分割・読み上げ開始
- `nextSentence()` / `prevSentence()`: 文ナビゲーション
- `reset()`: 状態リセット
- `speakCurrentSentence()` / `speakJapaneseTranslation()`: 音声合成
- `AVSpeechSynthesizerDelegate` で英語→翻訳→日本語のフロー制御

### 5.3. `ContentView.swift`
- プレースホルダー表示 / メイン表示の切り替え
- ドロップ / ペースト / ファイルピッカーの入力ハンドリング
- 前後文コンテキスト表示
- コピー機能

## 6. テスト

- **FileHandlerTests** (7テスト): txt/pdf の読み込み・エラーハンドリング
- **TraReadViewModelTests** (15テスト): 文処理・ナビゲーション・翻訳保存・リセット
- **TraReadTests** (1テスト): 基本的な組み込みテスト
- **合計**: 23テストがパスすることを確認済み。
