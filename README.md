# PLS 單條聚合線簡化

![PLS](assets/banner.svg)

[工具儲存庫](https://github.com/whos-dwg/CadLISP-PLS) · [全部工具索引](https://github.com/whos-dwg/CadLISP-Index)

對一條開放且無弧段的 LWPOLYLINE 移除近點並以 RDP 簡化頂點。

| 項目 | 內容 |
| --- | --- |
| 指令 | `PLS` |
| 檔案 | [PLS.lsp](lsp/PLS.lsp) |
| 分類 | 幾何處理 |
| 狀態 | 來源快照，實機回歸待完成 |
| 授權 | [MIT](LICENSE)，Copyright (c) 2026 whos-dwg |

[安裝](#安裝) · [操作](#操作) · [相依與設定](#相依與設定) · [已知問題](docs/KNOWN_ISSUES.md) · [驗證紀錄](docs/VALIDATION.md)

## 安裝

以 Windows 桌面版 AutoCAD 為目標。原碼使用的 Visual LISP／ActiveX、DCL 或原生命令，需在目標 AutoCAD 版本分別確認；尚未做整包年份、LT、Mac 或其他 CAD 的相容性認證。ActiveX 的平台限制見 [Autodesk](https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-AutoLISP/files/GUID-A0459510-CE7A-4206-9EAA-E25AAB569B20.htm)。

1. 下載並解壓縮本工具到固定位置，先開啟測試圖面。
2. 依公司環境把 `lsp` 資料夾加入需要的支援搜尋路徑與受信任位置。
3. 輸入 `APPLOAD`，載入 `PLS.lsp`；關閉視窗後輸入 `PLS`。

也可使用完整路徑單獨載入；下列路徑需依實際位置修改：

```lisp
(load "C:/CAD/CadLISP-PLS/lsp/PLS.lsp")
```

完成驗證後，可將這支 LISP 加入 APPLOAD 的 Startup Suite。請維持既定的 SECURELOAD 政策，使用受信任位置處理載入限制。[SECURELOAD 說明](https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Core/files/GUID-541566C6-2738-49DD-87C3-C1490E924A02.htm)。

## 操作

1. 輸入 `PLS`，設定最小頂點距離，預設 1。
2. 設定最大線偏差，預設 2，再選取一條 LWPOLYLINE。
3. 檢查前後頂點數及幾何偏差；重建成功後原物件被刪除。

## 相依與設定

只支援開放、無 bulge 弧段的輕量聚合線。實際指令是 PLS。

圖面影響：以新物件取代被簡化的原聚合線。

## 行為與限制

載入訊息與檔頭仍寫 PLS6，但檔案沒有定義 C:PLS6。兩個參數均要求正值；封閉與含弧段聚合線直接跳過。近點移除與 RDP 是兩階段處理，不能把單一參數當成整體誤差保證。

## 來源與授權

本工具依維護者確認為自行從零撰寫，或以 AI 協作從零開發。程式與本次文件採 [MIT 授權](LICENSE)，允許使用、修改與再散布，須保留授權及著作權聲明。詳細來源紀錄見 [provenance.json](metadata/provenance.json)。

## 回報與維護

回報時附 AutoCAD 完整版本、命令列錯誤與去識別的重現範例。修改前請閱讀 [CONTRIBUTING](CONTRIBUTING.md)；發行步驟見 [PUBLISHING](docs/PUBLISHING.md)。本工具可獨立維護、下載及發布，不依賴其他 CadLISP 工具儲存庫。
