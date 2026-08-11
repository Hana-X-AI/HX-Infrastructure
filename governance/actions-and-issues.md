# actions and issues

Use this single log for project action items and issues.

## types

- `action` — work that must be completed.
- `issue` — a known problem, unresolved behavior, defect, or technical constraint.

## status values

`open` · `in progress` · `investigating` · `blocked` · `resolved` · `done`

## log

| id | type | item | impact / outcome | owner | status | related | resolution / closeout |
|---|---|---|---|---|---|---|---|
| act-001 | action | Establish persistent router-side `hx.local.arpa` DNS records for approved server-managed static IP addresses. Record each approved address in `SERVER-REGISTRY.md`, configure static addressing on the Ubuntu server, and use ASUSWRT only for persistent name resolution. DHCP reservations remain out of scope for the primary LAN. The solution must survive router reboot, dnsmasq restart, and ASUSWRT configuration apply. | Persistent local server naming and address management. | hx infrastructure | open | iss-001 | |
| iss-001 | issue | Stock ASUSWRT regenerates `/etc/dnsmasq.conf` and `/etc/hosts`, so direct edits cannot currently be relied upon for persistent `hx.local.arpa` server DNS records. | Persistent server DNS mechanism is not yet established. | hx infrastructure | open | act-001 | |
