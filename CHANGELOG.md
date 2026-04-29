## v1.7.1

更新內容:
- 新增人物備註分頁，可在人物頁直接編輯長文字筆記，並支援插入人物與媒體 token。
- 新增 person notes 資料表、DAO、provider 與路由參數，備註會隨人物刪除並可透過 `tab=note` 直接開啟。
- 新增 app 設定，可控制 personal database 與屬性管理頁的初始 property 展開或收合狀態。
- 更新備份格式至 v8，匯出與匯入可保留人物備註、主題色、開場動畫與初始 property 展開設定。
- 補強資料庫、備份、設定與人物頁測試，涵蓋備註儲存、token 操作、備份還原與初始展開行為。

Updates:
- Added a person note tab for editing long-form notes on each person page, with person and media tokens.
- Added the person notes table, DAO, provider, and route parameter support so notes cascade with deleted people and can open directly through `tab=note`.
- Added an app setting for the initial expanded or collapsed state of personal database and property manager rows.
- Updated the backup format to v8 so exports and imports preserve person notes, theme seed, opening animation, and initial property expansion settings.
- Added database, backup, settings, and person page coverage for note persistence, token behavior, backup restore, and initial expansion behavior.

## v1.6.0

更新內容:
- 擴充 personal database 的清單欄位，新增元素型別與元素模板設定，支援根層與巢狀陣列直接從既有模板新增物件元素。
- 新增元素模板編輯頁與型別標籤 UI，並在屬性管理、人物資料庫編輯與屬性選擇流程中顯示陣列元素型別與相關操作。
- 更新 personal database schema、DAO、provider 與備份版本，讓陣列元素型別與模板可正確儲存、讀取、匯出與匯入。
- 補強資料庫、provider 與 widget/page 測試，涵蓋陣列元素 metadata、模板新增、模板編輯與未指定元素型別不被誤寫的情境。

Updates:
- Expanded personal database list fields with element type and element template support, including adding object elements from saved templates at both root and nested array levels.
- Added an element template editor page and array element type tags, and surfaced the new list metadata across property management, person database editing, and property chooser flows.
- Updated the personal database schema, DAO, providers, and backup version so array element type/template metadata is persisted and restored correctly through storage and backup flows.
- Added database, provider, page, and widget coverage for array metadata, template-based insertion, template editing, and preserving the unspecified element type during no-op saves.

## v1.5.0

更新內容:
- 新增媒體資料管理頁，可從側邊欄進入，支援搜尋、匯入圖片/影片/音訊、重新命名與開啟媒體檔案。
- 新增媒體資料庫資料表、DAO、Riverpod provider 與檔案儲存/挑選/縮圖/開啟服務，並補上 Android / iOS 檔案分享與安全存取設定。
- 擴充 personal database，新增媒體欄位型別，可從既有媒體庫選擇或直接從裝置匯入媒體作為人物資料。
- 改善資料匯入匯出流程，讓備份可保留媒體資料、媒體欄位與相關 app/生物辨識設定。
- 更新待辦與人物資料庫 schema、關聯查詢與 generated database code，支援媒體資產與更完整的任務/人物資料關聯。
- 補強媒體庫、個人資料庫媒體欄位、資料匯入匯出、生物辨識設定與資料庫層測試。

Updates:
- Added a media library page in the navigation drawer with search, image/video/audio import, rename, and open actions.
- Added media database tables, DAO, Riverpod providers, and file storage/picker/thumbnail/opening services, including Android and iOS file access configuration.
- Expanded the personal database with a media field type that can reference existing library items or import media directly from the device.
- Improved backup import/export so media assets, media field values, and related app/biometric settings are preserved.
- Updated todo and people database schemas, relationship queries, and generated database code to support media assets and richer task/person data links.
- Added coverage for the media library, personal database media fields, data import/export, biometric settings, and database layer behavior.


## v1.4.0

更新內容:
- 新增管理資料庫屬性頁，可從側邊欄進入，支援建立根屬性與子屬性、搜尋、重新命名、變更類型、刪除與拖曳排序。
- 擴充 personal database 屬性管理邏輯，加入欄位定義建立與移動能力，並阻擋仍被人物使用的屬性刪除、移到自己的子層級，或跨可見性範圍移動。
- 調整人物 personal database 編輯流程，既有屬性編輯時改為只更新值，並補強物件子屬性顯示、選取與相關測試。
- 新增人物頭像選取與裁切流程，建立或編輯人物時可從相簿挑圖後裁成圓形頭像，並補上 Android / iOS 所需設定。
- 擴充 app 設定，新增更多主題色與開場動畫開關，並改善生物辨識解鎖後的開場動畫與操作回饋。
- 更新 GitHub Actions 工作流程名稱為 Trace。

Updates:
- Added a database property manager page in the navigation drawer with root and child property creation, search, rename, retype, delete, and drag reordering.
- Expanded personal database property management with definition creation and move logic, while blocking deletes for assigned properties, moves into descendants, and cross-scope moves.
- Updated personal database editing so existing properties only change their value during edit flows, and strengthened object subproperty visibility, selection flows, and related tests.
- Added avatar picking and circular cropping for people creation and editing, along with the required Android and iOS configuration.
- Expanded app settings with more theme seeds and an opening animation toggle, and refined post-biometric opening animation and interaction feedback.
- Renamed the GitHub Actions workflow labels to Trace.

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
