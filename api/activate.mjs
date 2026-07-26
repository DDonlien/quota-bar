import {
  callCreem,
  errorResponse,
  isPlausibleKey,
  isPlausibleShortText,
  json,
  readJsonBody,
  toClientPayload,
} from "./_lib/creem.mjs";

// 激活入口：macOS App 的「偏好设置 → 激活」把用户输入的 license key 发到这里，
// 由服务端带着 CREEM_API_KEY 去调 Creem，把这台设备注册成一个 instance。
// 客户端拿到 instanceId 后存本地，之后复验都带着它（见 api/validate.mjs）。
export async function POST(request) {
  const body = await readJsonBody(request);
  if (!body) {
    return json({ ok: false, error: "请求格式不正确" }, 400);
  }
  if (!isPlausibleKey(body.key)) {
    return json({ ok: false, error: "许可证密钥格式不正确" }, 400);
  }
  if (!isPlausibleShortText(body.instanceName)) {
    return json({ ok: false, error: "设备名称不正确" }, 400);
  }

  let upstream;
  try {
    upstream = await callCreem("/licenses/activate", {
      key: body.key,
      instance_name: body.instanceName,
    });
  } catch (error) {
    return errorResponse(error);
  }

  if (!upstream.ok) {
    return errorResponse(null, upstream);
  }
  return json(toClientPayload(upstream.data));
}

// 显式拒绝非 POST：这个 endpoint 会消耗上游额度，不该被 GET 预取/爬虫误触发。
export async function GET() {
  return json({ ok: false, error: "Method Not Allowed" }, 405);
}
