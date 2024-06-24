import sys
import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter
from wordcloud import WordCloud

def read_descriptions(file_path):
    descriptions = []
    with open(file_path, 'r') as file:
        for line in file:
            descriptions.append(line.lower().strip())
    return descriptions

def count_word_frequencies(descriptions):
    word_frequencies = Counter()
    for description in descriptions:
        words = description.split()
        word_frequencies.update(words)
    return word_frequencies

def filter_words(word_frequencies, filtered_words):
    for word in filtered_words:
        if word in word_frequencies:
            del word_frequencies[word]
    return word_frequencies

def generate_word_cloud(word_frequencies, output_file):
    # Specify the path to a TrueType font file (e.g., Arial)
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    wordcloud = WordCloud(width=1920, height=1080, background_color='black', font_path=font_path).generate_from_frequencies(word_frequencies)
    scale = 5
    plt.figure(figsize=(scale*10, scale*5))
    plt.imshow(wordcloud, interpolation='bilinear')
    plt.axis('off')
    plt.savefig(output_file, bbox_inches='tight')
    #plt.show()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <descriptions_file>")
        sys.exit(1)

    descriptions_file = sys.argv[1]
    descriptions     = read_descriptions(descriptions_file)
    word_frequencies = count_word_frequencies(descriptions)

    filtered_words = ['a', 'in', 'is', 'through', 'using', 'based', 'via', 'for', 'non', 'to', 'of', 'an', 'your', 'and', 'etc', 'the', 'from', 'by', 'on', 'end', 'with']
    word_frequencies = filter_words(word_frequencies, filtered_words)

    generate_word_cloud(word_frequencies, '%s.png'%sys.argv[1])

