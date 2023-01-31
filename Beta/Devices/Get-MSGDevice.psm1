function Get-MSGDevice
{

    <#
    .SYNOPSIS
    Gets a device from Azure Active Directory

    .DESCRIPTION
    The Get-MSGDevice cmdlet gets a device from Azure Active Directory

    .PARAMETER Id
    Specifies the Id (ObjectId) of a device  in Azure AD.

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all devices. If false, return the number of objects specified by the Top parameter

    .PARAMETER AdvancedQuery
    Sets header to support advanced query options (see https://docs.microsoft.com/en-us/graph/aad-advanced-queries#support-for-filter-on-properties-of-azure-ad-directory-objects#support-for-filter-on-properties-of-azure-ad-directory-objects)

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE

    Get-MSGDevice -ObjectId b1bf565c-3c86-4147-abb5-800efb21d633

    Id                                   DeviceId                             DisplayName ApproximateLastSignInDateTime IsCompliant IsManaged
    --                                   --------                             ----------- ----------------------------- ----------- ---------
    b1bf565c-3c86-4147-abb5-800efb21d633 38ac9774-5c82-4ee5-b5a8-5ff7e815c0a4 FUTALEUFA   2019-08-19T18:53:19Z          False       True

    .EXAMPLE
    Get-MSGDevice -SearchString "NEBAP" -CountOnly
    1141

    .LINK
     https://docs.microsoft.com/en-us/graph/api/device-list?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the device.")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(
            ParameterSetName = "Search",
            HelpMessage = "Search criteria.")]
        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(
            ParameterSetName = "Filter",
            HelpMessage = "OData query filter")]
        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(ParameterSetName = "Id",
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [int]$Top = 100,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [switch]$All,

        [Parameter(ParameterSetName = "Count")]
        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [Parameter(ParameterSetName = "Filter")]
        [switch]$AdvancedQuery,

        [Parameter(ParameterSetName = "Count")]
        [switch]$CountOnly
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
                Get-MSGObject -Type "devices/$Id" -Filter $queryFilter
                break
            }

            { $PSItem -match "topall|search" }
            {
                Get-MSGObject -Type "devices" -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                break
            }
            "count"
            {
                Get-MSGObject -Type "devices" -Filter $queryFilter -CountOnly
            }

        }
    }
}
