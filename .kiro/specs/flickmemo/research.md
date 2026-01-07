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
  - Flutter（Dart）で実装し、状態管理は Riverpod（または同等のシングルソース管理）で統一、ローカル保存は Drift(SQLite) を採用してオフライン前提を満たす。
  - Android向け正確な短期通知は `flutter_local_notifications` のAndroid側実装＋`SCHEDULE_EXACT_ALARM`権限で扱い、遅延・再提示や端末再起動は `workmanager` プラグインで再スケジュールする。
  - 通知/ショートカット/ウィジェット（App Shortcuts & Android Widgets）からのエントリポイントは共通の Application Service 経由で Note/Reminder/Preset ドメインを操作する。

## Research Log
### 通知スケジュールとDND/省電力の扱い
- **Context**: 絶対/相対時刻の確実な通知、DND や電源OFFからの復帰要件。
- **Sources Consulted**: Android公式ドキュメント（AlarmManager, WorkManager, NotificationManager, exact alarm permission）、`flutter_local_notifications` / `workmanager` プラグインドキュメント。
- **Findings**:
  - Android 12+ では正確な時刻には `SCHEDULE_EXACT_ALARM` が必要。許可されない場合は inexact/WorkManager での近似になる。
  - DND 下では通知は抑制される。通知ポリシー許可がなければ再提示は再スケジュールで補う必要がある。
  - 端末再起動や電池最適化でキャンセルされ得るため、WorkManagerによる再登録が必要。
- **Implications**: 通知スケジューラは許可状態を確認し、許可なしの場合のフォールバックと再登録処理を備える。リマインダ状態管理が必須。

### ウィジェット・ショートカットからの即時起動
- **Context**: ホームウィジェット/アイコン長押しショートカットからのクイック作成。
- **Sources Consulted**: Android公式ドキュメント（AppWidgetProvider, ShortcutManager）、FlutterのAppWidget/Shortcut統合ガイド。
- **Findings**:
  - ウィジェットとショートカットはそれぞれ異なる Intent を発行するため、共通の QuickAdd エントリポイントで処理を集約する。
  - ロックスクリーン状態ではセキュリティ上フロー再開が必要。
- **Implications**: エントリポイントをラップする Application Service (`EntryDispatcher`) を用意し、ロック状態時の再開処理を組み込む。

### 入力方式と音声入力
- **Context**: 文字/音声/カラー分類の入力モードと途中切替。
- **Sources Consulted**: Android公式ドキュメント（SpeechRecognizer/RecognizerIntent, Runtime Permissions）、Flutter `speech_to_text` などのプラグインリファレンス。
- **Findings**:
  - 音声入力は RECORD_AUDIO 権限が必要で、オフライン認識は端末依存。ネットワーク必須の場合のUXを設計する必要がある。
  - 入力モード切替時は状態保持（タイトル/本文/カラー）を StateNotifier/Riverpod 等の状態管理で集約するのが適する。
- **Implications**: 権限ダイアログとフォールバック（テキスト入力促し）を設計し、UI状態を StateNotifier/StateHolder で集中管理する。

## Architecture Pattern Evaluation
| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Clean Architecture (Flutter UI / Domain / Data + Platform Adapters) | Flutter UIとDomainを分離し、リポジトリ/スケジューラを介してプラットフォームAPIへ委譲 | 境界明確、テスト容易、複数エントリ対応 | DIとプラグイン橋渡しの初期コスト | 新規プロジェクトで採用、依存方向を内向きに固定 |
| 単層（Widget中心） | Widgetにロジック集中 | 実装最小 | 境界崩壊、テスト困難、拡張時破綻 | 要求の複雑性に合わず不採用 |

## Design Decisions
### Decision: 通知スケジューリングの二段構え
- **Context**: 正確な時刻と遅延再提示を両立する必要。
- **Alternatives Considered**:
  1. flutter_local_notificationsのみ
  2. workmanagerのみ
- **Selected Approach**: flutter_local_notifications（Android exact許可あれば exact）で即時/短期、workmanager で再提示・バックオフを併用。
- **Rationale**: 精度と省電力制御への適合を両立。
- **Trade-offs**: 権限未許可時は精度が落ちる。プラグインが二系統になる。
- **Follow-up**: 実機テストで端末別挙動を確認。

### Decision: データ永続化に Drift (SQLite) を使用
- **Context**: オフライン前提・ローカル保存要求。
- **Alternatives Considered**: SharedPreferences/Proto, Hive, Realm
- **Selected Approach**: Drift(SQLite) を採用。
- **Rationale**: 型安全・マイグレーション管理・Dartでのクエリ生成が容易。
- **Trade-offs**: ビルド生成とスキーマ定義の手間。
- **Follow-up**: 将来クラウド同期を追加する場合のマイグレーション設計を検討。

### Decision: UI は Flutter + Riverpod(StateNotifier)
- **Context**: 円形UIや入力モード切替の状態管理が複雑。
- **Alternatives Considered**: setState中心、Bloc、Riverpod
- **Selected Approach**: Riverpod(StateNotifier) で単一ソースの状態管理。
- **Rationale**: 宣言的UIで状態遷移が明瞭、エントリポイントが複数でも状態共有がしやすい。
- **Trade-offs**: DI/Providerのセットアップが必要。
- **Follow-up**: 最低サポートAPIレベル決定時に依存プラグインの対応を確認。

## Risks & Mitigations
- exact alarm 権限未許可で通知精度が低下 ? 権限要求とフォールバック（近似スケジュール+再提示）を実装。
- 音声入力のオフライン精度・権限拒否 ? 権限ガイダンスとテキスト入力への即時フォールバック。
- ウィジェット/ショートカット呼び出し時の状態不整合 ? QuickAddエントリを経由させ、Controller初期化を共通化。

## References
- Android Developers: AlarmManager, WorkManager, NotificationManager, AppWidgetProvider, ShortcutManager, SpeechRecognizer, SCHEDULE_EXACT_ALARM permission (公式ドキュメントを参照)
