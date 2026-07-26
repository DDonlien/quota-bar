// Creem license API 的共享封装：给 api/activate.mjs 和 api/validate.mjs 复用。
// 文件名前缀 `_` 让 Vercel 零配置 /api 路由跳过它，不会被当成独立 endpoint。
//
// 这一层存在的唯一理由是 **密钥隔离**：Creem 用 `x-api-key` 鉴权，那把 key 能读写
// 整个 Creem 账户，不能进 macOS 客户端（何况源码是公开的）。App 只跟本域名说话，
// 由这里带着密钥去调 Creem。

const CREEM_BASE_URL = process.env.CREEM_API_BASE_URL || "https://api.creem.io/v1";

/** 统一的 JSON 响应，避免每个 endpoint 各写一份 header。 */
export function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      // 授权结果绝不能被任何一层缓存（CDN 或客户端）复用。
      "Cache-Control": "no-store",
    },
  });
}

/**
 * 校验 license key 的基本形状。
 *
 * 这两个 endpoint 会带着我们的密钥去打 Creem，属于对外暴露的转发面，必须先把明显
 * 无意义的输入挡在本地，不要让任意字符串都变成一次真实的上游调用（既是防滥用，
 * 也避免把 Creem 的额度浪费在垃圾请求上）。这里只做宽松的形状校验，不猜 Creem 的
 * key 具体格式——真正的判定交给 Creem。
 */
export function isPlausibleKey(value) {
  return typeof value === "string" && value.length >= 8 && value.length <= 200;
}

export function isPlausibleShortText(value) {
  return typeof value === "string" && value.length >= 1 && value.length <= 200;
}

/** 解析请求体，坏 JSON 不抛异常而是返回 null，让调用方给出 400 而不是 500。 */
export async function readJsonBody(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}

/**
 * 调 Creem license 接口。
 *
 * 返回 `{ ok, status, data }`：`ok` 只表示 HTTP 层成功，业务状态在 `data.status` 里。
 * 密钥缺失时抛一个可识别的错误，让调用方回 503（"服务没配好"）而不是 500（"炸了"）——
 * 这两种情况的排查方向完全不同，混在一起会浪费很多时间。
 */
export async function callCreem(path, payload) {
  const apiKey = process.env.CREEM_API_KEY;
  if (!apiKey) {
    const error = new Error("CREEM_API_KEY is not configured on the server");
    error.code = "MISSING_API_KEY";
    throw error;
  }

  const response = await fetch(`${CREEM_BASE_URL}${path}`, {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "Content-Type": "application/json",
      "User-Agent": "QuotaBar-Vercel",
    },
    body: JSON.stringify(payload),
  });

  let data = null;
  try {
    data = await response.json();
  } catch {
    // Creem 偶尔在错误路径上返回空 body，保持 data = null 交给调用方判断。
  }
  return { ok: response.ok, httpStatus: response.status, data };
}

/**
 * 把 Creem 的响应收敛成客户端需要的最小字段集。
 *
 * 刻意不把 Creem 的原始响应整个透传：里面有 product_id、customer 等跟激活判定无关
 * 的信息，客户端不需要，少传一点就少一点意外泄漏面。
 */
export function toClientPayload(data) {
  return {
    ok: true,
    status: data?.status ?? null,
    instanceId: data?.instance?.id ?? null,
    expiresAt: data?.expires_at ?? null,
    activation: data?.activation ?? null,
    activationLimit: data?.activation_limit ?? null,
  };
}

/** 把上游/本地错误翻译成给最终用户看的中文文案 + 合适的 HTTP 状态码。 */
export function errorResponse(error, upstream) {
  if (error?.code === "MISSING_API_KEY") {
    return json(
      { ok: false, error: "激活服务尚未配置完成，请稍后再试或联系 taobe@ddonlien.com" },
      503
    );
  }
  if (upstream) {
    const { httpStatus, data } = upstream;
    if (httpStatus === 404) {
      return json({ ok: false, error: "许可证密钥无效" }, 404);
    }
    if (httpStatus === 400) {
      return json({ ok: false, error: data?.message || "许可证密钥无效或已达激活上限" }, 400);
    }
    if (httpStatus === 401) {
      // 我们自己的密钥不对——对用户来说这是服务端问题，不是他们的密钥有问题，
      // 不能回"密钥无效"误导他们反复重试。
      return json({ ok: false, error: "激活服务鉴权失败，请联系 taobe@ddonlien.com" }, 502);
    }
    return json({ ok: false, error: `激活服务暂时不可用（${httpStatus}）` }, 502);
  }
  return json(
    { ok: false, error: `激活服务暂时不可用：${String(error?.message ?? error)}` },
    502
  );
}
