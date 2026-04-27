import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  const { password } = await req.json();
  const correct = password === process.env.ADMIN_SECRET;
  if (!correct) return NextResponse.json({ error: 'Invalid password' }, { status: 401 });
  return NextResponse.json({ ok: true });
}
