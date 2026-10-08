# Total Solution: field-user usability review

**Review date:** 6 October 2026  
**Basis:** Static review of the active Flutter login route and dashboards, plus relevant backend routes. This is a design and code review, not an observed test with field staff or a running device. The separate dashboard files are not the dashboards opened by the active login flow. No `.env` values were inspected.

## Verdict

The app has the main business functions a field team needs, but the current field experience is **too complicated for a first-time user**. A person who already understands bills, series, loads, and the company's process can learn it. A new salesperson, collection worker, or delivery worker will need training, especially for payments and delivery. This is a usability assessment, not a judgment about anyone's education.

The highest-value change is to give each worker a **Today** screen with only their assigned tasks and one clear next action per customer. Keep the underlying functions; reveal advanced fields only when needed.

## What is already useful

| Feature | Why it helps | Keep / refine |
|---|---|---|
| Role-based sign-in and remembered session | Avoids repeated login; distributors and salesmen reach different dashboards. | Keep the session behavior. Simplify the sign-in page. |
| New order flow with customer, products, review, confirmation | Clear general sequence and a chance to check before submitting. | Keep the sequence; use larger text and fewer details per step. |
| Searchable customers and products | Reduces scrolling when lists grow. | Keep; prioritize name and phone in search. |
| Outstanding balance shown on bill cards | Helps collection workers identify what is due. | Keep; make customer name more prominent than bill codes. |
| Cash, UPI, cheque, and mixed payment support | Covers real collection situations. | Keep; show method-specific details only after selection. |
| Payment proof by camera/gallery | Useful for disputed transactions. | Keep, with a clear policy for when proof is required. |
| Delivery route and navigation | Useful for multiple stops. | Keep, with a list fallback when map or location fails. |
| Collect at delivery and mark delivered | Matches a real doorstep workflow. | Keep the actions together on one stop screen. |
| Distributor control of products, customers, salesmen, orders, and loads | Gives the office the tools to prepare field work. | Keep these controls out of the field worker's primary navigation. |

## Role-by-role experience

| Worker | Current path | Main difficulty | Better daily path |
|---|---|---|---|
| Salesperson | Dashboard → New Order → customer → products → review → confirm | Dashboard exposes unrelated collection/delivery tools; product/order screens use small text and dense detail. | Today → Visit customer → Add products → Review and send. |
| Collection worker | Dashboard or menu → Payments → history/outstanding → bill → long payment dialog | Payments tab initially opens history, not collection. Search ignores customer name. Multiple totals and optional fields add reading and scrolling. | Today → Customer due → Enter amount → Choose method → Review → Saved receipt. |
| Delivery worker | Load Delivery → Sync Data → Filter → series/load number → Start → route/stop → complete | The required sequence is not obvious. The screen has tiny labels and several summaries before the next stop. Missing customer coordinates block completion. | Today → Assigned load → Start route → Next stop → Delivered / Could not deliver. |

## Issues to fix, in order

