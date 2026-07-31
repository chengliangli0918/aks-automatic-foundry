import logging
import os
import streamlit

from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import AssistantMessage, SystemMessage, UserMessage
from azure.identity import DefaultAzureCredential

# Read environment variables
assistant_profile = "I am a chatbot running on AKS and backed by Microsoft Foundry."
title = os.environ.get("TITLE", "Chatbot backed by AKS and Microsoft Foundry")
image_file_name = os.environ.get("IMAGE_FILE_NAME", "mychatbot.png")
system = os.environ.get("SYSTEM", assistant_profile)
model_endpoint = os.environ["MODEL_ENDPOINT"]
model_deployment = os.environ["MODEL_DEPLOYMENT"]
temperature = float(os.environ.get("TEMPERATURE", 0.5))
credential = DefaultAzureCredential()
model_client = None
image_width = 80
file = open("/etc/hostname", "r")
hostname = file.read()
file.close()

def main():
  configure_model_client()
  
  # customize streanlit ui
  customize_streamlit_ui()
  
  col1, col2 = streamlit.columns([1, 6])

  # Display the robot image
  with col1:
    streamlit.image(image = os.path.join("images", image_file_name), width = image_width)

  # Display the header
  with col2:
    streamlit.header(title)

  col3, col4, col5 = streamlit.columns([6, 1, 1])

  # Create text input in column 1
  with col3:
    user_input = streamlit.text_input(" ", key = "user", on_change = user_change)

  # Create send button in column 2
  with col4:
    streamlit.button(label = "Post")

  # Create cleam button in column 3
  with col5:
    streamlit.button(label = "Clean", on_click = clean_click)

  if streamlit.session_state['generated']:
    for i in range(len(streamlit.session_state['generated']) - 1, -1, -1):
       streamlit.markdown("**:blue[{}]**".format(streamlit.session_state['past'][i]))
       streamlit.markdown(streamlit.session_state['generated'][i])
       streamlit.markdown("---answered by " + str(hostname))
       streamlit.markdown("""---""")

def configure_model_client():
  global model_client

  model_client = ChatCompletionsClient(
    endpoint=model_endpoint,
    credential=credential,
    credential_scopes=["https://ai.azure.com/.default"],
  )

def customize_streamlit_ui():
  # Customize Streamlit UI using CSS
  streamlit.set_page_config(page_title='Chatbot on AKS powered by Microsoft Foundry')
  streamlit.markdown("""
  <style>

  div.stButton > button:first-child {
    background-color: #eb5424;
    color: white;
    font-size: 20px;
    font-weight: bold;
    border-radius: 0.5rem;
    padding: 0.5rem 1rem;
    border: none;
    box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
    width: 500 px;
    height: 42px;
    transition: all 0.2s ease-in-out;
  } 

  div.stButton > button:first-child:hover {
    transform: translateY(-3px);
    box-shadow: 0 1rem 2rem rgba(0,0,0,0.15);
  }

  div.stButton > button:first-child:active {
    transform: translateY(-1px);
    box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
  }

  div.stButton > button:focus:not(:focus-visible) {
    color: #FFFFFF;
  }

  @media only screen and (min-width: 1000px) {
    /* For desktop: */
    div {
      font-family: 'Roboto', sans-serif;
    }

    div.stButton > button:first-child {
      background-color: #0066cc;
      color: white;
      font-size: 20px;
      font-weight: bold;
      border-radius: 0.5rem;
      padding: 0.5rem 1rem;
      border: none;
      box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
      width: 500 px;
      height: 42px;
      transition: all 0.2s ease-in-out;
      position: relative;
      bottom: -32px;
      right: 0px;
    } 

    div.stButton > button:first-child:hover {
      transform: translateY(-3px);
      box-shadow: 0 1rem 2rem rgba(0,0,0,0.15);
    }

    div.stButton > button:first-child:active {
      transform: translateY(-1px);
      box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
    }

    div.stButton > button:focus:not(:focus-visible) {
      color: #FFFFFF;
    }

    input {
      border-radius: 0.5rem;
      padding: 0.5rem 1rem;
      border: none;
      box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
      transition: all 0.2s ease-in-out;
      height: 40px;
    }
  }

  footer {visibility: hidden;}
  </style>
  """, unsafe_allow_html=True)

  # Initialize Streamlit session state
  if 'prompts' not in streamlit.session_state:
    streamlit.session_state['prompts'] = [{"role": "system", "content": system}]

  if 'generated' not in streamlit.session_state:
    streamlit.session_state['generated'] = []

  if 'past' not in streamlit.session_state:
    streamlit.session_state['past'] = []

  if 'user' not in streamlit.session_state:
    streamlit.session_state['user'] = ""

# Send the user prompt to the configured model backend.
def generate_response(prompt):
  try:
    streamlit.session_state['prompts'].append({"role": "user", "content": prompt})

    message_types = {
      "system": SystemMessage,
      "user": UserMessage,
      "assistant": AssistantMessage,
    }
    messages = [
      message_types[item["role"]](content=item["content"])
      for item in streamlit.session_state['prompts']
    ]
    completion = model_client.complete(
      model=model_deployment,
      messages=messages,
      temperature=temperature,
    )
    
    message = completion.choices[0].message.content
    return message
  except Exception as e:
    logging.exception(f"Exception in generate_response: {e}")

# Reset Streamlit session state to start a new chat from scratch
def clean_click():
  streamlit.session_state['prompts'] = [{"role": "system", "content": system}]
  streamlit.session_state['past'] = []
  streamlit.session_state['generated'] = []
  streamlit.session_state['user'] = ""

# Handle on_change event for user input
def user_change():
  # Avoid handling the event twice when clicking the Send button
  chat_input = streamlit.session_state['user']
  streamlit.session_state['user'] = ""
  if (chat_input == '' or
      (len(streamlit.session_state['past']) > 0 and chat_input == streamlit.session_state['past'][-1])):
    return
  
  # Generate response using the Foundry model deployment.
  if chat_input !=  '':
    output = generate_response(chat_input)
    
    # store the output
    streamlit.session_state['past'].append(chat_input)
    streamlit.session_state['generated'].append(output)
    streamlit.session_state['prompts'].append({"role": "assistant", "content": output})

if __name__ == '__main__':
  main()