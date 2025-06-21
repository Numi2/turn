# Single-Phase Turn System Refactor

## Goal
Unify the player experience so all actions (income, build, move, combat) happen in one fluid phase. The human player performs any combination of actions in any order and then taps **Next Turn**. At that moment the AI resolves its entire turn and control returns to the human.

## Key Changes
1. **Turn Flow**
   • `GameMap.endTurn()` now:
     – Resets action flags for the active player.
     – Switches `currentPlayer`.
     – Calls `collectIncome()` **once** for the incoming player.
     – Sets `turnPhase = .build` so every turn starts ready for actions.

2. **Income Timing**
   • Income is no longer tied to an `.income` phase. It is awarded automatically at the very start of each player's turn.

3. **UI (GameMapView)**
   • Removed phase badge; replaced with dynamic **Your Turn / Opponent Turn** indicator.
   • Combined control buttons into a single panel that is always available during the player's turn.
   • Added prominent **Next Turn** button (disabled when it's not the player's move).

4. **Action Availability**
   • Move / Attack / Build buttons are enabled solely by unit state and `currentPlayer`, not by phase.

5. **Default State Adjustments**
   • Game starts in `.build` phase and immediately calls `collectIncome()` so players have starting resources without any extra taps.
   • Level generator and new-game routines updated accordingly.

6. **AI Compatibility**
   • AI turn now begins in `.build`. Existing AI logic already handles this path, so no behavioural change was required.

## Files Touched
– `Models/GameMap.swift`
– `Views/GameMapView.swift`
– `SinglePlayerGame.swift`
– `Scripts/LevelGenerator.swift`
– `PHASE_MERGE_CHANGELOG.md` (this file)

## Next Steps
• Play-test for balance – houses now generate income immediately.
• Refresh tutorial / onboarding text to reflect simplified turn system.
• Consider subtle animations when AI actions replay after **Next Turn**.