function ProcessBoundParams
{
    param(
        [object]$paramList
    )
    $argList = @()
    $propFilter = $null
    if (-not [string]::IsNullOrEmpty($paramList['Filter']))
    {
        $argList += $paramList['Filter']
    }

    if ($paramList['AdvancedQuery'] -or $paramList['CountOnly'] -or $paramList['SearchString'] -or $paramList['Filter'] -match "`$orderby")
    {
        $argList += "`$count=true"
    }

    if ($paramList['Expand'])
    {
        $argList += "`$expand=$($paramList['Expand'])"
    }
    # Add support for $search as replacement for startsWith(displayName, $SearchString)
    if ($paramList['SearchString'])
    {
        if ($paramList['SearchString'] -match '\w:\w')
        {
            $argList += "`$search=`"$($paramList['SearchString'])`""
        }
        else
        {
            $argList += "`$search=`"displayName:$($paramList['SearchString'])`""
        }
    }
    if (-not [string]::IsNullOrEmpty($paramList['Properties']))
    {
        $propFilter = "`$select="
        $propFilter += $paramList['Properties'] -join ','
        $argList += $propFilter
    }

    if ($paramList['All'])
    {
        $argList += "`$top=999"
    }
    elseif (-not [string]::IsNullOrEmpty($paramList['Top']) -and -not $paramList['All'])
    {
        $argList += "`$top=$($paramList['Top'])"
    }
    $argList -join '&'
}
