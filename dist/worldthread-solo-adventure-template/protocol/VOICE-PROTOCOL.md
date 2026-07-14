# 語音輸入協定

語音轉寫記錄採 `{speaker, transcript, confidence, uncertain_spans, mode}`；`mode` 為 `in_character`、`out_of_character` 或 `command`。低信心、專有名詞、會改變風險或界線的內容，先以自然語言確認。玩家說「更正」時，若尚未結算，替換該輸入；已結算則追加 correction 事件。

原始音檔預設不保存。若玩家明確要求保存，只能置於私有、未追蹤位置，且不可放入發行包。TTS 可朗讀主持人的公開敘事，不能朗讀 director 資料。
