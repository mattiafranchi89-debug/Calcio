# Create a full Next.js + NextAuth + Prisma + Tailwind starter
# with email allow-list & admin role, plus a starter UI for the
# team manager (tabs similar to the TSX you liked). We'll zip it.

import os, json, textwrap, zipfile, pathlib

base = "/mnt/data/seguro-site"
os.makedirs(base, exist_ok=True)

def write(path, content):
    p = os.path.join(base, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(content)

# package.json
write("package.json", json.dumps({
  "name": "seguro-calcio-u19-site",
  "private": True,
  "version": "0.1.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "postinstall": "prisma generate",
    "db:push": "prisma db push",
    "db:seed": "tsx prisma/seed.ts"
  },
  "dependencies": {
    "next": "14.2.10",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "next-auth": "4.24.7",
    "@next-auth/prisma-adapter": "1.0.7",
    "@prisma/client": "5.16.1",
    "lucide-react": "0.441.0"
  },
  "devDependencies": {
    "prisma": "5.16.1",
    "typescript": "5.6.2",
    "tailwindcss": "3.4.10",
    "postcss": "8.4.44",
    "autoprefixer": "10.4.20",
    "tsx": "4.19.2"
  }
}, indent=2))

# next.config.js
write("next.config.js", textwrap.dedent("""\
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};
module.exports = nextConfig;
"""))

# tsconfig.json
write("tsconfig.json", json.dumps({
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "es2022"],
    "allowJs": False,
    "skipLibCheck": True,
    "strict": True,
    "forceConsistentCasingInFileNames": True,
    "noEmit": True,
    "esModuleInterop": True,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": True,
    "isolatedModules": True,
    "jsx": "preserve",
    "incremental": True,
    "plugins": [{ "name": "next" }]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}, indent=2))

write("next-env.d.ts", "/// <reference types=\"next\" />\n/// <reference types=\"next/image-types/global\" />\n")

# Tailwind / PostCSS
write("postcss.config.js", textwrap.dedent("""\
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
"""))
write("tailwind.config.js", textwrap.dedent("""\
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
"""))
write("styles/globals.css", textwrap.dedent("""\
@tailwind base;
@tailwind components;
@tailwind utilities;

html, body, #__next {
  height: 100%;
}

:root {
  --brand-blue: #0b66ff;
}
"""))

# Prisma schema: NextAuth + AllowedEmail + User.role + Player minimal + Match minimal
write("prisma/schema.prisma", textwrap.dedent("""\
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model User {
  id            String   @id @default(cuid())
  name          String?
  email         String?  @unique
  emailVerified DateTime?
  image         String?
  role          Role     @default(COACH)
  accounts      Account[]
  sessions      Session[]

  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}

enum Role {
  ADMIN
  COACH
  VIEWER
}

model AllowedEmail {
  id        String   @id @default(cuid())
  email     String   @unique
  role      Role     @default(VIEWER)
  createdAt DateTime @default(now())
  invitedBy String?
}

model Player {
  id         String  @id @default(cuid())
  name       String
  number     Int
  position   String
  goals      Int     @default(0)
  assists    Int     @default(0)
  presences  Int     @default(0)
  birthYear  Int
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
}

model Match {
  id        String  @id @default(cuid())
  opponent  String
  date      DateTime
  type      String   // "Campionato" | "Coppa"
  result    String   // "-" or "3-2"
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
"""))

# .env.example
write(".env.example", textwrap.dedent("""\
# Copy to .env and fill these
DATABASE_URL="file:./dev.db"

# NextAuth
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="replace-with-a-long-random-string"

GOOGLE_CLIENT_ID=""
GOOGLE_CLIENT_SECRET=""

# Admin & allowlist bootstrap (used by seed)
ADMIN_EMAIL="mattia.franchi89@gmail.com"
ALLOWLIST_EMAILS="alanrigo70@gmail.com,mattia.franchi89@gmail.com"
"""))

# lib/prisma.ts
write("lib/prisma.ts", textwrap.dedent("""\
import { PrismaClient } from '@prisma/client';

declare global {
  // eslint-disable-next-line no-var
  var prisma: PrismaClient | undefined;
}

export const prisma = global.prisma || new PrismaClient();

if (process.env.NODE_ENV !== 'production') global.prisma = prisma;
"""))

