import { fetchReleases } from "./_lib/releases.mjs";

// 大陆可达性兜底第二步：macOS 客户端和官网下载按钮直连 api.github.com 失败时，
// 改请求这个同源 endpoint。原样转发 GitHub 的 release 数组，客户端复用现有解析逻辑。
export async function GET() {
  try {
    const releases = await fetchReleases();
    return new Response(JSON.stringify(releases), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        // 短缓存 + SWR：减少对 GitHub API 的重复穿透，同时不会让用户等太久看到新版本。
        "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Failed to fetch releases from GitHub",
        detail: String(error?.message ?? error),
      }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }
}
