import { fetchReleases, pickLatestDmgRelease } from "./_lib/releases.mjs";

// 大陆可达性兜底第二步：GitHub dmg 直链下载失败时，改走这个同源 endpoint。
// 服务端现查最新 release + 现拉 dmg 资产，流式转发响应体（不整份缓冲进内存），
// 只代理"当前最新版"这一个固定目标，不接受任意 URL 参数，避免被当开放代理滥用。
export async function GET() {
  let best;
  try {
    const releases = await fetchReleases();
    best = pickLatestDmgRelease(releases);
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Failed to resolve latest release",
        detail: String(error?.message ?? error),
      }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  if (!best) {
    return new Response(JSON.stringify({ error: "No installable release found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  const assetResponse = await fetch(best.dmgAsset.browser_download_url, {
    headers: { "User-Agent": "QuotaBar-Vercel-Proxy" },
    redirect: "follow",
  });
  if (!assetResponse.ok || !assetResponse.body) {
    return new Response(
      JSON.stringify({ error: `Failed to fetch dmg asset (HTTP ${assetResponse.status})` }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  const headers = {
    "Content-Type": "application/octet-stream",
    "Content-Disposition": `attachment; filename="${best.dmgAsset.name}"`,
    "Cache-Control": "public, max-age=300",
  };
  const contentLength = assetResponse.headers.get("content-length");
  if (contentLength) headers["Content-Length"] = contentLength;

  // 直接把上游 ReadableStream 转发出去，零配置流式转发，不缓冲整份文件。
  return new Response(assetResponse.body, { status: 200, headers });
}