| Priority | Issue and evidence | Effect on field worker | Recommended change |
|---|---|---|---|
| **P0** | Delivery completion rejects a bill with no valid store coordinates and rejects users outside a location radius (`login_screen.dart`, `_markDeliveryCompleted`, around lines 27597–27644). | A genuine delivery can remain open when office data is missing or GPS is inaccurate. | Offer an exception path with reason, timestamp, photo/signature if policy requires, and supervisor review. Keep the normal GPS check. |
| **P0** | The Payments bottom tab resets to history; Collect Payment in the side menu opens a separate subtab (around 18985–18995, 21023–21045, 31534–31573). | A collection worker may think the payment function is missing. | Label bottom tab **Collect**, open outstanding bills directly, and put **History** as a separate secondary control. |
| **P1** | Field users share one broad Salesman dashboard with orders, payments, delivery, customers, products, and history (around 18883–18936 and 20721–20806). | Too many choices for someone who performs one job. | Use assigned work type or permission-based home actions: Sell, Collect, Deliver. Show only relevant tasks first; keep other permitted tools under More. |
| **P1** | The collection dialog is long and scrollable, with repeated balance information, four modes, proof, remarks, and many conditional fields (around 15666–16265). | Slow entry and higher chance of wrong amount or missed fields. | Use a full screen, large amount field, three primary modes, a live remaining balance, then a review screen. Put Cash + Cheque under **More methods**. Show only fields required by the chosen method. |
| **P1** | Outstanding search matches series, bill number, amount, and balance, but not customer name (around 30985–30999). | Staff commonly remember the shop, not the bill number. | Search by customer name, phone, shop code, and bill number. Show shop name first in results. |
| **P1** | Delivery start asks users to sync, open a control labelled **Filter**, select a series, type a load number, then start (around 27915–28013, 28125–28137). | Users must know office codes and the hidden sequence. | Show **Assigned loads** as cards with a large **Start delivery** button. Rename sync to **Refresh** and display last refreshed time. |
| **P1** | Delivery screen uses 8–11 px text in the load chip and progress area (around 28230–28246, 28289–28298, 28357–28366); order confirmation has 9–10 px detail text (around 26218–26245). | Hard to read outdoors and on small phones. | Use at least ~16 px for body copy, 14 px only for secondary text, and touch targets around 48 px. Check text scaling. |
| **P1** | There is no clear offline save-and-later-sync workflow in the active order, payment, or delivery UI. “Sync Data” appears as a manual action (around 21766–21767, 26976–26977, 28125–28130). | Weak connectivity can interrupt work without a visible pending state. | Add explicit **Saved on this phone / Waiting to send / Sent** states and prevent duplicate submissions. Verify the backend contract before promising offline use. |
| **P2** | Bottom navigation **More** selects the Customers screen (around 21023–21045 and 19023–19033). | Label and destination disagree. | Make More open a simple menu, or rename it **Customers**. |
| **P2** | Login shows a role selector, but login sends only email/password and follows the server-returned role (around 32791–32866 and 32285–32335). | Tapping Salesman may seem necessary but does not choose the login role. | Remove the selector from sign-in. Retain it only where role is genuinely selected during registration. |
| **P2** | “Remember me” is rendered as a checked visual row, with no user toggle (around 33008–33040). “Contact Admin” opens the registration toggle (around 33140–33169). | Controls promise different behavior from what they do. | Replace with truthful labels: **Stay signed in** if configurable, and **Create account** or an actual admin contact action. |
| **P2** | The Create Order action in the bottom bar is a lone plus icon, and the four-step flow has some 10–12 px text (around 18522–18531, 23791–23801, 23842–23909). | The most important action may be unclear or hard to read. | Add a visible **New order** label and increase text sizes. Keep one primary action per step. |

## Screen changes

1. **Collect Payment: redesign first.** See [`collect-payment-simple.png`](collect-payment-simple.png). The concept shows a full screen for one bill, with amount and payment method visible immediately. A second review step should show customer, bill, amount, method, remaining balance, and the final **Save payment** button. The mockup is a design proposal; it is not implemented in Flutter.
2. **Delivery Today:** show assigned load, count of stops left, and the next customer. Make **Navigate**, **Call**, **Collect**, **Delivered**, and **Could not deliver** clear actions. Move distance and estimated time below the next stop.
3. **Sales Today:** show visits/customers and one **New order** action. Hide charts and management information behind a secondary view.
4. **Login:** email, password, sign in, and one truthful help link. The backend decides the role after login.
5. **Distributor:** keep the richer management tools, but group the long menu into Customers & Products, Team, Orders & Payments, and Imports & Loads.

## Practical acceptance checks before calling it “simple”

- Give a new worker a demo account and ask them to place one order, collect one partial payment, and complete one delivery **without coaching**. Observe where they pause or choose the wrong action.
- Test on a small Android phone, outdoors, with larger system text. Every primary action should remain visible and readable.
- Test no network, slow network, duplicate taps, wrong amount, wrong payment mode, missing customer coordinates, and denied GPS permission. The worker should always see what was saved and what needs help.
- Measure task completion, wrong entries, and time to finish. Use these results to refine labels and screens.

**Overall:** Strong feature coverage, moderate usability for an experienced user, and high complexity for a new field worker. Simplify navigation and the collection/delivery journeys before adding more features.
