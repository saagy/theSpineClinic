# Engineer meeting and client acceptance checklist

Bring the [review plan](pre-delivery-review-plan.md), [results](pre-delivery-review-results.md)
and the code diff. Allow 60â€“90 minutes. Use fictional patients in a separate
test Supabase project and separate document storage. The existing project is
the only current backend, so do not perform destructive demonstrations there.

## Before the meeting

- [ ] Create staging and role accounts: admin, receptionist with/without payment
      permission, ordinary doctor, senior doctor and inactive applicant.
- [ ] Apply migrations in order, deploy the edge function and build the matching
      client. Record the exact commit/release and successful CI run.
- [ ] Resolve the high-priority open findings in the results document.
- [ ] Prepare two fictional patients with different assigned doctors, a known
      package balance, partial payment, cash visit and assessment.
- [ ] Record database/R2 backup and a successful isolated restore.
- [ ] Confirm the client's essential workflows, acceptance owner and support plan.

## 0â€“10 minutes: establish scope

Explain that this was AI-assisted development and show the actual evidence.
Say which defects were found, which fixes passed, and which checks remain open.
Agree that acceptance depends on working requirements and recoverability.
Do not claim zero bugs, enterprise certification or a security guarantee.

## 10â€“25 minutes: accounts and access

- [ ] Sign in/out; refresh; open a protected URL before login.
- [ ] Verify each role sees the expected navigation and actions.
- [ ] Ordinary doctor cannot read the other doctor's patient or document through
      a direct API request or guessed URL, and cannot self-assign or self-promote.
- [ ] Inactive account cannot access operational records.
- [ ] Deactivate an already-signed-in account; retry read/write and refresh.
- [ ] Switch roles/accounts in the same browser; check cached records disappear.
- [ ] Confirm password recovery and admin access recovery procedures.

## 25â€“45 minutes: a complete clinic visit

- [ ] Create patient and assign doctor; find them by name/phone.
- [ ] Record package purchase; verify exact credits and remaining payment due.
- [ ] Book package, cash and assessment visits; check future commitments.
- [ ] Check in, reverse, cancel, change type and delete a test appointment;
      inspect credits after every action. No unexplained balance difference.
- [ ] Edit patient and appointment with assignment changes; verify all-or-nothing.
- [ ] Add clinical history, program, treatment plan and visit notes as permitted.
- [ ] Upload/open/rename/delete a fictional PDF/image; test denied access.
- [ ] Reconcile dashboard/report totals with the known fixture, including more
      records than the API response limit.

## 45â€“60 minutes: PC, phone and failure cases

- [ ] Run the essential flows on desktop Chrome/Edge and phone Safari/Chrome.
- [ ] Test small width, keyboard open, long names, large text and scrolling sheets.
- [ ] Check loading/error/empty/data states and refresh after every mutation.
- [ ] Drop a save response, slow an upload, retry and double-click submit.
- [ ] Use two operators to book the last credit and collect the same due.
- [ ] Confirm no duplicate records, wrong balances or misleading success.
- [ ] Check keyboard navigation and labels on essential forms.

## 60â€“90 minutes: operations and decision

- [ ] Restore database plus documents into isolation and open restored records.
- [ ] Review error monitoring using fictional data; verify sensitive fields absent.
- [ ] Confirm account ownership, billing, export, retention and incident contact.
- [ ] Agree on rollback and the order of database/edge/client deployment.
- [ ] Record every issue with severity, owner, evidence and retest date.

| Decision | Meaning |
| --- | --- |
| Pass | Essential workflows and release gates have observed, recorded passes. |
| Conditional | Only explicitly accepted nonessential issues remain, with owners/dates. |
| Hold | Unauthorized access, incorrect money/balances, data loss, missing recovery or an untested critical gate remains. |

Keep a signed acceptance record: release identifier, devices/browsers tested,
requirements demonstrated, known limitations, open issue owners and support
terms. A reassuring demo alone is not a substitute for these checks.
