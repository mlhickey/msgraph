function New-MSGServicePrincipalOAuth2PermissionGrant
{
    <#
    .SYNOPSIS
    Creates a new oAuth2PermissionGrant associated with the specifed service principal

    .DESCRIPTION
    The New-MSGServicePrincipalOAuth2PermissionGrant cmdlet returns the oAuth2PermissionGrant associaged with the specifed service principal

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER ResourceId
    Specifies the Id of the  resource being accessed

    .PARAMETER Scope
    Specifies the space-separated list of claims

    .EXAMPLE
    New-MSGServicePrincipalOAuth2PermissionGrant -Id 1242e33d-6d85-4fce-81c6-cc6bb71afdbe -resourceid 41cfb6ea-0398-4ecd-b9e4-6c6ab0f84c4b -scope "User.Read"

    StatusCode StatusDescription
    ---------- -----------------
    201        Created

    .LINK
    https://docs.microsoft.com/en-us/graph/api/oauth2permissiongrant-post?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id",
            HelpMessage = "Id of the servicePrincipal.")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [Alias("ObjectId")]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id",
            HelpMessage = "Id of the resource.")]
        [string]$ResourceId,

        [Parameter(Mandatory = $true,
            Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id",
            HelpMessage = "List of scopes")]
        [string]$Scope
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
    }

    process
    {
        $Now = Get-Date ([datetime]::UtcNow) -UFormat "%Y-%m-%dT%H:%M:%SZ"
        $oauth2Grant = [PSCustomObject][Ordered]@{
            clientId    = $Id
            consentType = "AllPrincipals"
            principalId = $null
            resourceId  = $ResourceId
            scope       = $Scope
            startTime   = $Now
            expiryTime  = $Now
        }
        if ($PSCmdlet.ShouldProcess("$Id", "Create oAuth2Permissiongrants"))
        {
            New-MSGObject -Type "oAuth2Permissiongrants " -Body $oauth2Grant
        }
    }
}
