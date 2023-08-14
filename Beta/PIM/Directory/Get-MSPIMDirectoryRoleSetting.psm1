function Get-MSPIMDirectoryRoleSetting
{
    <#
    .SYNOPSIS
    Get current settings for a PIM role

    .DESCRIPTION
    The Get-MSPIMDirectoryRoleSetting cmdlet returns settings of the specified role

    .PARAMETER RoleName
    Specifies the particular Azure role name to query.

    .PARAMETER RoleId
    Specifies the particular Azure role id to query.

    .EXAMPLE
    Get-MSPIMDirectoryRoleSetting -RoleName 'Global Readers'

    Id                                   RoleName       ElevationDuration MfaOnElevation
    --                                   --------       ----------------- --------------
    a91344fb-8607-4b4d-968c-28a27329428c Global Readers 01:00:00          True

    .LINK
    https://docs.microsoft.com/en-us/graph/api/privilegedrolesettings-get?view=graph-rest-beta&tabs=cs

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(DefaultParameterSetName = 'all')]
    param(
        [Parameter(ParameterSetName = 'RoleId',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GUID of PIM role to enable')]
        [Alias('RoleDefinitionId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$RoleID,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All',
            HelpMessage = 'Return all role assignments')]
        [switch]$All
    )

    dynamicparam
    {
        if ($null -eq $global:PIMRoleDictionary)
        {
            $global:PIMRoleDictionary = New-RoleMapping
        }
        $global:PIMRoleDictionary
    }

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
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'rolename'
            {
                $RoleName = $PSBoundParameters['RoleName']
                $roleId = $global:roleName2Id.Item($RoleName)
                break
            }
            'roleid'
            {
                $RoleName = $global:roleId2Name.Item($roleId)
                break
            }
            'all'
            {
                $All = $true
                break;
            }
        }

        if (-not $All)
        {
            $filter = "roleDefinitionId eq '$roleId'"
        }

        $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "privilegedAccess/aadroles/resources/$($MSGAuthInfo.TenantId)/roleSettings" -Filter $filter
        if ($null -ne $res -and $res.StatusCode -lt 300)
        {
            $res | ForEach-Object { Add-Member -InputObject $_ -MemberType NoteProperty -Name 'RoleName' -Value $global:roleId2Name.Item($_.RoleDefinitionId).displayName }
            $res | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, 'MSPIM.privilegedRoleSettings') }
        }
        $res
    }
}
