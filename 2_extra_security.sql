-- RUN THIS SECOND (after tables + first RLS code). Safe to run many times.

-- Allow synthetic scholar profiles (B02-B06) that have no login
alter table profiles drop constraint if exists profiles_id_fkey;

-- Staff can manage profiles (register scholars)
drop policy if exists "staff manage profiles" on profiles;
create policy "staff manage profiles" on profiles for all
  using (is_staff()) with check (is_staff());

-- Scholar can submit only for self, only if assigned, only as Pending, nothing pre-evaluated
drop policy if exists "scholar inserts own" on submissions;
create policy "scholar inserts own" on submissions for insert
  with check (
    scholar_id = auth.uid()
    and verification_status = 'Pending'
    and compliance_result is null
    and renewal_decision is null
    and exists (select 1 from assignments a where a.scholar_id = auth.uid())
  );

-- Scholar can correct ONLY their own Returned submission
drop policy if exists "scholar corrects" on submissions;
create policy "scholar corrects" on submissions for update
  using (scholar_id = auth.uid() and verification_status = 'Returned')
  with check (scholar_id = auth.uid());

-- History: staff see all, scholar sees own; anyone logged in can log their own action
drop policy if exists "staff history" on history;
drop policy if exists "staff add history" on history;
drop policy if exists "read history" on history;
drop policy if exists "add history" on history;
create policy "read history" on history for select
  using (is_staff() or exists (select 1 from submissions s where s.id = submission_id and s.scholar_id = auth.uid()));
create policy "add history" on history for insert
  with check (actor_id = auth.uid());

-- Backend business-rule guard (cannot be bypassed by the browser)
create or replace function guard_submission() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return new; end if;  -- SQL editor / seed

  if not is_staff() then
    if old.scholar_id <> auth.uid() or old.verification_status <> 'Returned' then
      raise exception 'Only your own Returned submission can be corrected';
    end if;
    new.scholar_id := old.scholar_id;
    new.academic_year := old.academic_year;
    new.semester := old.semester;
    new.submitted_at := old.submitted_at;
    new.verification_status := 'Pending';
    new.verification_reason := old.verification_reason;
    new.compliance_result := null;
    new.compliance_reasons := null;
    new.renewal_decision := null;
    new.decision_note := null;
    return new;
  end if;

  if new.compliance_result is distinct from old.compliance_result
     and new.compliance_result is not null
     and new.verification_status <> 'Verified' then
    raise exception 'Cannot evaluate: evidence is not Verified';
  end if;

  if new.renewal_decision is distinct from old.renewal_decision
     and new.renewal_decision is not null then
    if new.verification_status <> 'Verified' or new.compliance_result is null then
      raise exception 'Cannot decide renewal: verify and evaluate first';
    end if;
    if new.renewal_decision = 'Approved' and new.compliance_result <> 'Compliant' then
      raise exception 'Cannot approve a record that is With Deficiency';
    end if;
  end if;

  if new.verification_status <> 'Verified' then
    new.compliance_result := null;
    new.compliance_reasons := null;
    new.renewal_decision := null;
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_submission on submissions;
create trigger trg_guard_submission before update on submissions
  for each row execute function guard_submission();
