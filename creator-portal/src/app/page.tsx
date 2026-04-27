'use client';
import { useState } from 'react';
import { supabase } from '@/lib/supabase';

export default function Home() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [loggedIn, setLoggedIn] = useState<boolean>(false);

  async function login() {
    setLoading(true);
    setError('');
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (error) { setError(error.message); return; }
    if (data.session) setLoggedIn(true);
  }

  if (loggedIn) return <Dashboard />;

  return (
    <main style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh' }}>
      <div style={{ background: '#1a1a2e', padding: 40, borderRadius: 16, width: 340 }}>
        <h1 style={{ marginTop: 0 }}>Creator Portal</h1>
        <input
          type="email" placeholder="Email" value={email}
          onChange={e => setEmail(e.target.value)}
          style={inputStyle}
        />
        <input
          type="password" placeholder="Password" value={password}
          onChange={e => setPassword(e.target.value)}
          style={inputStyle}
        />
        {error && <p style={{ color: '#ff6b9d', fontSize: 13 }}>{error}</p>}
        <button onClick={login} disabled={loading} style={btnStyle}>
          {loading ? 'Signing in…' : 'Sign In'}
        </button>
      </div>
    </main>
  );
}

function Dashboard() {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [genre, setGenre] = useState('Romance');
  const [episodeNumber, setEpisodeNumber] = useState(1);
  const [thumbnailUrl, setThumbnailUrl] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [status, setStatus] = useState('');
  const [submissions, setSubmissions] = useState<Record<string, string>[]>([]);
  const [loadedSubs, setLoadedSubs] = useState(false);

  const genres = ['Romance', 'Thriller', 'Comedy', 'Fantasy', 'Drama', 'Mystery'];

  async function loadSubmissions() {
    const { data } = await supabase.from('content_submissions').select('id,title,status,submitted_at').order('created_at', { ascending: false });
    setSubmissions((data as Record<string, string>[]) ?? []);
    setLoadedSubs(true);
  }

  async function upload() {
    if (!title || !file) { setStatus('Title and video file are required.'); return; }
    setStatus('Getting upload URL…');

    const { data: { session } } = await supabase.auth.getSession();
    const freshToken = session?.access_token;
    if (!freshToken) { setStatus('Session expired. Please sign in again.'); return; }

    const res = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/get-upload-url`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${freshToken}`,
      },
      body: JSON.stringify({ title, description, genre, episode_number: episodeNumber, thumbnail_url: thumbnailUrl, file_size: file.size }),
    });

    const data = await res.json();
    if (!res.ok) { setStatus(`Error: ${data.error}`); return; }

    const { upload_url, submission_id } = data;

    setStatus('Uploading video…');
    // Use tus resumable upload
    const { default: tus } = await import('tus-js-client');
    await new Promise<void>((resolve, reject) => {
      const upload = new tus.Upload(file, {
        uploadUrl: upload_url,
        retryDelays: [0, 3000, 5000, 10000],
        metadata: { filename: file.name, filetype: file.type },
        onError: (err) => { setStatus(`Upload failed: ${err.message}`); reject(err); },
        onProgress: (uploaded, total) => setStatus(`Uploading… ${Math.round(uploaded / total * 100)}%`),
        onSuccess: () => resolve(),
      });
      upload.start();
    });

    setStatus('Submitting for review…');
    const { data: { session: subSession } } = await supabase.auth.getSession();
    const subToken = subSession?.access_token;
    if (!subToken) { setStatus('Session expired. Please sign in again.'); return; }
    const subRes = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/submit-content`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${subToken}` },
      body: JSON.stringify({ submission_id }),
    });

    const subData = await subRes.json();
    if (!subRes.ok) { setStatus(`Submit error: ${subData.error}`); return; }

    setStatus('✅ Submitted! We\'ll review within 48 hours.');
    setTitle(''); setDescription(''); setFile(null);
    loadSubmissions();
  }

  return (
    <main style={{ maxWidth: 680, margin: '0 auto', padding: '40px 24px' }}>
      <h1 style={{ marginTop: 0 }}>Creator Studio</h1>
      <div style={{ background: '#1a1a2e', borderRadius: 16, padding: 28, marginBottom: 24 }}>
        <h2 style={{ marginTop: 0, fontSize: 18 }}>Upload New Episode</h2>
        <label style={labelStyle}>Title *</label>
        <input value={title} onChange={e => setTitle(e.target.value)} style={inputStyle} placeholder="Episode title" />
        <label style={labelStyle}>Description</label>
        <textarea value={description} onChange={e => setDescription(e.target.value)} style={{ ...inputStyle, height: 80, resize: 'vertical' }} placeholder="Short description" />
        <label style={labelStyle}>Genre</label>
        <select value={genre} onChange={e => setGenre(e.target.value)} style={inputStyle}>
          {genres.map(g => <option key={g}>{g}</option>)}
        </select>
        <label style={labelStyle}>Episode Number</label>
        <input type="number" value={episodeNumber} min={1} onChange={e => setEpisodeNumber(Number(e.target.value))} style={inputStyle} />
        <label style={labelStyle}>Thumbnail URL (optional)</label>
        <input value={thumbnailUrl} onChange={e => setThumbnailUrl(e.target.value)} style={inputStyle} placeholder="https://…" />
        <label style={labelStyle}>Video File * (MP4/MOV)</label>
        <input type="file" accept="video/*" onChange={e => setFile(e.target.files?.[0] ?? null)} style={{ marginBottom: 16, color: '#aaa' }} />
        {status && <p style={{ color: status.startsWith('✅') ? '#4ade80' : '#aaa', fontSize: 13 }}>{status}</p>}
        <button onClick={upload} style={btnStyle}>Upload & Submit</button>
      </div>

      <div style={{ background: '#1a1a2e', borderRadius: 16, padding: 28 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h2 style={{ margin: 0, fontSize: 18 }}>My Submissions</h2>
          <button onClick={loadSubmissions} style={{ ...btnStyle, padding: '8px 16px', fontSize: 13 }}>Refresh</button>
        </div>
        {!loadedSubs && <p style={{ color: '#666' }}>Click refresh to load submissions.</p>}
        {loadedSubs && submissions.length === 0 && <p style={{ color: '#666' }}>No submissions yet.</p>}
        {submissions.map(s => (
          <div key={s.id} style={{ padding: '12px 0', borderBottom: '1px solid #2a2a3e' }}>
            <span style={{ fontWeight: 600 }}>{s.title}</span>
            <span style={{ marginLeft: 12, fontSize: 12, color: statusColor(s.status), background: '#2a2a3e', padding: '2px 8px', borderRadius: 99 }}>{s.status}</span>
          </div>
        ))}
      </div>
    </main>
  );
}

function statusColor(status: string) {
  return status === 'approved' ? '#4ade80' : status === 'rejected' ? '#ff6b9d' : status === 'submitted' ? '#a78bfa' : '#888';
}

const inputStyle: React.CSSProperties = {
  display: 'block', width: '100%', marginBottom: 12, padding: '10px 14px',
  background: '#0d0d1a', border: '1px solid #333', borderRadius: 8,
  color: '#fff', fontSize: 14, boxSizing: 'border-box',
};
const labelStyle: React.CSSProperties = { display: 'block', fontSize: 12, color: '#888', marginBottom: 4 };
const btnStyle: React.CSSProperties = {
  display: 'block', width: '100%', padding: '12px 0',
  background: 'linear-gradient(135deg, #7c3aed, #a855f7)',
  border: 'none', borderRadius: 99, color: '#fff',
  fontSize: 15, fontWeight: 700, cursor: 'pointer',
};
