// Worldthread 狀態健檢工具：遞迴掃描目錄下的 .json/.jsonl，逐檔回報是否可解析。
// 零依賴：僅使用 Node 內建 node:fs / node:path。相容 Node 18+。
// 與 tools/healthcheck.py 共用同一份輸出契約：同一目錄樹兩支工具的輸出逐位元一致，
// 可互為對照組（契約由 tools/healthcheck.fixtures.jsonl 鎖定）。僅讀取、不修改任何檔案。
// 契約範圍：目標樹為一般檔案與目錄；符號連結一律略過、無法讀取的項目略過而非中止
// （game/state 正常情況下不含符號連結，兩支工具在此範圍內逐位元一致）。
import { readFileSync, statSync, lstatSync, readdirSync } from 'node:fs';
import { join, relative, basename, resolve, sep } from 'node:path';

const HELP = `用法：node healthcheck.mjs [路徑]

  遞迴掃描 [路徑]（省略時預設 game/state）下所有 .json 與 .jsonl 檔，
  逐檔輸出一行 JSON 回報是否可解析，末行輸出彙總；路徑亦可為單一檔案。
  同時檢查玩家可見檔是否夾帶導演私有檔的識別字串（見下）。
  任何檔案未通過時結束碼為 1，全部通過為 0。

輸出每行：{"file":<相對路徑>,"kind":"json"|"jsonl","ok":<布林>,"line":<行號|null>,"leak":<字串|null>}
  line 僅 .jsonl 解析失敗時給出第一個壞行的 1-based 行號，其餘為 null。
  leak 為命中的私有識別字串，未命中為 null。
末行：{"summary":{"scanned":N,"ok":N,"failed":N}}

私有識別字串檢查：
  依 DATA-SCHEMA〈主持人操作日誌〉，game/private/director/ 底下任何檔案的存在、
  檔名與紀錄 id 都不得出現在玩家可見輸出。逐檔判定：位於 game/private/ 或 tools/
  之內的檔案略過本檢查（私有檔本來就會提及自己；夾具檔以 marker 字面為測試資料）。

選項：
  --help  顯示本說明並結束。

本工具僅讀取、不修改任何檔案；它是輔助自查、非寫入驗證的替代（見 PLAYBOOK〈每回合〉第 5 步）。
`;

// 導演私有檔的識別字串：出現在玩家可見檔即違反公私分層（DATA-SCHEMA〈主持人操作日誌〉）。
const PRIVATE_MARKERS = ['host-log', 'hlog-', 'campaign-arc', 'hook-market', 'fronts/', 'private/director'];

// 這些位置提及私有檔名屬正常，不套用上述檢查：
// game/private/ 內的私有檔本來就會提及自己；tools/ 內的夾具檔以 marker 字面為測試資料。
function leakExempt(absPath, sepChar) {
  const norm = `/${resolve(absPath).split(sepChar).join('/')}/`;
  return norm.includes('/game/private/') || norm.includes('/tools/');
}

function fail(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}

// 遞迴收集 .json/.jsonl，回傳 {abs, rel} 陣列，依 rel（相對於 root 的正斜線路徑）排序。
// 符號連結一律略過，無法讀取的目錄／項目略過（與 healthcheck.py 行為對齊）。
function collect(root) {
  const files = [];
  const walk = (dir) => {
    let names;
    try {
      names = readdirSync(dir).sort();
    } catch {
      return;
    }
    for (const name of names) {
      const full = join(dir, name);
      let st;
      try {
        st = lstatSync(full);
      } catch {
        continue;
      }
      if (st.isSymbolicLink()) continue;
      if (st.isDirectory()) walk(full);
      else if (/\.(?:json|jsonl)$/u.test(name)) files.push(full);
    }
  };
  walk(root);
  return files
    .map((abs) => ({ abs, rel: relative(root, abs).split(sep).join('/') }))
    .sort((a, b) => (a.rel < b.rel ? -1 : a.rel > b.rel ? 1 : 0));
}

// 檢查單一檔案，回傳 {kind, ok, line, leak}。
// checkLeak 為 false 時（該檔位於 game/private/ 或 tools/ 內）略過私有字串檢查。
function check(absPath, checkLeak) {
  const kind = absPath.endsWith('.jsonl') ? 'jsonl' : 'json';
  let text;
  try {
    text = readFileSync(absPath, 'utf8');
  } catch {
    return { kind, ok: false, line: null, leak: null };
  }
  const leak = checkLeak ? (PRIVATE_MARKERS.find((m) => text.includes(m)) ?? null) : null;
  if (kind === 'jsonl') {
    const lines = text.split(/\r?\n/u);
    for (let i = 0; i < lines.length; i += 1) {
      if (lines[i].trim() === '') continue;
      try {
        JSON.parse(lines[i]);
      } catch {
        return { kind, ok: false, line: i + 1, leak };
      }
    }
    return { kind, ok: leak === null, line: null, leak };
  }
  try {
    JSON.parse(text);
    return { kind, ok: leak === null, line: null, leak };
  } catch {
    return { kind, ok: false, line: null, leak };
  }
}

function main() {
  const argv = process.argv.slice(2);
  if (argv.includes('--help') || argv.includes('-h')) {
    process.stdout.write(HELP);
    return;
  }
  for (const a of argv) {
    if (a.startsWith('-')) fail(`錯誤：未知參數：${a}`);
  }
  if (argv.length > 1) fail('錯誤：只能提供一個路徑。');
  const target = argv.length === 1 ? argv[0] : 'game/state';

  let st;
  try {
    st = statSync(target);
  } catch {
    fail(`錯誤：路徑不存在：${target}`);
    return;
  }

  const entries = st.isDirectory() ? collect(target) : [{ abs: target, rel: basename(target) }];

  let ok = 0;
  let failed = 0;
  const out = [];
  for (const e of entries) {
    // 逐檔判定豁免：祖先目錄掃描時，私有檔與夾具檔仍各自豁免。
    const r = check(e.abs, !leakExempt(e.abs, sep));
    if (r.ok) ok += 1;
    else failed += 1;
    out.push(JSON.stringify({ file: e.rel, kind: r.kind, ok: r.ok, line: r.line, leak: r.leak }));
  }
  out.push(JSON.stringify({ summary: { scanned: entries.length, ok, failed } }));
  process.stdout.write(`${out.join('\n')}\n`);
  process.exit(failed > 0 ? 1 : 0);
}

main();
