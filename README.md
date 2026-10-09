# DriveCare Admin Dashboard

Open `admin.html` on your deployed HTTPS website. This is an actual Supabase-connected dashboard, not a sample-data demo.

## Setup (required)
1. Upload ALL files from this folder to the same HTTPS website directory (including `config.js`). Replace older `index.html` and `portal.html` only if you want this complete version.
2. In the SAME Supabase project, run `schema.sql` and `quote_requests.sql` only if they have NOT already been installed. These are initial setup scripts, not general migrations. If tables already exist, do not rerun blindly.
3. Run `admin_inbox.sql` in Supabase SQL Editor. It grants **admin-only** inquiry read/status-update access, using `public.is_admin()` from `schema.sql`.
4. Enable Supabase Email authentication. Create your account through `portal.html`, confirm your email, and locate your account UUID in Authentication > Users.
5. In SQL Editor, as the project owner, run `update public.profiles set role = 'admin' where id = 'YOUR-USER-UUID';` replacing the placeholder. Only grant this to trusted staff. Refresh `admin.html` and sign in.
6. Submit a test quote through `index.html`; verify it appears in `admin.html` and its status changes persist after refresh.

## Features
- Admin-only login; separate customer portal
- Overview counts and newest inquiries
- Inquiry search/filter, detail viewer, status updates (New, Contacted, Approved, Declined)
- Customer, vehicle, fleet, membership and service request lists (up to 500 latest per section)
- Responsive layout for phones and desktop

## Important limitations
- No live database access was available during development; browser/production end-to-end testing is still required.
- The public quote form currently uses browser-supplied pricing: **recalculate and verify before quoting or charging**.
- No payments, scheduling confirmation, or email/SMS alerts; an Approved inquiry is NOT an active membership.
- Add server-side bot protection, rate limiting, a privacy policy, retention/deletion rules, and audit logs before public launch.
- Never put Supabase secret/service_role keys in client-side files.
- If your Supabase schema differs from the included scripts, you may need to adapt queries or migrate the schema.
