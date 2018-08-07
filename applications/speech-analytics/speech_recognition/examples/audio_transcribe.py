#!/usr/bin/env python3

import speech_recognition as sr

# obtain path to "english.wav" in the same folder as this script
from os import path
#AUDIO_FILE = path.join(path.dirname(path.realpath(__file__)), "english.wav")
AUDIO_FILE = path.join(path.dirname(path.realpath(__file__)), "french.aiff")
#AUDIO_FILE = path.join(path.dirname(path.realpath(__file__)), "chinese.flac")

# use the audio file as the audio source
r = sr.Recognizer()
with sr.AudioFile(AUDIO_FILE) as source:
    audio = r.record(source)  # read the entire audio file

# recognize speech using Sphinx
try:
    print("Sphinx thinks you said " + r.recognize_sphinx(audio))
except sr.UnknownValueError:
    print("Sphinx could not understand audio")
except sr.RequestError as e:
    print("Sphinx error; {0}".format(e))

# recognize speech using Google Speech Recognition
try:
    # for testing purposes, we're just using the default API key
    # to use another API key, use `r.recognize_google(audio, key="GOOGLE_SPEECH_RECOGNITION_API_KEY")`
    # instead of `r.recognize_google(audio)`
    print("Google Speech Recognition thinks you said " + r.recognize_google(audio))
except sr.UnknownValueError:
    print("Google Speech Recognition could not understand audio")
except sr.RequestError as e:
    print("Could not request results from Google Speech Recognition service; {0}".format(e))

# recognize speech using Google Cloud Speech
GOOGLE_CLOUD_SPEECH_CREDENTIALS = r"""{
  "type": "service_account",
  "project_id": "ds-linx",
  "private_key_id": "a60766b872aeaf1681267237db286dcc53a5f81f",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC5xXBOmBNkkw95\n1xnk69cS4EBuFucS4JUSJSlbh0ssmylW1lfpSmO6mPm82KwLs6ezdyfeZuZEz9Tf\nch+HN3PW/4c5ZS65FZUfH5ukbxD4TFOdf2IxjFmyC0cP/uylRTRsVaDUakW65joL\n3R6FDT+Se9+q0UJ7pmwKhipQMXmuRmvqB1aHMVyiPz4qUFshMj+3gJ8GB3NLbH1d\nabMiD2ctBGv/R9kXLzIkwc270kbutR/PyH3wWRQaDj8yrUYD8mt1RCA2p3vfAV80\nnrl4vMMGmFU8K4+XrvJvpPwT+YJf+Z7JN/76JKOyQN5i4Ty2uFiTIzoUICxPCk+V\nGN7QCsXlAgMBAAECggEAC9n5uTngetka8qXzY/Rbyzt9QMi7QywKtpaiVdGCzTy0\n3XJdN2fkhuH9hLu59iEnAL8ITxr3c8pihULNmh3CiSPSJ6o52drzoYGtt0bSqVSN\nPQ4EYK7YhhBMH0wfIsgQeRzZXtPM0QihCWK48LoQpTK76TTibesHF4DJsEYHwkNm\nCE+Tk8GJm6ommGoya1fHpjKdZvQ1Bs++dt30f8N8bREUHx8kuztJpI7Gf9+8YqOB\nbHFvRFPvg1KjNfLvyeWNUBoTrvIptN3fa3LW7YIu4XXWU17x5AKG12xbZRRMumhF\nVTx8DU1RbtTTqseuS6lvWczuJ8TtcZL80q1tMkdxHQKBgQDekIKWXyT7HWvq5qk4\nidXOG+K/hSOnpmLBR89yo/Vg88nEFuxzy7IrpyTpkzRZ6ebKCkPBxY2gQqpmUG7X\nzzSZYrEVBr3IDvkgkSjBouag0EpckVt7jQ59MlqKvWfMGboozN1nR9DBnTE5onOb\nMXwm1RRknlwTWSy1AHlH0IufEwKBgQDVreqkpONVwBw7x161/59eMxT9GonKHODB\nX7nDPAk8YLDwg29N4d3WMK7joQpojoR9FX4j19EIvEGWWk4+ZWXh5BPSfMPiSK4J\nSb5wzZ/7qNIeEM3rU6Xa8chnFg1YjNhtgUtEf7rDw7uLjJtdWea3ovozxYr1HEqR\nWv3EsXOOJwKBgQCbmFnDOKcI66u7oCBjx3Dy0+n0zOZ9WUQnLcXotplge27uKLyL\nw7c+725N4TyzM2PGkeCGwk7d4F1yg/7J3zE9npKASaM6DsW6L+FXZkRn3tZt2q0j\nNh0QB7jmz72WIdJUncyXXMyj3vo/+cNqlvDd0Q+dvFxQpoIr1DX1r+U8gwKBgFAL\nNEi008w9iNYD20DGHwcEj6o4lME3jCIkH8w44yTQ+7c9JSbBo34nAnyWyPVd3deV\ng4kdwVpKWy9daM4K4d16uMoynpZXr4ofK83J2VJGbV+B4AF1dj3MMMwdAKbZLAHp\nWy6vwmCvI8QkydZwZPMJhDx8lY84J97HfSR/bNAlAoGADappKQtXObbhwwviPhDI\nNE858mBRk2ZEqgsNhiQRrG3BecVue9X6NkOszfnx5WxhpzaFREUYOJ0rKv8Q1AR7\nQSAfav+3EAYkCNbWCv5HFqxBvrLeKISXnkdxUZXHdrNSgBvi15AAnvlo6KBgMy2E\nKj5/8IdDCC4yEQuEpOBQ5jc=\n-----END PRIVATE KEY-----\n",
  "client_email": "zurve-speech@ds-linx.iam.gserviceaccount.com",
  "client_id": "112562709672768656410",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/zurve-speech%40ds-linx.iam.gserviceaccount.com"
}"""
try:
    print("Google Cloud Speech thinks you said " + r.recognize_google_cloud(audio, credentials_json=GOOGLE_CLOUD_SPEECH_CREDENTIALS))
