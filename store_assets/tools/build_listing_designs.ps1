# Builds Play Store listing designs from the raw screenshots in
# store_assets/play_listing/{phone,tablet_7,tablet_10}.
#
# The screenshot bitmap is pasted 1:1 — never scaled, cropped or recoloured —
# onto a larger branded canvas, so the design cannot distort what the app
# actually rendered. Everything else (background, grid, caption, bezel) is drawn
# around it. Re-run after recapturing screenshots:
#
#   powershell -ExecutionPolicy Bypass -File store_assets/tools/build_listing_designs.ps1
#
# Colours mirror lib/app/theme/app_colors.dart.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$listing = Join-Path $repo 'store_assets\play_listing'
$outRoot = Join-Path $listing 'designs'

# --- brand palette (app_colors.dart) ---
$forest = [System.Drawing.Color]::FromArgb(0x63, 0x89, 0x7A)
$ink = [System.Drawing.Color]::FromArgb(0x1B, 0x28, 0x22)
$warmWhite = [System.Drawing.Color]::FromArgb(0xFB, 0xFA, 0xF5)
$mist = [System.Drawing.Color]::FromArgb(0xE4, 0xEC, 0xE6)
$grid = [System.Drawing.Color]::FromArgb(60, 0x63, 0x89, 0x7A)

function New-RoundedPath([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# Draws text centred on $cx, one character at a time, so the eyebrow label can
# carry real letter spacing (GDI+ has no tracking property).
function Draw-Tracked($g, [string]$text, $font, $brush, [single]$cx, [single]$y, [single]$track) {
    $chars = $text.ToCharArray()
    $total = 0
    foreach ($c in $chars) {
        $total += $g.MeasureString([string]$c, $font, 0, [System.Drawing.StringFormat]::GenericTypographic).Width + $track
    }
    $total -= $track
    $x = $cx - $total / 2
    foreach ($c in $chars) {
        $g.DrawString([string]$c, $font, $brush, $x, $y)
        $x += $g.MeasureString([string]$c, $font, 0, [System.Drawing.StringFormat]::GenericTypographic).Width + $track
    }
}

# Greedy wrap into at most 2 lines that fit $maxWidth.
function Wrap-Caption($g, [string]$text, $font, [single]$maxWidth) {
    $words = $text -split '\s+'
    $lines = @()
    $current = ''
    foreach ($w in $words) {
        $candidate = if ($current -eq '') { $w } else { "$current $w" }
        if ($g.MeasureString($candidate, $font).Width -le $maxWidth -or $current -eq '') {
            $current = $candidate
        }
        else {
            $lines += $current
            $current = $w
        }
    }
    if ($current -ne '') { $lines += $current }
    return , $lines
}

function Build-Design([string]$srcPath, [string]$outPath, [string]$eyebrow, [string]$caption) {
    $src = New-Object System.Drawing.Bitmap $srcPath
    try {
        $scale = $src.Width / 1080.0
        $padX = [int](100 * $scale)
        $bottom = [int](92 * $scale)
        $bezel = [int](14 * $scale)

        # Measure the caption first so the header is exactly as tall as it needs
        # to be: the accent rule must never collide with a wrapped second line.
        $measureFont = New-Object System.Drawing.Font 'Segoe UI Semibold', ([single](58 * $scale)), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
        $scratch = New-Object System.Drawing.Bitmap 1, 1
        $mg = [System.Drawing.Graphics]::FromImage($scratch)
        $capTop = 176 * $scale
        $lineH = 74 * $scale
        $capLines = Wrap-Caption $mg $caption $measureFont ([single]($src.Width + 2 * $padX - 150 * $scale))
        $mg.Dispose(); $scratch.Dispose()
        $ruleY = $capTop + $capLines.Count * $lineH + 30 * $scale
        $header = [int]($ruleY + 62 * $scale)

        $cw = $src.Width + 2 * $padX
        $ch = $src.Height + $header + $bottom
        $canvas = New-Object System.Drawing.Bitmap $cw, $ch
        $g = [System.Drawing.Graphics]::FromImage($canvas)
        try {
            $g.SmoothingMode = 'AntiAlias'
            $g.TextRenderingHint = 'ClearTypeGridFit'
            $g.InterpolationMode = 'HighQualityBicubic'
            $g.PixelOffsetMode = 'HighQuality'

            # background wash: brand mist at the top fading into warm white
            $rect = New-Object System.Drawing.Rectangle 0, 0, $cw, $ch
            $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $mist, $warmWhite, 90.0
            $g.FillRectangle($bg, $rect)
            $bg.Dispose()

            # faint grid paper, echoing the app's own background
            $step = [int](64 * $scale)
            $gridPen = New-Object System.Drawing.Pen $grid, ([single](1 * $scale))
            for ($x = $step; $x -lt $cw; $x += $step) { $g.DrawLine($gridPen, $x, 0, $x, $ch) }
            for ($y = $step; $y -lt $ch; $y += $step) { $g.DrawLine($gridPen, 0, $y, $cw, $y) }
            $gridPen.Dispose()

            $cx = $cw / 2.0

            # eyebrow (module label)
            $eyeFont = New-Object System.Drawing.Font 'Segoe UI Semibold', ([single](26 * $scale)), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
            $forestBrush = New-Object System.Drawing.SolidBrush $forest
            Draw-Tracked $g $eyebrow.ToUpper() $eyeFont $forestBrush $cx ([single](108 * $scale)) ([single](7 * $scale))

            # caption headline
            $inkBrush = New-Object System.Drawing.SolidBrush $ink
            $fmt = New-Object System.Drawing.StringFormat
            $fmt.Alignment = 'Center'
            $y = $capTop
            foreach ($line in $capLines) {
                $g.DrawString($line, $measureFont, $inkBrush, $cx, $y, $fmt)
                $y += $lineH
            }

            # short accent rule under the headline
            $rulePen = New-Object System.Drawing.Pen $forest, ([single](5 * $scale))
            $ruleHalf = 54 * $scale
            $g.DrawLine($rulePen, $cx - $ruleHalf, $ruleY, $cx + $ruleHalf, $ruleY)
            $rulePen.Dispose()

            # device bezel + soft shadow
            $bx = $padX - $bezel
            $by = $header - $bezel
            $bw = $src.Width + 2 * $bezel
            $bh = $src.Height + 2 * $bezel
            $radius = 46 * $scale
            for ($i = 10; $i -ge 1; $i--) {
                $spread = $i * 3 * $scale
                $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(6, 0x1B, 0x28, 0x22))
                $path = New-RoundedPath ($bx - $spread) ($by - $spread + 4 * $scale) ($bw + 2 * $spread) ($bh + 2 * $spread) ($radius + $spread)
                $g.FillPath($shadow, $path)
                $path.Dispose(); $shadow.Dispose()
            }
            $bezelBrush = New-Object System.Drawing.SolidBrush $ink
            $bezelPath = New-RoundedPath $bx $by $bw $bh $radius
            $g.FillPath($bezelBrush, $bezelPath)
            $bezelPath.Dispose(); $bezelBrush.Dispose()

            # the screenshot itself: pasted at native size, untouched
            $g.DrawImage($src, (New-Object System.Drawing.Rectangle $padX, $header, $src.Width, $src.Height),
                0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel)

            $eyeFont.Dispose(); $measureFont.Dispose(); $forestBrush.Dispose(); $inkBrush.Dispose(); $fmt.Dispose()
        }
        finally { $g.Dispose() }

        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outPath) | Out-Null
        $canvas.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $canvas.Dispose()
        "{0,-46} {1}x{2}" -f (Split-Path -Leaf $outPath), $cw, $ch
    }
    finally { $src.Dispose() }
}

