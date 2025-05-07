import os
import subprocess
import gradio as gr
from kokoro import KPipeline
import soundfile as sf

#LD_PRELOAD=/usr/local/cuda-12.4/lib64/libcusparse.so.12 python3 server.py 


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
    """Combine multiple WAV files into a single MP3 file."""
    with open("wav_list.txt", "w") as f:
        for wav in wav_files:
            f.write(f"file '{wav}'\n")
    os.system(f"ffmpeg -y -f concat -safe 0 -i wav_list.txt -acodec libmp3lame {output_mp3}")
    os.remove("wav_list.txt")
    return output_mp3

def text_to_speech(text):
    """Generate speech from text and return the MP3 file for playback."""
    wav_files = generate_speech(text)
    mp3_file = combine_wavs_to_mp3(wav_files)
    return mp3_file, mp3_file

gui = gr.Interface(
    fn=text_to_speech,
    inputs=gr.Textbox(label="Enter text"),
    outputs=[gr.Audio(label="Listen"), gr.File(label="Download MP3")],
    title="Text-to-Speech Generator",
    description="Enter text and receive an MP3 file with synthesized speech."
)

gui.launch()


