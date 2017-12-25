
 $StorageName = "...."
 $StorageKey ="......"
 $localFileDirectory = "C:\unicode_Countries\"
 $ContainerName = “blob-dev”
 
 
$destfolder = "IATI"
 
$blobContext = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey
 

$SQLServer = "(local)" #use Server\Instance for named SQL instances! 
$SQLDBName = "DashboardDb"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
#$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True;"
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = false; UID=..; PWD=...."
$SqlConnection.Open()
$execute_query = New-Object System.Data.SqlClient.SqlCommand
$execute_query.connection = $SqlConnection

$cacheControlValue = "public, max-age=60480" 

 [String]  $sqlcmd = "SELECT [USG_Name], [LocationCode], [XMLFileName] , [activityCount],[last_updated_datetime] ,[XMLType]   FROM  [dbo].[Transactions_XMLExport_XmlFiles] where XMLType='COUNTRY'  or XMLType='REGION' or XMLType='REG_998' ";
  
$execute_query.CommandText = $sqlcmd
$adp = New-Object System.Data.SqlClient.SqlDataAdapter $execute_query
$dataSet = New-Object System.Data.DataSet 
$adp.Fill($dataSet) | Out-Null 
$SqlConnection.Close()
$Result = $dataSet.Tables[0]
$ExeList = @();
Write-Host  $Result.Rows.Count $ExeList.Count -ForegroundColor  green 

Foreach ($Record in $Result) {
   
    $recipientname  = $Record.XMLFileName
     Write-Host  $recipientname   -ForegroundColor  green 
    $blob  = Get-AzureStorageBlob -Container $ContainerName -Context $blobContext -blob  IATI/$recipientname
    $CloudBlockBlob = [Microsoft.WindowsAzure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob
    $cloudBlockBlob.Metadata["filename"] = $Record.XMLFileName
    $cloudBlockBlob.Metadata["activity_count"] =  $Record.activityCount
    $cloudBlockBlob.Metadata["generated_date"] =  $Record.last_updated_datetime.replace("Z","")
    $cloudBlockBlob.Metadata["version"] = "2.02"
    $cloudBlockBlob.SetMetadata()  
}
