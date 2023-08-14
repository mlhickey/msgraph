<#
    https://docs.microsoft.com/en-us/graph/api/resources/directorysetting?view=graph-rest-beta
#>
function Get-MSGOrganizationContact
{
    <#

    .PARAMETER Id
    SPecifies the id (ObjectId) of a contact

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .LINK
    https://docs.microsoft.com/en-us/graph/api/resources/orgcontact?view=graph-rest-beta
    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the contact')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = 'OData query filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

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
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "contacts/$id" -Filter $queryFilter
                break
            }
            'topall'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'contacts' -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
