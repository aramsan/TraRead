# 📚 TraRead（トラリード）

英語テキストを「1文ずつ」読み上げ、日本語に翻訳して交互に音声出力するステップ式翻訳リーダーアプリです。

## 🐯 コンセプト

TraRead は、英語学習をサポートする macOS 向けアプリケーションです。入力された英文を1文ずつ区切り、英語の読み上げ → 日本語翻訳の表示・読み上げ → ユーザーの操作で次の文へ進行、というフローで英語学習を支援します。

## ✨ 主な機能

- **文ごとのステップ式読み上げ** — Enter キーで次の文に進行
- **バイリンガルリレー** — 英語読み上げ → 日本語翻訳表示・読み上げ
- **ファイル読み込み** — `.txt` / `.pdf` ファイルに対応
- **ドラッグ＆ドロップ** — ファイルをウィンドウにドロップして読み込み
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

- macOS 14.0 以上
- Xcode 15 以上
- Swift 5.9 以上

### ビルド・実行

1. `xcode/TraRead.xcodeproj` を Xcode で開く
2. ビルドターゲットを **TraRead** に設定
3. `⌘R` で実行

### テストの実行

Swift Package Manager を使用してテストを実行できます。

```bash
cd xcode
swift test
```

現在 **21件の単体テスト** が実装されています（FileHandler: 7件、ViewModel: 13件、基本テスト: 1件）。

## 📖 使い方

1. アプリを起動し、テキストエリアに英文を入力するか、`.txt` / `.pdf` ファイルを読み込む
2. テキストが自動的に文ごとに分割される
3. 英語の文が読み上げられる
4. 日本語翻訳が表示・読み上げされる
5. **Enter キー** または **Next ボタン** で次の文へ進む
6. **Prev ボタン** で前の文に戻ることも可能

## 🗺 開発ロードマップ

- [x] 第1段階：Core Engine（テキスト入力・文分割・英語読み上げ）
- [x] 第2段階：Bilingual Relay（翻訳・日本語読み上げ）
- [x] 第3段階：PDF Integration（PDF読み込み・ドラッグ＆ドロップ）
- [ ] 第4段階：Universal Adaptation（iOS / iPadOS 対応）

## 📝 ライセンス

Private Repository
