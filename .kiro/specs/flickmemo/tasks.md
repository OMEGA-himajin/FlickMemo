# Implementation Plan

- [ ] 1. 開発基盤セットアップ（Flutter/Riverpod/Drift/通知プラグイン）
- [x] 1.1 プロジェクト依存導入と初期設定 (P)
  - Riverpod/StateNotifier、Drift、flutter_local_notifications、workmanager、speechプラグインを追加し、Androidで必要な権限・マニフェスト設定を行う
  - _Requirements: 3.1,3.2,3.3,3.4,7.1_
- [x] 1.2 Drift 基本設定とビルド環境 (P)
  - Driftのビルドランナー/コード生成設定を整備し、SQLiteドライバとバージョニング方針を有効化
  - _Requirements: 7.1,7.2_

- [ ] 2. データレイヤ実装（Driftテーブル＋Repository）
- [x] 2.1 notes/presets/reminders スキーマ定義とDAO作成
  - Note/Preset/Reminder テーブルと外部キー・インデックス（scheduledAt）を定義し、基本CRUDを実装
  - _Requirements: 1.2,2.3,3.1,3.2,5.1,5.2,5.3,5.4,6.4,7.1_
- [x] 2.2 Repository 実装 (P)
  - NoteRepository/PresetRepository/ReminderRepository をDrift DAOに接続し、非同期で永続化・取得を提供
  - _Requirements: 1.2,2.3,3.1,3.2,5.1,5.2,5.3,5.4,6.4,7.1_

- [ ] 3. ドメインサービス実装
- [x] 3.1 NoteService 実装 (P)
  - タイトル必須・カラー制約を含むメモ作成/更新ロジックをRepository経由で実装
  - _Requirements: 1.2,2.3,6.4,7.1_
- [x] 3.2 PresetService 実装 (P)
  - プリセット保存/更新/取得とバリデーション（時間帯/オフセット/入力方式/カラー）を実装
  - _Requirements: 5.1,5.2,5.3,5.4,6.2_
- [ ] 3.3 ReminderScheduler 実装
  - ReminderTriggerの時間計算（absolute/relative/bucket）、Bucket→08/12/17/21繰越規則、exact許可有無での通知スケジュール、MVPのSnooze/手動再設定、P1のWorkManager再提示を組み込む
  - _Requirements: 3.1,3.2,3.3,3.4,4.4,6.4,7.4_
- [ ] 3.4 LocalNotificationAdapter / WorkManagerAdapter
  - flutter_local_notificationsで通知チャンネル・表示を実装し、workmanagerで再提示ジョブを登録（P1）しつつMVPは手動/Snooze起点を許容
  - _Requirements: 3.1,3.2,3.3,3.4_

- [ ] 4. アプリケーションサービス・エントリ統合
- [ ] 4.1 EntryDispatcher 実装
  - Entry Input Contract（entryType/presetId/openNoteId/defaultTrigger/inputMode/color）のIntent変換と起動元別の初期化、ロック解除後のリジュームを実装
  - _Requirements: 6.1,6.2,6.3,6.4_
- [ ] 4.2 NotificationHandler 実装
  - 通知タップでノート表示に遷移し、再提示ロジックはReminderScheduler/WorkManagerAdapterに委譲
  - _Requirements: 3.3,3.4_
- [ ] 4.3 WidgetEntry / ShortcutEntry 実装 (P)
  - ウィジェット/ショートカットからEntryDispatcherを呼び出し、プリセット適用とロック状態考慮でQuickAddを起動
  - _Requirements: 6.1,6.2,6.4_

- [ ] 5. UI / State 実装
- [ ] 5.1 QuickAddController (StateNotifier)
  - タイトル必須バリデーション、本文/カラー/モード状態保持、NoteService+ReminderScheduler連携、プリセット適用を実装
  - _Requirements: 1.1,1.2,1.4,2.3,3.1,3.2,3.3,3.4,4.4,6.4,7.4_
- [ ] 5.2 InputModeController
  - text/voiceの入力モード管理とcolor選択、音声開始/停止の権限チェックとフォールバックを実装
  - _Requirements: 1.3,2.1,2.2,2.3,2.4_
- [ ] 5.3 CircularSchedulerUI
  - 詳細/簡易モードの円形UIで時刻・時間帯選択、モード切替時の保持とトリガー変換を実装
  - _Requirements: 4.1,4.2,4.3_
- [ ] 5.4 QuickAddUI
  - 最小入力画面、未保存警告、円形UI組込み、保存トリガーを実装
  - _Requirements: 1.1,1.4,4.1,4.2,7.4_

- [ ] 6. テストと検証
- [ ] 6.1 Unit: ReminderScheduler/Triggers
  - absolute/relative/bucket計算、繰越規則、exact許可有無分岐をテスト
  - _Requirements: 3.1,3.2,3.3,3.4_
- [ ] 6.2 Unit: PresetService / NoteService
  - プリセット保存/更新/適用とバリデーション、タイトル必須とカラー保持をテスト
  - _Requirements: 1.2,2.3,5.1,5.2,5.3,5.4_
- [ ] 6.3 Integration: QuickAddController + EntryDispatcher
  - 起動経路別初期化、保存〜スケジュール連携、Snooze/手動再設定フローを検証
  - _Requirements: 1.*,2.*,3.*,4.4,6.*,7.4_
- [ ] 6.4 E2E/UI: ウィジェット/ショートカット → 通知
  - ウィジェット/ショートカット起動からメモ保存、通知表示/タップ復帰を通しで確認
  - _Requirements: 3.*,4.*,6.*,7.1,7.2_
