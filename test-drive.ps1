Remove-Module msgraph -ErrorAction SilentlyContinue
Import-Module msgraph
Disconnect-MSG
Connect-MSG
Get-MSGServicePrincipal -All -Properties id, AppId, DisplayName, customSecurityAttributes, appOwnerOrganizationId -AdvancedQuery
