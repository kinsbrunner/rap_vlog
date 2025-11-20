# Building a Real RAP Application Step by Step — Vlog Series Introduction

This vlog series aims to demonstrate how to build a real-life ABAP RAP application, following a practical, incremental, and production-oriented approach.

> Disclaimer:
> 
> 
> This series focuses on showcasing how a RAP application can be built incrementally from real functional requirements. The app is intentionally kept practical and educational, rather than exhaustive or fully hardened for production. Some edge cases or potential enhancements are intentionally not covered.
> 
> The purpose of the vlog is to share knowledge, demonstrate real development workflows, and contribute to the SAP community, not to deliver a fully polished commercial-grade application.
> 

Instead of showing a pre-built demo or isolated RAP examples, the series walks through the development process **from scratch**, implementing the application one requirement at a time,  exactly as it would be done in an actual ABAP Cloud project.

Each episode focuses on a small, well-defined set of user stories, keeping the learning process smooth and allowing you to see how the application grows after every step. The structure ensures the app is testable from the very beginning, and every enhancement is immediately visible in the UI preview.

If you want to understand RAP not just in theory but in practice, including determinations, validations, feature control, actions, semantic keys, and UI configuration, this series is for you.

# What are we going to build?

We’ll be developing an internal equipment request application for a consulting firm.

Employees can request items kept in internal stock (laptops, monitors, headsets, etc.).

Each request follows a simple lifecycle:

- Not Prepared / In Preparation / Delivered / *(later also Cancelled)*

Each request includes header data (requester, deadline, priority, status, …) and one or more items referencing products from a customizing table of available materials.

The scenario is intentionally simple but rich enough to cover the most important RAP concepts: CDS data modeling, RAP behavior definitions in managed scenarios, Semantic keys, Determinations & validations, UI annotations, Feature control, Prechecks, Popup actions, Value helps, Inline editing, Integration with customizing tables, ABAP Cloud–compliant development practices. 

# Full requirement backlog (User Stories)

Below is the collection of user stories implemented throughout the series, listed in the exact order used for development: 

**US-01: Basic** request **object:** As an employee, I want to create internal equipment requests so that I can receive the products I need.

**US-02: Search and Filter capabilities:** As a user, I want to search requests using structured filters so that I can quickly locate relevant orders.

**US-03: Sequential External ID and semantic key:** As the system, I want to assign each request a sequential external number so that users can reference meaningful IDs.

**US-04: Mandatory fields:** As a user, I want the system to require Requester and Deadline so that requests are always complete.

**US-05: Deadline validation:** As the system, I want to validate that the deadline is at least one day in the future so that operations can prepare on time.

**US-06: Automatic priority determination:** As the system, I want priority to be set based on deadline so that urgent requests receive proper attention.

**US-07: Status icons:** As a user, I want statuses displayed with colored icons so that I can understand them at a glance.

**US-08: Cancel status restrictions:** As a user, I want to search for cancelled requests but not manually set status as “Cancelled” so that lifecycle rules are respected.

**US-09: Default status:** As the system, I want new requests to default to “In Preparation” so that the lifecycle begins correctly.

**US-10: Status editability rules:** As a user, I want status to be editable only after creation so that inconsistencies are avoided.

**US-11: Cancel action:** As a user, I want to cancel one or more requests from the list so that I can invalidate unnecessary requests.

**US-12: Cancellation popup:** As a user, I want to cancel and justify cancellations through a popup so that the system enforces to have reasons registered.

**US-13: Cancel reason rules:** As a user, I want “Cancellation Reason” to be editable only when status is “Cancelled” so that it appears only when relevant.

**US-14: No editing after cancellation:** As the system, I want cancelled requests to become read-only so that historical data is kept intact.

**US-15: Product catalog restriction:** As a user, I want to select products only from internal stock so that I request only available items.

**US-16: Product value help:** As a user, I want a value help showing only available products so that selection is efficient.

**US-17: Unique product per request:** As a system, I want to prevent duplicate products within a request so that items remain consistent.

**US-18: Item creation via popup:** As a user, I want to create items in a popup and edit them inline so that maintenance is fast and intuitive.
