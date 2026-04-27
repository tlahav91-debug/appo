import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Creator Portal — AppLoop',
  description: 'Upload your micro-drama content',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: 'system-ui, sans-serif', background: '#0d0d1a', color: '#fff', minHeight: '100vh' }}>
        {children}
      </body>
    </html>
  );
}
