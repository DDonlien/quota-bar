import { fetchBlobManifest, fetchGitHubFallback, manifestAsReleaseArray } from "./_lib/manifest.mjs";

// "最新版是什么"的对外查询入口。macOS 客户端和官网下载按钮都打这里。
//
// v0.15.0 起数据源优先级：Vercel Blob 上的 manifest（新发布链路的事实来源）
// → GitHub Releases（迁移期降级，只对还带 dmg 资产的历史 release 有效）。
// 无论走哪条路，**输出都是 GitHub Releases API 的数组形状**——已经装在用户机器上
// 的客户端解析的是这个结构，保持形状不变，这次迁移对它们就是完全透明的。
export async function GET(request) {
  const origin = new URL(request.url).origin;

  const manifest = await fetchBlobManifest();
  if (manifest) {
    return json(manifestAsReleaseArray(manifest, origin));
  }

  try {
    const { releases } = await fetchGitHubFallback();
    return json(releases);
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Failed to resolve latest release",
        detail: String(error?.message ?? error),
      }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }
}

function json(body) {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      // 短缓存 + SWR：不让每次检查更新都穿透到存储/GitHub，同时新版本最多晚一分钟可见。
      "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
