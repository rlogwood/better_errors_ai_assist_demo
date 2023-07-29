import openai

OPEN_AI_KEY = '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'
openai.api_key = OPEN_AI_KEY

default_task = """
 You are to look for the errors in the given code and respond back with a brief but
 self explanatory correction or the errors in ruby or rails
 """

def ask_chat_gpt(context, task=default_task):
    # task is the task that you need to perform and context is the data on which you need to perform
    completion = (openai.ChatCompletion.create(
        model='gpt-3.5-turbo',
        messages=[{'role': 'user',
                   'content': f'Given the task [{task}] you have to perform the task on the data [{context}]'}]
    ))

    return completion.choices[0].message.content

