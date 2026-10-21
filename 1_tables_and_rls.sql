-- 1_tables_and_rls.sql
-- Run first. Creates tables, the two program policy records, and base RLS.
-- After this: create 2 auth users, insert them into profiles, then run 2_ and 3_.

create table if not exists profiles (
  id uuid primary key references auth.users(id),
  full_name text, student_id text unique,
  role text check (role in ('scholar','staff')) not null
);

create table if not exists programs (
  id serial primary key, name text unique,
  max_gwa numeric, min_units int, max_failed int,
  max_inc int, max_drop int, deadline timestamptz
);
insert into programs (name,max_gwa,min_units,max_failed,max_inc,max_drop,deadline) values
 ('Excellence Scholar',2.00,18,0,0,0,'2026-11-06 17:00+08'),
 ('Access Scholar',2.50,15,0,0,1,'2026-11-06 17:00+08')
on conflict (name) do nothing;

create table if not exists assignments (
  id serial primary key,
  scholar_id uuid references profiles(id) unique,
  program_id int references programs(id)
);

create table if not exists submissions (
  id serial primary key,
  scholar_id uuid references profiles(id),
  academic_year text, semester int,
  gwa numeric check (gwa between 1 and 5),
  units int check (units >= 0),
  failed int check (failed >= 0),
  inc int check (inc >= 0),
  dropped int check (dropped >= 0),
  evidence_ref text not null,
  submitted_at timestamptz default now(),
  verification_status text default 'Pending',
  verification_reason text,
  compliance_result text,
  compliance_reasons text[],
  renewal_decision text,
  decision_note text,
  unique (scholar_id, academic_year, semester)
);

create table if not exists history (
  id serial primary key,
  submission_id int references submissions(id),
  actor_id uuid, action text, detail text,
  created_at timestamptz default now()
);

-- ===== Row Level Security =====
create or replace function is_staff() returns boolean
language sql security definer set search_path = public as
$$ select exists(select 1 from profiles where id = auth.uid() and role='staff') $$;

alter table submissions enable row level security;
alter table profiles enable row level security;
alter table assignments enable row level security;
alter table history enable row level security;
alter table programs enable row level security;

drop policy if exists "scholar sees own" on submissions;
drop policy if exists "scholar inserts own" on submissions;
drop policy if exists "staff updates" on submissions;
drop policy if exists "read programs" on programs;
drop policy if exists "own profile" on profiles;
drop policy if exists "own assignment" on assignments;
drop policy if exists "staff manage assignments" on assignments;

create policy "scholar sees own" on submissions for select
  using (scholar_id = auth.uid() or is_staff());
create policy "scholar inserts own" on submissions for insert
  with check (scholar_id = auth.uid() and verification_status = 'Pending');
create policy "staff updates" on submissions for update using (is_staff());
create policy "read programs" on programs for select using (true);
create policy "own profile" on profiles for select using (id = auth.uid() or is_staff());
create policy "own assignment" on assignments for select using (scholar_id = auth.uid() or is_staff());
create policy "staff manage assignments" on assignments for all using (is_staff());
