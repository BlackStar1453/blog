/**
 * Cloudflare Workers API 端点
 * 功能：为打赏组件生成微信支付动态二维码
 *
 * 调用方式：
 * POST /api/donation/wechat-qr
 * Body: { "amount": 10 }  // 金额单位：人民币（¥）
 *
 * 返回：
 * {
 *   "success": true,
 *   "qrCodeDataUrl": "data:image/png;base64,...",
 *   "orderId": "donation_xxx",
 *   "expiresIn": 300
 * }
 */

interface Env {
  XORPAY_AID: string;
  XORPAY_SECRET: string;
  BASE_URL: string;
}

interface RequestBody {
  amount: number;
}

interface XorpayResponse {
  status: string;
  info?: {
    qr: string; // WeChat payment URL
  };
  aoid?: string;
  expires_in?: number;
  msg?: string;
}

/**
 * MD5 加密函数（用于 Xorpay 签名）
 */
async function md5(message: string): Promise<string> {
  const msgUint8 = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('MD5', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  return hashHex;
}

/**
 * 生成唯一订单 ID
 */
function generateOrderId(): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 10);
  return `donation_${timestamp}_${random}`;
}

/**
 * 调用 Xorpay API 创建支付订单
 */
async function createXorpayOrder(
  amount: number,
  orderId: string,
  env: Env
): Promise<XorpayResponse> {
  const name = `打赏支付 - ¥${amount}`;
  const payType = 'native'; // 扫码支付
  const price = amount.toString();
  const notifyUrl = `${env.BASE_URL}/api/xorpay/notify`;
  const more = '';

  // 生成签名
  const signString = name + payType + price + orderId + notifyUrl + env.XORPAY_SECRET;
  const sign = await md5(signString);

  // 构建请求参数
  const params = new URLSearchParams({
    name,
    pay_type: payType,
    price,
    order_id: orderId,
    order_uid: 'anonymous', // 匿名打赏
    notify_url: notifyUrl,
    more,
    sign,
  });

  // 调用 Xorpay API
  const response = await fetch(`https://xorpay.com/api/pay/${env.XORPAY_AID}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  });

  return await response.json();
}

/**
 * 将支付 URL 转换为二维码图片（Base64）
 */
async function generateQRCode(paymentUrl: string): Promise<string> {
  // 使用第三方 QR Code 生成服务
  const qrApiUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&format=png&data=${encodeURIComponent(paymentUrl)}`;

  const response = await fetch(qrApiUrl);
  const imageBuffer = await response.arrayBuffer();

  // 转换为 Base64
  const base64 = btoa(
    String.fromCharCode(...new Uint8Array(imageBuffer))
  );

  return `data:image/png;base64,${base64}`;
}

/**
 * Cloudflare Workers 请求处理函数
 */
export async function onRequestPost(context: { request: Request; env: Env }) {
  const { request, env } = context;

  try {
    // 解析请求体
    const body: RequestBody = await request.json();
    const { amount } = body;

    // 验证金额
    if (!amount || typeof amount !== 'number' || amount < 10) {
      return new Response(
        JSON.stringify({
          success: false,
          error: '金额无效，最低金额为 ¥10',
        }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // 生成订单 ID
    const orderId = generateOrderId();

    // 调用 Xorpay API
    const xorpayResponse = await createXorpayOrder(amount, orderId, env);

    // 检查 Xorpay 响应
    if (xorpayResponse.status !== 'ok' || !xorpayResponse.info?.qr) {
      console.error('Xorpay API 错误:', xorpayResponse);
      return new Response(
        JSON.stringify({
          success: false,
          error: xorpayResponse.msg || '生成支付二维码失败',
        }),
        {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // 生成二维码图片
    const qrCodeDataUrl = await generateQRCode(xorpayResponse.info.qr);

    // 返回成功响应
    return new Response(
      JSON.stringify({
        success: true,
        qrCodeDataUrl,
        orderId,
        expiresIn: xorpayResponse.expires_in || 300,
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (error) {
    console.error('处理请求时发生错误:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: '服务器内部错误',
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  }
}

/**
 * 处理 CORS 预检请求
 */
export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
