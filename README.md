# OBS Auto Away Image

OBS Studioで表示している「離席中」「BRB」などのソースを、指定した時間が経過すると自動で非表示にするLuaスクリプトです。

## Features

- 対象ソースの表示を自動検知
- 指定時間後に自動で非表示
- 手動で非表示にした場合はタイマーを自動リセット
- OBS内のソース一覧から対象を選択可能
- グループ内のソースにも対応

## Installation

1. `AutoAwayImage.lua` をダウンロードします。
2. OBS Studioを起動します。
3. `ツール` → `スクリプト` を開きます。
4. `+` ボタンから `AutoAwayImage.lua` を追加します。

## Settings

### 離席画像のソース

自動で非表示にしたいOBSソースを選択します。

### 自動OFFまでの時間

以下から選択できます。

- 5分
- 10分
- 15分
- 20分
- 30分
- 45分
- 60分

## Usage

1. OBSで対象ソースの目アイコンをONにします。
2. 対象ソースの表示を検知するとタイマーが開始されます。
3. 設定時間が経過すると対象ソースが自動で非表示になります。
4. 途中で手動OFFにした場合はタイマーがリセットされます。

## Requirements

- OBS Studio
- Luaスクリプト対応環境

## Notes

- 同じ名前のソースが複数シーンにある場合、その名前に一致する表示中ソースが対象になります。
- OBSやLua APIの仕様変更により動作しなくなる場合があります。

## License

MIT License

## Disclaimer

This is an unofficial OBS Studio script.

This project is not affiliated with or endorsed by OBS Project.

Use at your own risk.