# lib/auth-options.ts
write("lib/auth-options.ts", textwrap.dedent("""\
import type { NextAuthOptions, User } from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';
import { PrismaAdapter } from '@next-auth/prisma-adapter';
import { prisma } from './prisma';

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'mattia.franchi89@gmail.com';

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      allowDangerousEmailAccountLinking: true,
    }),
  ],
  session: { strategy: 'database' },
  callbacks: {
    async signIn({ user }) {
      // Allow only if in AllowedEmail table OR is in bootstrap list (seeded)
      if (!user?.email) return false;
      const email = user.email.toLowerCase();

      const allowed = await prisma.allowedEmail.findUnique({ where: { email } });
      if (!allowed) {
        // no access
        return false;
      }
      // Ensure role is synced if user exists
      const existing = await prisma.user.findUnique({ where: { email } });
      if (existing && existing.role !== allowed.role) {
        await prisma.user.update({ where: { email }, data: { role: allowed.role }});
      }
      // If admin, ensure role ADMIN
      if (email === ADMIN_EMAIL.toLowerCase()) {
        await prisma.user.upsert({
          where: { email },
          update: { role: 'ADMIN' },
          create: { email, role: 'ADMIN', name: user.name ?? 'Admin' }
        });
      }
      return true;
    },
    async session({ session, user }) {
      if (session.user) {
        (session.user as any).role = (user as any).role;
        (session.user as any).id = (user as any).id;
      }
      return session;
    },
  },
  pages: {
    signIn: '/login',
    error: '/unauthorized',
  },
};
"""))

# pages/_app.tsx
write("pages/_app.tsx", textwrap.dedent("""\
import type { AppProps } from 'next/app';
import { SessionProvider } from 'next-auth/react';
import '../styles/globals.css';

export default function MyApp({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <SessionProvider session={session}>
      <Component {...pageProps} />
    </SessionProvider>
  );
}
"""))

# pages/login.tsx
write("pages/login.tsx", textwrap.dedent("""\
import { getSession, signIn } from 'next-auth/react';
import type { GetServerSideProps } from 'next';

export const getServerSideProps: GetServerSideProps = async (ctx) => {
  const session = await getSession(ctx);
  if (session) {
    return { redirect: { destination: '/app', permanent: false } };
  }
  return { props: {} };
};

export default function Login() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="bg-white p-8 rounded-2xl shadow-xl w-full max-w-md">
        <div className="text-center mb-6">
          <img src="/logo.png" alt="Seguro Calcio" className="w-16 h-16 mx-auto mb-2" />
          <h1 className="text-2xl font-bold text-gray-900">Seguro Calcio U19</h1>
          <p className="text-gray-500">Accesso riservato</p>
        </div>
        <button
          onClick={() => signIn('google')}
          className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-semibold transition"
        >
          Accedi con Google
        </button>
        <p className="text-xs text-gray-400 mt-4 text-center">
          L'accesso è consentito solo agli utenti in allow-list.
        </p>
      </div>
    </div>
  );
}
"""))

# pages/unauthorized.tsx
write("pages/unauthorized.tsx", textwrap.dedent("""\
export default function Unauthorized() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-red-50">
      <div className="bg-white p-8 rounded-2xl shadow-xl w-full max-w-lg text-center">
        <h1 className="text-2xl font-bold text-red-600">Accesso negato</h1>
        <p className="text-gray-600 mt-2">
          Il tuo account non è autorizzato. Contatta l'amministratore per essere abilitato.
        </p>
      </div>
    </div>
  );
}
"""))

# auth API - next-auth (pages router)
write("pages/api/auth/[...nextauth].ts", textwrap.dedent("""\
import NextAuth from 'next-auth';
import { authOptions } from '../../../lib/auth-options';

export default NextAuth(authOptions);
""")))

