function Get-MSGDirectorySetting
{
    <#
    .SYNOPSIS
    Gets current settings from tenant

    .DESCRIPTION
    The Get-MSGDirectorySetting cmdlet retrieves settings from tenant

    .PARAMETER Id
    Specifieds the id (ObjectId) of a directory setting

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .EXAMPLE
    Get-MSGDirectorySetting -Id 916724a1-dd95-4e7e-bf44-219c2d64e709

    id                                   displayName   templateId                           values
    --                                   -----------   ----------                           ------
    916724a1-dd95-4e7e-bf44-219c2d64e709 Group.Unified 62375ab9-6b52-47ed-826b-58e47e0e304b {@{name=EnableMIPLabels; value=false}, @{name=CustomBlockedWordsList; value=Ahole,anal,anus,a...

    .EXAMPLE
    Get-MSGDirectorySetting

    id                                   displayName                          templateId                           values
    --                                   -----------                          ----------                           ------
    916724a1-dd95-4e7e-bf44-219c2d64e709 Group.Unified                        62375ab9-6b52-47ed-826b-58e47e0e304b {@{name=EnableMIPLabels; value=false}, @{name=CustomBlockedWordsList; ...
    3b4b06a9-835a-478a-be96-5870a74bbe12 Prohibited Names Restricted Settings aad3907d-1d1a-448b-b3ef-7bf7f63db63b {@{name=CustomAllowedSubStringsList; value=}, @{name=CustomAllowedWhol...
    1e14a92f-37de-47f7-a0fe-27fe49629d8f Password Rule Settings               5cf42378-d67d-4f36-ba46-e8b86229381d {@{name=BannedPasswordCheckOnPremisesMode; value=Enforce}, @{name=Enab...
    02f3de40-1dca-435a-995e-233668216924 Consent Policy Settings              dffd5d46-495d-40a9-8e21-954ff55e198a {@{name=EnableGroupSpecificConsent; value=false}, @{name=BlockUserCons...

    .LINK
    https://docs.microsoft.com/en-us/graph/api/resources/directorysetting?view=graph-rest-beta
#>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the extension')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(Mandatory = $false)]
        [switch]$All
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "settings/$Id" -Filter $queryFilter
                break
            }
            'topall'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'settings' -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
