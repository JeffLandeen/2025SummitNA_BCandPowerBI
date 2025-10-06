# Copilot Instructions for BC to Power BI Connector

## Project Overview
This project is a Microsoft Dynamics 365 Business Central (BC) extension that exposes purchase order and KPI data for reporting in Power BI. It automates test data generation, tracks key dates, and synchronizes custom fields across related tables for analytics.

## Architecture & Key Components
- **Codeunits** (`src/Codeunit/`):
  - `Cod59500.CreateTestPOs.al`: Automates creation, posting, and updating of test purchase orders, receipts, and invoices.
  - `Cod59501.POKPIandPowerBISubscribers.al`: Event subscribers to update custom fields on BC posting events.
- **Table Extensions** (`src/TableExtension/`):
  - Adds fields like `Test Purchase Order`, `Target Receipt Date`, `First Receipt Date`, and `Receipt Delay` to purchase-related tables for KPI tracking.
- **Page Extensions** (`src/PageExtension/`):
  - Surfaces custom fields and actions in the BC UI, e.g., buttons to generate test POs.

## Data Flow & Patterns
- Test POs are generated with random vendors/items, then posted through receipts and invoices.
- Custom fields are propagated across header/line tables and updated via event subscribers.
- `Receipt Delay` is calculated as the difference between `Target Receipt Date` and `First Receipt Date`.
- All custom fields are non-editable and set programmatically.

## Developer Workflows
- **Build/Deploy**: Use standard AL extension packaging and deployment for BC. No custom build scripts detected.
- **Testing**: Test data is generated via UI actions (see `PurchOrderList Ext` page extension). No automated test suite present.
- **Debugging**: Enable debugging in BC as per standard AL extension practices. Source is exposed for debugging (see `app.json`).

## Conventions & Patterns
- All custom fields use IDs in the 59500+ range (see `app.json` idRanges).
- Event subscribers are used for cross-table updates, not direct triggers.
- UI actions are added before standard posting actions for discoverability.
- DataClassification is set for all custom fields.

## Integration Points
- Power BI connects via exposed queries (not present in current codebase, but referenced in `app.json`).
- No external dependencies or custom libraries detected.

## Key Files
- `src/Codeunit/Cod59500.CreateTestPOs.al`: Test PO logic
- `src/Codeunit/Cod59501.POKPIandPowerBISubscribers.al`: Event-driven field updates
- `src/TableExtension/Tab-Ext59500.PurchHeaderExtension.al`: KPI field definitions
- `src/PageExtension/Pag-Ext59501.PurchOrderListExt.al`: UI actions for test data

## Example: Generating Test Data
- Use the "Generate Test Purchase Orders" or "Generate & Post Test POs" actions in the Purchase Order List page to create and post test data for Power BI reporting.

---

**Feedback requested:** Are any workflows, integration points, or conventions unclear or missing? Please specify for further refinement.