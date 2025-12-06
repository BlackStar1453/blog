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
 * 使用纯 JavaScript 实现，因为 Cloudflare Workers 的 crypto.subtle 不支持 MD5
 */
function md5(message: string): string {
  // 纯 JavaScript MD5 实现
  function rotateLeft(value: number, shift: number): number {
    return (value << shift) | (value >>> (32 - shift));
  }

  function addUnsigned(x: number, y: number): number {
    const lsw = (x & 0xFFFF) + (y & 0xFFFF);
    const msw = (x >> 16) + (y >> 16) + (lsw >> 16);
    return (msw << 16) | (lsw & 0xFFFF);
  }

  function md5_F(x: number, y: number, z: number): number {
    return (x & y) | ((~x) & z);
  }

  function md5_G(x: number, y: number, z: number): number {
    return (x & z) | (y & (~z));
  }

  function md5_H(x: number, y: number, z: number): number {
    return x ^ y ^ z;
  }

  function md5_I(x: number, y: number, z: number): number {
    return y ^ (x | (~z));
  }

  function md5_FF(a: number, b: number, c: number, d: number, x: number, s: number, ac: number): number {
    a = addUnsigned(a, addUnsigned(addUnsigned(md5_F(b, c, d), x), ac));
    return addUnsigned(rotateLeft(a, s), b);
  }

  function md5_GG(a: number, b: number, c: number, d: number, x: number, s: number, ac: number): number {
    a = addUnsigned(a, addUnsigned(addUnsigned(md5_G(b, c, d), x), ac));
    return addUnsigned(rotateLeft(a, s), b);
  }

  function md5_HH(a: number, b: number, c: number, d: number, x: number, s: number, ac: number): number {
    a = addUnsigned(a, addUnsigned(addUnsigned(md5_H(b, c, d), x), ac));
    return addUnsigned(rotateLeft(a, s), b);
  }

  function md5_II(a: number, b: number, c: number, d: number, x: number, s: number, ac: number): number {
    a = addUnsigned(a, addUnsigned(addUnsigned(md5_I(b, c, d), x), ac));
    return addUnsigned(rotateLeft(a, s), b);
  }

  function convertToWordArray(str: string): number[] {
    const wordArray: number[] = [];
    for (let i = 0; i < str.length * 8; i += 8) {
      wordArray[i >> 5] |= (str.charCodeAt(i / 8) & 0xFF) << (i % 32);
    }
    return wordArray;
  }

  function wordToHex(value: number): string {
    let hex = '';
    for (let i = 0; i < 4; i++) {
      hex += ((value >> (i * 8 + 4)) & 0x0F).toString(16) +
             ((value >> (i * 8)) & 0x0F).toString(16);
    }
    return hex;
  }

  // UTF-8 encoding
  let utf8Message = unescape(encodeURIComponent(message));

  const x = convertToWordArray(utf8Message);
  let a = 0x67452301;
  let b = 0xEFCDAB89;
  let c = 0x98BADCFE;
  let d = 0x10325476;

  const msgLen = utf8Message.length * 8;
  x[msgLen >> 5] |= 0x80 << (msgLen % 32);
  x[(((msgLen + 64) >>> 9) << 4) + 14] = msgLen;

  const S11 = 7, S12 = 12, S13 = 17, S14 = 22;
  const S21 = 5, S22 = 9, S23 = 14, S24 = 20;
  const S31 = 4, S32 = 11, S33 = 16, S34 = 23;
  const S41 = 6, S42 = 10, S43 = 15, S44 = 21;

  for (let k = 0; k < x.length; k += 16) {
    const AA = a, BB = b, CC = c, DD = d;

    a = md5_FF(a, b, c, d, x[k + 0], S11, 0xD76AA478);
    d = md5_FF(d, a, b, c, x[k + 1], S12, 0xE8C7B756);
    c = md5_FF(c, d, a, b, x[k + 2], S13, 0x242070DB);
    b = md5_FF(b, c, d, a, x[k + 3], S14, 0xC1BDCEEE);
    a = md5_FF(a, b, c, d, x[k + 4], S11, 0xF57C0FAF);
    d = md5_FF(d, a, b, c, x[k + 5], S12, 0x4787C62A);
    c = md5_FF(c, d, a, b, x[k + 6], S13, 0xA8304613);
    b = md5_FF(b, c, d, a, x[k + 7], S14, 0xFD469501);
    a = md5_FF(a, b, c, d, x[k + 8], S11, 0x698098D8);
    d = md5_FF(d, a, b, c, x[k + 9], S12, 0x8B44F7AF);
    c = md5_FF(c, d, a, b, x[k + 10], S13, 0xFFFF5BB1);
    b = md5_FF(b, c, d, a, x[k + 11], S14, 0x895CD7BE);
    a = md5_FF(a, b, c, d, x[k + 12], S11, 0x6B901122);
    d = md5_FF(d, a, b, c, x[k + 13], S12, 0xFD987193);
    c = md5_FF(c, d, a, b, x[k + 14], S13, 0xA679438E);
    b = md5_FF(b, c, d, a, x[k + 15], S14, 0x49B40821);

    a = md5_GG(a, b, c, d, x[k + 1], S21, 0xF61E2562);
    d = md5_GG(d, a, b, c, x[k + 6], S22, 0xC040B340);
    c = md5_GG(c, d, a, b, x[k + 11], S23, 0x265E5A51);
    b = md5_GG(b, c, d, a, x[k + 0], S24, 0xE9B6C7AA);
    a = md5_GG(a, b, c, d, x[k + 5], S21, 0xD62F105D);
    d = md5_GG(d, a, b, c, x[k + 10], S22, 0x02441453);
    c = md5_GG(c, d, a, b, x[k + 15], S23, 0xD8A1E681);
    b = md5_GG(b, c, d, a, x[k + 4], S24, 0xE7D3FBC8);
    a = md5_GG(a, b, c, d, x[k + 9], S21, 0x21E1CDE6);
    d = md5_GG(d, a, b, c, x[k + 14], S22, 0xC33707D6);
    c = md5_GG(c, d, a, b, x[k + 3], S23, 0xF4D50D87);
    b = md5_GG(b, c, d, a, x[k + 8], S24, 0x455A14ED);
    a = md5_GG(a, b, c, d, x[k + 13], S21, 0xA9E3E905);
    d = md5_GG(d, a, b, c, x[k + 2], S22, 0xFCEFA3F8);
    c = md5_GG(c, d, a, b, x[k + 7], S23, 0x676F02D9);
    b = md5_GG(b, c, d, a, x[k + 12], S24, 0x8D2A4C8A);

    a = md5_HH(a, b, c, d, x[k + 5], S31, 0xFFFA3942);
    d = md5_HH(d, a, b, c, x[k + 8], S32, 0x8771F681);
    c = md5_HH(c, d, a, b, x[k + 11], S33, 0x6D9D6122);
    b = md5_HH(b, c, d, a, x[k + 14], S34, 0xFDE5380C);
    a = md5_HH(a, b, c, d, x[k + 1], S31, 0xA4BEEA44);
    d = md5_HH(d, a, b, c, x[k + 4], S32, 0x4BDECFA9);
    c = md5_HH(c, d, a, b, x[k + 7], S33, 0xF6BB4B60);
    b = md5_HH(b, c, d, a, x[k + 10], S34, 0xBEBFBC70);
    a = md5_HH(a, b, c, d, x[k + 13], S31, 0x289B7EC6);
    d = md5_HH(d, a, b, c, x[k + 0], S32, 0xEAA127FA);
    c = md5_HH(c, d, a, b, x[k + 3], S33, 0xD4EF3085);
    b = md5_HH(b, c, d, a, x[k + 6], S34, 0x04881D05);
    a = md5_HH(a, b, c, d, x[k + 9], S31, 0xD9D4D039);
    d = md5_HH(d, a, b, c, x[k + 12], S32, 0xE6DB99E5);
    c = md5_HH(c, d, a, b, x[k + 15], S33, 0x1FA27CF8);
    b = md5_HH(b, c, d, a, x[k + 2], S34, 0xC4AC5665);

    a = md5_II(a, b, c, d, x[k + 0], S41, 0xF4292244);
    d = md5_II(d, a, b, c, x[k + 7], S42, 0x432AFF97);
    c = md5_II(c, d, a, b, x[k + 14], S43, 0xAB9423A7);
    b = md5_II(b, c, d, a, x[k + 5], S44, 0xFC93A039);
    a = md5_II(a, b, c, d, x[k + 12], S41, 0x655B59C3);
    d = md5_II(d, a, b, c, x[k + 3], S42, 0x8F0CCC92);
    c = md5_II(c, d, a, b, x[k + 10], S43, 0xFFEFF47D);
    b = md5_II(b, c, d, a, x[k + 1], S44, 0x85845DD1);
    a = md5_II(a, b, c, d, x[k + 8], S41, 0x6FA87E4F);
    d = md5_II(d, a, b, c, x[k + 15], S42, 0xFE2CE6E0);
    c = md5_II(c, d, a, b, x[k + 6], S43, 0xA3014314);
    b = md5_II(b, c, d, a, x[k + 13], S44, 0x4E0811A1);
    a = md5_II(a, b, c, d, x[k + 4], S41, 0xF7537E82);
    d = md5_II(d, a, b, c, x[k + 11], S42, 0xBD3AF235);
    c = md5_II(c, d, a, b, x[k + 2], S43, 0x2AD7D2BB);
    b = md5_II(b, c, d, a, x[k + 9], S44, 0xEB86D391);

    a = addUnsigned(a, AA);
    b = addUnsigned(b, BB);
    c = addUnsigned(c, CC);
    d = addUnsigned(d, DD);
  }

  return (wordToHex(a) + wordToHex(b) + wordToHex(c) + wordToHex(d)).toLowerCase();
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
  const sign = md5(signString);

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
