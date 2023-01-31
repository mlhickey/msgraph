function Get-MSGDirectoryRole
{
    <#
    .SYNOPSIS
    Gets directory roles available in Azure AD

    .DESCRIPTION
    The Get-MSGDirectoryRole cmdlet returns a list of directory roles available in Azure AD

    .PARAMETER Id
    Specifieds the id (ObjectId) of a directory role

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .EXAMPLE
    Get-MSGDirectoryRole


    Id                                   DisplayName                                Description
    --                                   -----------                                -----------
    09a00969-e732-4ebe-ba46-e6a6d9aace30 Search Editor                              Can create and manage the editorial content such as bookmarks, Q and As, locations, floorplan.
    151588e9-3407-4225-a76e-4c0ba6bc2cd7 Guest Inviter                              Can invite guest users independent of the 'members can invite guests' setting.
    23f3b4b4-8a29-4420-8052-e4950273bbda Reports Reader                             Can read sign-in and audit reports.
    2a6c0263-c4b6-4527-8261-7e13fccda653 Exchange Service Administrator             Can manage all aspects of the Exchange product.
    2cdfd881-468a-4eec-a5e9-ae4ec5869c46 CRM Service Administrator                  Can manage all aspects of the Dynamics 365 product.
    .
    .
    .
    .LINK
     https://docs.microsoft.com/en-us/graph/api/directoryrole-list?view=graph-rest-beta&tabs=http

  #>
    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the role")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

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
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "id"
            {
                Get-MSGObject -Type "directoryRoles/$Id"
                break
            }
            "topall"
            {
                Get-MSGObject -Type "directoryRoles" -All:$All
                break
            }
        }
    }
}
