from keras.layers import Input, Dense
from keras.models import Model
import numpy as np 
import csv

# this is the size of our encoded representations
encoding_dim = 16  # 32 floats -> compression of factor 24.5, assuming the input is 784 floats

# this is our input placeholder
input_img = Input(shape=(36,))
# "encoded" is the encoded representation of the input
encoded = Dense(encoding_dim, activation='relu')(input_img)
# "decoded" is the lossy reconstruction of the input
decoded = Dense(36, activation='sigmoid')(encoded)

# this model maps an input to its reconstruction
autoencoder = Model(input_img, decoded)

# this model maps an input to its encoded representation
encoder = Model(input_img, encoded)

# create a placeholder for an encoded (32-dimensional) input
encoded_input = Input(shape=(encoding_dim,))
# retrieve the last layer of the autoencoder model
decoder_layer = autoencoder.layers[-1]
# create the decoder model
decoder = Model(encoded_input, decoder_layer(encoded_input))

autoencoder.compile(optimizer='adadelta', loss='binary_crossentropy')


fo = open("cache.dat", "r")

solutionList= list() # empty list
compressedList= list() # empty list
pointsList = list() # empty list

i=0
reader = csv.reader( fo , delimiter ='|')
for r in reader:
    
    #print r
    items = csv.reader( r , delimiter =',', skipinitialspace=True)    
    for f in items:
          #print(i%3)
          if (i%3==0) : 
             #print("Solution :")
             solutionList.append(f)
          if (i%3==1) : 
             #print("Compressed :")
             compressedList.append(f)
          if (i%3==2) : 
             #print("Points2D :")
             pointsList.append(f)
          i=i+1
          #print(f)


fo.close()

  
npPoints = np.asarray(pointsList)
npSolution = np.asarray(solutionList)

print(npPoints.shape)
print(npSolution.shape)


history = autoencoder.fit(npPoints,npSolution,
                epochs=1050,
                batch_size=256,
                shuffle=True,
                validation_data=(npPoints,npSolution))


#autoencoder.save("autoencoder_save", overwrite=True)
#encoder.save("encoder_save", overwrite=True)
#decoder.save("decoder_save", overwrite=True)

# encode and decode some digits
# note that we take them from the *test* set
encoded_tests = encoder.predict(npPoints)
decoded_tests = decoder.predict(encoded_tests)



import matplotlib.pyplot as plt 

# summarize history for loss
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('model loss')
plt.ylabel('loss')
plt.xlabel('epoch')
plt.legend(['train', 'test'], loc='upper right')
plt.show()


 

