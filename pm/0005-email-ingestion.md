# 0005 — Email ingestion

Goal: Flow 2. Action Mailbox routes from a forwarding address (e.g., `inbox@<domain>`). Classify incoming attachments (PDF/HTML invoice, statement, etc.) → `IncomingDocument` with the right `kind`, file into the right month folder. Unknown ⇒ status `needs_review`.

Detail at milestone start.
