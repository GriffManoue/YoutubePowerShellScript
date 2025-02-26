<#
.SYNOPSIS
    YouTube ChatGPT Tutorials Finder - Searches and exports top ChatGPT coding tutorials.

.DESCRIPTION
    This script uses the YouTube Data API to find the most viewed tutorials related to ChatGPT 
    coding and scripting. It combines search results, sorts them by view count, and exports
    the top 50 videos to a CSV file.

.NOTES
    File Name      : YoutubeCodingTutorials.ps1
    Author         : Buga Péter
    Prerequisite   : PowerShell 5.1 or higher
                     Internet connection
                     Valid YouTube Data API key

.DEPENDENCIES
    - PowerShell 5.1+ (comes pre-installed on Windows 10/11)
    - No additional modules required
    - YouTube Data API key

.INSTALLATION
    No special installation needed. Just ensure you have:
    1. A valid YouTube Data API key and replace "[Your API Key]" with your key.
    2. PowerShell 5.1 or higher (check with $PSVersionTable.PSVersion)

.EXAMPLE
    PS> .\YoutubeCodingTutorials.ps1

.TESTING
    Run the Test-YouTubeApiConnection function to verify API connectivity:
    PS> Test-YouTubeApiConnection
#>

# Function to test YouTube API connectivity
function Test-YouTubeApiConnection {
    param (
        [string]$ApiKey = "[Your API Key]"
    )
    
    try {
        $testUrl = "https://www.googleapis.com/youtube/v3/videos?part=snippet&chart=mostPopular&maxResults=1&key=$ApiKey"
        $response = Invoke-RestMethod -Uri $testUrl -Method Get
        Write-Host "API connection successful! Retrieved video: $($response.items[0].snippet.title)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "API connection failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# To run the test, use: Test-YouTubeApiConnection
# YouTube Data API is required for searching.
$apiKey = "[Your API Key]"

# Search terms
$queryScript = "scripting ChatGPT"
$queryCode = "coding ChatGPT"

# Maximum number of results to retrieve
$maxResults = 50

# Output file name
$outputFile = "ChatGPT_Tutorials.csv"

# YouTube Data API search URLs
$searchUrlScript = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=$queryScript&type=video&maxResults=$maxResults&order=viewCount&key=$apiKey"
$searchUrlCode = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=$queryCode&type=video&maxResults=$maxResults&order=viewCount&key=$apiKey"

# Invoke API requests
$responseScript = Invoke-RestMethod -Uri $searchUrlScript -Method Get
$responseCode = Invoke-RestMethod -Uri $searchUrlCode -Method Get

# Combine search results from both queries
$combinedResults = $responseScript.items + $responseCode.items

# Extract unique video IDs
$videoIds = $combinedResults | ForEach-Object { $_.id.videoId } | Select-Object -Unique
$videoIdBatches = for ($i = 0; $i -lt $videoIds.Count; $i += 50) {
    $videoIds[$i..([Math]::Min($i+49, $videoIds.Count-1))]
}

# Array to store all video details
$allVideoDetails = @()

# Retrieve video details in batches of 50
foreach ($batch in $videoIdBatches) {
    $videoIdsString = [string]::Join(",", $batch)
    $videoStatsUrl = "https://www.googleapis.com/youtube/v3/videos?part=statistics,snippet&id=$videoIdsString&key=$apiKey"
    $videoStatsResponse = Invoke-RestMethod -Uri $videoStatsUrl -Method Get
    $allVideoDetails += $videoStatsResponse.items
}

# Sort videos by view count and select top 50
$top50Videos = $allVideoDetails | 
    Sort-Object { [long]$_.statistics.viewCount } -Descending | 
    Select-Object -First 50

# Format video details for output
$formattedPairs = $top50Videos | ForEach-Object {
    "$($_.snippet.title)`thttps://www.youtube.com/watch?v=$($_.id)"
}

# Combine formatted pairs into a single string
$formattedOutput = [string]::Join(",", $formattedPairs)

# Export results to a CSV file
$formattedOutput | Out-File -FilePath $outputFile

# Output success message
Write-Output "A keresés eredményei mentve lettek: $outputFile"
