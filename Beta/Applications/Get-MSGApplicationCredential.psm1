function Get-MSGApplicationCredential
{
    <#
    .SYNOPSIS
    Get credentials assocatied with the specifed id

    .DESCRIPTION
    The Get-MSGApplicationCredential cmdlet gets information about credential objects associated with the specified id.

    .PARAMETER Id
    Specifies the application iD (objectId) of an application in Azure Active Directory

    .PARAMETER Appid
    Specifies the application id of an application in Azure Active Directory

    .PARAMETER Type
    Specifies the type of credential to retrieve:  KeyCredentials, PasswordCredentials or All.  Default is all

    .EXAMPLE
     Get-MSGApplicationCredential -AppId 7f3ea722-a5a6-4252-aada-c204888aacf4

    StartDate             EndDate               KeyId                                Type
    ---------             -------               -----                                ----
    6/24/2016 10:45:27 AM 6/24/2017 10:45:27 AM 204ec2cc-3021-4c17-844b-e02140b32fcd Password
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the application or Application.')]
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
            $id = [guid](Get-MSGApplication -AppId $AppId -Properties id).Id
        }
        if ([string]::IsNullOrEmpty($Id))
        {
            Write-Warning 'Must provide either a valid ObjectId or AppId'
            return $null
        }

        if ($filter -match 'KeyCredentials')
        {
            $credList += @(Get-MSGApplicationKeyCredential -Id $id)
        }
        if ($filter -match 'PasswordCredentials')
        {
            $credList += @(Get-MSGApplicationPasswordCredential -Id $id)
        }
        if ($credList.Count)
        {
            buildCredList -cObjectList $credList
        }
    }
}
