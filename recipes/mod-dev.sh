#!/usr/bin/env bash
# mod-dev レシピ: Mod 開発用の space を作る。左に Claude、右にその Mod のペイン。
# 使い方: mod-dev.sh <ModName> [--dry-run]
# 無ければ ~/Projects/herdr-mods/<ModName> を作り (git init, mod.json, main.js)、
# ~/.config/herdr-app/mods/<ModName> へ symlink し、space を作る。
set -euo pipefail
NAME="${1:?usage: mod-dev.sh <ModName> [--dry-run]}"
DRY="${2:-}"
DIR="$HOME/Projects/herdr-mods/$NAME"
LINK="$HOME/.config/herdr-app/mods/$NAME"
TASK="$NAME の Mod 開発セッションです。~/.config/herdr-app/AGENTS.md と herdr.d.ts を読み、main.js から進めてください。変更後は herdr-app check と herdr-app shot で確認し、挙動が変わる操作は実行前に報告してください。同梱 Mod は編集せず mod.clone で複製してください。画面を持つ Mod は storybook.json と main.js 内のモックを持ち、状態(描画を変える入力)が変わったら同時に更新してください(契約: ~/Projects/herdr-mods/ModsStoryBook/STORYBOOK.md)。"
run() { if [ "$DRY" = "--dry-run" ]; then echo "+ $*"; else "$@"; fi; }

if [ ! -d "$DIR" ]; then
  run mkdir -p "$DIR"
  if [ "$DRY" != "--dry-run" ]; then
    git -C "$DIR" init -q
    echo '{ "place": "none" }' > "$DIR/mod.json"
    cat > "$DIR/main.js" <<'JS'
import { View, div } from "gpui-kit";
import { theme, shared, props } from "herdr";

// モック中(Story が開いたプレビュー)は選択値、本番なら null (STORYBOOK.md §3 の正本)。
// mock は別ファイルにせずこの main.js に置く(mods-watcher のファイル単位 symlink では ./mock.js が check で弾かれる)。
export function storybook(mod) {
  const id = props()?.storybook;
  return id ? (shared(`storybook:${mod}:${id}`)?.values ?? {}) : null;
}

// 状態ごとのモックデータ。本番データ関数と副作用のある呼び出しは、モック中は使わない。
const MOCK = {};

export default class extends View {
  render(_cx) {
    return div().size_full().bg(theme().surface).p(10).child("hello");
  }
}
JS
    # Story 用の雛形(契約: ModsStoryBook/STORYBOOK.md)。状態が増えたら storybook.json と main.js 内のモックを同時に直す。
    cat > "$DIR/storybook.json" <<'JSON'
{
  "version": 1,
  "props": {},
  "states": [
    { "key": "compact", "label": "コンパクト表示", "kind": "switch", "default": false }
  ]
}
JSON
    # この Mod のセッションだけに storybook-sync hook を登録(ユーザー設定は触らない。コミットもしない)
    mkdir -p "$DIR/.claude"
    cat > "$DIR/.claude/settings.local.json" <<'JSON'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "f=\"$HOME/Projects/herdr-mods/hooks/storybook-sync.py\"; [ -x \"$f\" ] && \"$f\" || true",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
JSON
    printf 'gpui-kit.d.ts\njsconfig.json\nnode_modules/\n.claude/settings.local.json\n' > "$DIR/.gitignore"
  else echo "+ (新規作成) $DIR: git init, mod.json, main.js(helper+MOCK 入り), storybook.json, .claude/settings.local.json"; fi
fi
[ -e "$LINK" ] || run ln -s "$DIR" "$LINK"
[ "$DRY" = "--dry-run" ] || herdr-app check "$LINK"

if [ "$DRY" = "--dry-run" ]; then
  echo "+ herdr-app do space.new --name $NAME --folder $DIR --argv '[\"claude\"]' --task ..."
  echo "+ herdr-app do pane.split --pane <claude pane> --direction right --mod $NAME"
  exit 0
fi
SPACE=$(herdr-app do space.new --name "$NAME" --folder "$DIR" --argv '["claude"]' --task "$TASK" | python3 -c 'import sys,json;print(json.load(sys.stdin)["space"])')
sleep 2
PANE=$(herdr-app ls | python3 -c '
import sys,json
t=sys.stdin.read(); d,_=json.JSONDecoder().raw_decode(t[t.index("{"):])
s=[x for x in d["spaces"] if x["id"]==sys.argv[1]][0]
print(s["tabs"][0]["terminals"][0]["pane"])' "$SPACE")
herdr-app do pane.split --pane "$PANE" --direction right --mod "$NAME"
