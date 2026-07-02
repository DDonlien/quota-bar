#!/usr/bin/env node
// Postbuild hook: 通知 IndexNow，Bing/Yandex/Naver 等会秒级来抓首页。
// 跑在 `npm run build` 之后（site/package.json 的 postbuild 字段）。
//
// 工作流：
//   1. build 完之后 site/dist 已生成；indexnow.key 在 site/public/ 里，被静态托管
//   2. 拼接 IndexNow payload（host + key + keyLocation + urlList）
//   3. POST 到 https://api.indexnow.org/indexnow
//   4. 收到 2xx 就当作成功；4xx/5xx 打 warn 但不 fail build（IndexNow 是 best-effort，
//      ping 失败不应阻塞 site 部署；下个 build 还会重试）
//
// 参考：https://www.indexnow.org/

import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SITE_ROOT = resolve(__dirname, ".."); // .../site
const SITE = "https://quotabar.ddonlien.com";

async function main() {
  const keyPath = resolve(SITE_ROOT, "public/indexnow.key");
  if (!existsSync(keyPath)) {
    console.warn(`[ping-indexnow] ${keyPath} 不存在，跳过`);
    return;
  }
  const key = readFileSync(keyPath, "utf8").trim();
  if (!/^[a-f0-9]{8,128}$/i.test(key)) {
    console.warn(`[ping-indexnow] key 格式异常（${key.slice(0, 8)}…），跳过`);
    return;
  }

  const payload = {
    host: new URL(SITE).host,
    key,
    keyLocation: `${SITE}/indexnow.key`,
    urlList: [`${SITE}/`],
  };

  let res;
  try {
    res = await fetch("https://api.indexnow.org/indexnow", {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=utf-8" },
      body: JSON.stringify(payload),
    });
  } catch (err) {
    console.warn(`[ping-indexnow] 网络错误：${err.message}（best-effort，不阻塞 build）`);
    return;
  }

  // IndexNow 状态码：
  //   200 OK               — 已被处理（已提交 / 已缓存命中 / 已存在）
  //   202 Accepted         — 提交入队等待处理
  //   400 Bad Request      — keyLocation 取不到 / url 不属于 host / key 格式错
  //   403 Forbidden        — key 与 keyLocation 不一致
  //   422 Unprocessable    — urlList 为空 / url 语法错
  //   429 Too Many Requests — 速率限制（通常不会遇到，本项目只有 1 个 URL）
  if (res.ok) {
    console.log(`[ping-indexnow] ✓ ${res.status} ${res.statusText}  → ${payload.urlList[0]}`);
  } else {
    const body = await res.text().catch(() => "");
    console.warn(
      `[ping-indexnow] ✗ ${res.status} ${res.statusText}\n  url=${payload.urlList[0]}\n  body=${body.slice(0, 200)}`,
    );
  }
}

main();
