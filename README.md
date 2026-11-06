# Governor of Poker 2 bot (offline single-player mod)

A mod for the **offline, single-player** game *Governor of Poker 2*. It plays your seat automatically.
It is a cheat by design: it reads opponents' hole cards and the upcoming board, and stacks the deck so
your seat gets the winning hand. Do not use it anywhere online.

This repo contains only my own code. It does **not** include any game files or decompiled game code.

## How it works
The game loads `GraphicsAssets.swf` at startup; that AS2 SWF shares the game's globals. `build.ps1`
appends the bot to its frame-3 script. The bot then:

- wraps `pokerViewBase.askUsersAction` (the "ask the human" call) and answers with the game's own
  `processPlayerAction` (fold / check / call / raise);
- wraps `resetDeck` / `spliceRandomCard`: shuffle once per hand, deal in order, and stack the deck
  (`GB.stack`) so the user's seat has the best 7-card hand;
- reads every active opponent's hole cards and the not-yet-dealt board, then settles the hand exactly;
- sizes bets from the opponents' visible hand strength (small if all weak, ~pot if one is strong).

A yellow line top-left shows what the bot sees (`SEES FUTURE` / `EXACT` / `GUESS`).

## Build and install
Needs [JPEXS FFDec](https://github.com/jindrapetrik/jpexs-decompiler) and Java.

    .\build.ps1 -GameDir "D:\OfflineGames\Governor.of.Poker.2" -Install

The untouched original is kept as `GraphicsAssets.swf.orig`; copy it back over `GraphicsAssets.swf` to undo.

## Tests
Hand evaluator, equity, decision rules and the deck stacker (20k simulated tables):

    node test/test.js

## Status
Tested in Node only; not yet verified across full in-game tables. Achievement automation is not implemented.
