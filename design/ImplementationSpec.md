# 実装仕様書: TraRead UI・インタラクション

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
- 「英語のファイルをドロップしてください」を薄い灰色で中央に表示
- 「または ⌘V でテキストをペースト」をサブテキストとして表示
- 「ファイルを開く...」ボタンも表示

### 2.2. 文章表示（テキスト読込済み）
- **現在の文**: 大きいフォント（28pt, Bold）で中央配置
- **日本語翻訳**: Accent Orange で表示（20pt, Medium）
- **前の文**: 現在の文の上に小さく灰色で表示（16pt）
- **次の文**: 現在の文の下に小さく灰色で表示（16pt）
- プログレスバーで現在位置 (`n / total`) を表示

## 3. 次文進行インタラクション

以下の3つの方法で次の文に進む：
1. **再生ボタンタップ** — 中央下部の大きな丸型ボタン（Primary→Secondary グラデーション）
2. **画面全体タップ** — `.onTapGesture` で検知
3. **Enter キー** — `.onKeyPress(.return)` で検知

読み上げ中はすべての進行操作が無効化される。

## 4. コピー機能

- 右下のコピーボタン（📋アイコン）をタップ
- 現在の英文 + 日本語翻訳をクリップボードにコピー
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
- **TraReadViewModelTests** (13テスト): 文処理・ナビゲーション・リセット
