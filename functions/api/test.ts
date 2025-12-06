/**
 * 测试 Cloudflare Pages Functions 是否工作
 */
export async function onRequestGet() {
  return new Response(
    JSON.stringify({
      success: true,
      message: 'Cloudflare Pages Functions is working!',
      timestamp: new Date().toISOString()
    }),
    {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    }
  );
}
