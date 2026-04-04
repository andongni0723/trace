## v1.3.2
更新內容:
- 修正個人資料庫中人物標記功能在人物數量較多時無法完整顯示所有人物的問題。
- 新增屬性多選功能，讓部分欄位可同時選擇多個值。
- 新增 app 側邊欄並更新首頁介面，提升導覽與操作體驗。
- 新增物件型別屬性的子屬性可加入屬性庫，並可重複套用到其他人物。
- 在更新前記得備份資料，降低資料遺失風險.

Updates:
- Fixed a bug where people tagging in the personal database did not show the full people list when too many people were available.
- Added multi-select support for properties so applicable fields can store multiple selected values.
- Added an app side drawer and refreshed the home screen UI for clearer navigation and quicker access to key actions.
- Added support for saving sub-properties from object-type properties into the property library so they can be reused across other people.
- Remember to back up your data before updating to reduce the risk of data loss.

## v1.2.0
更新內容:
- 更新資料庫結構，擴充個人資料庫相關資料表與欄位結構，支援更完整的人物資料管理。
- 新增個人資料庫人物標記功能，支援在個人資料欄位中標記與引用人物。
- 新增 app 開場動畫，在指紋驗證成功後或未啟用指紋辨識時播放圖示與 Trace 字樣的開場動畫。
- 新增主題色種子設定，可在 app 設定中切換多組主題色彩。

Updates:
- Updated the database structure for personal database tables and field models to support richer per-person data management.
- Added user tagging in the personal database so people can be mentioned and referenced inside personal data fields.
- Added an app opening animation that plays the icon and Trace wordmark after successful biometric verification or when biometric lock is disabled.
- Added theme color seed settings so users can switch between multiple theme color palettes in app settings.

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
