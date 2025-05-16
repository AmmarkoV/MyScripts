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
    <title>Computer Vision News..</title>

<style>
a:link {
  color: black;
  background-color: transparent;
  text-decoration: none;
}

a:visited {
  color: #999999;
  background-color: transparent;
  text-decoration: none;
}

a:hover {
  color: red;
  background-color: transparent;
  text-decoration: underline;
}

a:active {
  color: yellow;
  background-color: transparent;
  text-decoration: underline;
}
</style> 

    <script>


        function resetDescriptions() {
            const keywordInput = document.getElementById('filter-input').value.toLowerCase();
            const keywords = keywordInput.split(' ').filter(word => word.trim() !== ''); // Split input into words
            
            const descriptions = document.querySelectorAll('.description-item');
            
            descriptions.forEach(function(description) {
                description.style.display = 'block'; // Show matching lines 
            });
        }

        // Function to filter descriptions based on the input
        function filterDescriptions() {
            const keywordInput = document.getElementById('filter-input').value.toLowerCase();
            const keywords = keywordInput.split(' ').filter(word => word.trim() !== ''); // Split input into words
            
            const descriptions = document.querySelectorAll('.description-item');
            
            descriptions.forEach(function(description) {
                const text = description.textContent.toLowerCase();
                const matches = keywords.some(keyword => text.includes(keyword));
                
                if (matches) {
                    description.style.display = 'block'; // Show matching lines
                } else {
                    description.style.display = 'none'; // Hide non-matching lines
                }
            });
        }

        // Function to fill the textbox with predefined keywords and filter
        function setKeywords(keywords) 
       {
            document.getElementById('filter-input').value = keywords;
            filterDescriptions(); // Trigger the filtering
        }
    </script>
</head>
<body bgcolor="#CCCCCC">
    <h1>Computer Vision News..</h1>

    <table>
     <tr>
      <td width=40> </td>
      <td>
    
    <?php
    // Output the previous day's .description.png file if it exists
    if (in_array($yesterdayFile, $descriptionPngFiles)) {
        echo "<p><center><img src='{$directory}{$yesterdayFile}' alt='$yesterdayFile' style='max-width:60%; height:auto;'></center></p>";
    } else {
        echo "<p>No description PNG file for yesterday ($yesterday) found.</p>";
    }

    // Output the .description files
    echo "<h2>Description Files</h2>";

    // Text input for filtering and buttons for setting keywords
    echo "<button onclick=\"resetDescriptions()\">C</button>";
    echo "<input type='text' id='filter-input' onkeyup='filterDescriptions()' placeholder='Type keywords to filter'>";
    
    // Add buttons to set specific keywords for different computer vision areas
    echo "<button onclick=\"setKeywords('pose body hand HPE')\">Pose</button>";
    echo "<button onclick=\"setKeywords('action anticipation')\">Action</button>";
    echo "<button onclick=\"setKeywords('caption')\">Caption</button>";
    echo "<button onclick=\"setKeywords('count agnostic')\">Counting</button>";
    echo "<button onclick=\"setKeywords('depth 3D reconstruction')\">Depth</button>";
    echo "<button onclick=\"setKeywords('segmentation mask classification R-CNN')\">Segmentation</button>";
    echo "<button onclick=\"setKeywords('detection YOLO')\">Detection</button>";
    echo "<button onclick=\"setKeywords('tracking video multi-object')\">Tracking</button>";
    echo "<button onclick=\"setKeywords('transformer attention')\">Transformer</button>";
    
    $count = 1;
    $file = $yesterdayDescFile;
    if (file_exists($directory . $file)) {
        //echo "<h3>$file</h3>";
        echo "<h3>$yesterday</h3>";

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

 </td>
 <td width=40></td>
 </table>

</body>
</html>

