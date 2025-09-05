# Shadow IT discovery checklist for Copilot readiness

1. **Inventory OAuth grants**
   - In Entra admin center, review Enterprise applications > User consent and admin consent settings.
   - Export service principal OAuth grants. Flag apps with high-risk scopes (Files.ReadWrite.All, Sites.FullControl.All, MailboxSettings.ReadWrite).

2. **Defender for Cloud Apps (MCAS)**
   - Enable Cloud Discovery and upload firewall/proxy logs.
   - Identify unsanctioned apps with file-sharing capabilities. Tag sanctioned vs unsanctioned, and create policies for uploads from unmanaged devices.

3. **User education**
   - Publish guidance on approved AI and collaboration tools.
   - Explain why unsanctioned tools increase data exposure risk when Copilot is enabled.

4. **Remediation**
   - Remove risky OAuth grants, block unsanctioned apps, and document approved alternatives.
