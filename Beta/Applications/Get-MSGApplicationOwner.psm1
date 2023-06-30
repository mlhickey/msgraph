function Get-MSGApplicationOwner
{
    <#
    .SYNOPSIS
    Returns a list of owners for the specified application id.

    .DESCRIPTION
    The Get-MSGApplicationOwner returns the owners assocaited with the specified application id

    .PARAMETER Id
    Specifies the application iD (objectId) of an application in Azure Active Directory

    .PARAMETER Appid
    Specifies the application id of an application in Azure Active Directory

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .EXAMPLE
    Get-MSGApplicationOwners -AppId 5b757830-5766-4ef2-9578-ab9ba16f4513

    Id                                   DisplayName                              UserPrincipalName      UserType
    --                                   -----------                              -----------------      --------
    4acfb7f4-e4f8-4592-81e0-2e31551a0498 Shunsuke Yoshinaga (Accenture Japan Ltd) v-shuyos@microsoft.com Member

    .EXAMPLE
    Get-MSGApplicationOwner -AppId 5b757830-5766-4ef2-9578-ab9ba16f4513 -Properties userPrincipalName

    @odata.type           userPrincipalName
    -----------           -----------------
    #microsoft.graph.user v-shuyos@microsoft.com

    .LINK
    https://docs.microsoft.com/en-us/graph/api/application-post-owners?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ObjectId')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'AppId',
            HelpMessage = 'AppId of the application')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId,

        [Parameter(Mandatory = $false,
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        if (-not [string]::IsNullOrEmpty($properties))
        {
            $propFilter = "`$select=$($properties -join ',')"
        }
    }

    process
    {

        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'appid'
            {
                $id = (Get-MSGApplication -AppId $AppId -Properties id).Id
                break
            }
        }

        if ($nuill -eq $id)
        {
            throw 'Either an objectId or appId is required'
        }

        Get-MSGObject -Type "applications/$id/owners" -Filter $propFilter
    }
}
