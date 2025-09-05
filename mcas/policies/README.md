# Defender for Cloud Apps session controls for Copilot scenarios

Recommended policies to create in MCAS:
1. **Session control for sensitive SharePoint sites**
   - Block download and cut/copy for labeled content when device is unmanaged.
2. **Activity policy: excessive copy/paste**
   - Alert when a user copies large volumes of data from SharePoint web sessions.
3. **OAuth app policy**
   - Alert on new apps requesting Files.ReadWrite.All or Sites.FullControl.All scopes.

Document policy names and intended outcomes here for your environment.
