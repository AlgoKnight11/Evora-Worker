# EVORA Field Worker Portal

> **Greener Choices. Healthier Cities.**  
> The mobile-first operational execution interface for municipal staff and approved field contractors under the EVORA Civic Intelligence Platform.

---

## 🛠️ Overview

The **EVORA Field Worker Portal** bridges municipal dispatch and boots-on-the-ground execution. Designed for harsh field conditions and low-connectivity environments, it turns assigned CivicFlow cases and municipal work orders into verifiable, trackable work.

### ✨ Key Capabilities
* **Task Inbox & Team Pools:** Individual task assignments and atomic first-claim team pool dispatch.
* **Offline-First PWA:** Safe local caching via encrypted IndexedDB and deferred command synchronization with server-validated state transitions.
* **Evidence & Verification:** Before/after photo pairing, structured measurements, mandatory task checklists, and citizen acknowledgement.
* **Worker Safety & Escalation:** Immediate out-of-band hazard reporting, emergency dispatch access, and operational block tracking.
* **Supervisor Review Flow:** Strict maker-checker review pipeline before task completion synchronizes with the citizen's CivicFlow grievance.

---

## 🗺️ Implementation Roadmap

The development of this portal is structured into 8 distinct phases as defined in [`phases.md`](./phases.md):

1. **Phase 1: Project Scaffolding & Core Architecture Baseline**
2. **Phase 2: Authentication, Tenant Context & Worker Identity**
3. **Phase 3: Task Inbox, Detail & Assignment Engine**
4. **Phase 4: Field Execution, Safety & Incident Engine**
5. **Phase 5: Evidence Capture, Checklists & Acknowledgements**
6. **Phase 6: Offline-First Queue, OPFS & Sync Engine**
7. **Phase 7: Supervisor Review Flow, History & Notifications**
8. **Phase 8: Security Hardening, E2E Testing & Pilot Readiness**

For detailed breakdowns, deliverables, state machines, and exit criteria, see [**`phases.md`**](./phases.md).

---

## 🔒 Security & Data Principles
* **Multi-Tenant Scoping:** All operations are strictly authorized within `tenants/{tenantId}/`.
* **Zero Citizen Data Leakage:** Citizen contact numbers, emails, home addresses, and private notes are masked from field workers.
* **Maker-Checker Validation:** A worker's completion submission never directly marks a citizen grievance `RESOLVED`; authoritative closure requires supervisor approval.
