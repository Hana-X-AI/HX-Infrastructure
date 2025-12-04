# CRITICAL PostgreSQL Configuration for hx-lang-server

⚠️ **READ THIS FIRST** - Critical configuration parameters that MUST be correct

---

## Critical Connection Parameters (Task 035)

```python
# These parameters are REQUIRED for langgraph-checkpoint-postgres
# Application will FAIL without them

connection_kwargs = {
    "autocommit": True,      # CRITICAL: Checkpoint commits fail without this
    "row_factory": dict_row, # CRITICAL: KeyError exceptions without this
}
```

### Why These Are Critical

**autocommit = True**
- **What it does**: Automatically commits every SQL statement immediately
- **Why required**: langgraph-checkpoint-postgres expects autocommit mode for checkpoint management
- **Without it**: Checkpoint data not persisted to database (DATA LOSS)
- **Symptoms**: Service restarts lose all conversation history and agent state

**row_factory = dict_row**
- **What it does**: Returns database rows as dictionaries (not tuples)
- **Why required**: langgraph-checkpoint-postgres accesses columns by name (dict keys)
- **Without it**: Application crashes with KeyError when trying to access columns
- **Symptoms**: `KeyError: 'thread_id'` or similar exceptions on checkpoint save/load

---

## Database Configuration

**Server:** hx-postgres-server.hx.dev.local (port 5432)
**Database:** hx_lang_server
**User:** hx_lang_server
**Schema:** langgraph
**Authentication:** SCRAM-SHA-256

**Connection Limits:**
- User: 20 connections
- Database: 50 connections

---

## Verification Checklist

Before starting LangGraph agent implementation (Work Stream 6), verify:

```bash
# 1. Connection test (Task 035)
python /opt/hx-lang-server/test_db_connection.py
# Must pass all 6 checks

# 2. Checkpoint initialization test (Task 036)
python /opt/hx-lang-server/test_checkpoint_init.py
# Must pass all 5 checks
```

---

## Quick Troubleshooting

**Problem:** Checkpoint data not persisted after service restart
**Cause:** autocommit=False (or not set)
**Fix:** Verify connection parameters in `/opt/hx-lang-server/app/config/db_config.py`

**Problem:** KeyError: 'thread_id' when saving checkpoints
**Cause:** row_factory not set to dict_row (returns tuples by default)
**Fix:** Verify row_factory=dict_row in connection parameters

**Problem:** Connection refused from hx-lang-server.hx.dev.local
**Cause:** pg_hba.conf not configured or IP address incorrect
**Fix:** Check `/etc/postgresql/16/main/pg_hba.conf` has entry for 192.168.10.226/32

**Problem:** Authentication failed for user hx_lang_server
**Cause:** Password incorrect or not loaded from Ansible Vault
**Fix:** Verify POSTGRES_PASSWORD in `/opt/hx-lang-server/.env`

---

## Reference Documents

**Task Files:**
- Task 031: Database creation
- Task 032: User provisioning
- Task 033: pg_hba.conf configuration
- Task 034: Schema creation
- Task 035: **Connection parameters (CRITICAL)** ⚠️
- Task 036: Checkpoint table verification

**Specification:** `/nodes/hx-lang-server/specification/node-spec.md` Section "PostgreSQL Checkpoint Configuration"

---

**Created by:** Trinity Smith (PostgreSQL DBA)
**Date:** 2025-12-04
**Last Updated:** 2025-12-04
