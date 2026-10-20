create extension if not exists pgcrypto;

create table if not exists public.student_profiles (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  full_name text not null check (char_length(full_name) between 1 and 120),
  mobile_number text not null check (mobile_number ~ '^[6-9][0-9]{9}$'),
  board_percentage numeric(5, 2) not null check (board_percentage between 0 and 100),
  cet_percentile numeric(5, 2) not null check (cet_percentile between 0 and 100),
  category text not null check (category in ('OPEN', 'EWS', 'SEBC', 'OBC', 'ST', 'SC', 'TFWS')),
  gender text not null check (gender in ('Female', 'Male', 'Prefer not to say')),
  preferred_region text not null check (preferred_region in ('All', 'Amravati', 'Chhatrapati Sambhajinagar', 'Mumbai', 'Nagpur', 'Nashik', 'Pune')),
  consent boolean not null default false check (consent),
  consented_at timestamptz not null default now()
);

create table if not exists public.mhcf_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.student_profiles enable row level security;
alter table public.mhcf_admins enable row level security;

revoke all on public.student_profiles from public, anon, authenticated;
revoke all on public.mhcf_admins from public, anon, authenticated;
grant insert on public.student_profiles to anon, authenticated;
grant select on public.student_profiles to authenticated;
grant select on public.mhcf_admins to authenticated;

drop policy if exists "consenting visitors can submit profiles" on public.student_profiles;
create policy "consenting visitors can submit profiles"
  on public.student_profiles
  for insert
  to anon, authenticated
  with check (consent is true);

drop policy if exists "approved admins can read student profiles" on public.student_profiles;
create policy "approved admins can read student profiles"
  on public.student_profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.mhcf_admins
      where mhcf_admins.user_id = (select auth.uid())
    )
  );

drop policy if exists "admins can read their own membership" on public.mhcf_admins;
create policy "admins can read their own membership"
  on public.mhcf_admins
  for select
  to authenticated
  using (user_id = (select auth.uid()));

-- After creating the admin account in Supabase Auth, approve it with:
-- insert into public.mhcf_admins (user_id)
-- select id from auth.users where email = 'your-admin-email@example.com'
-- on conflict do nothing;