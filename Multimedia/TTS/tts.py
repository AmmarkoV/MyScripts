import os
import subprocess
import tkinter as tk
from tkinter import filedialog
from kokoro import KPipeline
import soundfile as sf

def play_wav(file_path):
    """Play the WAV file using paplay."""
    try:
        subprocess.run(["paplay", file_path], check=True)
    except FileNotFoundError:
        print("Error: paplay not found. Make sure you have pulseaudio-utils installed.")
    except subprocess.CalledProcessError as e:
        print(f"Error playing file: {e}")

def generate_speech(text, voice='af_bella', speed=1):
    """Generate speech from text using Kokoro and save it as WAV files."""
    pipeline = KPipeline(lang_code='a')
    generator = pipeline(text, voice=voice, speed=speed, split_pattern=r'\n+')
    
    file_paths = []
    for i, (gs, ps, audio) in enumerate(generator):
        file_path = f"{i}.wav"
        sf.write(file_path, audio, 24000)
        file_paths.append(file_path)
    
    return file_paths
 

def combine_wavs_to_mp3(wav_files, output_mp3="output.mp3"):
    """Combine multiple WAV files into a single MP3 file using ffmpeg."""
    with open("wav_list.txt", "w") as f:
        for wav in wav_files:
            f.write(f"file '{wav}'\n")

    os.system("ffmpeg -y -f concat -safe 0 -i wav_list.txt -acodec libmp3lame " + output_mp3)
    os.remove("wav_list.txt")  # Cleanup
    print(f"Combined MP3 saved as {output_mp3}")


def upload_and_play():
    """Open a file dialog to select a WAV file and play it."""
    root = tk.Tk()
    root.withdraw()  # Hide the root window
    file_path = filedialog.askopenfilename(filetypes=[("WAV files", "*.wav")])
    
    if file_path:
        print(f"Playing: {file_path}")
        play_wav(file_path)
    else:
        print("No file selected.")

if __name__ == "__main__":
    text = '''

Can't read my, can't read my
No, he can't read my poker face (she's got me like nobody)
Can't read my, can't read my
No, he can't read my poker face (she's got me like nobody)

Po-po-po-poker face, fu-fu-fuck her face (mum-mum-mum-mah)
Po-po-po-poker face, fu-fu-fuck her face (mum-mum-mum-mah)

'''  # Example text
    files = generate_speech(text)

    combine_wavs_to_mp3(files, output_mp3="output.mp3")

    for file in files:
        play_wav(file)
    
    # Combine all generated WAV files into a single MP3
    combine_wavs_to_mp3(files)

