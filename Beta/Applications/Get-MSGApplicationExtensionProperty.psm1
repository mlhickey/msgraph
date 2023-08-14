function Get-MSGApplicationExtensionProperty
{
    <#
    .SYNOPSIS
    Returns a list of ExtensionProperties for the specified application id.

    .DESCRIPTION
    The Get-MSGApplicationExtensionProperty returns the ExtensionProperties assocaited with the specified application id

    .PARAMETER Id
    Specifies the application iD (objectId) of an application in Azure Active Directory

    .PARAMETER Appid
    Specifies the application id of an application in Azure Active Directory

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .LINK
    https://docs.microsoft.com/en-us/graph/api/application-list-extensionproperty?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ObjectId')]
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
            $propFilter = "`$select="
            $propFilter += $properties -join ','
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

        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "applications/$id/extensionProperties" -Filter $propFilter
    }
}
