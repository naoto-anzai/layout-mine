# layout-mine

herdr-app の個人 layout。同梱 `main`(0.1.13)のコピーで、次を変えている。

- 左サイドバーの spaces を `spaces-tree` に差し替え
- 右下に `machine-login`、左下に `mods-watcher` を floating で常駐
- 右パネル(`panel-body` の stack)に `files` / `changes` / `github` を並べる

## 必要な Mod
この layout は次の Mod を参照する。無いと該当ブロックが空になる(いずれも `~/.config/herdr-app/mods/<名前>` に置く)。
`spaces-tree` / `machine-login` / `mods-watcher` / `github`(同梱の `workspace-chrome` `tabs` `agents` `pane` `files` `changes` `workspace-status` も使う)

## 導入

    ln -s <このリポジトリ>/mine.json ~/.config/herdr-app/layouts/mine.json

その後 `layout.switch {name: "mine"}`(`ctrl-shift-l`)で切り替える。
反映されないときは `ln -sfn` で張り直す。

## recipes/mod-dev.sh
Mod 開発用の space を作るレシピ。左に Claude、右にその Mod のペインを開く。

    recipes/mod-dev.sh <ModName> [--dry-run]

`--dry-run` は実行内容だけ表示する。`~/Projects/herdr-mods/<ModName>` に Mod を作り、`~/.config/herdr-app/mods/` へ symlink する。
`~/Projects/herdr-mods/` 以下に Mod のリポジトリを並べる構成と、`herdr-app` の入った環境を前提にしている。
