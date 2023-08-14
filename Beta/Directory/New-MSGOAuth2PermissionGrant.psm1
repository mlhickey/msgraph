function New-MSGOAuth2PermissionGrant
{
    <#
    .SYNOPSIS
    Creates a new oAuth2PermissionGrant associated with the specifed service principal

    .DESCRIPTION
    The New-MSGOAuth2PermissionGrant cmdlet returns the oAuth2PermissionGrant associaged with the specifed service principal

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER ResourceId
    Specifies the Id of the  resource being accessed

    .PARAMETER Scope
    Specifies the space-separated list of claims

    .EXAMPLE
    New-MSGOAuth2PermissionGrant -Id 1242e33d-6d85-4fce-81c6-cc6bb71afdbe -resourceid 41cfb6ea-0398-4ecd-b9e4-6c6ab0f84c4b -scope "User.Read"

    StatusCode StatusDescription
    ---------- -----------------
    201        Created

    .LINK
    https://docs.microsoft.com/en-us/graph/api/oauth2permissiongrant-post?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id",
            HelpMessage = "Id of the servicePrincipal.")]
        [Parameter(ParameterSetName = "AdminConsent")]
        [Parameter(ParameterSetName = "PrincipalId")]
        [Alias("ObjectId", "Id")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$ClientId,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id",
            HelpMessage = "Id of the resource.")]
        [Parameter(ParameterSetName = "AdminConsent")]
        [Parameter(ParameterSetName = "PrincipalId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$ResourceId,

        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "PrincipalId",
            HelpMessage = "Id of the resource.")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$PrincipalId,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id",
            HelpMessage = "List of scopes")]
        [Parameter(ParameterSetName = "AdminConsent")]
        [Parameter(ParameterSetName = "PrincipalId")]
        [string]$Scope,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "AdminConsent")]
        [Parameter(ParameterSetName = "Id")]
        [switch]$AdminConsent
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
        if ($AdminConsent.IsPresent)
        {
            $ConsentType = "AllPrincipals"
            $PrincipalId = $null
        }
        else
        {
            $ConsentType = "Principal"
        }

        $Now = Get-Date ([datetime]::UtcNow) -UFormat "%Y-%m-%dT%H:%M:%SZ"
        $oauth2Grant = [PSCustomObject][Ordered]@{
            clientId    = $ClientId
            consentType = $ConsentType
            principalId = $PrincipalId
            resourceId  = $ResourceId
            scope       = $Scope
            startTime   = $Now
            expiryTime  = $Now
        }

        New-MSGObject  -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "oAuth2Permissiongrants " -Body $oauth2Grant
    }
}
