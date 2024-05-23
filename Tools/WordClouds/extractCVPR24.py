def extract_titles(filename):
    titles = []
    with open(filename, 'r') as file:
        lines = file.readlines()
        
        # Initialize a flag to indicate the next line should be a title
        next_is_title = True
        
        for line in lines:
            # Strip the line of leading/trailing whitespace
            stripped_line = line.strip()
            
            # If the line is empty, set the flag to expect the next line as title
            if not stripped_line:
                next_is_title = True
            elif next_is_title:
                # If the flag is set and the line is not empty, it's a title
                titles.append(stripped_line)
                next_is_title = False  # Reset the flag
        
    return titles

# Define the input file
input_file = 'CVPR24.txt'

# Extract titles and print them
titles = extract_titles(input_file)
for title in titles:
    print(title)

