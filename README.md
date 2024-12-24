# PDF Generation Script

A pretty simple PowerShell script that helps bypass Scribd's requirement for uploading unique PDFs before downloading user-uploaded PDFs.

## Description

This script generates a unique PDF file by adding random text and images to a blank PDF. This helps users to make five unique documents in order to download a PDF.

⚠️ **Disclaimer**: This script is for educational purposes only. Please respect websites' terms of service and copyright laws.

## Prerequisites

- PowerShell 5.1 or higher
- Internet connection (to download dummy images from picsum.photos)

## Usage
Download the script and the `content.txt` file, then run it in powershell:
```powershell
.\generate_pdf.ps1 
```
you will see the 5 pdfs in a new generated folder. Every time you run the script, it will generate 5 new unique pdfs and remove the old ones.
