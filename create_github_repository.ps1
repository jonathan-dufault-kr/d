<#
.SYNOPSIS
    .
.DESCRIPTION
    .
.PARAMETER Path
    The path to the .
.PARAMETER LiteralPath
    Specifies a path to one or more locations. Unlike Path, the value of 
    LiteralPath is used exactly as it is typed. No characters are interpreted 
    as wildcards. If the path includes escape characters, enclose it in single
    quotation marks. Single quotation marks tell Windows PowerShell not to 
    interpret any characters as escape sequences.
.EXAMPLE
    C:\PS> 
    <Description of example>
.NOTES
    Author: Keith Hill
    Date:   June 28, 2010    
#>






[cmdletbinding(SupportsShouldProcess)]

Param(
[Parameter(Position = 0, Mandatory, HelpMessage = "Enter the new repository name")]
[ValidateNotNullorEmpty()]
[string]$Name,

[string]$Description,

[switch]$Private,
[switch]$NoWiki,
[switch]$NoIssues,
[switch]$NoDownloads,
[switch]$AutoInitialize,

#license templates found at https://github.com/github/choosealicense.com/tree/gh-pages/_licenses
[ValidateSet("MIT","apache-2.0","gpl-3.0","ms-pl","unlicense")]
[string]$LicenseTemplate,

[Alias("token")]
[ValidateNotNullorEmpty()]
[string]$UserToken = $gitToken,

#write full native response to the pipeline
[switch]$Raw
)

Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"
#display PSBoundparameters formatted nicely for Verbose output  
[string]$pb = ($PSBoundParameters | Format-Table -AutoSize | Out-String).TrimEnd()
Write-Verbose "[BEGIN  ] PSBoundparameters: `n$($pb.split("`n").Foreach({"$("`t"*2)$_"}) | Out-String) `n" 

#create the header
$head = @{
Authorization = 'Basic ' + $UserToken
}

#create a hashtable from properties
$hash = @{
 name = $Name
 description = $Description
 private = $Private -as [boolean]
 has_wiki = (-Not $NoWiki)
 has_issues = (-Not $NoIssues)
 has_downloads = (-Not $NoDownloads)
 auto_init = $AutoInitialize -as [boolean]
}

if ($LicenseTemplate) {
    $hash.add("license_template",$LicenseTemplate)
}

$body = $hash | ConvertTo-Json

Write-Verbose "[PROCESS] Sending json"
Write-Verbose $body

#define parameter hashtable for Invoke-RestMethod
$paramHash = @{
Uri = "https://api.github.com/user/repos" 
Method = "Post"
body = $body 
ContentType = "application/json"
Headers = $head
UseBasicParsing = $True
DisableKeepAlive = $True
}

#should process
if ($PSCmdlet.ShouldProcess("$name [$description]")) {
   $r = Invoke-RestMethod @paramHash

    if ($r.id -AND $Raw) {
        Write-Verbose "[PROCESS] Raw result"
        $r

    } elseif ($r.id) {
        write-Verbose "[PROCESS] Formatted results"

        $r | Select-Object @{Name = "Name";Expression = {$_.name}},
        @{Name = "Description";Expression = {$_.description}},
        @{Name = "Private";Expression = {$_.private}},
        @{Name = "Issues";Expression = {$_.has_issues}},
        @{Name = "Wiki";Expression = {$_.has_wiki}},
        @{Name = "URL";Expression = {$_.html_url}},
        @{Name = "Clone";Expression = {$_.clone_url}}
    } else {
        
        Write-Warning "Something went wrong with this process"
    }

    if ($r.clone_url) {
      $msg = @"

To push an existing local repository to Github run these commands:
-> git remote add origin $($r.clone_url)"
-> git push -u origin master

"@
    Write-Host $msg -ForegroundColor Green

    }
}

Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"

