// 把构建好的 dmg + 一份 latest.json manifest 上传到 Vercel Blob（v0.15.0）。
//
// 由 .github/workflows/release.yml 在打包完成后调用。上传成功后，
// `api/latest-release.mjs` / `api/download-latest.mjs` 就以 Blob 上的 manifest
// 为准，GitHub Release 只保留 tag 和源码归档。
//
// 用法：node scripts/upload-release.mjs <dmg 路径> <tag> <版本号> <release notes 文件路径>
//
// 需要环境变量 BLOB_READ_WRITE_TOKEN。**没有它时调用方应该跳过这一步**（见
// release.yml 里的条件判断）：这样在 token 配好之前，发布流程仍然沿用旧的
// "dmg 挂 GitHub Release" 路径，不会因为迁移做到一半就把发版打断。

import { readFile, stat } from "node:fs/promises";
import { basename } from "node:path";
import { put } from "@vercel/blob";

const [dmgPath, tag, version, notesPath] = process.argv.slice(2);

if (!dmgPath || !tag || !version) {
  console.error("用法: node scripts/upload-release.mjs <dmg> <tag> <version> [notesFile]");
  process.exit(1);
}
if (!process.env.BLOB_READ_WRITE_TOKEN) {
  console.error("缺少 BLOB_READ_WRITE_TOKEN");
  process.exit(1);
}

const dmgName = basename(dmgPath);
const dmgBuffer = await readFile(dmgPath);
const { size } = await stat(dmgPath);

let notes = "";
if (notesPath) {
  try {
    notes = (await readFile(notesPath, "utf8")).trim();
  } catch {
    // notes 缺失不该让发布失败——客户端对空 notes 有兜底文案。
  }
}

// `addRandomSuffix: false` 让路径可预测；每个版本一个独立文件名（含 sha），
// 所以不会互相覆盖，历史版本也留在 Blob 上可回溯。
const dmgBlob = await put(`releases/${dmgName}`, dmgBuffer, {
  access: "public",
  addRandomSuffix: false,
  contentType: "application/x-apple-diskimage",
  allowOverwrite: true,
});
console.log(`dmg 已上传: ${dmgBlob.url}`);

const manifest = {
  version,
  tag,
  notes,
  dmgName,
  dmgUrl: dmgBlob.url,
  size,
  publishedAt: new Date().toISOString(),
};

// manifest 固定路径且必须覆盖——它就是"当前最新版是什么"的唯一事实来源。
// 短 cache：客户端和 CDN 最多晚一分钟看到新版本，但不至于每次检查都穿透到存储。
const manifestBlob = await put("releases/latest.json", JSON.stringify(manifest, null, 2), {
  access: "public",
  addRandomSuffix: false,
  contentType: "application/json",
  allowOverwrite: true,
  cacheControlMaxAge: 60,
});
console.log(`manifest 已上传: ${manifestBlob.url}`);
console.log(JSON.stringify(manifest, null, 2));
