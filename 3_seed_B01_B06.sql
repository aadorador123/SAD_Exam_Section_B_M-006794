-- RUN THIS THIRD. Requires: your scholar@test.com profile has student_id 'B01'.
-- AY 2026-2027, Semester 1. All synthetic.

insert into profiles (id, full_name, student_id, role)
select gen_random_uuid(), v.n, v.s, 'scholar'
from (values
  ('Scholar B02','B02'),('Scholar B03','B03'),('Scholar B04','B04'),
  ('Scholar B05','B05'),('Scholar B06','B06')
) v(n,s)
where not exists (select 1 from profiles p where p.student_id = v.s);

insert into assignments (scholar_id, program_id)
select p.id, pr.id
from (values
  ('B01','Excellence Scholar'),('B02','Excellence Scholar'),('B03','Access Scholar'),
  ('B04','Access Scholar'),('B05','Excellence Scholar'),('B06','Access Scholar')
) v(sid,pn)
join profiles p on p.student_id = v.sid
join programs pr on pr.name = v.pn
on conflict (scholar_id) do nothing;

insert into submissions
  (scholar_id, academic_year, semester, gwa, units, failed, inc, dropped,
   evidence_ref, submitted_at, verification_status)
select p.id, '2026-2027', 1, v.gwa, v.units, v.f, v.i, v.d, 'DOC-' || v.sid,
       v.ts::timestamptz, v.vs
from (values
  ('B01', 2.00, 18, 0, 0, 0, '2026-11-06 17:00:00+08', 'Verified'),
  ('B02', 2.01, 18, 0, 0, 0, '2026-11-05 10:00:00+08', 'Verified'),
  ('B03', 2.50, 15, 0, 0, 1, '2026-11-05 10:00:00+08', 'Verified'),
  ('B04', 2.50, 14, 0, 1, 0, '2026-11-05 10:00:00+08', 'Verified'),
  ('B05', 1.75, 18, 1, 0, 0, '2026-11-06 17:01:00+08', 'Verified'),
  ('B06', 2.25, 15, 0, 0, 0, '2026-11-05 10:00:00+08', 'Pending')
) v(sid,gwa,units,f,i,d,ts,vs)
join profiles p on p.student_id = v.sid
on conflict (scholar_id, academic_year, semester) do nothing;
