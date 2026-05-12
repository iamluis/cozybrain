# SL Brain — Design Document

## What this is

A quiet system that runs Luis's SLU with minimal attention. It captures expenses, organizes documents, drafts invoices, and keeps a clean house for the gestoría — all while staying out of the way.

---

## The person

Solo software consultant. One main client (Lab900), invoiced monthly. Travels regularly to Belgium. All expenses go on the company card. A gestoría handles tax decisions and filings — Luis captures and organizes, they classify and declare.

Laptop is the work surface. Phone is the capture tool. He's willing to do a few fields at the moment of capture, but after that, the system should handle everything.

---

## Design principles

1. **Invisible by default.** The system should feel like a habit, not a tool. No dashboards to check daily. No inboxes to clear. It works in the background and surfaces only when something needs a human decision.

2. **Capture at the moment, organize later.** The only time Luis should interact with the system in real-time is when a receipt is in his hand. Everything else — filing, categorizing, matching — happens without him.

3. **The gestoría walks into a clean room.** The folder structure is the interface for the gestoría. No app for them to learn, no portal to log into (unless they want one later). Just a well-organized, always-current shared folder they can access.

4. **Weekly pulse, not daily noise.** Once a week, a brief summary of what came in, what went out, and anything that needs attention. That's the only scheduled interruption.

5. **One tap away from done.** The monthly invoice should arrive pre-drafted. Review it, approve it, it's sent. No templates to find, no fields to fill.

---

## The three flows

### Flow 1: Capture (phone, at the moment)

**When it happens:** Right after paying. Receipt is in hand, phone is in pocket.

**What Luis does:**
- Opens the app (or a share-sheet shortcut)
- Points the camera at the receipt
- The system reads the receipt (OCR) and pre-fills: amount, date, vendor name, country
- Luis confirms or corrects the pre-filled fields
- Optionally adds a short note ("dinner with Matthias", "taxi to STT office")
- Taps save
- Puts the receipt in the bin

