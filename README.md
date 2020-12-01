#Azure Resource Graph queries

This repo contains all currently available Azure Resource Graph queries contributed by ShareGate and the community + additionnals queries

## About source code 
* Query code goes under the the right `queries` folder.
* Create a folder for the service it concerns (i.g.: storageAccounts, cdn, virtualNetworks).
* Create a folder for your query (all lower case with dases instead of spaces).
* The query goes in a `query.txt` file.
* Create a README.md file to provide a title/description of what the query does.
* (On Windows) Run `GraphQueries.ps1 -outfolder <Folder>` to execute the query.


## Requirements for CI of queries
* PowerShell v5+
* Azure CLI
* Azure CLI Resource Graph extension (`resource-graph`)

## Setup for CI
* Enable PowerShell execution, see (https://theknowledgehound.home.blog/2020/03/02/15-ways-to-bypass-the-powershell-execution-policy/) for more information.
* [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* Install Azure Resource Graph extension (`az extension add --name resource-graph`)
* az login

## Execute CI tests
In a PowerShell session, run `.\GraphQueries.ps1 -outfolder <Folder>` for all queries
It will create Excel output file with result of All queries