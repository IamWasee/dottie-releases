-- Applied to Supabase project dottie-site (ref wxleaxtxjfaurghtgknm) on 2026-11-03.
-- Dottie website signups: waitlist and beta tester applications.
-- Anyone (the website's public anon key) can add a row; nobody can read rows
-- without the service role, so the list of emails never leaks to visitors.

create table if not exists public.waitlist (
  id          bigint generated always as identity primary key,
  email       text not null,
  name        text,
  source      text default 'website',
  created_at  timestamptz not null default now(),
  constraint waitlist_email_format check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  constraint waitlist_email_length check (char_length(email) <= 254)
);
create unique index if not exists waitlist_email_unique on public.waitlist (lower(email));

create table if not exists public.beta_applications (
  id              bigint generated always as identity primary key,
  name            text not null,
  email           text not null,
  mac_chip        text,           -- 'apple-silicon' | 'intel' | 'not-sure'
  macos_version   text,
  use_case        text not null,  -- what they'd use Dottie for
  usage_frequency text,           -- 'daily' | 'few-times-week' | 'now-and-then'
  heard_from      text,
  feedback_ok     boolean not null default false,
  status          text not null default 'new',  -- new | invited | declined
  created_at      timestamptz not null default now(),
  constraint beta_email_format check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  constraint beta_lengths check (
    char_length(name) <= 120 and char_length(email) <= 254 and char_length(use_case) <= 2000
  )
);
create unique index if not exists beta_email_unique on public.beta_applications (lower(email));

alter table public.waitlist enable row level security;
alter table public.beta_applications enable row level security;

revoke all on public.waitlist from anon, authenticated;
revoke all on public.beta_applications from anon, authenticated;
grant insert on public.waitlist to anon;
grant insert on public.beta_applications to anon;

-- Visitors may only insert. No select/update/delete policies, so reads need the service role.
drop policy if exists "anyone can join the waitlist" on public.waitlist;
create policy "anyone can join the waitlist" on public.waitlist
  for insert to anon with check (source = 'website');

drop policy if exists "anyone can apply to the beta" on public.beta_applications;
create policy "anyone can apply to the beta" on public.beta_applications
  for insert to anon with check (status = 'new');

-- 2026-11-03: beta testers share an Instagram or Facebook handle.
alter table public.beta_applications add column if not exists social_platform text, add column if not exists social_handle text;
alter table public.beta_applications add constraint beta_social_lengths check (
  char_length(coalesce(social_platform,'')) <= 20 and char_length(coalesce(social_handle,'')) <= 200
  and (social_platform is null or social_platform in ('instagram','facebook'))
);
