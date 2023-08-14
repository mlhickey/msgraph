function Get-MSPIMDirectoryRole
{
    <#
    .SYNOPSIS
    Get current PIM role list

    .DESCRIPTION
    The Get-MSPIMDirectoryRole cmdlet returns the current list of roles that are supported by the Azure PIM service

    .EXAMPLE
    Get-MSPIMDirectoryRole

    id                                   name
    --                                   ----
    0964bb5e-9bdb-4d7b-ac29-58e794862a40 Search Administrator
    0f971eea-41eb-4569-a71e-57bb8a3eff1e B2C User Flow Attribute Administrator
    .
    .
    .
    .LINK
    https://docs.microsoft.com/en-us/graph/api/privilegedrole-list?view=graph-rest-beta&tabs=cs

    #>
    [CmdletBinding()]
    param()

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
    }

    process
    {
        $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "privilegedAccess/aadroles/resources/$($MSGAuthInfo.TenantId)/roleDefinitions" -ObjectName 'MSPIM'
        if ($null -ne $res -and $res.StatusCode -lt 300)
        {
            $res | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, 'MSPIM.privilegedAccess.directoryRoles') }
        }
        $res
    }
}
