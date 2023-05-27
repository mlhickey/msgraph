Remove-Module msgraph -ErrorAction SilentlyContinue
Import-Module msgraph
Disconnect-MSG
Connect-MSG
Get-MSPIMGroup -Filter "startsWith(displayName,'DSR')"
Get-MSGUserDirectReport -Id sdabbiru@microsoft.com
$staledate = (Get-Date).AddDays(-180).ToString('yyyy-MM-ddTHH:mm:ssZ')
Get-MSGUser -Filter "signInActivity/lastSignInDateTime le $staledate" -Properties id, userprincipalname, usertype -All | Export-Csv staleusers.csv -NoTypeInformation
Get-MSPIMGroupRoleAssignment -Id 58907b57-562e-4045-a5de-9b9770157f34
Get-MSGServicePrincipal -All -Properties id, AppId, DisplayName, customSecurityAttributes, appOwnerOrganizationId -AdvancedQuery
