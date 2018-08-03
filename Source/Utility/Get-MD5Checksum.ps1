
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true, ParameterSetName = "Files")]
    [string[]]$FileName,
    [Parameter(ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "String")]
    [string[]]$String,
    [string]$Encoding = "UTF-8"
)

begin {
    $returnArray = @()
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
}

process {

    #Get-FileHash should replace this nicely,
    foreach ($file in $fileName) {
        if (Test-Path $file -PathType Leaf) {

            $filePath = Get-Item $file | Select-Object -ExpandProperty FullName

            [byte[]]$hashBytes = $md5.ComputeHash([System.IO.File]::ReadAllBytes($filePath))


            $hash = [System.BitConverter]::ToString($hashBytes)
            $returnValues = @{}
            $returnValues.FileName = $filePath
            $returnValues.HashBytes = $hashBytes
            $returnValues.HashString = $hash
            $returnValues.HashBase64String = [System.Convert]::ToBase64String($hashBytes)
            $returnArray += $(New-Object -Type PSObject -Property $returnValues)


        }
    } 

    foreach ($thisString in $string) {
        $encoder = $null
        switch ($encoding) {
            "UTF-8" { $encoder = [System.Text.Encoding]::UTF8 }
            "UTF-16" { $encoder = [System.Text.Encoding]::UTF16 }
            "ASCII" { $encoder = [System.Text.Encoding]::ASCII }
            "UNICODE" { $encoder = [System.Text.Encoding]::UNICODE }
        }


        #[byte[]]$hash = [System.BitConverter]::ToString($md5.ComputeHash($encoder.GetBytes($thisString)))
        [byte[]]$hashBytes = $md5.ComputeHash($encoder.GetBytes($thisString))
        $hash = [System.BitConverter]::ToString($hashBytes)
        $returnValues = @{}
        $returnValues.String = $thisString
        $returnValues.HashBytes = $hashBytes
        $returnValues.HashString = $hash
        $returnValues.Hash = $hash
        $returnValues.HashBase64String = [System.Convert]::ToBase64String($hashBytes)
        $returnArray += $(New-Object -Type PSObject -Property $returnValues)
    }

}

end {
    return $returnArray
}

