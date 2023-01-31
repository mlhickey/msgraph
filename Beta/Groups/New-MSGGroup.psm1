function New-MSGGroup
{
    <#
    .SYNOPSIS
    Gets a group from Azure Active Directory

    .DESCRIPTION
    The New-MSGGroup cmdlet creates a group in Azure Active Directory

    .PARAMETER DisplayName
    Specifies the display name of the group

    .PARAMETER MailEnabled
    Indicates whether mail is enabled

    .PARAMETER MailNickName
    Specifies a nickname for mail

    .PARAMETER SecurityEnabled
    Indicates whether the group is security-enabled

    .PARAMETER GroupType
    Specifies the type of group to create. Valid types are:

        DynamicMembership
        Unified
        Elevated

    If no type is specified a Security Group is created

    .PARAMETER IsAssignableToRole
    Specified the group can be used for PIM assignments

    .PARAMETER MembershipRule
    Specifies the query parameters that will be used to populate the group

    .PARAMETER All
    If true, return all devices. If false, return the number of objects specified by the Top parameter

    .EXAMPLE

    New-MSGGroup -DisplayName "MyDynamicGroup" -MailEnabled $false -SecurityEnabled $true -MailNickName  -GroupType Elevated -DynamicQuery "(user.userPrincipalName -match ""#EXT#"")"

    .LINK
    https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/api/group_post_groups

    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [bool]$MailEnabled,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$MailNickName,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [bool]$SecurityEnabled,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [Parameter(Mandatory = $false,
            HelpMessage = "Type of group: DynamicMembership, Unified or Elevated")]
        [ValidateSet(
            "DynamicMembership",
            "Unified",
            "Elevated")]
        [string]$GroupType,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [bool]$IsAssignableToRole
    )

    dynamicparam
    {
        if ($GroupType -eq "DynamicMembership")
        {
            New-DynamicParam -Name MembershipRule -Mandatory -HelpMessage "Query to use for dynamic group population"
        }
    }

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }

        if ($PSBoundParameters['MembershipRule'])
        {
            Write-Verbose "$PSBoundParameters['MembershipRule']"
        }
    }

    process
    {

        $groupBody = [PSCustomObject][Ordered]@{
            displayName     = $DisplayName
            mailEnabled     = $MailEnabled
            mailNickname    = $MailNickName
            securityEnabled = $SecurityEnabled
        }

        if (-not [string]::IsNullOrEmpty($Description))
        {
            Add-Member -InputObject $groupBody -MemberType NoteProperty -Name description -Value $Description
        }
        if ($IsAssignableToRole)
        {
            Add-Member -InputObject $groupBody -MemberType NoteProperty -Name isAssignableToRole -Value $true
        }
        if ($PSBoundParameters['MembershipRule'])
        {
            Add-Member -InputObject $groupBody -MemberType NoteProperty -Name membershipRule -Value $PSBoundParameters['MembershipRule']
            Add-Member -InputObject $groupBody -MemberType NoteProperty -Name membershipRuleProcessingState -Value "On"
        }

        if (-not [string]::IsNullOrEmpty($GroupType))
        {
            $g = @($GroupType)
            if (-not ($g -match "Unified")) { $groupBody.securityEnabled = $true }
            Add-Member -InputObject $groupBody -MemberType NoteProperty -Name groupTypes -Value $g
        }
        if ($PSCmdlet.ShouldProcess("$Id", "Create group"))
        {
            New-MSGObject -Type groups -Body $groupBody
        }
    }
}
