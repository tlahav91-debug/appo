'use client';
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';

type Submission = {
  id: string; title: string; description: string; genre: string;
  episode_number: number; cf_stream_id: string; thumbnail_url: string;
  status: string; submitted_at: string;
  creator_profiles: { display_name: string; why_create: string } | null;
};

type CreatorApp = {
  id: string; display_name: string; bio: string; why_create: string;
  status: string; created_at: string;
  profiles: { username: string } | null;
};

export default function AdminPage() {
  const [password, setPassword] = useState('');
  const [authed, setAuthed] = useState(false);
  const [adminSecret, setAdminSecret] = useState('');
  const [tab, setTab] = useState<'content' | 'creators'>('content');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function login() {
    setLoading(true);
    setError('');
    const res = await fetch('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ password }),
    });
    setLoading(false);
    if (!res.ok) { setError('Invalid password'); return; }
    // Store password in component state for Edge Function calls (not in bundle)
    setAdminSecret(password);
    setAuthed(true);
  }

  if (!authed) {
    return (
      <main style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh' }}>
        <div style={{ background: '#1a1a2e', padding: 40, borderRadius: 16, width: 320 }}>
          <h2 style={{ marginTop: 0 }}>Admin Access</h2>
          <input
            type="password" placeholder="Admin secret" value={password}
            onChange={e => setPassword(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && login()}
            style={inputStyle}
          />
          {error && <p style={{ color: '#f87171', fontSize: 13, marginBottom: 8 }}>{error}</p>}
          <button onClick={login} disabled={loading} style={btnStyle}>
            {loading ? 'Checking…' : 'Enter'}
          </button>
        </div>
      </main>
    );
  }

  return (
    <main style={{ maxWidth: 900, margin: '0 auto', padding: '32px 24px' }}>
      <h1 style={{ marginTop: 0 }}>AppLoop Admin</h1>
      <div style={{ display: 'flex', gap: 12, marginBottom: 28 }}>
        {(['content', 'creators'] as const).map(t => (
          <button key={t} onClick={() => setTab(t)} style={{
            ...btnStyle, width: 'auto', padding: '8px 24px',
            background: tab === t ? 'linear-gradient(135deg,#7c3aed,#a855f7)' : '#1a1a2e',
          }}>
            {t === 'content' ? 'Content Queue' : 'Creator Applications'}
          </button>
        ))}
      </div>
      {tab === 'content' ? <ContentQueue adminSecret={adminSecret} /> : <CreatorApplications adminSecret={adminSecret} />}
    </main>
  );
}