# Protected layout components
write("components/NavTabs.tsx", textwrap.dedent("""\
import Link from 'next/link';
import { useRouter } from 'next/router';

const tabs = [
  { href: '/app', label: 'Dashboard' },
  { href: '/app/players', label: 'Giocatori' },
  { href: '/app/trainings', label: 'Allenamenti' },
  { href: '/app/callup', label: 'Convocazione' },
  { href: '/app/results', label: 'Risultati' },
  { href: '/app/standings', label: 'Classifica' },
  { href: '/app/matches', label: 'Partite' },
  { href: '/admin', label: 'Admin' },
];

export default function NavTabs() {
  const router = useRouter();
  return (
    <div className="bg-white rounded-lg shadow mb-6">
      <div className="flex overflow-x-auto border-b">
        {tabs.map(t => {
          const active = router.pathname === t.href;
          return (
            <Link
              key={t.href}
              href={t.href}
              className={`px-4 py-3 font-semibold whitespace-nowrap text-sm md:text-base ${active ? 'bg-blue-600 text-white' : 'text-gray-700 hover:bg-gray-50'}`}
            >
              {t.label}
            </Link>
          );
        })}
      </div>
    </div>
  );
}
"""))

write("components/ProtectedShell.tsx", textwrap.dedent("""\
import { signOut, useSession } from 'next-auth/react';
import NavTabs from './NavTabs';

export default function ProtectedShell({ children }: { children: React.ReactNode }) {
  const { data: session } = useSession();
  const name = session?.user?.name ?? '';
  const role = (session?.user as any)?.role ?? 'VIEWER';

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <header className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white p-6 shadow-lg">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">⚽ Seguro Calcio U19</h1>
            <p className="text-blue-100">Gestione Squadra — {role}</p>
          </div>
          <div className="text-right">
            <p className="font-semibold">{name}</p>
            <button onClick={() => signOut()} className="text-sm underline text-blue-100 hover:text-white">
              Esci
            </button>
          </div>
        </div>
      </header>
      <main className="max-w-6xl mx-auto p-6">
        <NavTabs />
        {children}
      </main>
    </div>
  );
}
"""))

# Auth helper: requireAuth & requireAdmin
write("lib/require-auth.ts", textwrap.dedent("""\
import type { GetServerSideProps, GetServerSidePropsContext } from 'next';
import { getSession } from 'next-auth/react';

export const requireAuth: GetServerSideProps = async (ctx: GetServerSidePropsContext) => {
  const session = await getSession(ctx);
  if (!session) {
    return { redirect: { destination: '/login', permanent: false } };
  }
  return { props: { session } };
};

export const requireAdmin: GetServerSideProps = async (ctx: GetServerSidePropsContext) => {
  const session: any = await getSession(ctx);
  if (!session) return { redirect: { destination: '/login', permanent: false } };
  if ((session.user as any)?.role !== 'ADMIN') {
    return { redirect: { destination: '/app', permanent: false } };
  }
  return { props: { session } };
};
"""))

# /pages/app/index.tsx - dashboard using the previous TSX simplified
write("pages/app/index.tsx", textwrap.dedent("""\
import type { GetServerSideProps } from 'next';
import ProtectedShell from '../../components/ProtectedShell';
import { requireAuth } from '../../lib/require-auth';
import { Users, Calendar, Award, Activity, TrendingUp } from 'lucide-react';
import Link from 'next/link';

export const getServerSideProps: GetServerSideProps = requireAuth;

export default function Dashboard() {
  const playersLen = 19;
  const totalMatches = 1;
  const totalGoals = 50;

  return (
    <ProtectedShell>
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-blue-50 p-6 rounded-lg border border-blue-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-blue-600 text-sm font-medium">Giocatori</p>
                <p className="text-3xl font-bold text-blue-900">{playersLen}</p>
              </div>
              <Users className="text-blue-600" size={32} />
            </div>
          </div>
          <div className="bg-green-50 p-6 rounded-lg border border-green-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-green-600 text-sm font-medium">Partite Giocate</p>
                <p className="text-3xl font-bold text-green-900">{totalMatches}</p>
              </div>
              <Calendar className="text-green-600" size={32} />
            </div>
          </div>
          <div className="bg-orange-50 p-6 rounded-lg border border-orange-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-orange-600 text-sm font-medium">Gol Totali</p>
                <p className="text-3xl font-bold text-orange-900">{totalGoals}</p>
              </div>
              <Award className="text-orange-600" size={32} />
            </div>
          </div>
          <div className="bg-purple-50 p-6 rounded-lg border border-purple-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-purple-600 text-sm font-medium">Prossima Partita</p>
                <p className="text-lg font-bold text-purple-900">19 Ott</p>
              </div>
              <Activity className="text-purple-600" size={32} />
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
            <TrendingUp className="text-blue-600" />
            Cosa vuoi gestire?
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <Link href="/app/players" className="p-4 rounded-lg border hover:shadow bg-gray-50">Rosa giocatori</Link>
            <Link href="/app/trainings" className="p-4 rounded-lg border hover:shadow bg-gray-50">Presenze allenamenti</Link>
            <Link href="/app/callup" className="p-4 rounded-lg border hover:shadow bg-gray-50">Convocazione partita</Link>
            <Link href="/app/matches" className="p-4 rounded-lg border hover:shadow bg-gray-50">Calendario partite</Link>
            <Link href="/app/results" className="p-4 rounded-lg border hover:shadow bg-gray-50">Risultati (widget)</Link>
            <Link href="/app/standings" className="p-4 rounded-lg border hover:shadow bg-gray-50">Classifica (widget)</Link>
          </div>
        </div>
      </div>
    </ProtectedShell>
  );
}
"""))

