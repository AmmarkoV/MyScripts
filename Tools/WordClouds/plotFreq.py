import pandas as pd
import matplotlib.pyplot as plt

"""
# Read the word frequencies into a DataFrame
word_freq = pd.read_csv('cvpr_word_frequencies.txt', delim_whitespace=True, header=None, names=['count', 'word'])

# Plot the frequencies
plt.figure(figsize=(10, 6))
plt.bar(word_freq['word'][:40], word_freq['count'][:40])  # Plot top 20 words
plt.xlabel('Words')
plt.ylabel('Frequencies')
plt.title('Top 40 Word Frequencies')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
"""
#pip install wordcloud matplotlib
import matplotlib.pyplot as plt
from wordcloud import WordCloud

# Read the word frequencies from the file
word_frequencies = {}

with open('cvpr_word_frequencies.txt', 'r') as file:
    for line in file:
        count, word = line.strip().split()
        word_frequencies[word] = int(count)

# Define a list of filtered out words
filtered_words = ['a', 'in', 'based', 'via', 'for', 'to', 'of', 'and', 'etc', 'with']  # Add more words as needed

# Remove filtered words from word frequencies
for word in filtered_words:
    if word in word_frequencies:
        del word_frequencies[word]

# Generate the word cloud
wordcloud = WordCloud(width=1080, height=1920, background_color='black').generate_from_frequencies(word_frequencies)

# Display the word cloud using matplotlib
scale = 5
plt.figure(figsize=(scale*10, scale*5))
plt.imshow(wordcloud, interpolation='bilinear')
plt.axis('off')

plt.savefig('cvpr_word_cloud.png', bbox_inches='tight')
plt.show()

