# PowerShell Script to Generate Dummy PDFs with Images

# Define the folder name and temp image folder
$folderName = Join-Path $PSScriptRoot "pdf_for_dummies"
$imageFolder = Join-Path $PSScriptRoot "temp_images"
$contentFile = Join-Path $PSScriptRoot "content.txt"

# Create necessary folders
@($folderName, $imageFolder) | ForEach-Object {
    if (-Not (Test-Path -Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
        Write-Output "Created folder: $_"
    }
}

# Remove existing PDF files
Get-ChildItem -Path $folderName -Filter *.pdf -Force | Remove-Item -Force
Write-Output "Removed existing PDF files in $folderName"

# Function to download random images
function Get-RandomImages {
    param (
        [int]$Count = 3
    )
    
    $images = @()
    for ($i = 1; $i -le $Count; $i++) {
        $randomId = Get-Random -Minimum 1 -Maximum 1000
        $width = Get-Random -Minimum 300 -Maximum 800
        $height = Get-Random -Minimum 300 -Maximum 800
        $url = "https://picsum.photos/$width/$height"
        $imagePath = Join-Path $imageFolder "image$i.jpg"
        
        try {
            Invoke-WebRequest -Uri $url -OutFile $imagePath
            if (Test-Path $imagePath) {
                $images += $imagePath
                Write-Output "Downloaded image: $imagePath"
            }
        }
        catch {
            Write-Output "Failed to download image $i : $_"
        }
    }
    return $images
}

# Function to convert image to base64
function Convert-ImageToBase64 {
    param (
        [string]$ImagePath
    )
    
    try {
        if (Test-Path $ImagePath) {
            $imageBytes = [System.IO.File]::ReadAllBytes([System.IO.Path]::GetFullPath($ImagePath))
            return [System.Convert]::ToBase64String($imageBytes)
        } else {
            Write-Output "Image file not found: $ImagePath"
            return $null
        }
    }
    catch {
        Write-Output "Error converting image to base64: $_"
        return $null
    }
}

# Function to generate a PDF with images
function Generate-PDF {
    param (
        [string]$Content,
        [string[]]$ImagePaths,
        [string]$OutputPath
    )

    # Create image objects for PDF
    $imageObjects = ""
    $imageReferences = ""
    $yPosition = 700
    $validImages = 0
    
    for ($i = 0; $i -lt $ImagePaths.Count; $i++) {
        $imageBase64 = Convert-ImageToBase64 -ImagePath $ImagePaths[$i]
        if ($imageBase64) {
            $imageObjects += @"
${i}0 0 obj
<< /Type /XObject
   /Subtype /Image
   /Width 300
   /Height 200
   /ColorSpace /DeviceRGB
   /BitsPerComponent 8
   /Filter /DCTDecode
   /Length $($imageBase64.Length)
>>
stream
$imageBase64
endstream
endobj

"@

            $imageReferences += "/Im${i} ${i}0 0 R "
            $validImages++
        }
    }

    # Basic PDF structure with images
    $pdf = @"
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page
   /Parent 2 0 R
   /MediaBox [0 0 612 792]
   /Contents 4 0 R
   /Resources <<
        /Font << /F1 5 0 R >>
        /XObject << $imageReferences>>
   >>
>>
endobj
4 0 obj
<< /Length 1000 >>
stream
BT
/F1 12 Tf
50 750 Td
($Content) Tj
ET

"@

    # Add image placement commands
    $yPosition = 600
    for ($i = 0; $i -lt $validImages; $i++) {
        $pdf += @"
q
300 0 0 200 50 $yPosition cm
/Im${i} Do
Q

"@
        $yPosition -= 250
    }

    $pdf += @"
endstream
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
$imageObjects
xref
0 6
0000000000 65535 f
0000000010 00000 n
0000000060 00000 n
0000000110 00000 n
0000000250 00000 n
0000001300 00000 n
trailer
<< /Size 6 /Root 1 0 R >>
startxref
1380
%%EOF
"@

    try {
        [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($OutputPath), $pdf)
    }
    catch {
        Write-Output "Error writing PDF file: $_"
    }
}

# Function to make content larger
function Expand-Content {
    param (
        [string]$Content,
        [int]$RepeatCount = 50
    )
    
    $expandedContent = ""
    for ($i = 0; $i -lt $RepeatCount; $i++) {
        $expandedContent += $Content + "`n"
    }
    return $expandedContent
}

# Function to generate random filename from content words
function Get-RandomFileName {
    param (
        [string[]]$Words
    )
    
    $validWords = $Words | 
        Where-Object { $_.Length -gt 3 } | 
        ForEach-Object { $_.ToLower() -replace '[^a-zA-Z]', '' } |
        Where-Object { $_.Length -gt 3 }

    $wordCount = Get-Random -Minimum 2 -Maximum 4
    $selectedWords = $validWords | Get-Random -Count $wordCount
    return ($selectedWords -join "_") + ".pdf"
}

# Read content from file
if (Test-Path $contentFile) {
    $allContent = Get-Content -Path $contentFile -Raw
    $contentBlocks = $allContent -split "`n`n"
    $allWords = $allContent -split '\W+' | Where-Object { $_ -ne '' }
} else {
    Write-Output "Content file not found: $contentFile"
    exit
}

# Generate five PDFs
try {
    for ($i = 1; $i -le 5; $i++) {
        Write-Output "Generating PDF $i of 5..."
        
        # Download random images for this PDF
        $images = Get-RandomImages -Count 3
        
        # Select random content block and expand it
        $randomBlock = $contentBlocks | Get-Random
        $expandedContent = Expand-Content -Content $randomBlock
        
        # Generate filename from random words
        $fileName = Get-RandomFileName -Words $allWords
        $filePath = Join-Path -Path $folderName -ChildPath $fileName
        
        # Create PDF with images
        Generate-PDF -Content $expandedContent -ImagePaths $images -OutputPath $filePath
        Write-Output "Created PDF: $filePath"
    }
}
catch {
    Write-Output "Error generating PDFs: $_"
}
finally {
    # Cleanup temporary images
    if (Test-Path $imageFolder) {
        Remove-Item -Path $imageFolder -Recurse -Force
        Write-Output "Cleaned up temporary images"
    }
}

Write-Output "PDF generation completed."