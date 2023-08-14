function Remove-MSGGroup
{
    <#
    .SYNOPSIS
    Removes the specifed group from Azure Active Directory

    .DESCRIPTION
    The Remove-MSGGroup cmdlet removes a group from Azure Active Directory. Unified Group can be restored withing 30 days after deletion using the Restore-AzureADMSDeletedDirectoryObject cmdlet.
    Security groups cannot be restored after deletion

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER PermanentlyDelete
    Permanently delete object.  Once complete this cannot be restored

    .EXAMPLE
    Get-MSGDeletedItems -ObjectType User -Top 1 -properties displayName,deletedDateTime

    deletedDateTime      displayName
    ---------------      -----------
    2018-07-31T19:05:58Z COMMAOC

    .LINK

    https://docs.microsoft.com/en-us/graph/api/group-delete?view=graph-rest-beta&tabs=http
    https://docs.microsoft.com/en-us/graph/api/directory-deleteditems-delete?view=graph-rest-beta&tabs=http

    #>

    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the group')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false)]
        [switch]$PermanentlyDelete
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        $groupList = @()
        if ($PermanentlyDelete)
        {
            $queryString = 'directory/deleteditems'
            $WhatIfMessage = 'Permanently delete'
        }
        else
        {
            $queryString = 'groups'
            $WhatIfMessage = 'Delete'
        }
    }

    process
    {
        if (-not $Id -and [string]::IsNullOrEmpty($SearchString))
        {
            throw 'Either an objectId or search string must be provided'
        }

        if ($SearchString)
        {
            try
            {
                $groupList = ProcessGroupSearchString -SearchString $SearchString 
            }
            catch
            {
                return $null 
            }
            if ($null -eq $groupList)
            {
                return $null
            }
            $group = $groupList
            $Id = $group.Id
        }

        if ($PSCmdlet.ShouldProcess("$Id", "$WhatIfMessage"))
        {
            Remove-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $queryString -Id $Id
        }
    }
}