# --- shot list: file -> eyebrow, caption -------------------------------------
$phone = [ordered]@{
    'phone_01_home'                = @('Workspace', 'Every academic tool in one place')
    'phone_02_equation_solver'     = @('Equation solver', 'Roots, and the method behind them')
    'phone_03_graphing'            = @('Graphing', 'Compare functions on one canvas')
    'phone_04_calculus_analysis'   = @('Calculus', 'Roots, extrema and intervals')
    'phone_05_statistics'          = @('Statistics', 'Datasets into clear measures')
    'phone_06_financial_npv'       = @('Finance', 'Educational cash-flow scenarios')
    'phone_07_operations_research' = @('Operations research', 'Assignment and optimization models')
    'phone_08_saved'               = @('Saved work', 'Results organized on device')
}
$tablet = [ordered]@{
    '01_home'                = @('Workspace', 'A workspace that scales up')
    '02_matrix'              = @('Linear algebra', 'Multiply, invert, inspect matrices')
    '03_graphing'            = @('Graphing', 'Compare functions on one canvas')
    '04_operations_research' = @('Operations research', 'Assignment and optimization models')
}

foreach ($name in $phone.Keys) {
    Build-Design (Join-Path $listing "phone\$name.png") (Join-Path $outRoot "phone\$name.png") $phone[$name][0] $phone[$name][1]
}
foreach ($suffix in $tablet.Keys) {
    Build-Design (Join-Path $listing "tablet_7\tablet7_$suffix.png") (Join-Path $outRoot "tablet_7\tablet7_$suffix.png") $tablet[$suffix][0] $tablet[$suffix][1]
    Build-Design (Join-Path $listing "tablet_10\tablet10_$suffix.png") (Join-Path $outRoot "tablet_10\tablet10_$suffix.png") $tablet[$suffix][0] $tablet[$suffix][1]
}
