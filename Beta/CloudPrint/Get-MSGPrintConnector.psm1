function Get-MSGPrintConnector
{

    <#
    .SYNOPSIS
    Gets a device from Azure Active Directory

    .DESCRIPTION
    The Get-MSGPrintConnector cmdlet gets a printt connector

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER SearchString
    Specifies a search string

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all devices. If false, return the number of objects specified by the Top parameter

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE

    .LINK
     https://docs.microsoft.com/en-us/graph/api/device-list?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the device.')]
        [ValidateNotNullOrEmpty()]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Search',
            HelpMessage = 'Partial/complete displayname of the object.')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Filter',
            HelpMessage = 'OData query filter')]
        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(ParameterSetName = 'Id',
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'TopAll',
            HelpMessage = 'Return all devices in directory')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Filter')]
        [switch]$All,

        [Parameter(ParameterSetName = 'Count')]
        [switch]$CountOnly
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
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "print/connectors/$Id" -Filter $queryFilter
                break
            }

            { $PSItem -match 'topall|search' }
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'print/connectors' -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                break
            }
            'count'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'print/connectors' -Filter $queryFilter -CountOnly
            }

        }
    }
}
