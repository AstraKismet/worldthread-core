// Worldthread 擲骰工具：解析擲骰公式並以密碼學級亂數擲骰，輸出單行 JSON 供事件紀錄使用。
// 零依賴：僅使用 Node 內建 node:crypto。相容 Node 18+。
import { randomInt, createHash } from 'node:crypto';

const HELP = `用法：node dice.mjs <公式> [--seed <字串>]

公式文法：expr := term (('+'|'-') term)*；term := dice | int
  dice := [N]dM（如 2d6、d20；N 為 1..100 的整數，省略為 1；M 為 2..1000 的整數；d 不分大小寫）
  int  := 0..9999 的整數常數
  減號只能出現在整數常數前；骰組僅支援相加（例：2d6-1d4 不合法）。
  公式內允許任意空白，其餘任何內容一律視為錯誤。

選項：
  --seed <字串>  測試夾具專用：以固定演算法產生決定性亂數結果，並非公平擲骰；
                 輸出會多一個 "seed" 鍵使測試骰可被辨識，時間戳固定為中性佔位值。
  --help         顯示本說明並結束。

信任邊界：本工具以密碼學級亂數擲骰；主持人須逐字引用輸出，改寫數值即可被比對發現。
工具無法防止使用者自行修改結果。
`;

function fail(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}

// 解析公式：先去除空白並轉小寫，再以指標掃描 term/運算子序列。
function parseFormula(raw) {
  const cleaned = raw.replace(/\s+/gu, '').toLowerCase();
  if (cleaned.length === 0) throw new Error('錯誤：公式不得為空。');
  if (cleaned[0] === '+' || cleaned[0] === '-') {
    throw new Error('錯誤：公式開頭不得為運算符號。');
  }

  let i = 0;
  const formatError = () => new Error('錯誤：公式格式錯誤，請使用如 2d6+3 的格式。');
  const assertNoLeadingZero = (digits) => {
    if (digits.length > 1 && digits[0] === '0') throw new Error('錯誤：數字不得有前導零。');
  };
  const readTerm = () => {
    const lead = /^\d*/.exec(cleaned.slice(i))[0];
    if (cleaned[i + lead.length] === 'd') {
      if (lead !== '') assertNoLeadingZero(lead);
      i += lead.length + 1;
      const faces = /^\d+/.exec(cleaned.slice(i));
      if (!faces) throw new Error('錯誤：骰組格式錯誤，需為 [N]d骰面數，例如 2d6。');
      assertNoLeadingZero(faces[0]);
      i += faces[0].length;
      const n = lead === '' ? 1 : Number(lead);
      const m = Number(faces[0]);
      if (!(n >= 1 && n <= 100)) throw new Error('錯誤：骰數（N）需為 1 至 100 的整數。');
      if (!(m >= 2 && m <= 1000)) throw new Error('錯誤：骰面數（M）需為 2 至 1000 的整數。');
      return { type: 'dice', n, m };
    }
    const num = /^\d+/.exec(cleaned.slice(i));
    if (!num) throw formatError();
    assertNoLeadingZero(num[0]);
    i += num[0].length;
    const v = Number(num[0]);
    if (!(v >= 0 && v <= 9999)) throw new Error('錯誤：整數常數需為 0 至 9999。');
    return { type: 'int', value: v };
  };

  const terms = [{ ...readTerm(), sign: 1 }];
  while (i < cleaned.length) {
    const op = cleaned[i];
    if (op !== '+' && op !== '-') throw formatError();
    i += 1;
    const term = readTerm();
    if (op === '-' && term.type === 'dice') {
      throw new Error('錯誤：骰組僅支援相加，減號只能用於整數常數前。');
    }
    terms.push({ ...term, sign: op === '-' ? -1 : 1 });
  }
  return { normalized: cleaned, terms };
}

// 以 SHA-256(seed + ':' + 遞增計數器) 之位元組流做拒絕取樣，避免 modulo bias；僅供測試夾具使用，非公平擲骰。
function seededRoll(seed, counter, max) {
  const limit = Math.floor(65536 / max) * max;
  for (;;) {
    const digest = createHash('sha256').update(`${seed}:${counter.n}`).digest();
    counter.n += 1;
    const v = digest.readUInt16BE(0);
    if (v < limit) return (v % max) + 1;
  }
}

function parseArgs(argv) {
  let formula = null;
  let seed = null;
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (a === '--seed') {
      seed = argv[i + 1];
      if (seed === undefined) fail('錯誤：--seed 需要提供字串值。');
      i += 1;
    } else if (a.startsWith('--')) {
      fail(`錯誤：未知參數：${a}`);
    } else if (formula === null) {
      formula = a;
    } else {
      fail('錯誤：只能提供一個擲骰公式。');
    }
  }
  if (formula === null) fail('錯誤：請提供擲骰公式，例如 2d6+3（可用 --help 查看說明）。');
  return { formula, seed };
}

function main() {
  const argv = process.argv.slice(2);
  if (argv.includes('--help') || argv.includes('-h')) {
    process.stdout.write(HELP);
    return;
  }
  const { formula, seed } = parseArgs(argv);

  let parsed;
  try {
    parsed = parseFormula(formula);
  } catch (e) {
    fail(e.message);
    return;
  }

  const rolls = [];
  let modifier = 0;
  const counter = { n: 0 };
  for (const term of parsed.terms) {
    if (term.type === 'dice') {
      for (let k = 0; k < term.n; k += 1) {
        rolls.push(seed !== null ? seededRoll(seed, counter, term.m) : randomInt(1, term.m + 1));
      }
    } else {
      modifier += term.sign * term.value;
    }
  }
  const result = rolls.reduce((a, b) => a + b, 0) + modifier;

  const output = { formula: parsed.normalized, rolls, modifier, result, source: 'tool' };
  if (seed !== null) output.seed = seed;
  // seed 模式固定時間戳，讓同 seed 同公式的輸出可逐字元比對（黃金行測試）。
  output.rolled_at = seed !== null ? '1970-01-01T00:00:00.000Z' : new Date().toISOString();
  process.stdout.write(`${JSON.stringify(output)}\n`);
}

main();
