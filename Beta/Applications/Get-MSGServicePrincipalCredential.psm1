function Get-MSGServicePrincipalCredential
{
    <#
    .SYNOPSIS
    Get credentials assocatied with the service principal

    .DESCRIPTION
    The Get-MSGServicePrincipalCredentials cmdlet gets information about credential objects associated with the service principal.

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER Type
    Specifies the type of credential to retrieve:  KeyCredentials, PasswordCredentials or All.  Default is all

    .EXAMPLE
    Get-MSGServicePrincipalCredential -Id 3a098b29-7e85-4ac7-ad17-23587198bcad -Verbose

    StartDate            EndDate              KeyId                                Type
    ---------            -------              -----                                ----
    3/26/2019 6:41:00 PM 6/24/2019 6:41:00 PM 406263e9-5647-4c45-853b-fc23d0870679 AsymmetricX509Cert
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'AppId of the application')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId,

        [Parameter(Mandatory = $false,
            HelpMessage = 'Type of credential: PasswordCredentials, KeyCredentials or All')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'PasswordCredentials',
            'KeyCredentials',
            'All')]
        [string]$Type = 'All'
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        if ($Type -eq 'All')
        {
            $filter = 'KeyCredentials,PasswordCredentials'
        }
        else
        {
            $filter = $Type
        }
    }

    process
    {
        $credList = @()

        if (-not [string]::IsNullOrEmpty($AppId))
        {
            $id = [guid](Get-MSGServicePrincipal -Debug:$DebugPreference -Verbose:$VerbosePreference -AppId $AppId -Properties id).Id
        }
        if ([string]::IsNullOrEmpty($Id))
        {
            Write-Warning 'Must provide either a valid ObjectId or AppId'
            return $null
        }
        if ($filter -match 'KeyCredentials')
        {
            $credList += Get-MSGServicePrincipalKeyCredential -Debug:$DebugPreference -Verbose:$VerbosePreference -Id $id
        }
        if ($filter -match 'PasswordCredentials')
        {
            $credList += Get-MSGServicePrincipalPasswordCredential -Debug:$DebugPreference -Verbose:$VerbosePreference -Id $id
        }
        if ($credList.Count)
        {
            buildCredList -cObjectList $credList
        }
    }
}
