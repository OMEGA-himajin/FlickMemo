# Research & Design Decisions Template

---
**Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.

**Usage**:
- Log research activities and outcomes during the discovery phase.
- Document design decision trade-offs that are too detailed for `design.md`.
- Provide references and evidence for future audits or reuse.
---

## Summary
- **Feature**: flickmemo
- **Discovery Scope**: New Feature
- **Key Findings**:
  - オフライン前提のローカル保存は Room（SQLite）を軸にし、音声入力・通知・ウィジェットなどの権限境界を明示する必要がある。
  - 正確な短期通知は `SCHEDULE_EXACT_ALARM` 権限を伴う AlarmManager で扱い、遅延・再提示やバッテリー最適化下は WorkManager でリトライを組み合わせる。
  - 通知からの操作・ショートカット・ウィジェットはそれぞれ別エントリポイントになるため、共通の Note/Reminder ドメインサービスで一貫した状態管理とプリセット適用を行う。

## Research Log
### 通知スケジュールとDND/省電力の扱い
- **Context**: 絶対/相対時刻の確実な通知、DND や電源OFFからの復帰要件。
- **Sources Consulted**: Android公式ドキュメント（AlarmManager, WorkManager, NotificationManager, exact alarm permission）。
- **Findings**:
  - Android 12+ では正確な時刻には `SCHEDULE_EXACT_ALARM` が必要。許可されない場合は inexact/WorkManager での近似になる。
  - Do Not Disturb 下では通知は抑制される。通知ポリシー許可がなければ再提示は再スケジュールで補う必要がある。
  - 端末再起動や電池最適化でキャンセルされ得るため、ブート/再起動受信で再登録するリカバリが必要。
- **Implications**: 通知スケジューラは許可状態を確認し、許可なしの場合のフォールバックと再登録処理を備える。リマインダ状態管理が必須。

### ウィジェット・ショートカットからの即時起動
- **Context**: ホームウィジェット/アイコン長押しショートカットからのクイック作成。
- **Sources Consulted**: Android公式ドキュメント（AppWidgetProvider, ShortcutManager）。
- **Findings**:
  - ウィジェットとショートカットはそれぞれ異なる Intent を発行するため、共通の QuickAdd エントリポイントで処理を集約する。
  - ロックスクリーン状態ではセキュリティ上フロー再開が必要。
- **Implications**: エントリポイントをラップする `EntryDispatcher` を用意し、認証/ロック状態に応じたリジューム処理を用意する。

### 入力方式と音声入力
- **Context**: 文字/音声/カラー分類の入力モードと途中切替。
- **Sources Consulted**: Android公式ドキュメント（SpeechRecognizer/RecognizerIntent, Runtime Permissions）。
- **Findings**:
  - 音声入力は RECORD_AUDIO 権限が必要で、オフライン認識は端末依存。ネットワーク必須の場合のUXを設計する必要がある。
  - 入力モード切替時は状態保持（タイトル/本文/カラー）を ViewModel 層で管理するのが一般的。
- **Implications**: 権限ダイアログとフォールバック（テキスト入力促し）を設計し、UI状態を ViewModel/StateHolder で集中管理する。

## Architecture Pattern Evaluation
| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Clean Architecture (UI/Domain/Data) | UIはCompose、ドメインサービスを介してリポジトリ/スケジューラに委譲 | 境界が明確、テストしやすい、ウィジェット/通知など複数エントリに対応しやすい | 境界定義とDIセットアップの初期コスト | 新規プロジェクトで採用、依存方向を内向きに固定 |
| 単層（Activity中心） | Activity/Serviceにロジック集中 | 実装が最小 | 境界崩壊、テスト困難、拡張時に破綻 | 要求の複雑性に合わず不採用 |

## Design Decisions
### Decision: 通知スケジューリングの二段構え
- **Context**: 正確な時刻と遅延再提示を両立する必要。
- **Alternatives Considered**:
  1. AlarmManagerのみで全て扱う
  2. WorkManagerのみで扱う
- **Selected Approach**: 正確な短期は AlarmManager（exact許可があれば setExactAndAllowWhileIdle）、バックオフ/再提示は WorkManager による再スケジュールを併用。
- **Rationale**: 精度と省電力制御への適合を両立。
- **Trade-offs**: 権限未許可時は精度が落ちる。実装が二系統になる。
- **Follow-up**: 実機テストで端末別挙動を確認。

### Decision: データ永続化に Room を使用
- **Context**: オフライン前提・ローカル保存要求。
- **Alternatives Considered**: SharedPreferences/Proto, Realm
- **Selected Approach**: Room(SQLite) + suspend DAO を採用。
- **Rationale**: 型安全・マイグレーション管理・テスト容易。
- **Trade-offs**: スキーマ定義が必要。初期セットアップの手間。
- **Follow-up**: 将来クラウド同期を追加する場合のマイグレーション設計を検討。

### Decision: UI は Compose + ViewModel/StateHolder
- **Context**: 円形UIや入力モード切替の状態管理が複雑。
- **Alternatives Considered**: XML View + Fragment, Compose + ViewModel
- **Selected Approach**: Compose + ViewModel/StateHolder で単一ソースの状態管理。
- **Rationale**: 宣言的UIで状態遷移が明瞭、ウィジェット/通知からの再開にも適合。
- **Trade-offs**: Compose依存を導入。古い端末サポート範囲に注意。
- **Follow-up**: 最低サポートAPIレベル決定時にCompose互換性を確認。

## Risks & Mitigations
- exact alarm 権限未許可で通知精度が低下 ? 権限要求とフォールバック（近似スケジュール+再提示）を実装。
- 音声入力のオフライン精度・権限拒否 ? 権限ガイダンスとテキスト入力への即時フォールバック。
- ウィジェット/ショートカット呼び出し時の状態不整合 ? QuickAddエントリを経由させ、ViewModel初期化を共通化。

## References
- Android Developers: AlarmManager, WorkManager, NotificationManager, AppWidgetProvider, ShortcutManager, SpeechRecognizer, SCHEDULE_EXACT_ALARM permission (公式ドキュメントを参照)
