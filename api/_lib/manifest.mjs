// v0.15.0：安装包迁到 Vercel Blob 之后，"当前最新版是什么"的唯一事实来源是
// Blob 上的 releases/latest.json（由 .github/workflows/release.yml 在打包后写入，
// 见 scripts/upload-release.mjs）。
//
// 这一层把"读 manifest"和"降级回 GitHub"封在一起：迁移期间（token 还没配、
// 或者最后一次发布还是旧流程）Blob 上可能压根没有 manifest，这时仍然要能回答
// 客户端的更新查询，否则用户会看到"暂时无法检查更新"。

import { fetchReleases, pickLatestDmgRelease } from "./releases.mjs";

const REPO = "DDonlien/quota-bar";
/// Blob 的公开读地址。store id 由 Vercel 分配，通过环境变量注入，避免硬编码。
const BLOB_BASE_URL = process.env.BLOB_PUBLIC_BASE_URL || "";

/**
 * 读 Blob 上的 latest.json。没配 base url、404、或内容不合法时返回 null，
 * 让调用方走 GitHub 降级——这里不抛异常，因为"还没迁移完"是预期状态而不是故障。
 */
export async function fetchBlobManifest() {
  if (!BLOB_BASE_URL) return null;
  try {
    const url = `${BLOB_BASE_URL.replace(/\/$/, "")}/releases/latest.json`;
    const response = await fetch(url, { headers: { "User-Agent": "QuotaBar-Vercel" } });
    if (!response.ok) return null;
    const manifest = await response.json();
    if (!manifest?.tag || !manifest?.dmgUrl) return null;
    return manifest;
  } catch {
    return null;
  }
}

/**
 * 把 manifest 合成成 **GitHub Releases API 的数组形状**。
 *
 * 这么做不是为了好看，是为了不破坏已经装在用户机器上的客户端：它们（以及官网的
 * 下载脚本）解析的是 GitHub 的 release 结构，只要这个 endpoint 继续输出同一个
 * 形状，迁移对它们就是完全透明的，不需要为新老两套格式各维护一份 parser。
 *
 * `browser_download_url` 指向本站的 /api/download-latest 而不是 Blob 直链：
 * 保持下载流量走自有域名，这正是 v0.14.0 加这条兜底链路的初衷（大陆可达性）。
 */
export function manifestAsReleaseArray(manifest, origin) {
  const downloadUrl = `${origin.replace(/\/$/, "")}/api/download-latest`;
  return [
    {
      tag_name: manifest.tag,
      html_url: `https://github.com/${REPO}/releases/tag/${manifest.tag}`,
      body: manifest.notes || "",
      draft: false,
      prerelease: false,
      published_at: manifest.publishedAt || new Date().toISOString(),
      assets: [
        {
          name: manifest.dmgName || `QuotaBar-${manifest.tag}.dmg`,
          browser_download_url: downloadUrl,
          size: manifest.size ?? 0,
        },
      ],
    },
  ];
}

/** 降级路径：Blob 上还没有 manifest 时，回到原来的"现查 GitHub release"。 */
export async function fetchGitHubFallback() {
  const releases = await fetchReleases();
  return { releases, best: pickLatestDmgRelease(releases) };
}
