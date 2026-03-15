# コード解説

## ファイル構成

```
bin/opencode-lmstudio          # 実行ファイル（入口）
lib/
  opencode_lmstudio.rb         # require をまとめるだけ
  opencode_lmstudio/
    version.rb                 # バージョン定数
    cli.rb                     # 引数・環境変数の解釈、全体の制御
    client.rb                  # LM Studio HTTP クライアント
    config.rb                  # opencode.jsonc の読み書き
test/
  test_cli.rb
  test_client.rb
  test_config.rb
```

---

## 各ファイルの役割

### `bin/opencode-lmstudio`

コマンド実行時の入口。`lib/` をロードパスに追加して `CLI` に `ARGV` を渡して起動するだけ。

```ruby
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "opencode_lmstudio"
OpencodeLmstudio::CLI.new(ARGV).run
```

---

### `cli.rb` — 司令塔

引数・環境変数を解釈して `Client` と `Config` を繋ぐ。

**設定値の優先順位**

```
コマンドライン引数 > 環境変数 > デフォルト値
```

| 設定 | オプション | 環境変数 | デフォルト |
|------|-----------|---------|-----------|
| ホスト | `-H` / `--host` | `LMSTUDIO_HOST` | `192.168.10.2` |
| ポート | `-p` / `--port` | `LMSTUDIO_PORT` | `1234` |
| 設定ファイル | `-c` / `--config` | `OPENCODE_CONFIG` | `~/.config/opencode/opencode.jsonc` |
| デフォルトモデル | `-m` / `--model` | なし | 既存設定 or 一覧の先頭 |

**`run` の流れ**

```ruby
model_ids = client.fetch_models          # API からモデル一覧取得
default_model = config.update_models(...)  # 設定ファイルに書き込み
puts "Updated #{config.path}"            # 結果を表示
```

---

### `client.rb` — HTTP クライアント

`GET /v1/models` を叩いてモデル ID の配列を返す。

```
GET http://<host>:<port>/v1/models

レスポンス:
{
  "data": [
    { "id": "model-a", ... },
    { "id": "model-b", ... }
  ]
}

↓ data[].id だけ取り出して返す

["model-a", "model-b"]
```

接続系の例外 (`ECONNREFUSED`, `EHOSTUNREACH`, `SocketError`) はまとめてユーザー向けのメッセージに変換して再 raise する。

---

### `config.rb` — 設定ファイルの読み書き

`opencode.jsonc` を読んで更新して書き戻す。外部から使うメソッドは `update_models` と `path` だけ。`read` / `write` は `private`。

**JSONC コメント除去**

`opencode.jsonc` は JSON with Comments 形式のため、パース前にコメントを除去する。

```
/* ブロックコメント */  → 正規表現で一括除去
// 行コメント          → 1文字ずつ走査して除去
"http://example.com"   → // が文字列内なので保持
```

文字列内の `//` を誤って除去しないよう、`in_string` フラグで文字列の内外を追跡している。

**`update_models` のデフォルトモデル決定順**

```
--model 引数で指定 > 既存の設定ファイルの値 > モデル一覧の先頭
```

---

## データフローの全体像

```
ARGV / 環境変数
      ↓
    CLI
   ↙    ↘
Client   Config
  ↓
GET http://<host>:<port>/v1/models
  ↓
["model-a", "model-b", ...]
              ↓
       opencode.jsonc に書き込む

{
  "model": "model-a",
  "provider": {
    "lmstudio": {
      "models": {
        "model-a": { "name": "model-a" },   ← opencode の /models に出る
        "model-b": { "name": "model-b" }
      },
      "options": {
        "baseURL": "http://host:port/v1"
      }
    }
  }
}
```

---

## 依存ライブラリ

外部 gem への依存はなく、すべて Ruby 標準ライブラリのみ使用。

| ライブラリ | 用途 |
|-----------|------|
| `net/http` | HTTP リクエスト |
| `json` | JSON パース・生成 |
| `uri` | URL のパース |
| `optparse` | コマンドライン引数のパース |
| `fileutils` | ディレクトリ作成 |
| `minitest` | テスト（開発時のみ） |
