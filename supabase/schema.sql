-- Competitor Discovery Agent: Supabase / Postgres schema
-- Run this once in the Supabase SQL editor of a new project.
-- n8n connects with the service_role key, which bypasses RLS.
-- RLS is on with no policies, so nobody else can read or write via the public API.

create table public.profile_runs (
  id uuid primary key default gen_random_uuid(),
  run_id text not null unique,
  input_url text,
  domain text,
  company_name text,
  legal_entity text,
  hq_city text,
  category text,
  notes text,
  profile_json text,            -- verified profile: every field with value, quote and source URL
  quote_check_json text,        -- verified / partial / rejected per field
  sources_json text,
  dropped_json text,
  fetched_text text,
  verified integer,
  partial integer,
  rejected integer,
  empty integer,
  json_repaired boolean,
  status text,                  -- profile_ready | insufficient_data
  focus_market text,            -- DACH, EU, Global ... (checked in code)
  include_global boolean default true,
  created_at timestamptz not null default now()
);

create table public.competitors (
  id uuid primary key default gen_random_uuid(),
  run_id text not null,
  name text,
  domain text,
  other_names_text text,
  analysed_domain text,
  forces_text text,
  force_count integer,
  display_group text,
  any_direct boolean,
  hits integer,
  what_they_do text,
  evidence_text text,           -- one line per quote: [force] "quote" - url
  recent_moves_text text,
  from_own_site boolean,
  -- judge (stage 2.1)
  buyer_match text,
  verdict text,
  verdict_rivalry text,         -- true | unsure | false
  verdict_substitute text,
  verdict_new_entrant text,
  judge_reasons text,
  judge_quote text,
  business_type text,           -- software | service | logistics_provider | consultancy | other
  segment_match text,           -- same | different | unclear
  segment_note text,
  job_focus text,               -- core | major_module | minor_feature
  status text default 'candidate',   -- candidate | verified | unsure | rejected
  approved boolean default false,
  your_note text,
  -- enrichment (stage 2.1, Apollo)
  enriched boolean default false,
  needs_domain boolean,
  enrich_note text,
  apollo_id text,
  apollo_name text,
  apollo_description text,
  website_url text,
  logo_url text,
  linkedin_url text,
  crunchbase_url text,
  hq_country text,
  hq_city text,
  industry text,
  keywords_text text,
  employees integer,
  founded_year integer,
  headcount_growth_6m numeric,
  headcount_growth_12m numeric,
  headcount_growth_24m numeric,
  sales_headcount integer,
  engineering_headcount integer,
  funding_total text,
  funding_total_usd numeric,
  last_funding_stage text,
  last_funding_date timestamptz,
  funding_rounds_text text,
  revenue text,
  parent_company text,
  public_ticker text,
  -- scoring (stage 2.2)
  score numeric,
  rank integer,
  tier text,                    -- Primary threat | Watch | Peripheral
  score_breakdown text,
  platform_owner boolean,
  market_presence text,         -- local | active | none | unknown | n/a
  market_note text,
  created_at timestamptz not null default now()
);
create index competitors_run_id_idx on public.competitors (run_id);

-- Buyer power (F4) and supplier power (F5). A new research run adds rows;
-- readers sort by created_at and use the newest row per force.
create table public.force_assessments (
  id uuid primary key default gen_random_uuid(),
  assessment text not null,     -- "<run_id> · <force>"
  run_id text not null,
  force text not null,          -- buyer_power | supplier_power
  overall text,                 -- high | medium | low | unknown (computed in code)
  known_drivers integer,
  summary text,
  drivers_text text,
  drivers_json text,
  citations_text text,
  created_at timestamptz not null default now()
);
create index force_assessments_run_force_idx on public.force_assessments (run_id, force, created_at);

alter table public.profile_runs enable row level security;
alter table public.competitors enable row level security;
alter table public.force_assessments enable row level security;
