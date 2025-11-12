# oqtopus-pulse-config

## Git pull を自動化する

リポジトリ直下の `scripts/git-auto-pull.sh` を cron から呼び出すことで、定期的に `git pull --ff-only` を実行し、結果を `logs/git-auto-pull.log` に追記できます。ローカル変更がある場合は上書きを避けるために処理をスキップします。

### 手動実行

```bash
./scripts/git-auto-pull.sh
```

必要に応じて環境変数で動作を上書きできます。

```bash
REPO_DIR=/path/to/repo BRANCH=main LOG_DIR=/path/to/logs ./scripts/git-auto-pull.sh
```

### cron の設定手順

1. `crontab -e` でユーザーの cron を開く
2. 下記のようなエントリを追記して保存

```
*/2 * * * * /usr/bin/env bash /path/to/scripts/git-auto-pull.sh
```

cron を再起動する必要はありません。頻度は左端の `*/30` を変更して調整します。たとえば 2 分おきに更新したい場合は `*/2 * * * *` としてください。ジョブが動いているかは `logs/git-auto-pull.log` を確認してください。

### Slack 通知

失敗時に Slack Webhook へ通知したい場合は、`SLACK_WEBHOOK_URL` を環境変数として渡してください。cron での設定例:

Webook URL は平文で保存されるため必要に応じて `crontab` のパーミッション管理や専用ユーザーを検討してください。通知本文にはホスト名・ブランチ・ログファイルの場所が含まれます。頻度やブランチを変えたい場合は `BRANCH` などの環境変数も同様に渡せます。

通知を特定のチャンネルや bot 名で出したい場合は `SLACK_CHANNEL`（例: `#infra-alerts`）や `SLACK_USERNAME`（例: `git-auto-pull-bot`）も設定できます。Incoming Webhook 側で上書き可能な場合のみ有効です。

### .env での設定

リポジトリ直下に `.env` を置くと、スクリプト実行時に自動で読み込まれます。例:

```
BRANCH=main
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
SLACK_CHANNEL=#infra-alerts
SLACK_USERNAME=git-auto-pull-bot
LOG_DIR=/var/log/git-auto-pull
```

`.env` を別の場所に置きたい場合は `ENV_FILE=/path/to/.env ./scripts/git-auto-pull.sh` のようにパスを指定してください。cron から呼び出す場合も同様に `ENV_FILE` を指定すれば OK です。`.env` 内の値は環境変数やデフォルト値よりも優先されます。