except sr.UnknownValueError:
    print("Google Cloud Speech could not understand audio")
except sr.RequestError as e:
    print("Could not request results from Google Cloud Speech service; {0}".format(e))

# recognize speech using Wit.ai
WIT_AI_KEY = "INSERT WIT.AI API KEY HERE"  # Wit.ai keys are 32-character uppercase alphanumeric strings
try:
    print("Wit.ai thinks you said " + r.recognize_wit(audio, key=WIT_AI_KEY))
except sr.UnknownValueError:
    print("Wit.ai could not understand audio")
except sr.RequestError as e:
    print("Could not request results from Wit.ai service; {0}".format(e))

# recognize speech using Microsoft Bing Voice Recognition
BING_KEY = "INSERT BING API KEY HERE"  # Microsoft Bing Voice Recognition API keys 32-character lowercase hexadecimal strings
try:
    print("Microsoft Bing Voice Recognition thinks you said " + r.recognize_bing(audio, key=BING_KEY))
except sr.UnknownValueError:
    print("Microsoft Bing Voice Recognition could not understand audio")
except sr.RequestError as e:
    print("Could not request results from Microsoft Bing Voice Recognition service; {0}".format(e))

# recognize speech using Houndify
HOUNDIFY_CLIENT_ID = "INSERT HOUNDIFY CLIENT ID HERE"  # Houndify client IDs are Base64-encoded strings
HOUNDIFY_CLIENT_KEY = "INSERT HOUNDIFY CLIENT KEY HERE"  # Houndify client keys are Base64-encoded strings
try:
    print("Houndify thinks you said " + r.recognize_houndify(audio, client_id=HOUNDIFY_CLIENT_ID, client_key=HOUNDIFY_CLIENT_KEY))
except sr.UnknownValueError:
    print("Houndify could not understand audio")
except sr.RequestError as e:
    print("Could not request results from Houndify service; {0}".format(e))

# recognize speech using IBM Speech to Text
IBM_USERNAME = "INSERT IBM SPEECH TO TEXT USERNAME HERE"  # IBM Speech to Text usernames are strings of the form XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
IBM_PASSWORD = "INSERT IBM SPEECH TO TEXT PASSWORD HERE"  # IBM Speech to Text passwords are mixed-case alphanumeric strings
try:
    print("IBM Speech to Text thinks you said " + r.recognize_ibm(audio, username=IBM_USERNAME, password=IBM_PASSWORD))
except sr.UnknownValueError:
    print("IBM Speech to Text could not understand audio")
except sr.RequestError as e:
    print("Could not request results from IBM Speech to Text service; {0}".format(e))
