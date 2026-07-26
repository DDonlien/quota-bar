import { fetchBlobManifest, fetchGitHubFallback } from "./_lib/manifest.mjs";

// 安装包下载入口。官网下载按钮和 macOS App 内更新都打这里。
//
// v0.15.0 起来源优先级：Vercel Blob（新发布链路）→ GitHub release 资产（迁移期降级）。
// 两种情况都是**流式转发**而不是 302 跳转：下载流量必须留在自有域名上，这正是
// v0.14.0 加这条链路的初衷（大陆可达性——能连上本站不代表能连上上游）。
// 只代理"当前最新版"这一个固定目标，不接受任意 URL 参数，避免被当成开放代理。
export async function GET() {
  let sourceUrl;
  let fileName;

  const manifest = await fetchBlobManifest();
  if (manifest) {
    sourceUrl = manifest.dmgUrl;
    fileName = manifest.dmgName || `QuotaBar-${manifest.tag}.dmg`;
  } else {
    let best;
    try {
      ({ best } = await fetchGitHubFallback());
    } catch (error) {
      return jsonError(`Failed to resolve latest release: ${String(error?.message ?? error)}`, 502);
    }
    if (!best) {
      return jsonError("No installable release found", 404);
    }
    sourceUrl = best.dmgAsset.browser_download_url;
    fileName = best.dmgAsset.name;
  }

  const assetResponse = await fetch(sourceUrl, {
    headers: { "User-Agent": "QuotaBar-Vercel-Proxy" },
    redirect: "follow",
  });
  if (!assetResponse.ok || !assetResponse.body) {
    return jsonError(`Failed to fetch dmg (HTTP ${assetResponse.status})`, 502);
  }

  const headers = {
    "Content-Type": "application/octet-stream",
    "Content-Disposition": `attachment; filename="${fileName}"`,
    "Cache-Control": "public, max-age=300",
  };
  const contentLength = assetResponse.headers.get("content-length");
  if (contentLength) headers["Content-Length"] = contentLength;

  // 直接把上游 ReadableStream 转发出去，零配置流式转发，不缓冲整份文件。
  return new Response(assetResponse.body, { status: 200, headers });
}

// Vercel 不会把 HEAD 自动路由到 GET，不显式导出的话探测请求会拿到 405。
// 下载器（curl -I、部分代理/CDN、以及习惯先探大小再拉全量的客户端）都会用 HEAD，
// 让它们撞 405 会被误读成"下载地址挂了"。这里复用 GET 的完整逻辑拿到真实的
// Content-Length / Content-Disposition，再丢掉 body 返回——比手写一份可能跟
// GET 不一致的头更可靠。
export async function HEAD() {
  const response = await GET();
  return new Response(null, { status: response.status, headers: response.headers });
}

function jsonError(message, status) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
