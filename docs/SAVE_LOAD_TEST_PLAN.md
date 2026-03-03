# Save/Load Integration Test Plan

**Created by:** PM Agent (pm-5)  
**Purpose:** Verify DataStore persistence round-trip for all persisted features across agents.

---

## Persisted Schema (TrainerData)

| Field | Agent | Test Focus |
|-------|-------|------------|
| `party` | Battle, Data | Brainrot instances with level, exp, hp, moves, statusEffect, heldItemId |
| `collection` | Data, Menu | PC box brainrots, release cleanup |
| `activeIndex` | Menu | Leader selection survives rejoin |
| `bag` | Data, Menu | Item quantities, item IDs |
| `stats` | Battle, Data | totalCaught, battlesWon, battlesLost, totalReleased |
| `dexSeen` | Battle, Content | Seen brainrot IDs |
| `dexCaught` | Battle, Content | Caught brainrot IDs |
| `settings` | Menu, Data | musicEnabled, sfxEnabled, cameraSensitivity |

---

## Test Cases

### TC-1: Party persistence
1. Join game, receive starter brainrot
2. Catch 1–2 more brainrots (add to party)
3. Level up a brainrot in battle
4. Apply status effect (poison/burn) to a party member
5. Assign held item to a party member
6. Leave game (PlayerRemoving triggers save)
7. Rejoin
8. **Verify:** Party has same brainrots, levels, exp, hp, status, held items

### TC-2: Collection (PC) persistence
1. Catch brainrot, store to PC via menu
2. Release one brainrot from PC
3. Leave and rejoin
4. **Verify:** PC has correct brainrots; released one is gone; stats.totalReleased incremented

### TC-3: Bag persistence
1. Acquire items (catch reward, pickup, spawn)
2. Use item in battle (reduce quantity)
3. Leave and rejoin
4. **Verify:** Bag quantities match; used items reduced correctly

### TC-4: Settings persistence
1. Change Music Off, SFX Off, Camera Sensitivity to 0.5
2. Leave and rejoin
3. **Verify:** Settings match; Menu Settings tab reflects values

### TC-5: Dex persistence
1. See and catch several brainrots
2. Leave and rejoin
3. **Verify:** dexSeen and dexCaught match; Troppi-dex shows correct Seen/Caught

### TC-6: Leader index persistence
1. Change leader via Brainrots tab
2. Leave and rejoin
3. **Verify:** Same brainrot is leader (activeIndex correct)

### TC-7: Migration (schema change)
1. Load save from older schemaVersion (if test data exists)
2. **Verify:** migrateTrainerData adds defaults for new fields; no errors

### TC-8: Auto-save
1. Play for 5+ minutes (auto-save interval)
2. Force-quit or disconnect without normal leave
3. Rejoin
4. **Verify:** Recent progress (catches, levels, items) is preserved

---

## Execution Notes

- **DataStore:** Uses `TrainerData_v1`; key = `Player_{UserId}`
- **Save triggers:** PlayerRemoving, auto-save every 300s
- **Load trigger:** PlayerAdded; starter data only if no save or empty party
- **Assign to:** Data Storage agent for TC-1–TC-8; Menu UI for TC-4, TC-6; Battle Systems for TC-1, TC-3

---

## Sign-off

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC-1 | ⬜ Pending | |
| TC-2 | ⬜ Pending | |
| TC-3 | ⬜ Pending | |
| TC-4 | ⬜ Pending | |
| TC-5 | ⬜ Pending | |
| TC-6 | ⬜ Pending | |
| TC-7 | ⬜ Pending | |
| TC-8 | ⬜ Pending | |
