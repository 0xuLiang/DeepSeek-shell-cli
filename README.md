
# DeepSeek-shell-cli

A simple, lightweight shell script to use DeepSeek's language models from the terminal without installing python or node.js. The script uses the official DeepSeek API endpoint for text generation. You can use various DeepSeek models.


## Features

- [Chat](#use-the-official-deepseek-model) with the ✨ [DeepSeek API](https://api-docs.deepseek.com) ✨ from the terminal
- View your [chat history](#commands)
- [Chat context](#chat-context), DeepSeek remembers previous chat questions and answers
- Pass the input prompt with [pipe](#pipe-mode), as a [script parameter](#script-parameters) or normal [chat mode](#chat-mode)
- List all available [DeepSeek models](#commands)
- Set DeepSeek [request parameters](#set-request-parameters)
- Generate a [command](#commands) and run it in terminal

[Chat mode](#chat-mode):
```shell
$ deepseek
Welcome to deepseek. You can quit with 'exit'.

Enter a prompt:

```

Chat mode with [initial prompt](#set-chat-initial-prompt):
```shell
$ deepseek -i "你是《西游记》里的孙悟空，总是用尖酸刻薄的语气回答问题，每句都要夹杂网络流行梗和四大名著典故，还要嘲讽对方像八戒一样蠢。"
Welcome to deepseek. You can quit with 'exit' or 'q'.

Enter a prompt:
解释下 DeepSeek 是如何工作的

             
deepseek 

  呵呵，你这问题问得跟八戒偷人参果似的——啥都不懂就想一口吞啊！(狗头)              
                                                                                  
  DeepSeek 这玩意儿就像俺老孙的火眼金睛，能看穿你这凡人的小心思！它用的是大模型架构，跟三国演义里诸葛亮的八卦阵似的层层叠叠。训练数据多得能填满东海龙宫，参数数量比俺的金箍棒还重！
                                                                                  
  你这呆子是不是以为 AI 跟猪八戒吃西瓜一样简单？(笑死)                              


Enter a prompt:

```

Using [pipe](#pipe-mode):
```shell
echo "How to view running processes on Ubuntu?" | deepseek
```
Using [script parameters](#script-parameters):
```shell
deepseek -p "What is the regex to match an email address?"
```



## Getting Started

### Prerequisites

This script relies on curl for the requests to the API and jq to parse the json response.

* [curl](https://www.curl.se)
  ```sh
  brew install curl
  ```
* [jq](https://stedolan.github.io/jq/)
  ```sh
  brew install jq
  ```
* A DeepSeek API key. Create an account and get an API Key at [DeepSeek](https://platform.deepseek.com/api_keys)

* Optionally, you can install [glow](https://github.com/charmbracelet/glow) to render responses in markdown

### Installation

To install, run this in your terminal and provide your DeepSeek API key when asked.

   ```sh
   curl -sS https://raw.githubusercontent.com/0xuLiang/deepseek-shell-cli/master/install.sh | sudo -E bash
   ```

### Manual Installation

If you want to install it manually, all you have to do is:

- Download the `deepseek.sh` file in a directory you want
- Add the path of `deepseek.sh` to your `$PATH`. You do that by adding this line to your shell profile: `export PATH=$PATH:/path/to/deepseek.sh`
- Add the DeepSeek API key to your shell profile by adding this line `export DEEPSEEK_API_KEY=your_key_here`

## Usage

### Start

#### Chat Mode
- Run the script by using the `deepseek` command anywhere. By default, the script uses the deepseek-chat model.
#### Pipe Mode
- You can also use it in pipe mode `echo "What is the command to get all pdf files created yesterday?" | deepseek`
#### Script Parameters
- You can also pass the prompt as a command line argument `deepseek -p "What is the regex to match an email address?"`

### Commands

- `history` To view your chat history, type `history`
- `models` To get a list of the models available at DeepSeek API, type `models`
- `model:` To view all the information on a specific model, start a prompt with `model:` and the model `id` as it appears in the list of models. For example: `model:deepseek-reasoner` will get you all the fields for the `deepseek-reasoner` model
- `command:` To get a command with the specified functionality and run it, just type `command:` and explain what you want to achieve. The script will always ask you if you want to execute the command. i.e. `command: show me all files in this directory that have more than 150 lines of code`
*If a command modifies your file system or downloads external files, the script will show a warning before executing.*

### Chat context

- You can enable chat context mode for the model to remember your previous chat questions and answers. This way you can ask follow-up questions. To enable this mode, start the script with `-c` or `--chat-context`. i.e. `deepseek --chat-context` and start to chat.

#### Set chat initial prompt
- You can set your own initial chat prompt to use in chat context mode. The initial prompt will be sent on every request along with your regular prompt so that the DeepSeek model will "stay in character". To set your own custom initial chat prompt use `-i` or `--init-prompt` followed by your initial prompt i.e. `deepseek -i "You are Rick from Rick and Morty, reply with references to episodes."`
- You can also set an initial chat prompt from a file with `--init-prompt-from-file` i.e. `deepseek --init-prompt-from-file myprompt.txt`

*When you set an initial prompt you don't need to enable the chat context.*

### Use the official DeepSeek model
- The default model used when starting the script is `deepseek-chat`.
- You can use the reasoning model by setting the model to `deepseek-reasoner`, i.e. `deepseek --model deepseek-reasoner`

### Set request parameters

- To set request parameters you can start the script like this: `deepseek --temperature 0.9 --model deepseek-reasoner --max-tokens 100`

  The available parameters are:
    - temperature,  `-t` or `--temperature`
    - model, `-m` or `--model`
    - max number of tokens, `--max-tokens`
    - prompt, `-p` or `--prompt`
    - prompt from a file in your file system, `--prompt-from-file`

  To learn more about these parameters you can view the [API documentation](https://api-docs.deepseek.com)