# Simple players page (client state placeholder, suggest later DB wiring)
write("pages/app/players.tsx", textwrap.dedent("""\
import type { GetServerSideProps } from 'next';
import ProtectedShell from '../../components/ProtectedShell';
import { requireAuth } from '../../lib/require-auth';
import { useMemo, useState } from 'react';
import { Trash2, UserPlus } from 'lucide-react';

export const getServerSideProps: GetServerSideProps = requireAuth;

type Player = {
  id: string | number;
  name: string;
  number: number;
  position: string;
  goals: number;
  assists: number;
  presences: number;
  birthYear: number;
};

export default function PlayersPage() {
  const [players, setPlayers] = useState<Player[]>([
    { id: 1, name: 'Russo Gabriele', number: 1, position: 'Portiere', goals: 0, assists: 0, presences: 12, birthYear: 2007 },
    { id: 2, name: 'Capasso Andrea', number: 12, position: 'Portiere', goals: 0, assists: 0, presences: 11, birthYear: 2007 },
    // ...aggiungi qui gli altri come nello starter
  ]);
  const [showAdd, setShowAdd] = useState(false);
  const [newP, setNewP] = useState({ name: '', number: 0, position: 'Attaccante', birthYear: 2007 });

  const sorted = useMemo(() => [...players].sort((a,b)=>a.number-b.number), [players]);

  const add = () => {
    if (!newP.name || !newP.number) return;
    setPlayers(prev => [...prev, {
      id: prev.length + 1,
      name: newP.name,
      number: Number(newP.number),
      position: newP.position,
      goals: 0, assists: 0, presences: 0,
      birthYear: Number(newP.birthYear),
    }]);
    setNewP({ name: '', number: 0, position: 'Attaccante', birthYear: 2007 });
    setShowAdd(false);
  };

  const delP = (id: number | string) => setPlayers(prev => prev.filter(p => p.id !== id));

  return (
    <ProtectedShell>
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <h2 className="text-2xl font-bold">Rosa Giocatori</h2>
          <button onClick={()=>setShowAdd(s=>!s)} className="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center gap-2">
            <UserPlus size={18}/> Aggiungi
          </button>
        </div>

        {showAdd && (
          <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
              <input className="px-3 py-2 border rounded-lg" placeholder="Nome Cognome" value={newP.name} onChange={e=>setNewP({...newP,name:e.target.value})}/>
              <input className="px-3 py-2 border rounded-lg" placeholder="Numero" type="number" value={newP.number} onChange={e=>setNewP({...newP,number:Number(e.target.value)})}/>
              <select className="px-3 py-2 border rounded-lg" value={newP.position} onChange={e=>setNewP({...newP,position:e.target.value})}>
                <option>Portiere</option><option>Terzino Destro</option><option>Difensore Centrale</option>
                <option>Terzino Sinistro</option><option>Centrocampista Centrale</option><option>Ala</option><option>Attaccante</option>
              </select>
              <input className="px-3 py-2 border rounded-lg" placeholder="Anno" type="number" value={newP.birthYear} onChange={e=>setNewP({...newP,birthYear:Number(e.target.value)})}/>
              <button onClick={add} className="bg-green-600 text-white px-4 py-2 rounded-lg">Conferma</button>
            </div>
          </div>
        )}

        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-100">
              <tr>
                <th className="px-4 py-3 text-left">N°</th>
                <th className="px-4 py-3 text-left">Nome</th>
                <th className="px-4 py-3">Ruolo</th>
                <th className="px-4 py-3">Anno</th>
                <th className="px-4 py-3">Gol</th>
                <th className="px-4 py-3">Assist</th>
                <th className="px-4 py-3">Pres.</th>
                <th className="px-4 py-3">Azioni</th>
              </tr>
            </thead>
            <tbody>
              {sorted.map(p => (
                <tr key={p.id} className="border-t hover:bg-gray-50">
                  <td className="px-4 py-3 font-bold text-blue-600">{p.number}</td>
                  <td className="px-4 py-3">{p.name}</td>
                  <td className="px-4 py-3 text-center">{p.position}</td>
                  <td className="px-4 py-3 text-center">
                    <span className={`px-2 py-1 rounded text-xs font-semibold ${p.birthYear<=2006?'bg-orange-100 text-orange-700':'bg-blue-100 text-blue-700'}`}>{p.birthYear}</span>
                  </td>
                  <td className="px-4 py-3 text-center">{p.goals}</td>
                  <td className="px-4 py-3 text-center">{p.assists}</td>
                  <td className="px-4 py-3 text-center">{p.presences}</td>
                  <td className="px-4 py-3 text-center">
                    <button onClick={()=>delP(p.id)} className="text-red-600 hover:text-red-800"><Trash2 size={18}/></button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </ProtectedShell>
  );
}
"""))

