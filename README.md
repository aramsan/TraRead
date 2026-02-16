# 📚 TraRead（トラリード）

英語テキストを「1文ずつ」読み上げ、日本語に翻訳して交互に音声出力するステップ式翻訳リーダーアプリです。

## 🐯 コンセプト

TraRead は、英語学習をサポートする macOS 向けアプリケーションです。入力された英文を1文ずつ区切り、英語の読み上げ → 日本語翻訳の表示・読み上げ → ユーザーの操作で次の文へ進行、というフローで英語学習を支援します。

## ✨ 主な機能

- **文ごとのステップ式読み上げ** — Enter キー / 画面タップ / 再生ボタンで次の文に進行
- **バイリンガルリレー** — 英語読み上げ → 日本語翻訳表示・読み上げ
- **前後文コンテキスト表示** — 現在の文の前後を薄い色で表示し、文脈を把握しやすく
- **3つの入力方法** — ファイルドロップ / ファイルピッカー / ⌘V ペースト
- **ファイル対応** — `.txt` / `.pdf` ファイルに対応
- **コピー機能** — 右下のボタンで英文・日文をクリップボードにコピー
- **前後ナビゲーション** — Prev / Next ボタンで文を自由に移動

## 🛠 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | Swift 6 |
| フレームワーク | SwiftUI |
| アーキテクチャ | MVVM |
| 音声合成 | AVFoundation (`AVSpeechSynthesizer`) |
| 文章分割 | NaturalLanguage (`NLTokenizer`) |
| 翻訳 | Translation (Apple Native) |
| PDF処理 | PDFKit |

## 📁 プロジェクト構成

```
TraRead/
├── design/                    # 設計書・仕様書
│   ├── design.md              # アプリ設計書
│   ├── ImplementationSpec.md  # 実装仕様書
│   └── rule.md                # 開発ルール
├── manual/                    # マニュアル
├── xcode/                     # Xcode プロジェクト
│   ├── Package.swift          # Swift Package Manager 設定
│   ├── TraRead/               # ソースコード
│   │   ├── TraReadApp.swift       # アプリエントリポイント
│   │   ├── ContentView.swift      # メイン画面 UI
│   │   ├── TraReadViewModel.swift # ViewModel (ロジック)
│   │   ├── FileHandler.swift      # ファイル読み込み処理
│   │   └── Color+Hex.swift        # カラーユーティリティ
│   ├── TraReadTests/          # ユニットテスト
│   │   ├── FileHandlerTests.swift
│   │   ├── TraReadViewModelTests.swift
│   │   └── sample.pdf
│   ├── TraRead.xcodeproj/     # Xcode プロジェクト設定
│   └── TraRead.xctestplan     # テストプラン
├── .gitignore
└── README.md
```

## 🚀 セットアップ

### 必要環境

- macOS 15.0 以上
- iOS 18.0 以上
- Xcode 16.0 以上
- Swift 6.0 以上

### ビルド・実行

1. `xcode/TraRead.xcodeproj` を Xcode で開く
2. ビルドターゲットを **TraRead** に設定
3. `⌘R` で実行

### テストの実行

```bash
cd xcode
swift test
```

現在 **23件の単体テスト** が実装されています（FileHandler: 7件、ViewModel: 15件、基本テスト: 1件）。すべて `swift test` でパスすることを確認済みです。

## 📖 使い方

1. アプリを起動するとアプリアイコン（透過率50%）のプレースホルダーが表示される
2. 以下のいずれかの方法で英文テキストを入力する：
   - `.txt` / `.pdf` ファイルをウィンドウにドラッグ＆ドロップ
   - 「ファイルを開く...」ボタンからファイルを選択
   - 英文テキストをコピーし、ウィンドウにフォーカスして `⌘V` でペースト
3. テキストが自動的に文ごとに分割され、最初の文が読み上げられる
4. 日本語翻訳が表示・読み上げされる
5. **Enter キー** / **画面タップ** / **再生ボタン** で次の文へ進む
6. **Prev / Next ボタン** で前後の文に移動可能（Next ボタンは読み上げ中もスキップツールとして機能）
7. 右下の **コピーボタン** でこれまで読み上げたすべての英文・日文のペアをクリップボードにコピー

## 🗺 開発ロードマップ

- [x] 第1段階：Core Engine（テキスト入力・文分割・英語読み上げ）
- [x] 第2段階：Bilingual Relay（翻訳・日本語読み上げ）
- [x] 第3段階：PDF Integration（PDF読み込み・ドラッグ＆ドロップ）
- [ ] 第4段階：Universal Adaptation（iOS / iPadOS 対応）

## 📝 ライセンス

Private Repository
