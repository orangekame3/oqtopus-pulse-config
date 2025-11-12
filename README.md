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

## oqtopus_sse_pulse のライブラリを使う

`oqtopus_sse_pulse` ディレクトリは [oqtopus-sse-pulse](https://github.com/orangekame3/oqtopus-sse-pulse) リポジトリをサブモジュールとして取り込んでおり、実験で共有する `libs` が `oqtopus_sse_pulse/src/oqtopus_sse_pulse/libs` 配下に含まれます。

クローン直後に以下を実行してサブモジュールを取得してください。

```shell
git submodule update --init --recursive
```

サブモジュールを upstream の最新に追従させたい場合は、`oqtopus_sse_pulse` 配下で通常の `git pull` を行い、その結果をこのリポジトリにコミット・プッシュしてください。

## 自動更新(管理者用)

```shell
*/2 * * * * /usr/bin/env bash /path/to/scripts/git-auto-pull.sh
```

スクリプトは `git pull` 後にサブモジュールも自動で `git submodule update --init --recursive` するため、`oqtopus_sse_pulse` も定期的に同期されます。
さらに、サブモジュールの各ブランチ(`.gitmodules` で `branch` 指定)に対して `git pull --ff-only origin <branch>` を実行するため、上流で更新された `oqtopus-sse-pulse` も自動で最新化されます（必要ならこのリポジトリでサブモジュールのコミットを更新して `git push` してください）。

### .env での設定

リポジトリ直下に `.env` を置くと、スクリプト実行時に自動で読み込まれます。例:

```shell
BRANCH=main
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
SLACK_CHANNEL=#infra-alerts
SLACK_USERNAME=git-auto-pull-bot
LOG_DIR=/var/log/git-auto-pull
```
