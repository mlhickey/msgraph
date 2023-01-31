function Get-MSGDirectoryRoleTemplate
{
    <#
    .SYNOPSIS
    Gets directory roles templates available in Azure AD

    .DESCRIPTION
    The Get-MSGDirectoryRoleTemplate cmdlet returns either a list of directory role templates or the template specified by the provided id.

    .PARAMETER Id
    Specifies the Id of a directory template

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .EXAMPLE
    Get-MSGDirectoryRoleTemplate -Id 2b745bdf-0803-4d80-aa65-822c4493daac

    id                                   deletedDateTime description
    --                                   --------------- -----------
    2b745bdf-0803-4d80-aa65-822c4493daac                 Can manage Office apps cloud services, including policy and settings management, and manage the ability to select, unselect and publish 'what's new' feature con...

    .EXAMPLE
    Get-MSGDirectoryRoleTemplate

    id                                   deletedDateTime description
    --                                   --------------- -----------
    62e90394-69f5-4237-9190-012177145e10                 Can manage all aspects of Azure AD and Microsoft services that use Azure AD identities.
    10dae51f-b6af-4016-8d66-8c2a99b929b3                 Default role for guest users. Can read a limited set of directory information.
    95e79109-95c0-4d8e-aee3-d01accf2d47b                 Can invite guest users independent of the 'members can invite guests' setting.
    fe930be7-5e62-47db-91af-98c3a49a38b1                 Can manage all aspects of users and groups, including resetting passwords for limited admins.
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
            HelpMessage = "Id of the template")]
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
                Get-MSGObject -Type "directoryRoleTemplates/$Id"
                break
            }
            "topall"
            {
                Get-MSGObject -Type "directoryRoleTemplates" -All:$All
                break
            }
        }
    }
}
