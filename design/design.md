完璧です！これで「TraRead」の構想が完全に視覚化され、技術的な実装手順も整いました。

作成したアイコンとUIスケッチ、そして虎のイメージに基づいたマテリアルデザイン準拠のカラーパレットを追加した、最終版の設計書を作成します。

これをそのままGemini CLIに読み込ませて、開発をスタートしてください！

---

# 📚 アプリ設計書：TraRead (Final Version for Gemini CLI)

## 1. プロジェクト概要

* **アプリ名:** TraRead（トラリード）
* **プラットフォーム:** Apple Universal (macOS, iOS, iPadOS)
* **コンセプト:** 英語と日本語を「1文ずつ」交互に読み上げ、ユーザーの入力（Enter/Tap）で進行するステップ式翻訳リーダー。虎のキャラクターがナビゲートする、力強く楽しい学習体験を提供します。

## 2. デザイン & カラーパレット

### 2.1 アプリアイコン

虎が英語（A）から日本語（あ）へ、音の波形に乗って変換していく様子を表現したアイコン。親しみやすい笑顔が特徴。

![アプリアイコン](TraRead-Icon.png)

### 2.2 UIスケッチ (Universal)

iOS(左)とmacOS(右)のUIイメージ。テキスト未読込時は「英語のファイルをドロップしてください」のプレースホルダーを表示。テキスト読込後は、現在の文を中央に大きく表示し、前後の文を薄い色で表示。大きな丸型再生ボタン（Tiger Gold → Accent Orange グラデーション）を配置。右下にコピーボタンを配置。入力方法はドラッグ＆ドロップ、ファイルピッカー、⌘V ペーストの3種類に対応。

![アプリアイコン](TraRead-UI.png)

### 2.3 カラーパレット (Material Design準拠)

虎のイメージカラー（黄色・黒）をベースにした、ハイコントラストで視認性の高い配色計画です。

| Role | Color Code | Description | 使用例 |
| --- | --- | --- | --- |
| **Primary** | **`#FFD700`** | Tiger Gold | メインカラー。再生ボタン、強調枠線、進行バー、アイコンの背景など。 |
| **Secondary** | **`#FF8C00`** | Accent Orange | 「あ」のグラデーション、テキストの強調ハイライト、補助的なアクション。 |
| **Background** | **`#FFFBE6`** | Warm Off-White | アプリ全体の背景色（UIスケッチ参照）。目に優しい温かみのある白。 |
| **Surface/Text** | **`#121212`** | Almost Black | 主要なテキスト、虎の縞模様、UIの黒枠。完全な黒ではなく少し柔らかい黒。 |
| **Warning** | **`#FFA000`** | Amber | 注意喚起、確認ダイアログなど（Primaryと近いが、よりオレンジ寄り）。 |
| **Info** | **`#0288D1`** | Standard Blue | ヘルプ、設定情報など、ニュートラルな情報表示。 |
| **Success** | **`#388E3C`** | Standard Green | 完了状態、正解表示など。 |
| **Grey** | **`#BDBDBD`** | Medium Grey | 無効なボタン、控えめな境界線、プレースホルダーテキスト。 |

---

## 3. 技術スタック & アーキテクチャ

* **Language:** Swift 6 / **Framework:** SwiftUI
* **Architecture:** MVVM (Model-View-ViewModel)
* **Core Frameworks:**
* `AVFoundation` (TTS: AVSpeechSynthesizer)
* `Natural Language` (文章分割: NLTokenizer)
* `Translation` (翻訳: Apple Native Framework)
* `PDFKit` (PDFテキスト抽出)



---

## 4. 開発ロードマップ (段階的実装)

### 第1段階: Core Engine (macOS MVP)

* テキスト入力 ➜ `NLTokenizer`で文分割。
* 英語(`en-US`)読み上げ ➜ 待機。
* **Enterキー**で次文へ進行する基本ループの実装。

### 第2段階: Bilingual Relay (翻訳機能)

* 英語読み上げ完了をトリガーに`Translation`フレームワークで翻訳。
* 日本語訳を表示し、日本語(`ja-JP`)で読み上げ。
* フロー確立: [英音] ➜ [日表示・日音] ➜ [待機]。

### 第3段階: PDF Integration

* `PDFKit`導入。PDFから全テキストを抽出し、整形して第1段階のエンジンへ渡す。
* ファイルピッカーで`.txt`と`.pdf`に対応。

### 第4段階: Universal Adaptation (iOS/iPadOS)

* UIのレスポンシブ化（上記スケッチ参照）。
* 画面タップによる進行インタラクションの追加。
* `fileImporter`を用いたiCloud Drive連携。