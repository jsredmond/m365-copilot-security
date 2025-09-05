# Correlating Copilot use with insider risk

- **Signals to correlate**
  - Copilot interactions that were blocked by DLP
  - Large downloads or unusual file access following AI prompts
  - New guest invitations or new OAuth grants
  - USB or print events from endpoints (via MDE)

- **Investigation flow**
  1. Start from a DLP incident. Identify the user, label involved, and source site.
  2. Pull audit for the same user within +/- 24 hours. Look for spikes in access volume.
  3. Check device posture and session controls. If unmanaged, validate CA policy coverage.
  4. Escalate to Insider Risk case if multiple exfiltration indicators stack up.

- **Outcome**
  - Triage false positives
  - Coach users on safer prompts
  - Tune label scope or DLP threshold
