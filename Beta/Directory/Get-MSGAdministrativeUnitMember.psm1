function Get-MSGAdministrativeUnitMember
{
    <#
    .SYNOPSIS
    Gets a members of an administrative unit.

    .DESCRIPTION
    The Get-MSGAdministrativeUnitMember cmdlet retrieves the members of the specified administrative unit

    .PARAMETER Id
    Specifies the Id of an administrative unit

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .EXAMPLE
    Get-MSGAdministrativeUnitMember -Id 9a93af25-a20a-4b1e-b03b-26b965d64bdc

    Id                                   DisplayName   UserPrincipalName    UserType
    --                                   -----------   -----------------    --------
    70635b49-f809-40df-b593-9a52f8afb41a AADTestAccess zetest@microsoft.com Member

    .LINK
     https://docs.microsoft.com/en-us/graph/api/administrativeunit-list-members?view=graph-rest-beta

  #>
    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the administrative unit")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ParameterSetName = "MemberId",
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the administrative unit")]
        [guid]$MemberId,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(Mandatory = $false)]
        [switch]$All
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "MemberId"
            {
                Get-MSGObject -Type "administrativeUnits/$id/members/$MemberId" -Filter $queryFilter
                break
            }
            default
            {
                Get-MSGObject -Type "administrativeUnits/$id/members" -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
