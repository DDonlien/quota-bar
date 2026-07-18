// 共享逻辑：给 api/latest-release.mjs 和 api/download-latest.mjs 复用。
// 文件名前缀 `_` 让 Vercel 零配置 /api 路由跳过它，不会被当成独立 endpoint。

const REPO = "DDonlien/quota-bar";
const GITHUB_RELEASES_URL = `https://api.github.com/repos/${REPO}/releases?per_page=30`;

// 与 macOS 客户端 `UpdateReleaseParser.versionTagPattern` 保持一致：
// `vX.Y.Z` 或 `vX.Y.Z-<git-short-sha>`。
const VERSION_TAG_PATTERN = /^v\d+\.\d+\.\d+(-[0-9a-f]{7,40})?$/;

/**
 * 服务端拉取 GitHub Releases 列表，原样返回 GitHub 的 JSON 数组结构——
 * 客户端（macOS UpdateChecker / 官网下载按钮）复用同一套解析逻辑，不需要为这个
 * 兜底源单独维护一份 parser。
 */
export async function fetchReleases() {
  const response = await fetch(GITHUB_RELEASES_URL, {
    headers: {
      Accept: "application/vnd.github+json",
      "User-Agent": "QuotaBar-Vercel-Proxy",
    },
  });
  if (!response.ok) {
    throw new Error(`GitHub releases API returned HTTP ${response.status}`);
  }
  return response.json();
}

function parseSemver(tag) {
  let raw = tag.startsWith("v") ? tag.slice(1) : tag;
  const dashIndex = raw.indexOf("-");
  if (dashIndex !== -1) raw = raw.slice(0, dashIndex);
  const parts = raw.split(".");
  if (parts.length !== 3) return null;
  const nums = parts.map(Number);
  if (nums.some((n) => !Number.isInteger(n) || n < 0)) return null;
  const [major, minor, patch] = nums;
  return { major, minor, patch };
}

function compareSemver(a, b) {
  if (a.major !== b.major) return a.major - b.major;
  if (a.minor !== b.minor) return a.minor - b.minor;
  return a.patch - b.patch;
}

/**
 * 在 release 列表里找"当前最新、可安装"的一条：tag 能解析出语义化版本号、
 * 非 draft、带 .dmg 资产，取版本号最大的那个。不比较"当前安装版本"——
 * 这一步只属于客户端（只有客户端知道自己装的是哪个版本）。
 */
export function pickLatestDmgRelease(releases) {
  let best = null;
  let bestVersion = null;
  for (const release of releases ?? []) {
    if (!release || release.draft) continue;
    const tag = release.tag_name || "";
    if (!VERSION_TAG_PATTERN.test(tag)) continue;
    const version = parseSemver(tag);
    if (!version) continue;
    const dmgAsset = (release.assets || []).find(
      (asset) => typeof asset?.name === "string" && asset.name.toLowerCase().endsWith(".dmg")
    );
    if (!dmgAsset) continue;
    if (!bestVersion || compareSemver(version, bestVersion) > 0) {
      bestVersion = version;
      best = { release, dmgAsset };
    }
  }
  return best;
}
