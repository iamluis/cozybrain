# 0003 — Capture flow (mobile)

Goal: implement Flow 1 from `brain.md`. Phone-friendly page where Luis snaps a receipt, confirms OCR-prefilled fields, hits save. Server stores image (Active Storage), creates `IncomingDocument` + `Expense`, kicks an enqueued job to push to Holded.

Detail at milestone start.