# Other placeholder pages
simple_page = """\
import type { GetServerSideProps } from 'next';
import ProtectedShell from '../../components/ProtectedShell';
import { requireAuth } from '../../lib/require-auth';

export const getServerSideProps: GetServerSideProps = requireAuth;

export default function PAGE() {
  return (
    <ProtectedShell>
      <div className="bg-white p-6 rounded-lg shadow">Work in progress…</div>
    </ProtectedShell>
  );
}
"""

write("pages/app/trainings.tsx", simple_page.replace("PAGE", "TrainingsPage"))
write("pages/app/callup.tsx", simple_page.replace("PAGE", "CallUpPage"))
write("pages/app/matches.tsx", simple_page.replace("PAGE", "MatchesPage"))

# results & standings with Tuttocampo widgets
write("pages/app/results.tsx", textwrap.dedent("""\
import type { GetServerSideProps } from 'next';
import ProtectedShell from '../../components/ProtectedShell';
import { requireAuth } from '../../lib/require-auth';

export const getServerSideProps: GetServerSideProps = requireAuth;

export default function ResultsPage() {
  return (
    <ProtectedShell>
      <div className="space-y-4">
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="bg-gradient-to-r from-blue-500 to-indigo-600 text-white p-4">
            <h3 className="text-lg font-semibold">Risultati in Tempo Reale</h3>
            <p className="text-blue-100 text-sm">Aggiornamenti automatici da Tuttocampo</p>
          </div>
          <div className="p-4 flex justify-center bg-gray-50">
            <iframe
              src='https://www.tuttocampo.it/WidgetV2/Risultati/ba1901ca-5c24-4426-bb2b-165a80652fd6'
              width='100%'
              height='600'
              scrolling='no'
              frameBorder='0'
              loading='lazy'
              className="max-w-2xl rounded-lg shadow-sm"
              title="Risultati"
            />
          </div>
        </div>
      </div>
    </ProtectedShell>
  );
}
"""))

