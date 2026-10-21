# Student Scholarship Monitoring and Academic Compliance System

**SAD Laboratory Examination, Section B**
Name: ______________________  Student ID: ______________________  Program/Year: ______________________

A browser-based minimum viable system with two roles (Scholar and Scholarship Staff). Scholars submit semester academic summaries with a grade-document reference. Staff verify evidence, evaluate policy compliance, and record Approved or Held renewal decisions. All data is synthetic. The system does not alter official grades or release payments.

## Stack

- Frontend: HTML, CSS, JavaScript (single file, `index.html`)
- Backend: Supabase (PostgreSQL, Auth, Row Level Security, trigger)
- Source control: GitHub

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole application |
| `1_tables_and_rls.sql` | Tables, program policy records, first RLS policies |
| `2_extra_security.sql` | Extra policies, correction rule, backend guard trigger |
| `3_seed_B01_B06.sql` | Six seeded test records (AY 2026-2027, Semester 1) |

## Configuration (names only, no secrets in this repo)

At the top of the script in `index.html`:

- `SUPABASE_URL` : Project URL from Supabase, Project Settings, API
- `SUPABASE_KEY` : the publishable (anon) key

The `service_role` key is **not** used anywhere and must never be added.

## Setup

1. Create a Supabase project.
2. Authentication, Users: create two test users with Auto Confirm ticked (one staff, one scholar).
3. SQL Editor: run `1_tables_and_rls.sql`.
4. Insert both users into `profiles` using their real UIDs:
   ```sql
   insert into profiles (id, full_name, role)
   values ('STAFF-UID', 'Staff Test', 'staff');
   insert into profiles (id, full_name, student_id, role)
   values ('SCHOLAR-UID', 'Scholar Test', 'B01', 'scholar');
   ```
5. Run `2_extra_security.sql`, then `3_seed_B01_B06.sql`.
6. Put your own Project URL and publishable key in `index.html`.

## How to run

Open `index.html` in a browser (double-click, or serve the folder with any static server). Log in with the test accounts. **Test-account credentials are supplied privately to the instructor.**

## Features

- **Role access:** enforced by Row Level Security and a database trigger, not only by hidden buttons. A scholar sees only their own submissions and cannot verify, evaluate, or decide renewals.
- **Scholar and policy management:** staff register a scholar record and assign one of two persisted programs. Thresholds (max GWA, min units, failed, incomplete, dropped, deadline) are read from the `programs` table.
- **Grade submission:** academic year, semester, GWA, units, failed, incomplete, dropped, and evidence reference, with validation and timestamp. A unique constraint rejects a duplicate scholar, academic year, and semester.
- **Verification:** staff mark evidence Verified or Returned (reason required). A corrected resubmission returns to Pending verification.
- **Compliance and renewal:** only Verified records can be evaluated. Policy checks and deficiency reasons are displayed. Approval requires Compliant; Held is allowed after evaluation. The rule is also enforced in the database trigger.
- **Dashboard and search:** totals for the selected semester, search by student ID or name, filters by program and compliance.
- **History:** submissions, verifications, evaluations, and renewal decisions are logged with actor and timestamp, along with decision notes.

Submission status, academic compliance, and renewal decision are stored and shown separately.

## Policy rules used (fictional examination policy)

| Rule | Excellence Scholar | Access Scholar |
|---|---|---|
| Maximum GWA | 2.00 | 2.50 |
| Minimum units | 18 | 15 |
| Failed allowed | 0 | 0 |
| Incomplete allowed | 0 | 0 |
| Dropped allowed | 0 | 1 |
| Deadline | 2026-11-06 17:00 Asia/Manila | 2026-11-06 17:00 Asia/Manila |

## Test results

See `TEST_RESULTS` (table for TC01 to TC10 with screenshots in the `screenshots` folder).

## Known defects and limitations

- Seeded scholars B02 to B06 are synthetic profile records without login accounts. Only B01 is linked to a login (`scholar@test.com`).
- On correction and resubmission, the original submission timestamp is kept, so lateness is judged on the first submission. The correction time is recorded in history.
- No live Registrar API, SMS, payment, or appeal workflow (out of scope).
- Add any additional defects found during your own testing here: ______________________
