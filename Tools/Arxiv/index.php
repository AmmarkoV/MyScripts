<?php
// Set the directory path
$directory = './';

// Ensure the directory path ends with a slash
if (substr($directory, -1) !== '/') {
    $directory .= '/';
}

// Get all files from the directory
$files = scandir($directory);

// Filter and sort files
$descriptionFiles = [];
$descriptionPngFiles = [];
foreach ($files as $file) {
    if (strpos($file, '.description.png') !== false) {
        $descriptionPngFiles[] = $file;
    } elseif (strpos($file, '.description') !== false) {
        $descriptionFiles[] = $file;
    }
}

// Sort files by name
sort($descriptionFiles);
sort($descriptionPngFiles);

// Get previous day's date
$yesterday = date('Y-m-d', strtotime('yesterday'));
$yesterdayFile = $yesterday . '.description.png';
$yesterdayDescFile = $yesterday . '.description';

?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>News..</title>
    <script>
        function filterDescriptions() {
            const keyword = document.getElementById('filter-input').value.toLowerCase();
            const descriptions = document.querySelectorAll('.description-item');
            
            descriptions.forEach(function(description) {
                const text = description.textContent.toLowerCase();
                if (text.includes(keyword)) {
                    description.style.display = 'block'; // Show matching lines
                } else {
                    description.style.display = 'none'; // Hide non-matching lines
                }
            });
        }
    </script>
</head>
<body>
    <h1>News..</h1>
    
    <?php
    // Output the previous day's .description.png file if it exists
    if (in_array($yesterdayFile, $descriptionPngFiles)) {
        echo "<p><img src='{$directory}{$yesterdayFile}' alt='$yesterdayFile' style='max-width:100%; height:auto;'></p>";
    } else {
        echo "<p>No description PNG file for yesterday ($yesterday) found.</p>";
    }

    // Output the .description files
    echo "<h2>Description Files</h2>";

    // Text input for filtering
    echo "<input type='text' id='filter-input' onkeyup='filterDescriptions()' placeholder='Type a keyword to filter'>";
    
    $count = 1;
    $file = $yesterdayDescFile;
    if (file_exists($directory . $file)) {
        echo "<h3>$file</h3>";
        $content = file_get_contents($directory . $file);
        $lines = explode("\n", htmlspecialchars($content));
        echo "<div id='description-list'>";
        foreach ($lines as $line) {
            $trimmedLine = trim($line);
            if (!empty($trimmedLine)) {
                echo "<p class='description-item'><a href='https://www.google.com/search?q=" . urlencode($trimmedLine) . "' target='_blank'>".$count." - ".$trimmedLine."</a></p>";
                $count++;
            }
        }
        echo "</div>";
    }
    ?>
</body>
</html>