write("pages/app/standings.tsx", textwrap.dedent("""\
import type { GetServerSideProps } from 'next';
import ProtectedShell from '../../components/ProtectedShell';
import { requireAuth } from '../../lib/require-auth';

export const getServerSideProps: GetServerSideProps = requireAuth;

export default function StandingsPage() {
  return (
    <ProtectedShell>
      <div className="space-y-4">
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="bg-gradient-to-r from-yellow-500 to-orange-600 text-white p-4">
            <h3 className="text-lg font-semibold">Classifica Campionato</h3>
            <p className="text-yellow-100 text-sm">Aggiornamenti automatici da Tuttocampo</p>
          </div>
          <div className="p-4 flex justify-center bg-gray-50">
            <iframe
              src='https://www.tuttocampo.it/WidgetV2/Classifica/ba1901ca-5c24-4426-bb2b-165a80652fd6'
              width='100%'
              height='800'
              scrolling='no'
              frameBorder='0'
              loading='lazy'
              className="max-w-2xl rounded-lg shadow-sm"
              title="Classifica"
            />
          </div>
        </div>
      </div>
    </ProtectedShell>
  );
}
"""))

# /pages/app route guard via getServerSideProps, index page created above

# Admin page to manage allowlist
write("pages/admin/index.tsx", textwrap.dedent("""\
import type { GetServerSideProps } from 'next';
import { getSession, useSession } from 'next-auth/react';
import ProtectedShell from '../../components/ProtectedShell';
import { requireAdmin } from '../../lib/require-auth';
import { useEffect, useState } from 'react';

export const getServerSideProps: GetServerSideProps = requireAdmin;

type Allowed = { id: string; email: string; role: 'ADMIN'|'COACH'|'VIEWER'; createdAt: string; invitedBy?: string|null };

export default function AdminPage() {
  const { data: session } = useSession();
  const [items, setItems] = useState<Allowed[]>([]);
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<'ADMIN'|'COACH'|'VIEWER'>('VIEWER');

  const load = async () => {
    const res = await fetch('/api/allowed-emails');
    const data = await res.json();
    setItems(data.items);
  };
  useEffect(()=>{ load(); }, []);

  const add = async () => {
    if (!email) return;
    const res = await fetch('/api/allowed-emails', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ email, role })
    });
    if (res.ok) { setEmail(''); setRole('VIEWER'); load(); } else { alert('Errore'); }
  };

  const del = async (id: string) => {
    if (!confirm('Rimuovere dalla allow-list?')) return;
    const res = await fetch('/api/allowed-emails?id=' + id, { method: 'DELETE' });
    if (res.ok) load();
  };

  return (
    <ProtectedShell>
      <div className="space-y-4">
        <h2 className="text-2xl font-bold">Admin — Allow-list</h2>
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
            <input className="px-3 py-2 border rounded-lg" placeholder="email@domain.com" value={email} onChange={e=>setEmail(e.target.value)}/>
            <select className="px-3 py-2 border rounded-lg" value={role} onChange={e=>setRole(e.target.value as any)}>
              <option value="VIEWER">VIEWER</option>
              <option value="COACH">COACH</option>
              <option value="ADMIN">ADMIN</option>
            </select>
            <button onClick={add} className="bg-blue-600 text-white px-4 py-2 rounded-lg">Aggiungi</button>
          </div>
        </div>
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-100">
              <tr>
                <th className="px-4 py-3 text-left">Email</th>
                <th className="px-4 py-3">Ruolo</th>
                <th className="px-4 py-3">Invitato da</th>
                <th className="px-4 py-3">Azioni</th>
              </tr>
            </thead>
            <tbody>
              {items.map(i => (
                <tr key={i.id} className="border-t">
                  <td className="px-4 py-3">{i.email}</td>
                  <td className="px-4 py-3 text-center">{i.role}</td>
                  <td className="px-4 py-3 text-center">{i.invitedBy ?? '-'}</td>
                  <td className="px-4 py-3 text-center">
                    <button onClick={()=>del(i.id)} className="text-red-600 hover:underline">Rimuovi</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </ProtectedShell>
  );
}
"""))

