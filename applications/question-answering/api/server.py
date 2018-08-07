import os
from flask import Flask, request, Response, render_template
import pandas as pd
import unidecode

# # # # # BILBIOTECAS # # # # # 
import torch
import argparse
import code
import prettytable
import logging

from termcolor import colored
from drqa import pipeline
from drqa.retriever import utils

from googletrans import Translator
translator = Translator(service_urls=[
      'translate.google.com',
      'translate.google.co.kr',
    ])

import warnings
warnings.filterwarnings("ignore")

logger = logging.getLogger()
logger.setLevel(logging.INFO)
fmt = logging.Formatter('%(asctime)s: [ %(message)s ]', '%m/%d/%Y %I:%M:%S %p')
console = logging.StreamHandler()
console.setFormatter(fmt)
logger.addHandler(console)

# # # # # FUNCOES # # # # # 
def normalizaString(string):
    return unidecode.unidecode(str(string))

def getAnswer(question, candidates=None, top_n=1, n_docs=5):
    tSrc = 'pt'
    tDest = 'en'
    translate = True

    if translate:
        question = translator.translate(question, src = tSrc, dest = tDest).text
        
    predictions = DrQA.process(
        question, candidates, top_n, n_docs, return_context=True
    )
    #table = prettytable.PrettyTable(
    #    ['Rank', 'Answer', 'Doc', 'Answer Score', 'Doc Score']
    #)
    #for i, p in enumerate(predictions, 1):
    #    table.add_row([i, p['span'], p['doc_id'],
    #                   '%.5g' % p['span_score'],
    #                   '%.5g' % p['doc_score']])
    #print('Top Predictions:')
    #print(table)
    
    #print('\nContexts:')
    answers = []
    i = 1
    for p in predictions:
        context = translator.translate(p['context']['text'], src = tDest, dest = tSrc).text
        start = p['context']['start']
        end = p['context']['end']
        #output = p['context']
        answers.append({"rank": i, 
                        "answer": translator.translate(p['span'], src = tDest, dest = tSrc).text,
                        "doc_id": p['doc_id'],
                        "answer_score": p['span_score'],
                        "doc_score": p['doc_score'],
                        "context": {"text": context, "start": start, "end": end }
                        })
        i = i + 1
        #print('[ Doc = %s ]' % p['doc_id'])
        #print(output + '\n')
    return answers

# # # # # FUNCOES # # # # # 

# Instanciando DrQA com a base de dados e modelo Wikipedia
#drqaDir = '../DrQA'
#reader_model = drqaDir + '/data/reader/multitask.mdl'
#retriever_model = drqaDir + '/data/wikipedia/docs-tfidf-ngram=2-hash=16777216-tokenizer=simple.npz'
#doc_db = drqaDir + '/data/wikipedia/docs.db'
#tokenizer = 'corenlp'
 
# Carregando modelo e base Wikipedia
if os.environ.get("WERKZEUG_RUN_MAIN") == "true":
    print('Carregando modelo de QA e base Wikipedia/2016...', end = '')
    DrQA = pipeline.DrQA( cuda = torch.cuda.is_available() )
#
# DrQA = pipeline.DrQA(
#     cuda = torch.cuda.is_available(), # Disponibilidade do CUDA (proc. paralelo)
#     fixed_candidates = None,
#     reader_model = reader_model,
#     ranker_config = {'options': {'tfidf_path': retriever_model}},
#     db_config = {'options': {'db_path': doc_db}},
#     tokenizer = tokenizer
# )
    print(' Ok!')

app = Flask(__name__)

# for CORS
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,POST') # Put any other methods you need here
    return response

@app.route('/')
def index():
    return Response('5 - Q&A Intelligent System')

@app.route('/answer', methods = ['GET', 'POST'])
def answer():
    print(request)
    #print(request.form)
    #print(request.args)
    try:
        question = ''
        answers = False

        if request.method == 'POST':
            print(request.form['question'])

            # Parametros: pergunta
            question = request.form['question']

        else:
            #print('Only POST requests are accepted!')
            question = request.args.get('question')

        print('Question > ', question)  

        # Processo: resposta
        answers = getAnswer(question)

        return pd.io.json.dumps({"answer": answers}, ensure_ascii=False) #request.data
    except Exception as e:
        print('POST /answer error ' + str(e) )
        return str(e)

@app.route('/qa')
def qa():
    return render_template('index.html')

if __name__ == '__main__':

    app.run(debug=True, host='0.0.0.0', ssl_context='adhoc')#, use_reloader=False)

    #app.run(debug=True, host='0.0.0.0', ssl_context='adhoc')