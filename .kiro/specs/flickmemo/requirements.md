# 要件ドキュメント

## 導入
FlickMemo（フリックメモ）は、円形UIとフリック操作で通知設定を最短化するカスタマイズ型Androidメモアプリである。メモ入力と通知設定を一連の操作で完結させ、入力負担・思考負担・起動負担を最小化することを目的とする。

## 要件

### Requirement 1: クイックメモ入力
**Objective:** As a 日常的にスマホでメモを取るユーザー, I want to 最小ステップでタイトル中心のメモを記録できる, so that 記録漏れなく後で参照できる

#### Acceptance Criteria
1. When user opens quick add from app entry point, the Flickmemo app shall present a minimal input for タイトル（必須）と本文（任意）を即時編集できる画面を表示する.
2. When user enters text and taps save, the Flickmemo app shall persist the note with timestamp and a default state without 追加設定を要求しない.
3. When user starts voice input, the Flickmemo app shall capture 音声をテキスト化してタイトルまたは本文に反映する.
4. If user attempts to exit the input without saving, the Flickmemo app shall prompt the user to save or discard the current note.

### Requirement 2: 入力方式の選択
**Objective:** As a 入力スタイルを選びたいユーザー, I want to 文字・音声・色分けを状況に応じて使い分けたい, so that 手間なく自分に合った分類ができる

#### Acceptance Criteria
1. When user selects text input mode, the Flickmemo app shall allow keyboard entry for タイトルおよび本文.
2. When user selects voice input mode, the Flickmemo app shall allow マイクからの入力を開始し、変換結果を即時表示する.
3. When user assigns a color to a note, the Flickmemo app shall 保存時にカラー属性を保持し一覧に視覚的区別を反映する.
4. If user switches input mode during editing, the Flickmemo app shall retain existing text and カラー設定を失わずに新しい入力モードを適用する.

### Requirement 3: 通知スケジュール（時刻・相対時間）
**Objective:** As a 通知を確実に受け取りたいユーザー, I want to メモと同時に通知時刻や「何分後」を設定したい, so that 思いついた内容を忘れずに受け取れる

#### Acceptance Criteria
1. When user sets an absolute time for a note, the Flickmemo app shall schedule a notification at その指定時刻.
2. When user sets a relative offset (e.g., 30分後), the Flickmemo app shall calculate the target time and schedule the notification accordingly.
3. If the device state blocks alerts (e.g., Do Not Disturb), the Flickmemo app shall queue the notification and deliver it at the next allowed opportunity.
4. Where the scheduled time has passed while the device was unavailable, the Flickmemo app shall surface the pending notification on the next available runtime without requiring manual relaunch.

### Requirement 4: 円形UIとモード切替（中核）
**Objective:** As a 通知設定を素早く行いたいユーザー, I want to 円形UIで詳細／簡易モードを切り替えて時刻や時間帯を指定したい, so that 正確さと速さを状況に応じて選べる

#### Acceptance Criteria
1. Where detailed mode is active, the Flickmemo app shall present a finely divided circular control that allows 分単位で針を回して時刻を指定する.
2. Where simple mode is active, the Flickmemo app shall present a circular control divided into time buckets (e.g., 朝・昼・夕方・夜) and allow フリック方向で時間帯を指定する.
3. When user switches between detailed and simple mode, the Flickmemo app shall preserve the current note content and apply the selected mode’s granularity for time selection.
4. If user finalizes a time selection via the circular UI, the Flickmemo app shall bind that selection to the note’s notification schedule before save.

### Requirement 5: プリセットとカスタマイズ
**Objective:** As a 繰り返し同じ条件で通知したいユーザー, I want to よく使う通知条件をプリセット化して再利用したい, so that 毎回の設定操作を減らせる

#### Acceptance Criteria
1. When user saves a preset, the Flickmemo app shall store 通知条件（詳細/簡易モード、時刻/時間帯、相対時間）、入力方式、カラー設定を含むプリセットとして保存する.
2. When user applies a preset, the Flickmemo app shall prefill note creation with 保存された通知条件・入力方式・カラーを適用する.
3. If user edits an existing preset, the Flickmemo app shall update the stored parameters and apply them to subsequent uses without duplicating entries.
4. When user selects “詳細/簡易”切替をプリセットに含める, the Flickmemo app shall restore the corresponding circular UI mode on apply.

### Requirement 6: ウィジェット・ショートカットによる即起動
**Objective:** As a 待ち時間を減らしたいユーザー, I want to ホームウィジェットやアイコン長押しから直接メモ作成・通知設定を開始したい, so that 思いついた瞬間に記録できる

#### Acceptance Criteria
1. When user taps the home widget quick-add button, the Flickmemo app shall open a new note input with 通知設定UIを即表示し、アプリ内遷移を要求しない.
2. When user long-presses the app icon and selects a shortcut (e.g., すぐメモ/30分後/時間帯指定), the Flickmemo app shall launch note creation applying the linked preset.
3. If the widget or shortcut is invoked while the app is locked, the Flickmemo app shall respect OS security (e.g., lock screen) and resume the quick-add flow after unlock.
4. While offline, the Flickmemo app shall allow widget/shortcut initiated notes to be created and stored locally with their scheduled notifications queued.

### Requirement 7: 非機能・制約
**Objective:** As a Android専用アプリの利用者, I want to オフラインでもプライバシーを保ったまま動作してほしい, so that 外出先でも安全に使える

#### Acceptance Criteria
1. The Flickmemo app shall operate on Android platforms and store notes/設定データを端末ローカルに保存する.
2. While network connectivity is unavailable, the Flickmemo app shall allow full note creation and scheduling, queueing any notifications or sync operations until connectivity returns.
3. The Flickmemo app shall avoid sending 個人情報やメモ内容を外部に送信しない.
4. When user performs メモ作成と通知設定, the Flickmemo app shall target completion within 10 seconds under 正常な端末状態.
