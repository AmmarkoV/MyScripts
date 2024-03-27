from datetime import datetime

# Conference deadlines dictionary
conference_deadlines = {
    "CVPR": "November-December",
    "ECCV": "March-April",
    "ICML": "January-February",
    "NeurIPS": "May-June",
    "ICCV": "March-April",
    "IJCAI": "January-February"
}

# Function to generate HTML for conference tables
def generate_html():
    months = [
        "January", "February", "March", "April", 
        "May", "June", "July", "August", 
        "September", "October", "November", "December"
    ]

    # Current year and month
    current_year = datetime.now().year
    current_month = datetime.now().month

    # Open HTML file for writing
    with open("conference_deadlines.html", "w") as file:
        # Write HTML header
        file.write("<!DOCTYPE html>\n<html>\n<head>\n<title>Conference Deadlines</title>\n")
        # Write JavaScript for highlighting current month and next three months
        file.write("<script>\n")
        file.write("document.addEventListener('DOMContentLoaded', function() {\n")
        file.write(f"    var currentMonth = {current_month} - 1;\n")
        file.write("    var tables = document.getElementsByTagName('table');\n")
        file.write("    for (var i = 0; i < tables.length; i++) {\n")
        file.write("        if (i >= currentMonth && i <= currentMonth + 3) {\n")
        file.write("            tables[i].style.background = '#FFFF99';\n")
        file.write("        }\n")
        file.write("    }\n")
        file.write("});\n")
        file.write("</script>\n")
        file.write("</head>\n<body>\n")

        # Iterate over months
        for i, month in enumerate(months):
            # Write month heading
            file.write(f"<h2>{month} {current_year}</h2>\n")
            # Write table start tag
            file.write("<table border='1'>\n")
            # Write table header
            file.write("<tr><th>Conference</th><th>Submission Deadline</th></tr>\n")

            # Iterate over conference deadlines
            for conference, deadline in conference_deadlines.items():
                # Check if submission deadline is in the current month
                if month.lower() in deadline.lower():
                    # Write table row for conference
                    file.write(f"<tr><td>{conference}</td><td>{deadline}</td></tr>\n")

            # Write table end tag
            file.write("</table>\n")
        
        # Write HTML footer
        file.write("</body>\n</html>")

# Call function to generate HTML
generate_html()

