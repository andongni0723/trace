## v1.2.0
更新內容:
- 更新 database structure，擴充 personal database 相關資料表與欄位結構，支援更完整的人物資料管理。
- 新增 app opening animation，在指紋驗證成功後或未啟用指紋辨識時播放 icon 與 Trace 字樣的開場動畫。
- 新增 theme color seed 設定，可在 app 設定中切換多組主題色彩。

Updates:
- Updated the database structure to support richer personal database tables and field relationships.
- Added an app opening animation that plays after successful biometric verification or when biometric lock is disabled.
- Added theme color seed settings so users can switch between multiple app accent palettes.

## v1.1.0
更新內容:
- 新增 personal database，可為每個人物建立結構化資料欄位，支援新增、編輯、刪除與巢狀資料管理。
- 新增指紋辨識功能，支援 app 重新開啟後驗證，以及 15 分鐘、30 分鐘或下次開啟時再次驗證的設定。
- 新增 person avatar 設定，建立與編輯人物時可選擇、更換或移除頭像圖片。
- 新增資料庫摘要頁，方便快速查看人物與待辦資料統計。
- 改善資料匯入與匯出，現在可保留 personal database、avatar 與 app 設定。
- 改善 bottom sheet 與鍵盤同時出現時的動畫流暢度，減少輸入表單開啟時的卡頓。

Updates:
- Added personal database support with structured fields, nested data editing, and per-person context storage.
- Added biometric authentication with configurable re-auth intervals after reopening the app.
- Added person avatar support for creating, updating, and removing profile images.
- Added a database summary page for quickly reviewing local people and todo statistics.
- Improved backup import/export to preserve personal database data, avatars, and app settings.
- Improved bottom sheet and keyboard transition smoothness when opening input forms.
