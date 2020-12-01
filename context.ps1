$ctxList = Get-AzContext -ListAvailable

# output resource group name and location for each context
foreach($ctx in $ctxList){
  Select-AzContext -Name $ctx.Name | Out-Null
  Write-Output "$($ctx.Name) resource groups:"
  Get-AzResourceGroup | Select-Object ResourceGroupName, Location
}