# API for allowlist
write("pages/api/allowed-emails.ts", textwrap.dedent("""\
import type { NextApiRequest, NextApiResponse } from 'next';
import { getServerSession } from 'next-auth/next';
import { authOptions } from '../../lib/auth-options';
import { prisma } from '../../lib/prisma';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const session: any = await getServerSession(req, res, authOptions);
  if (!session || session.user?.role !== 'ADMIN') {
    return res.status(403).json({ error: 'Forbidden' });
  }

  if (req.method === 'GET') {
    const items = await prisma.allowedEmail.findMany({ orderBy: { createdAt: 'desc' } });
    return res.json({ items });
  }
  if (req.method === 'POST') {
    const { email, role } = req.body || {};
    if (!email) return res.status(400).json({ error: 'email required' });
    const item = await prisma.allowedEmail.upsert({
      where: { email: String(email).toLowerCase() },
      update: { role: role || 'VIEWER', invitedBy: session.user.email },
      create: { email: String(email).toLowerCase(), role: role || 'VIEWER', invitedBy: session.user.email },
    });
    return res.json({ item });
  }
  if (req.method === 'DELETE') {
    const id = String(req.query.id || '');
    if (!id) return res.status(400).json({ error: 'id required' });
    await prisma.allowedEmail.delete({ where: { id } });
    return res.json({ ok: true });
  }
  res.setHeader('Allow', 'GET,POST,DELETE');
  return res.status(405).end();
}
"""))

# Root /pages/index.tsx -> redirect based on session
write("pages/index.tsx", textwrap.dedent("""\
import type { GetServerSideProps } from 'next';
import { getSession } from 'next-auth/react';

export const getServerSideProps: GetServerSideProps = async (ctx) => {
  const session = await getSession(ctx);
  if (!session) return { redirect: { destination: '/login', permanent: false } };
  return { redirect: { destination: '/app', permanent: false } };
};
export default function Home(){ return null; }
"""))

# Public logo placeholder
write("public/logo.png", "")  # empty placeholder; user can replace later

# Seed script
write("prisma/seed.ts", textwrap.dedent("""\
import { prisma } from '../lib/prisma';

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'mattia.franchi89@gmail.com';
const ALLOWLIST = (process.env.ALLOWLIST_EMAILS || '').split(',').map(e=>e.trim().toLowerCase()).filter(Boolean);

async function main() {
  // Seed allowlist
  if (ALLOWLIST.length) {
    for (const email of ALLOWLIST) {
      await prisma.allowedEmail.upsert({
        where: { email },
        update: {},
        create: { email, role: email === ADMIN_EMAIL.toLowerCase() ? 'ADMIN' : 'COACH', invitedBy: 'seed' },
      });
    }
  } else {
    // Fallback: ensure admin + alan
    await prisma.allowedEmail.upsert({
      where: { email: ADMIN_EMAIL.toLowerCase() },
      update: {},
      create: { email: ADMIN_EMAIL.toLowerCase(), role: 'ADMIN', invitedBy: 'seed' },
    });
    await prisma.allowedEmail.upsert({
      where: { email: 'alanrigo70@gmail.com' },
      update: {},
      create: { email: 'alanrigo70@gmail.com', role: 'COACH', invitedBy: 'seed' },
    });
  }
  console.log('Allow-list seeded.');
}

main().then(()=>process.exit(0)).catch((e)=>{ console.error(e); process.exit(1); });
"""))

# README
write("README.md", textwrap.dedent("""\
# Seguro Calcio U19 — Sito con accesso ristretto e ruolo admin

Stack: **Next.js (Pages Router)** + **NextAuth (Google)** + **Prisma** + **SQLite (dev)** + **Tailwind**.

## Requisiti
- Accesso permesso solo a: `alanrigo70@gmail.com`, `mattia.franchi89@gmail.com`
- `mattia.franchi89@gmail.com` è **ADMIN** e può aggiungere nuovi utenti (allow-list).
- UI a tab con: Dashboard, Giocatori, Allenamenti, Convocazione, Risultati, Classifica, Partite.

## Setup locale (anche senza Mac)
1. Scarica il progetto come ZIP e scompattalo.
2. Crea `.env` copiando da `.env.example`. Inserisci:
   - `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` (creali su Google Cloud → OAuth consent screen).
   - `NEXTAUTH_SECRET` (stringa lunga random).
3. Installa dipendenze:
   ```bash
   npm install