function ContentQueue({ adminSecret }: { adminSecret: string }) {
  const [items, setItems] = useState<Submission[]>([]);
  const [selected, setSelected] = useState<Submission | null>(null);
  const [seriesId, setSeriesId] = useState('');
  const [newSeriesTitle, setNewSeriesTitle] = useState('');
  const [isFree, setIsFree] = useState(false);
  const [episodeOrder, setEpisodeOrder] = useState(1);
  const [rejectReason, setRejectReason] = useState('');
  const [status, setStatus] = useState('');

  async function load() {
    const { data, error } = await supabase
      .from('content_submissions')
      .select('*, creator_profiles(display_name, why_create)')
      .eq('status', 'submitted')
      .order('submitted_at', { ascending: true });
    if (error) { setStatus(`Failed to load queue: ${error.message}`); return; }
    setItems((data as Submission[]) ?? []);
  }

  useEffect(() => { load(); }, []);

  async function approve() {
    if (!selected) return;
    setStatus('Approving…');
    const res = await fetch(`${SUPABASE_URL}/functions/v1/approve-content`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-secret': adminSecret },
      body: JSON.stringify({
        submission_id: selected.id,
        is_free: isFree,
        episode_order: episodeOrder,
        series_id: seriesId || undefined,
        new_series_title: newSeriesTitle || undefined,
      }),
    });
    const d = await res.json();
    if (!res.ok) { setStatus(`Error: ${d.error}`); return; }
    setStatus('✅ Approved!');
    setSelected(null);
    load();
  }

  async function reject() {
    if (!selected) return;
    setStatus('Rejecting…');
    const res = await fetch(`${SUPABASE_URL}/functions/v1/reject-content`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-secret': adminSecret },
      body: JSON.stringify({ submission_id: selected.id, reason: rejectReason }),
    });
    const d = await res.json();
    if (!res.ok) { setStatus(`Error: ${d.error}`); return; }
    setStatus('Rejected.');
    setSelected(null);
    load();
  }

  if (items.length === 0) return <p style={{ color: '#666' }}>No pending submissions. {status}</p>;

  return (
    <div style={{ display: 'grid', gridTemplateColumns: selected ? '1fr 1fr' : '1fr', gap: 20 }}>
      <div>
        {status && <p style={{ color: status.startsWith('✅') ? '#4ade80' : '#aaa', marginBottom: 12 }}>{status}</p>}
        {items.map(item => (
          <div key={item.id} onClick={() => { setSelected(item); setStatus(''); }}
            style={{ padding: 16, marginBottom: 10, background: selected?.id === item.id ? '#2a2a4e' : '#1a1a2e', borderRadius: 10, cursor: 'pointer', border: selected?.id === item.id ? '1px solid #7c3aed' : '1px solid transparent' }}>
            <strong>{item.title}</strong>
            <span style={{ marginLeft: 8, fontSize: 12, color: '#a78bfa' }}>{item.genre}</span>
            <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>
              by {item.creator_profiles?.display_name ?? '?'} · Ep {item.episode_number} · {new Date(item.submitted_at).toLocaleDateString()}
            </div>
          </div>
        ))}
      </div>
      {selected && (
        <div style={{ background: '#1a1a2e', borderRadius: 12, padding: 24 }}>
          <h3 style={{ marginTop: 0 }}>{selected.title}</h3>
          <p style={{ color: '#888', fontSize: 13 }}>{selected.description}</p>
          {selected.cf_stream_id && (
            <iframe
              src={`https://iframe.cloudflarestream.com/${selected.cf_stream_id}`}
              style={{ width: '100%', aspectRatio: '9/16', border: 'none', borderRadius: 8, marginBottom: 16 }}
              allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
            />
          )}
          <label style={labelStyle}>Series ID (leave blank to create new)</label>
          <input value={seriesId} onChange={e => setSeriesId(e.target.value)} style={inputStyle} placeholder="existing-series-uuid" />
          <label style={labelStyle}>New Series Title (if no Series ID)</label>
          <input value={newSeriesTitle} onChange={e => setNewSeriesTitle(e.target.value)} style={inputStyle} placeholder="My New Series" />
          <label style={labelStyle}>Episode Order</label>
          <input type="number" value={episodeOrder} min={1} onChange={e => setEpisodeOrder(Number(e.target.value))} style={inputStyle} />
          <label style={{ ...labelStyle, display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
            <input type="checkbox" checked={isFree} onChange={e => setIsFree(e.target.checked)} />
            Free episode
          </label>
          <button onClick={approve} style={{ ...btnStyle, marginBottom: 10, background: 'linear-gradient(135deg,#16a34a,#22c55e)' }}>✅ Approve</button>
          <label style={labelStyle}>Rejection reason</label>
          <input value={rejectReason} onChange={e => setRejectReason(e.target.value)} style={inputStyle} placeholder="Optional reason" />
          <button onClick={reject} style={{ ...btnStyle, background: 'linear-gradient(135deg,#be123c,#f43f5e)' }}>❌ Reject</button>
          {status && <p style={{ marginTop: 12, color: status.startsWith('✅') ? '#4ade80' : '#f87171' }}>{status}</p>}
        </div>
      )}
    </div>
  );
}

function CreatorApplications({ adminSecret }: { adminSecret: string }) {
  const [apps, setApps] = useState<CreatorApp[]>([]);
  const [status, setStatus] = useState('');

  async function load() {
    const { data, error } = await supabase
      .from('creator_profiles')
      .select('*, profiles(username)')
      .eq('status', 'pending')
      .order('created_at', { ascending: true });
    if (error) { setStatus(`Failed to load queue: ${error.message}`); return; }
    setApps((data as CreatorApp[]) ?? []);
  }

  useEffect(() => { load(); }, []);

  async function action(userId: string, approved: boolean, reason?: string) {
    setStatus('Processing…');
    const res = await fetch(`${SUPABASE_URL}/functions/v1/approve-creator`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-secret': adminSecret },
      body: JSON.stringify({ user_id: userId, approved, rejection_reason: reason }),
    });
    const d = await res.json();
    if (!res.ok) { setStatus(`Error: ${d.error}`); return; }
    setStatus(approved ? '✅ Approved!' : 'Rejected.');
    load();
  }

  if (apps.length === 0) return <p style={{ color: '#666' }}>No pending applications. {status}</p>;

  return (
    <div>
      {status && <p style={{ color: status.startsWith('✅') ? '#4ade80' : '#aaa', marginBottom: 12 }}>{status}</p>}
      {apps.map(app => (
        <div key={app.id} style={{ background: '#1a1a2e', borderRadius: 12, padding: 20, marginBottom: 14 }}>
          <strong style={{ fontSize: 16 }}>{app.display_name}</strong>
          <span style={{ marginLeft: 8, fontSize: 12, color: '#888' }}>@{app.profiles?.username ?? '?'}</span>
          <p style={{ color: '#aaa', fontSize: 13, margin: '8px 0' }}>{app.bio}</p>
          <p style={{ color: '#888', fontSize: 12 }}><em>Why create:</em> {app.why_create}</p>
          <div style={{ display: 'flex', gap: 10, marginTop: 12 }}>
            <button onClick={() => action(app.id, true)} style={{ ...btnStyle, width: 'auto', padding: '8px 20px', background: 'linear-gradient(135deg,#16a34a,#22c55e)', fontSize: 13 }}>✅ Approve</button>
            <button onClick={() => action(app.id, false, 'Application not approved at this time.')} style={{ ...btnStyle, width: 'auto', padding: '8px 20px', background: 'linear-gradient(135deg,#be123c,#f43f5e)', fontSize: 13 }}>❌ Reject</button>
          </div>
        </div>
      ))}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  display: 'block', width: '100%', marginBottom: 10, padding: '9px 12px',
  background: '#0d0d1a', border: '1px solid #333', borderRadius: 8,
  color: '#fff', fontSize: 13, boxSizing: 'border-box',
};
const labelStyle: React.CSSProperties = { display: 'block', fontSize: 12, color: '#888', marginBottom: 4 };
const btnStyle: React.CSSProperties = {
  display: 'block', width: '100%', padding: '11px 0',
  background: 'linear-gradient(135deg,#7c3aed,#a855f7)',
  border: 'none', borderRadius: 99, color: '#fff',
  fontSize: 14, fontWeight: 700, cursor: 'pointer',
};
