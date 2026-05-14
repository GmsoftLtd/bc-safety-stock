# BC Safety Stock Calculator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Business Central](https://img.shields.io/badge/BC-v27+-blue.svg)](https://learn.microsoft.com/en-us/dynamics365/business-central/)

A free, MIT-licensed Business Central extension that calculates **Safety Stock** using the Z-score method, accounting for both demand variability and lead time variability.

**Companion blog post:** [Safety Stock in Business Central — Theory + Code](https://insidebusinesscentral.com/safety-stock-business-central-calculator/)

---

## What it does

Most BC implementations leave `Item."Safety Stock Quantity"` set to zero, or worse — set it manually with a number the planner remembered from a training course years ago. This extension computes the value properly using **statistics**, based on each item's actual demand pattern and supplier lead time history.

The formula:

```
Safety Stock = Z × √( LT × σ²demand  +  D² × σ²LT )
```

Where:
- **Z** = service level Z-score (1.65 for 95%, 1.96 for 97.5%, 2.33 for 99%)
- **LT** = average lead time in days
- **σdemand** = standard deviation of daily demand
- **D** = average daily demand
- **σLT** = standard deviation of lead time

## Features

- **Item Card action** — *Calculate Safety Stock (Sales-Based)* — calculate for one item, see the result code + reason, choose to apply
- **Item List bulk action** — *Calculate Safety Stock (Bulk, Sales-Based)* — process all filtered/selected items in one run, with a heads-up if any aren't purchase-replenished
- **Job Queue codeunit** — schedule recurring recalculation (weekly, monthly)
- **Calculation log** — every run is logged for traceability (item, datetime, user, z-score, stddev values, result code, plain-English reason)
- **Setup page** — service level, history window, min observations, round behaviour
- **Service levels supported** — 70% to 99.99% (Z-scores hard-coded for accuracy)

## How it works

1. Looks at **Item Ledger Entries** of type `Sale` for the configured history window (default 180 days)
2. Computes mean and standard deviation of daily demand
3. Looks at **Purchase Receipts** for the same item, comparing `Order Date` to `Posting Date` to derive actual lead times
4. Computes mean and stddev of those lead times
5. Applies the full-variance formula above
6. Optionally writes the result to `Item."Safety Stock Quantity"`
7. Logs the calculation to history

If lead time history is missing, falls back to `Item."Lead Time Calculation"` (set on the item card).

## Installation

### From source

1. Clone this repo
2. Open `app.json` and confirm the object ID range doesn't conflict with your tenant (default 50100-50199)
3. In VS Code with AL extension, run **AL: Publish** (Ctrl+F5) to your BC sandbox
4. Or build with `al package` and upload the `.app` file via **Extension Management** in BC admin

### From a packaged .app

Releases (when available) at [Releases page](https://github.com/GmsoftLtd/bc-safety-stock/releases).

## Usage

### Single item

1. Open any Item Card
2. Click **Calculate Safety Stock** (in the Actions tab)
3. Review the calculated value
4. Confirm to apply, or just preview

### Bulk

1. Open the Item List
2. Filter to the items you want (e.g. by Item Category Code)
3. Optionally multi-select specific rows
4. Click **Calculate Safety Stock (Bulk)**
5. Each item is processed and logged

### Job Queue

To schedule monthly recalculation of all FERT items at 99% service level:

1. **Job Queue Entries → New**
2. Object Type to Run: **Codeunit**
3. Object ID: **50101** (Safety Stock Job Queue Run)
4. Parameter String: `FILTER=Item Category Code:FERT;SERVICELEVEL=99`
5. Set the recurring schedule

Without parameters, all inventory items are processed at the setup default service level.

### Sandbox: try it on a clean item

If you want to see real numbers without scrubbing live data:

1. Open any Item Card in a **sandbox** environment
2. Click **Generate Demo Data (Sandbox)** — creates ~6 past Purchase Orders, ~30 past Sales Orders (last 180 days), and 3 future Sales Orders for the current item; all unposted
3. Open **Purchase Orders**, multi-select the new ones, *Post Batch* — builds inventory
4. Open **Sales Orders**, multi-select the new past ones, *Post Batch* — creates demand history
5. Back on the Item Card, click **Calculate Safety Stock (Sales-Based)** — you should now get a non-zero result with a meaningful reason

⚠ This action is for sandbox/test use only — it floods your order tables with synthetic data. Remove the `SafetyStockDemoData.Codeunit.al` file (and the `GenerateSSDemoData` action) before building a production `.app`.

## Configuration

**Safety Stock Setup** page (Search → Safety Stock Setup):

- **Default Service Level %** — default fill rate target (95% recommended)
- **Demand History Window (Days)** — how far back to look (180 = 6 months balanced default)
- **Min Demand Observations** — minimum demand entries needed (skip items below this)
- **Round Up Result** — round to whole units (recommended for piece-count items)
- **Auto-Update Item Field** — write to Item.Safety Stock Quantity automatically
- **Log History** — save every calculation to the log (recommended for audit)

## Limitations

> **This is a sales-based, purchase-replenished tool.** It is intended for items the company **buys and resells**. Manufactured items, sub-assemblies, and BOM components will typically return **0** because their outbound movements post as `Consumption` / `Assembly Consumption` (not `Sale`) and their inbound movements come from production / assembly orders (not `Purch. Rcpt. Line`). A paid manufacturer-aware edition with `Replenishment System` branching is planned — this free edition deliberately keeps the scope narrow.

- **Sales-only demand** — counts Item Ledger Entries of type `Sale`. Doesn't include `Consumption`, `Assembly Consumption`, `Transfer`, or `Negative Adjmt.`
- **Lead time from PO receipts only** — uses purchase receipts (`Order Date` → `Posting Date`). No production-order or assembly-order lead times.
- **Assumes normal distribution** — standard safety-stock theory; breaks down for highly skewed/lumpy demand. For very slow movers, prefer category-based defaults.
- **No seasonality adjustment** — uses a flat average over the history window. For seasonal items, run during the relevant season.
- **No multi-location split** — calculates globally per item. Per-location stockholding logic is up to the user.

## When NOT to use this

- **Manufacturers running production** on the items in scope — the calc will return 0 for components and sub-assemblies. Wait for the paid manufacturer edition or extend `ComputeDemandStats` / `ComputeLeadTimeStats` yourself.
- **Brand-new items** (< minimum demand observations): use a category default instead.
- **Lumpy/intermittent demand**: Z-score method assumes near-normal. Consider Croston's method.
- **Configurable / make-to-order items**: safety stock applies to make-to-stock only.
- **Items with regulatory min stock**: those values come from compliance, not statistics.

## Related

- [Inside Business Central — blog](https://insidebusinesscentral.com)
- [GMSOFT AppSource publisher](https://appsource.microsoft.com/en-us/marketplace/apps?search=GMSOFT)
- Companion deep-dive: [Safety Stock in BC — full theory + code walkthrough](https://insidebusinesscentral.com/safety-stock-business-central-calculator/)

## License

MIT — see [LICENSE](LICENSE).

## Contributions

Issues and pull requests welcome. This is a working calculator, not a fully productised app — improvements are appreciated, especially:

- Croston's method for intermittent demand
- Seasonal adjustment
- Lead time from transfer / production routings
- Per-location calculation
- AppSource-style installer wizard

## Author

**Grigorios Mavrogeorgis** — Director & Founder of [GMSOFT Limited](https://gmsoft.co.uk)
Microsoft Dynamics 365 Business Central Community Super User, Season 1 2026
