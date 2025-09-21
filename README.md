
# DeepSeek-shell-cli

一个简单、轻量级的 shell 脚本，让你可以在终端中使用 DeepSeek 的语言模型，无需安装 python 或 node.js。该脚本使用官方的 DeepSeek API 端点进行文本生成。你可以使用各种 DeepSeek 模型。


## 功能特性

- 在终端中与 ✨ [DeepSeek API](https://api-docs.deepseek.com) ✨ 进行[对话](#use-the-official-deepseek-model)
- [聊天模式](#chat-mode)，支持普通提示词或使用 `pb` 前缀从剪贴板获取内容
- 通过[管道](#pipe-mode)或[剪贴板](#pasteboard-mode)传递输入提示词，或作为[脚本参数](#script-parameters)
- [对话上下文](#chat-context)，DeepSeek 会记住之前的聊天问题和答案
- 基于系统语言的自动响应本地化
- 查看你的[聊天历史](#commands)
- 列出所有可用的 [DeepSeek 模型](#commands)
- 设置 DeepSeek [请求参数](#set-request-parameters)
- 生成[命令](#commands)并在终端中运行

[聊天模式](#chat-mode):
```shell
$ deepseek
Welcome to deepseek. You can quit with 'exit' or 'q'.

Enter a prompt:
# 普通提示词或使用 'pb' 前缀从剪贴板获取内容

```

带有[初始提示词](#set-chat-initial-prompt)的聊天模式:
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

使用[管道模式](#pipe-mode):
```shell
echo "How to view running processes on Ubuntu?" | deepseek
```
使用[脚本参数](#script-parameters):
```shell
deepseek -p "What is the regex to match an email address?"
```



## 快速开始

### 前置要求

该脚本依赖 curl 发送 API 请求，依赖 jq 解析 json 响应。

* [curl](https://www.curl.se)
  ```sh
  brew install curl
  ```
* [jq](https://stedolan.github.io/jq/)
  ```sh
  brew install jq
  ```
* DeepSeek API 密钥。在 [DeepSeek](https://platform.deepseek.com/api_keys) 创建账户并获取 API 密钥

* 可选：你可以安装 [glow](https://github.com/charmbracelet/glow) 来以 markdown 格式渲染响应

### 安装

要安装，请在终端中运行此命令，并在提示时提供你的 DeepSeek API 密钥。

   ```sh
   curl -sS https://raw.githubusercontent.com/0xuLiang/deepseek-shell-cli/master/install.sh | sudo -E bash
   ```

### 手动安装

如果你想手动安装，你需要做的就是：

- 下载 [`deepseek.sh`](https://raw.githubusercontent.com/0xuLiang/DeepSeek-shell-cli/master/deepseek.sh) 文件到你想要的目录
- 将路径添加到你的 `$PATH`。通过在你的 shell 配置文件中添加这一行来实现：`export PATH=$PATH:/path/to/deepseek.sh`
- 通过在你的 shell 配置文件中添加这一行来添加 DeepSeek API 密钥：`export DEEPSEEK_API_KEY=your_key_here`

## 使用方法

### 开始使用

#### 聊天模式
- 在任何地方使用 `deepseek` 命令运行脚本。默认情况下，脚本使用 `deepseek-chat` 模型。
- 输入前缀 `pb` 从剪贴板获取提示词：
  ```shell
  $ deepseek
  Enter a prompt:
  pb explain this # 自动获取剪贴板内容
  ```
#### 管道模式
- 你也可以在管道模式下使用：`echo "What is the command to get all pdf files created yesterday?" | deepseek`
#### 剪贴板模式
- 使用 `--prompt-from-pasteboard` 直接从剪贴板读取提示词：
  ```shell
  deepseek --prompt-from-pasteboard
  ```
#### 脚本参数
- 你也可以将提示词作为命令行参数传递：`deepseek -p "What is the regex to match an email address?"`
#### 本地化
- 响应现在默认使用你的系统语言（从环境变量或操作系统设置中检测）。
- 要覆盖，请在你的提示词中指定语言（例如："Respond in French: How does DeepSeek work?"）。

### 命令

- `history` 要查看你的聊天历史，输入 `history`
- `models` 要获取 DeepSeek API 可用模型的列表，输入 `models`
- `model:` 要查看特定模型的所有信息，以 `model:` 开头，后跟模型列表中显示的模型 `id`。例如：`model:deepseek-reasoner` 将获取 `deepseek-reasoner` 模型的所有字段
- `command:` 要获取具有指定功能的命令并运行它，只需输入 `command:` 并解释你想要实现的目标。脚本总是会询问你是否要执行该命令。例如：`command: show me all files in this directory that have more than 150 lines of code`
*如果命令修改你的文件系统或下载外部文件，脚本会在执行前显示警告。*
- `pb` 在聊天模式下，输入前缀 `pb` 来使用剪贴板中的提示词

### 对话上下文

- 你可以启用对话上下文模式，让模型记住你之前的聊天问题和答案。这样你可以提出后续问题。要启用此模式，使用 `-c` 或 `--chat-context` 启动脚本。例如：`deepseek --chat-context` 然后开始聊天。

#### 设置聊天初始提示词
- 你可以设置自己的初始聊天提示词在对话上下文模式中使用。初始提示词将与你的常规提示词一起在每次请求时发送，以便 DeepSeek 模型"保持角色"。要设置自己的自定义初始聊天提示词，使用 `-i` 或 `--init-prompt` 后跟你的初始提示词，例如：`deepseek -i "You are Rick from Rick and Morty, reply with references to episodes."`
- 你也可以使用 `--init-prompt-from-file` 从文件设置初始聊天提示词，例如：`deepseek --init-prompt-from-file myprompt.txt`

*当你设置初始提示词时，你不需要启用对话上下文。*

### 使用官方 DeepSeek 模型
- 启动脚本时使用的默认模型是 `deepseek-chat`。
- 你可以通过将模型设置为 `deepseek-reasoner` 来使用推理模型，例如：`deepseek --model deepseek-reasoner`

### 设置请求参数

- 要设置请求参数，你可以这样启动脚本：`deepseek --temperature 0.9 --model deepseek-reasoner --max-tokens 100`

  可用参数包括：
    - temperature，`-t` 或 `--temperature`
    - model，`-m` 或 `--model`
    - max number of tokens，`--max-tokens`
    - prompt，`-p` 或 `--prompt`
    - prompt from a file in your file system，`--prompt-from-file`
    - prompt from pasteboard，`--prompt-from-pasteboard`

  要了解更多关于这些参数的信息，你可以查看 [API 文档](https://api-docs.deepseek.com)