**What the system does behind the scenes:**
- Applies certified digitization (via Holded's homologated process) so the photo has legal standing
- Stores the original image and the certified version
- Files it into the right month and category folder
- Matches it against the company card transaction when bank data syncs

**Time budget:** Under 30 seconds from camera to done.

**Edge cases:**
- No receipt (e.g., a vending machine, parking meter): Luis can log a manual entry with just amount + note. The bank transaction is the backup proof.
- Multiple receipts at once (emptying a wallet): batch mode — snap, snap, snap, confirm all at the end.

---

### Flow 2: Collect (background, automatic)

**What it covers:** All the digital documents that arrive without Luis doing anything — Ryanair confirmations, SaaS invoices, bank statements, subscription renewals.

**How it works:**
- An email rule or forwarding address catches invoices and receipts that arrive by email
- The system recognizes what they are, extracts key data, and files them
- Documents land in the right month's folder, organized by type

**What Luis does:** Nothing, ideally. If the system can't figure out what a document is, it puts it in a "needs review" area. Luis glances at this during his weekly review — it should almost always be empty.

**Document types and where they go:**
- Received invoices (SaaS, flights, hotels) → Expenses / [Year] / [Month]
- Bank statements → Bank / [Year] / [Month]
- Tax documents from gestoría → Tax / [Year] / [Quarter or Model number]
- Corporate documents (Registro Mercantil, contracts) → Corporate / [Type]

---

### Flow 3: Invoice (monthly, laptop)

**When it happens:** End of month. Predictable, recurring.

**The rhythm:**
1. Around the 28th-1st, the system nudges Luis: "Your Lab900 invoice is ready to review."
2. Luis opens it on his laptop. It's pre-filled with:
   - The standard line items and structure from last month
   - Updated hours/amounts (either entered by Luis during the month, or prompted now)
   - Correct sequential invoice number
   - Current date
3. Luis reviews, adjusts if needed, approves.
4. The system generates the invoice PDF, sends it through the compliance layer (VeriFactu via Holded), and delivers it to Lab900.
5. A copy goes into the Issued / [Year] / [Month] folder.

**For the rare non-Lab900 invoice:** Luis creates it from scratch, but the system remembers the client for next time. Same review-and-approve flow.

---

## The weekly pulse

Every Monday morning (or whatever day Luis picks), a brief summary arrives — a message, an email, or a notification. Not a dashboard to visit, it comes to him.

**What it contains:**

- **Money in:** Any payments received this week
- **Money out:** Total expenses captured, broken down roughly (travel, food, subscriptions, other)
- **Needs attention:** Unmatched bank transactions (spent something but no receipt), documents in "needs review", upcoming deadlines (quarterly tax model, cuentas anuales, etc.)
- **Running totals:** Month-to-date income and expenses — just the numbers, no charts

**What it doesn't contain:** Advice, tips, alerts about things that are fine, marketing. Just signal, no noise.

---

## The gestoría interface

**Philosophy:** The gestoría doesn't use the app. They access a shared folder that's always organized and current. They already know how to work with folders — it's the universal interface.

**Folder structure:**

```
[SLU Name] /
├── Issued /
│   └── 2026 /
│       ├── 01-January /
│       ├── 02-February /
│       └── ...
├── Expenses /
│   └── 2026 /
│       ├── 01-January /
│       ├── 02-February /
│       └── ...
├── Bank /
│   └── 2026 /
│       ├── 01-January /
│       └── ...
├── Tax /
│   └── 2026 /
│       ├── Q1 /
│       ├── Q2 /
│       └── ...
├── Corporate /
│   ├── Constitución /
│   ├── Registro Mercantil /
│   ├── Contracts /
│   └── Certificates /
├── Payroll /
│   └── 2026 /
│       └── ...
└── _Needs Review /
```

**Naming convention for files:**
`[YYYY-MM-DD]_[vendor-or-description]_[amount].[ext]`

Example: `2026-05-08_restaurant-le-pain-quotidien_23.50.pdf`

**What the gestoría gets:**
- All receipts already certified (legal digital copies)
- All issued invoices with VeriFactu confirmation
- Bank statements filed monthly
- Everything they need to do quarterly declarations and annual accounts without asking Luis for a single document

**What the gestoría can do (later, optionally):**
- Drop filed tax models back into the Tax folder
- Flag items by renaming or moving to a subfolder
- Add notes via a simple text file if needed

---

## The compliance layer (hidden)

Luis never sees this. It just works.

**Issued invoices:**
- Every invoice goes through VeriFactu (via Holded's integration)
- Hash chain, QR code, AEAT submission — all automatic
- Holded holds the Declaración Responsable as the software producer
- Confirmation stored alongside the invoice

**Received paper receipts:**
- Certified digitization via Holded's AEAT-homologated process
- Original photo + certified PDF stored together
- Paper can be destroyed after capture

**Received digital documents:**
- Stored in original format (PDF as PDF, not re-rendered)
- Integrity hash computed at ingestion
- No modification allowed after filing

**Retention:**
- Nothing is ever deleted automatically
- System maintains documents for the legally required periods (6 years commercial, 4 years tax minimum, 10 years if carrying forward losses)
- After retention period, system flags for optional cleanup — human decides

---

## What the system is NOT

- **Not an accounting tool.** It doesn't do double-entry bookkeeping. Holded handles that, and the gestoría manages it.
- **Not a tax advisor.** It doesn't decide what's deductible. It captures everything; the gestoría classifies.
- **Not a bank.** It doesn't move money. It just watches what moves and matches it to documents.
- **Not a project manager.** It doesn't track hours (unless Luis wants to add that later for invoice prep). For now, Luis knows his hours.

---

## Implementation notes (for the builder)

These are flexible — the specific tools can change, but the roles they play shouldn't.

| Role | Current best candidate | Why |
|---|---|---|
| Invoicing + VeriFactu + certified digitization | Holded (paid plan with API) | Single tool, AEAT-homologated, REST API, handles compliance |
| VeriFactu submission (if not Holded) | Verifacti API | Lightweight, JSON in / QR out, own Declaración Responsable |
| Bank transaction sync | Holded's bank connection | Auto-imports transactions for matching |
| Shared folder for gestoría | Any file sync service | Must support shared access, versioning, and work on laptop + phone |
| Weekly pulse delivery | Email or messaging | Comes to Luis, he doesn't go to it |
| Phone capture interface | Holded mobile app (or custom) | Must support camera → OCR → certified digitization in one flow |
| Monthly invoice drafting | Holded API + custom logic | Pull last month's invoice, update amounts, present for review |

**The custom layer (what Claude Code builds):**
- The glue between Holded's API and Luis's preferred surfaces (weekly email, invoice review page, forwarding rules)
- The folder sync logic that keeps the shared folder structure always current
- The email-to-filing pipeline for incoming digital documents  
- The monthly invoice preparation logic
- The weekly summary generator
- The "needs review" detection (unmatched transactions, unfiled docs)

**What doesn't need to be custom:**
- VeriFactu compliance (Holded does this)
- Certified digitization (Holded does this)
- Bank sync (Holded does this)
- Accounting entries (Holded + gestoría do this)

---

## Success criteria

The system is working when:

1. Luis never loses a receipt again
2. The gestoría never asks Luis for a document — they find it in the folder
3. Monthly invoicing takes under 5 minutes
4. Luis knows his rough financial position every week without opening anything
5. An AEAT inspection would find every document, in original format, within minutes
6. Luis thinks about the system less than once a day