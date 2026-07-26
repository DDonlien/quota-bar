import {
  callCreem,
  errorResponse,
  isPlausibleKey,
  isPlausibleShortText,
  json,
  readJsonBody,
  toClientPayload,
} from "./_lib/creem.mjs";

// 复验入口：App 每 24 小时最多问一次"这个授权还有效吗"。
// 客户端对失败是 fail-open 的（连不上不吊销本地授权，见 LicenseManager 的说明），
// 所以这里不需要为可用性做额外兜底，如实转达 Creem 的判断即可。
export async function POST(request) {
  const body = await readJsonBody(request);
  if (!body) {
    return json({ ok: false, error: "请求格式不正确" }, 400);
  }
  if (!isPlausibleKey(body.key)) {
    return json({ ok: false, error: "许可证密钥格式不正确" }, 400);
  }
  if (!isPlausibleShortText(body.instanceId)) {
    return json({ ok: false, error: "设备标识不正确" }, 400);
  }

  let upstream;
  try {
    upstream = await callCreem("/licenses/validate", {
      key: body.key,
      instance_id: body.instanceId,
    });
  } catch (error) {
    return errorResponse(error);
  }

  if (!upstream.ok) {
    return errorResponse(null, upstream);
  }
  return json(toClientPayload(upstream.data));
}

export async function GET() {
  return json({ ok: false, error: "Method Not Allowed" }, 405);
}
