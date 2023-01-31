function Get-MSGAdministrativeUnit
{
    <#
    .SYNOPSIS
    Gets an administrative unit.

    .DESCRIPTION
    The Get-MSGAdministrativeUnit cmdlet retrieves the specified administrative unit

    .PARAMETER Id
    Specifies the Id of an administrative unit

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .EXAMPLE
    Get-MSGAdministrativeUnit

    Id                                   DisplayName                    Description           Visibility
    --                                   -----------                    -----------           ----------
    9a93af25-a20a-4b1e-b03b-26b965d64bdc AdminUnit testing zaedwa algas Contact zaedwa;alglas

    .EXAMPLE
    Get-MSGAdministrativeUnit -Id 9a93af25-a20a-4b1e-b03b-26b965d64bdc

    Id                                   DisplayName                    Description           Visibility
    --                                   -----------                    -----------           ----------
    9a93af25-a20a-4b1e-b03b-26b965d64bdc AdminUnit testing zaedwa algas Contact zaedwa;alglas

    .LINK
     https://docs.microsoft.com/en-us/graph/api/administrativeunit-list?view=graph-rest-beta&tabs=http

  #>
    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the extension")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            ParameterSetName = "Search",
            HelpMessage = "Search criteria.")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
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
            "id"
            {
                Get-MSGObject -Type "administrativeUnits/$id" -Filter $queryFilter
                break
            }

            { $PSItem -match "topall|search" }
            {
                Get-MSGObject -Type "administrativeUnits" -Filter $queryFilter -All:$All
            }
        }
    }
}
