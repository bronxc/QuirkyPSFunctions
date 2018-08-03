[CmdLetBinding()]
param([string]$SourceFolder,
    [string]$TargetFolder,
    [string[]]$FilesToExclude = @('*.xml', '*.config', '*.bak'),
	[switch]$DisplayOnly,
	[switch]$Quiet)

begin {
    if (-not (Test-Path -Path $SourceFolder -PathType Container)) {throw "Can't find Source: $SourceFolder"}
    if (-not (Test-Path -Path $SourceFolder -PathType Container)) {throw "Can't find Source: $SourceFolder"}
    [array]$exclusions = $FilesToExclude 
    [hashtable]$returnValues = @{}
	$numToCopy = 0
	
    if ($Quiet -and $DisplayOnly) {throw 'Invalid arguments: -DisplayOnly and -Quiet mean there will be zero output.'}

}
process {

  
    $returnValues.ComputerName = $Env:COMPUTERNAME
    $returnValues.SourceFolder = $SourceFolder
    $returnValues.DestinationFolder = $TargetFolder
    $returnValues.Files = @()


	[bool]$didSomething = $false
    $results = $(& "robocopy.exe" "$SourceFolder" "$TargetFolder" *.* /NJS /NJH /NS /XX /NDL /L $($exclusions.Split()))
    foreach ($line in $results) {
        Write-Verbose "Processing Line $line"
        if ($line.Length -gt 0) {
			$numToCopy++
			$didSomething = $true
            $fileClass = $line.Substring(0, 15).Trim()
            $fileName = $line.Substring(16).Trim()
            Write-Verbose "File : $fileName"
            Write-Verbose "Class: $fileClass"

            [hashtable]$fileInfo = @{}
            #$fileName = $(Join-Path $SourceFolder $fileName)
            if (Test-Path $fileName -PathType Leaf) {
                
                $fileItem = Get-Item $fileName
                $fileInfo.FullName = $fileItem.FullName
                $fileInfo.Class = $fileClass
                [DateTime]$fileInfo.SourceDate = $fileItem.LastWriteTime
                $fileInfo.SourceSize = $fileItem.Length
                $fileInfo.TargetDate = $null
                $fileInfo.TargetSize = $null
                $fileInfo.TargetChecksum = $null

                $targetName = $(Join-Path $TargetFolder $($fileInfo.Name))
                if (Test-Path -Path $targetName -PathType Leaf) {
                    $targetItem = Get-Item $targetName
                    $fileInfo.TargetDate = $targetItem.LastWriteTime
                    $fileInfo.TargetSize = $targetItem.Length 
                    $fileInfo.TargetChecksum = $(Get-MD5Checksum -FileName $targetItem.FullName|Select-Object -Expand HashBase64String)
                } else {Write-Verbose "Can't find $targetName"}
                $fileObject = New-Object -TypeName PSObject -Property $fileInfo
                $returnValues.Files += $fileObject

            } else {Write-Verbose "Can't find $fileName"}

        }
    }
    #Newer                       C:\hold\first\psb9.zip
}

end {
	#return $returnValues
	
    if (-not $Quiet) {
        Write-Host "Will copy $numToCopy files"
    }


    foreach ($f in $returnValues.Files) {

        
        if (-not $Quiet) {Write-Host $_.FullName}
		
        if (-not $DisplayOnly) {
       
            $outObject = $( $f| Select-Object -property `
                @{Label = "Class"; Expression = {($_.Class)}},
                @{Label = "Name"; Expression = {($_.FullName)}},
                @{Label = "Source Date"; Expression = {($_.SourceDate).ToshortDateString()}},
                @{label = "Source Size"; Expression = {"{0:N2}" -f ($_.SourceSize / 1MB)}},
                @{label = "Source MD5"; Expression = {$_.SourceChecksum}},
                @{Label = "Target Date"; Expression = {($_.TargetDate).ToshortDateString()}},
                @{label = "Target Size"; Expression = {"{0:N4}" -f ($_.TargetSize / 1MB)}},
                @{label = "Target MD5"; Expression = {$_.TargetChecksum}})

      

            Write-Output $outObject
        }
       
    }
}