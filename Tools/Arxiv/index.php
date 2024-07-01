<?php
//Do : crontab -e and then add
// 0 23 * * * /bin/bash -c 'source /home/ammar/.bashrc && /usr/bin/python3 /home/ammar/public_html/news/getArxivNews.py'

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
</head>
<body>
    <h1>News..</h1>
    
    <?php
    // Debugging: Output the previous day and the list of PNG files
    //echo "<p>Yesterday's date: $yesterday</p>";
    //echo "<p>Yesterday's file: $yesterdayFile</p>";
    //echo "<p>Available .description.png files:</p>";
    //echo "<ul>";
    //foreach ($descriptionPngFiles as $file) {
    //    echo "<li>$file</li>";
    // }
    //echo "</ul>";

    // Output the previous day's .description.png file if it exists
    if (in_array($yesterdayFile, $descriptionPngFiles)) {
        //echo "<h2>Yesterday's Description PNG</h2>";
        echo "<p><img src='{$directory}{$yesterdayFile}' alt='$yesterdayFile' style='max-width:100%; height:auto;'></p>";
    } else {
        echo "<p>No description PNG file for yesterday ($yesterday) found.</p>";
    }

    // Output the .description files
    echo "<h2>Description Files</h2>";
    #foreach ($descriptionFiles as $file)

    $count = 1;
    $file = $yesterdayDescFile ;
    {
        echo "<h3>$file</h3>";
        $content = file_get_contents($directory . $file);
        $lines = explode("\n", htmlspecialchars($content));
        foreach ($lines as $line) 
        {
            $trimmedLine = trim($line);
            if (!empty($trimmedLine)) 
            {
                echo "<p><a href='https://www.google.com/search?q=" . urlencode($trimmedLine) . "' target='_blank'>".$count." - ".$trimmedLine."</a></p>";
                $count = $count + 1;
    
            }

        }
    }


    ?>
</body>
</html>

