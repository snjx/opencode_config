# opencode_lmstudio

LM Studio のモデル一覧を取得して opencode の設定を更新するコマンドラインツール。

## インストール

### GitHub から直接インストール

```bash
gem install specific_install
gem specific_install https://github.com/snjx/opencode_lmstudio
```

### または clone してインストール

```bash
git clone https://github.com/snjx/opencode_lmstudio
cd opencode_lmstudio
gem build opencode_lmstudio.gemspec
gem install opencode_lmstudio-*.gem
```

## 使い方

```bash
# モデル一覧を取得して opencode.jsonc を更新する
opencode-lmstudio

# デフォルトモデルを指定して更新
opencode-lmstudio --model qwen/qwen3-coder-30b

# ホスト・ポートを指定
opencode-lmstudio --host 192.168.1.100 --port 1234
```

実行後に opencode を起動して `/models` コマンドで取得したモデル一覧から選択できます。

## 環境変数

| 変数名 | デフォルト | 説明 |
|--------|-----------|------|
| `LMSTUDIO_HOST` | `192.168.10.2` | LM Studio のホスト名/IP |
| `LMSTUDIO_PORT` | `1234` | LM Studio のポート番号 |
| `OPENCODE_CONFIG` | `~/.config/opencode/opencode.jsonc` | opencode 設定ファイルのパス |

## オプション

```
-H, --host HOST      LM Studio ホスト
-p, --port PORT      LM Studio ポート
-c, --config PATH    opencode.jsonc のパス
-m, --model MODEL    デフォルトモデルを指定
-v, --version        バージョン表示
-h, --help           ヘルプ表示
```
