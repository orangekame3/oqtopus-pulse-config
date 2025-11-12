# oqtopus-pulse-config

## 実験で使うパラメータ設定用のディレクトリ

こちらのリポジトリに個人のパラメータ設定ファイルをおいておくことで実験時に読み込みする事ができます。
こちらのリポジトリのファイルは2分毎に実験室と同期を取っているため、push後最大2分で実験室に反映されます。

## 設定方法

このリポジトリをクローンし、ご自身の名前でディレクトリを作成してください。

```shell
git clone
cd oqtopus-pulse-config
mkdir your_name
```

デフォルトのパラメータ設定ファイルをコピーし、必要に応じて編集してください。

```shell
cp ogawa/params/params.yaml your_name/params/params.yaml
cp ogawa/params/props.yaml your_name/params/props.yaml
```

編集が終わったら、コミットしてプッシュしてください。

```shell
git add your_name/params/params.yaml your_name/params/props.yaml
git commit -m "your_name: Add my parameter settings"
git push origin main
```

各人のパラメータを利用するさいには以下のようにしてしてください。

```python
exp = Experiment(
	chip_id="64Qv3",
	muxes=[9],
	params_dir="/sse/in/repo/miyanaga/params",
	calib_note_path="/sse/in/repo/miyanaga/calib_note.json"
)
```

## 自動更新(管理者用)

```shell
*/2 * * * * /usr/bin/env bash /path/to/scripts/git-auto-pull.sh
```

### .env での設定

リポジトリ直下に `.env` を置くと、スクリプト実行時に自動で読み込まれます。例:

```shell
BRANCH=main
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
SLACK_CHANNEL=#infra-alerts
SLACK_USERNAME=git-auto-pull-bot
LOG_DIR=/var/log/git-auto-pull
```
