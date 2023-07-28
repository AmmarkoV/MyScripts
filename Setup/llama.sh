#!/bin/bash

git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make
cd models
wget https://huggingface.co/eachadea/ggml-vicuna-7b-1.1/resolve/main/ggml-vic7b-uncensored-q5_1.bin
cd ..
./main -m ./models/ggml-vic7b-uncensored-q5_1.bin -n 256 --repeat_penalty 1.0 --color -i -r "User:" -f prompts/chat-with-bob.txt

exit 0
