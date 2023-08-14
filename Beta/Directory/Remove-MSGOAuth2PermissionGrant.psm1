function Remove-MSGOAuth2PermissionGrant
{
    <#
    .SYNOPSIS
    Removes an oAuth2PermissionGrant associated with the specifed id

    .DESCRIPTION
    The Remove-MSGOAuth2PermissionGrant cmdlet removes the oAuth2PermissionGrant associaged with the specifed id

    .PARAMETER Id
    Specifies the id of the OAuth2 grant

    .EXAMPLE
    Remove-MSGOAuth2PermissionGrant -Id PeNCEoVtzk-Bxsxrtxr9vuq2z0GYA81OueRsarD4TEs

    .LINK
    https://docs.microsoft.com/en-us/graph/api/oauth2permissiongrant-delete?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Id',
            HelpMessage = 'Id of the oAuth2PermissionGrant')]
        [string]$Id
    )

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
        if ($PSCmdlet.ShouldProcess("$Id", 'Remove oAuth2Permissiongrants'))
        {
            $res = Remove-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'oAuth2Permissiongrants' -Id $Id
            $global:lastexitcode = $res.StatusCode
        }
    }
}
