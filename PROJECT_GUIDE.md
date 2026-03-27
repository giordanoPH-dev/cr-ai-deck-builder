# Project Setup & UI Implementation Guide

This guide explains how to set up the Clash Royale AI Deck Builder and documents the UI features implemented for AI coaching and monetization.

## 1. Environment Configuration

To enable AI and API features, create a `.env` file in the root directory with the following keys:

- **CLASH_ROYALE_API_KEY**: Obtain this from the [Clash Royale Developer Portal](https://developer.clashroyale.com/). Ensure your IP is whitelisted.
- **GEMINI_API_KEY**: Obtain this from [Google AI Studio](https://aistudio.google.com/). Used for generating strategic insights.
- **ADMOB_APP_ID**: (Optional/Prod) For production, use your AdMob App ID. Development uses Google's test IDs by default.

## 2. UI Implementation Steps

### Search Screen
- **Help Section**: Added a "Where is my Tag?" guided expansion tile to assist users in finding their player tag within the Clash Royale app.
- **Policy Compliance**: A mandatory unofficiality disclaimer is pinned to the footer to comply with Supercell's Fan Content Policy.

### Profile Screen (AI Coaching)
The AI Coaching section was designed as a premium feature locked behind a rewarded ad.

1.  **Archetype Selection**: Before analysis, users can select their preferred playstyle (e.g., Beatdown, Control, Cycle, Siege, or Splash).
2.  **Monetization Flow**:
    - Clicking "WATCH AD TO UNLOCK" triggers a Rewarded Ad via the `AdService`.
    - Once the user earns the reward, the `AiService` is called with the player's profile and battle data.
3.  **Elite Strategy Report**:
    - Generates a personalized report focusing on the selected archetype.
    - Prioritizes the user's highest-level cards.
    - Provides a "How to Play" guide (Opening, Defense, Win Condition).
4.  **One-Click Deck Import**:
    - The AI suggests an 8-card deck.
    - A "IMPORT DECK TO CLASH ROYALE" button appears, using deep-linking to launch the official game with the suggested deck.

## 3. Web Compatibility Note
As of the latest update, **Rewarded Ads are skipped on Web/Chrome** platforms to prevent crashes. Users can access AI insights directly after clicking the button when running in the browser.
