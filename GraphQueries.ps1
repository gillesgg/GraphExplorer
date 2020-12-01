[CmdletBinding()]
param(
      [parameter(Mandatory,ParameterSetName='outfolder')]
      [String]
      $outfolder,

      [parameter(ParameterSetName='help')] [switch] $help
)


# dump the dictionnary used to store json values
# key is the name of the propertie, values are list of properties
# Parameter $dictionnaryList : the dictionnary : string,<list>string
function DumpDictionnary
{
    param ([system.collections.generic.dictionary[[string],[system.collections.generic.list[string]]]] $dictionnaryList)

    #[system.collections.generic.list[string]] $item

    foreach ($item in $dictionnaryList.Keys) 
    {
        if ($item)
        {
            $listvalues = $dictionnaryList[$item]
            #Write-Host -NoNewline  "key:" $item " "
           
        }
    }
    Write-Host " "
}
# Parse the JSON array 
# key is the name of the propertie, values are list of properties
# Parameter $dictionnaryList : the dictionnary : string,<list>string
# Parameter $result : json to parse
function parseJsonArray
{
    param ($dictionnaryList,$result)
    try
    {    
        [Reflection.Assembly]::LoadFile("$PSScriptRoot\packages\Newtonsoft.Json.12.0.3\lib\net45\Newtonsoft.Json.dll")
   
        if ($result)
        {
            $jsonArray = [Newtonsoft.Json.Linq.JArray]::Parse($result)   

            for ($x = 0; $x -lt $jsonArray.Count ; $x++)
            {
                [Newtonsoft.Json.Linq.JObject] $item = $jsonArray[$x]  
                foreach ($item1 in $item)
                {
                $thename = $item1.Name
                $thevalue = $item1.Value.Value.ToString()
                #Write-Output $thename $thevalue

                    if ( ![string]::IsNullOrWhiteSpace($thename) -And  ![string]::IsNullOrWhiteSpace($thevalue) )
                    {
                        if (!$dictionnaryList.ContainsKey($thename))
                        {
                            $currentlist = New-Object 'system.collections.generic.list[string]'
                            $currentlist.add($thevalue)
                            $dictionnaryList.Add($thename,$currentlist)   
                        }
                        else 
                        {
                            $currentlist = $dictionnaryList[$thename]
                            $currentlist.add($thevalue)
                            $dictionnaryList[$thename] = $currentlist
                        }
                    }
                }
            }
        }
        else 
        {
            Write-Verbose -Message ("the json result is null", ($result -join [Environment]::NewLine))
        }            
   }
   catch [Exception]
   {
       Write-Host $_.Exception.Message
   }
}

# Save the json result to an XL file
# $dictionnaryList : data to save
# $outpath : file path 
# $outfile : Excel filename
# $sheetname : Excel sheet name
function savetoXL
{
    param ($dictionnaryList,$outpath, $outfile, $sheetname)
    try
    {
        [Reflection.Assembly]::LoadFile("$PSScriptRoot\packages\ClosedXML.0.95.3\lib\net46\ClosedXML.dll")
        [Reflection.Assembly]::LoadFile("$PSScriptRoot\packages\DocumentFormat.OpenXml.2.7.2\lib\net46\DocumentFormat.OpenXml.dll")
        

        if ($sheetname.ToString().length -gt 30) { $sheetname = $sheetname.substring(0, 30) }

        
        $filetosave = $outpath+ "\" + $outfile + ".xlsx"
         
        [ClosedXML.Excel.XLWorkbook]   $workBook = new-object ClosedXML.Excel.XLWorkbook
        [ClosedXML.Excel.IXLWorksheet]  $workSheet

         if ([System.IO.File]::Exists($filetosave))
         {
            $workBook = new-object ClosedXML.Excel.XLWorkbook($filetosave)
         }
         else
         {
            $workBook = new-object ClosedXML.Excel.XLWorkbook
         }

         if ($workBook.Worksheets.Contains($sheetname))
         {
            $workSheet = $workBook.Worksheets.Delete($sheetname)
         }        
        $workSheet = $workBook.Worksheets.Add($sheetname)       

        $row = 1;
        $col = 1;
         
        foreach ($colname in $dictionnaryList.Keys)
        {    
            if ($colname )
            {
                $listvalues = $dictionnaryList[$colname]
                $workSheet.Cell($row++, $col).Value = $colname.ToString()
                foreach ($value in $listvalues)
                {
                    $workSheet.Cell($row++, $col).Value = $value.ToString()
                }                
            }
            $col++
            $row = 1
        }
        #Save the workbook
        if ([System.IO.File]::Exists($filetosave))
        {
            $workBook.Save()
        }
        else
        {
            $workBook.SaveAs($filetosave)
        }
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        exit 1
    }
}

if ($help)
{
    write-host "usage : GraphQueries.ps1 -outfolder [Folder]"
    return
}

if (!$infolder)
{
    $FolderToTest = $PSScriptRoot
}



# $FolderToTest = "C:\Users\gillesg.EUROPE\Desktop\GraphExplorer\queries1"

$ErrorActionPreference = 'Stop'

$settingsFilename = Join-Path $PSScriptRoot 'settings.json'

if(-not (Test-Path $settingsFilename)) 
{
    az account list --query [0] | ConvertFrom-Json | Select-Object @{Name="subscriptionId";"Expression"={$_.id}} | ConvertTo-Json -Depth 10 | Out-File $settingsFilename
}
$settings = Get-Content -Path $settingsFilename -Raw | ConvertFrom-Json
$queries = Get-ChildItem -Path $FolderToTest\query.txt -Recurse



$queries | ForEach-Object {
    $query = ((Get-Content -Path $_.FullName -Raw) -replace '\n\d|\n|\r', ' ') -replace '"', '\"'
    $queryName = $_.Directory.Name
    Write-Host -Message "Processing: $queryName"
    #Write-Verbose -Message "'$queryName' query: $query"

    $resultSize = if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) 
    {
        100
    } 
    else 
    {
        1
    }

    $result = az graph query -q "$query" --subscription $settings.subscriptionId
    # do not put anything between the graph call and the if statement
    if (! $?) 
    {
        throw "Error during execution of: $queryName\n\nQuery: $query"
    }   
    #Write-Output -NoNewline $result 
    #Write-Output " "

    if (!$outFolder)
    {
        $OutFolder = $_.Directory.Parent.FullName
    }

    $dictionnaryList = New-Object 'system.collections.generic.dictionary[[string],[system.collections.generic.list[string]]]'
    parseJsonArray $dictionnaryList  $result
    savetoXL $dictionnaryList $OutFolder $_.Directory.Parent.Name $_.Directory.Name
    #DumpDictionnary $dictionnaryList
    #Write-Verbose -Message ("'$queryName' output:{0}{1}" -f [Environment]::NewLine, ($result -join [Environment]::NewLine))
}
