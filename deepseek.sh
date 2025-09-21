#!/bin/bash

GLOBIGNORE="*"

get_system_language() {
  local detected_langs=()
  local current_lang

  if [ -n "$LANG" ]; then
    current_lang=$(echo "$LANG" | cut -d. -f1)
    detected_langs+=("$current_lang")
  fi

  if [ -n "$LC_ALL" ]; then
    current_lang=$(echo "$LC_ALL" | cut -d. -f1)
    detected_langs+=("$current_lang")
  fi

  # macOS
  if command -v defaults &> /dev/null; then
    current_lang=$(defaults read -g AppleLocale 2>/dev/null)
    if [ -n "$current_lang" ]; then
      detected_langs+=("$current_lang")
    fi
  fi

  # Linux
  if [ -f /etc/locale.conf ]; then
    current_lang=$(grep -oP "(?<=LANG=).+" /etc/locale.conf 2>/dev/null | cut -d. -f1)
    if [ -n "$current_lang" ]; then
      detected_langs+=("$current_lang")
    fi
  fi

  # return the first non-English language found
  for lang in "${detected_langs[@]}"; do
    if [[ ! "$lang" =~ ^en ]]; then
      echo "$lang"
      return 0
    fi
  done

  # if no non-English language found, return the first detected language if any
  if [ ${#detected_langs[@]} -gt 0 ]; then
    echo "${detected_langs[0]}"
    return 0
  fi

  echo "en_US"
  return 1
}

# language code to full name mapping for translation
get_language_name() {
  local lang_code="$1"
  case "$lang_code" in
    zh) echo "Chinese" ;;
    en) echo "English" ;;
    ja) echo "Japanese" ;;
    fr) echo "French" ;;
    de) echo "German" ;;
    es) echo "Spanish" ;;
    ko) echo "Korean" ;;
    ru) echo "Russian" ;;
    it) echo "Italian" ;;
    pt) echo "Portuguese" ;;
    *) echo "$lang_code" ;;  # fallback to code if unknown
  esac
}

CHAT_INIT_PROMPT="You are a helpful AI assistant trained by DeepSeek. You answer as concisely as possible for each response. If you are generating a list, do not have too many items. Keep the number of items short. Before each user prompt you will be given the chat history in Q&A form. Output your answer directly, with no labels in front. Today's date is $(date +%m/%d/%Y)."

SYSTEM_PROMPT="You are a helpful AI assistant trained by DeepSeek. Answer as concisely as possible. Default respond in the language $(get_system_language), unless the user prompt specifies otherwise. Current date: $(date +%m/%d/%Y)."

COMMAND_GENERATION_PROMPT="You are a Command Line Interface expert and your task is to provide functioning shell commands. Return a CLI command and nothing else - do not send it in a code block, quotes, or anything else, just the pure text CONTAINING ONLY THE COMMAND. If possible, return a one-line bash command or chain many commands together. Return ONLY the command ready to run in the terminal. The command should do the following:"

DEEPSEEK_BLUE_LABEL="\033[34mdeepseek \033[0m"
PROCESSING_LABEL="\n\033[90mProcessing... \033[0m\033[0K\r"
OVERWRITE_PROCESSING_LINE="             \033[0K\r"

if [[ -z "$DEEPSEEK_API_KEY" ]]; then
	echo "You need to set your DEEPSEEK_API_KEY to use this script"
	echo "You can set it temporarily by running this on your terminal: export DEEPSEEK_API_KEY=YOUR_KEY_HERE"
	exit 1
fi

usage() {
	cat <<EOF
A simple, lightweight shell script to use DeepSeek's Language Models from the terminal without installing Python or Node.js. Open Source and written in 100% Shell (Bash)

Commands:
  history - To view your chat history
  models - To get a list of the models available at DeepSeek API
  model: - To view all the information on a specific model, start a prompt with model: and the model id
  command: - To get a command with the specified functionality and run it, just type "command:" and explain what you want to achieve. The script will always ask you if you want to execute the command. i.e.
  "command: show me all files in this directory that have more than 150 lines of code"
  *If a command modifies your file system or dowloads external files the script will show a warning before executing.

Options:
  -i, --init-prompt          Provide initial chat prompt to use in context

  --init-prompt-from-file    Provide initial prompt from file

  -p, --prompt               Provide prompt instead of starting chat

  --prompt-from-file         Provide prompt from file

  --prompt-from-pasteboard   Provide prompt from pasteboard

  -b, --big-prompt           Allow multi-line prompts during chat mode

  -t, --temperature          Temperature

  --max-tokens               Max number of tokens

  -l, --list                 List available DeepSeek models

  -m, --model                Model to use (default: deepseek-chat)

  -tr, --translate           Translate piped input to specified language (default: zh)
                             Use -tr <lang> for specific language (e.g., en, ja)

  -c, --chat-context         For models that do not support chat context by
                             default, you can enable chat context, for the
                             model to remember your previous questions and
                             its previous answers.

EOF
}

# error handling function
# $1 should be the response body
handle_error() {
	if echo "$1" | jq -e '.error' >/dev/null; then
		echo -e "Your request to DeepSeek API failed: \033[0;31m$(echo "$1" | jq -r '.error.type')\033[0m"
		echo "$1" | jq -r '.error.message'
		exit 1
	fi
}

# request to DeepSeek API models endpoint. Returns a list of models
# takes no input parameters
list_models() {
	models_response=$(curl https://api.deepseek.com/v1/models \
		-sS \
		-H "Authorization: Bearer $DEEPSEEK_API_KEY")
	handle_error "$models_response"
	models_data=$(echo $models_response | jq -r -C '.data[] | {id, owned_by}')
	echo -e "$OVERWRITE_PROCESSING_LINE"
	echo -e "${DEEPSEEK_BLUE_LABEL}This is a list of models currently available at DeepSeek API:\n ${models_data}"
}

# request to DeepSeek API completions endpoint function
# $1 should be the request prompt
request_to_completions() {
	local prompt="$1"

	curl https://api.deepseek.com/v1/completions \
		-sS \
		-H 'Content-Type: application/json' \
		-H "Authorization: Bearer $DEEPSEEK_API_KEY" \
		-d '{
  			"model": "'"$MODEL"'",
  			"prompt": "'"$prompt"'",
  			"max_tokens": '$MAX_TOKENS',
  			"temperature": '$TEMPERATURE'
			}'
}

# request to DeepAPI API chat completion endpoint function
# $1 should be the message(s) formatted with role and content
request_to_chat() {
	local message="$1"
	escaped_system_prompt=$(escape "$SYSTEM_PROMPT")

	curl https://api.deepseek.com/v1/chat/completions \
		-sS \
		-H 'Content-Type: application/json' \
		-H "Authorization: Bearer $DEEPSEEK_API_KEY" \
		-d '{
            "model": "'"$MODEL"'",
            "messages": [
                {"role": "system", "content": "'"$escaped_system_prompt"'"},
                '"$message"'
                ],
            "max_tokens": '$MAX_TOKENS',
            "temperature": '$TEMPERATURE'
            }'
}

# build chat context before each request for /completions (all models except
# chat models)
# $1 should be the escaped request prompt,
# it extends $chat_context
build_chat_context() {
	local escaped_request_prompt="$1"
	if [ -z "$chat_context" ]; then
		chat_context="$CHAT_INIT_PROMPT\nQ: $escaped_request_prompt"
	else
		chat_context="$chat_context\nQ: $escaped_request_prompt"
	fi
}

escape() {
	echo "$1" | jq -Rrs 'tojson[1:-1]'
}

# maintain chat context function for /completions
# builds chat context from response,
# keeps chat context length under max token limit
# * $1 should be the escaped response data
# * it extends $chat_context
maintain_chat_context() {
	local escaped_response_data="$1"
	# add response to chat context as answer
	chat_context="$chat_context${chat_context:+\n}\nA: $escaped_response_data"
	# check prompt length, 1 word ~= 1.3 tokens
	# reserving 100 tokens for next user prompt
	while (($(echo "$chat_context" | wc -c) * 1, 3 > (MAX_TOKENS - 100))); do
		# remove first/oldest QnA from prompt
		chat_context=$(echo "$chat_context" | sed -n '/Q:/,$p' | tail -n +2)
		# add init prompt so it is always on top
		chat_context="$CHAT_INIT_PROMPT $chat_context"
	done
}

# build user chat message function for /chat/completions
# builds chat message before request,
# $1 should be the escaped request prompt,
# it extends $chat_message
build_user_chat_message() {
	local escaped_request_prompt="$1"
	if [ -z "$chat_message" ]; then
		chat_message="{\"role\": \"user\", \"content\": \"$escaped_request_prompt\"}"
	else
		chat_message="$chat_message, {\"role\": \"user\", \"content\": \"$escaped_request_prompt\"}"
	fi
}

# adds the assistant response to the message in chat format
# keeps messages length under max token limit
# * $1 should be the escaped response data
# * it extends and potentially shrinks $chat_message
add_assistant_response_to_chat_message() {
	local escaped_response_data="$1"
	# add response to chat context as answer
	chat_message="$chat_message, {\"role\": \"assistant\", \"content\": \"$escaped_response_data\"}"

	# transform to json array to parse with jq
	local chat_message_json="[ $chat_message ]"
	# check prompt length, 1 word ~= 1.3 tokens
	# reserving 100 tokens for next user prompt
	while (($(echo "$chat_message" | wc -c) * 1, 3 > (MAX_TOKENS - 100))); do
		# remove first/oldest QnA from prompt
		chat_message=$(echo "$chat_message_json" | jq -c '.[2:] | .[] | {role, content}')
	done
}

# parse command line arguments
while [[ "$#" -gt 0 ]]; do
	case $1 in
	-i | --init-prompt)
		CHAT_INIT_PROMPT="$2"
		SYSTEM_PROMPT="$2"
		CONTEXT=true
		shift
		shift
		;;
	--init-prompt-from-file)
		CHAT_INIT_PROMPT=$(cat "$2")
		SYSTEM_PROMPT=$(cat "$2")
		CONTEXT=true
		shift
		shift
		;;
	--prompt-from-pasteboard)
		prompt=$(pbpaste)
		shift
		;;
	-p | --prompt)
		prompt="$2"
		shift
		shift
		;;
	--prompt-from-file)
		prompt=$(cat "$2")
		shift
		shift
		;;
	-t | --temperature)
		TEMPERATURE="$2"
		shift
		shift
		;;
	--max-tokens)
		MAX_TOKENS="$2"
		shift
		shift
		;;
	-l | --list)
		list_models
		exit 0
		;;
	-m | --model)
		MODEL="$2"
		shift
		shift
		;;
	-tr | --translate)
		if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then
			TRANSLATE_LANG="$2"
			shift
		else
			TRANSLATE_LANG="${DEEPSEEK_DEFAULT_TRANSLATE_LANG:-zh}"
		fi
		shift
		;;
	--multi-line-prompt)
		MULTI_LINE_PROMPT=true
		shift
		;;
	-c | --chat-context)
		CONTEXT=true
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown parameter: $1"
		exit 1
		;;
	esac
done

# set defaults
TEMPERATURE=${TEMPERATURE:-0.7}
MAX_TOKENS=${MAX_TOKENS:-1024}
MODEL=${MODEL:-deepseek-chat}
CONTEXT=${CONTEXT:-false}
MULTI_LINE_PROMPT=${MULTI_LINE_PROMPT:-false}

# create our temp file for multi-line input
if [ $MULTI_LINE_PROMPT = true ]; then
	USER_INPUT_TEMP_FILE=$(mktemp)
	trap 'rm -f ${USER_INPUT}' EXIT
fi

# create history file
if [ ! -f ~/.deepseek_history ]; then
	touch ~/.deepseek_history
	chmod 600 ~/.deepseek_history
fi

running=true
# check input source and determine run mode

# prompt from argument, run on pipe mode (run once, no chat)
if [ -n "$prompt" ]; then
	pipe_mode_prompt=${prompt}
# if input file_descriptor is a terminal, run on chat mode
elif [ -t 0 ]; then
	echo -e "Welcome to deepseek. You can quit with '\033[34mexit\033[0m' or '\033[34mq\033[0m'."
# prompt from pipe or redirected stdin, run on pipe mode
else
	pipe_mode_prompt+=$(cat -)
fi

while $running; do

	if [ -z "$pipe_mode_prompt" ]; then
		if [ $MULTI_LINE_PROMPT = true ]; then
			echo -e "\nEnter a prompt: (Press Enter then Ctrl-D to send)"
			cat >"${USER_INPUT_TEMP_FILE}"
			input_from_temp_file=$(cat "${USER_INPUT_TEMP_FILE}")
			prompt=$(escape "$input_from_temp_file")
		else
			echo -e "\nEnter a prompt:"
			read -e prompt
			if [[ "$prompt" =~ ^[[:space:]]*pb($|[[:space:]]) ]]; then
				prompt="$(pbpaste)"$'\n'"${prompt#"${prompt%%pb*}pb"}"
			fi
		fi
		if [[ ! $prompt =~ ^(exit|q)$ ]]; then
			echo -ne $PROCESSING_LABEL
		fi
	else
		# set vars for pipe mode
		prompt=${pipe_mode_prompt}
		running=false
		DEEPSEEK_BLUE_LABEL=""
	fi

	# apply translation if enabled
	if [ -n "$TRANSLATE_LANG" ]; then
		lang_name=$(get_language_name "$TRANSLATE_LANG")
		prompt="Translate the following text to $lang_name, keeping the original formatting and layout intact: $prompt"
	fi

	if [[ $prompt =~ ^(exit|q)$ ]]; then
		running=false
	elif [[ "$prompt" == "history" ]]; then
		echo -e "\n$(cat ~/.deepseek_history)"
	elif [[ "$prompt" == "models" ]]; then
		list_models
	elif [[ "$prompt" =~ ^model: ]]; then
		models_response=$(curl https://api.deepseek.com/v1/models \
			-sS \
			-H "Authorization: Bearer $DEEPSEEK_API_KEY")
		handle_error "$models_response"
		model_data=$(echo $models_response | jq -r -C '.data[] | select(.id=="'"${prompt#*model:}"'")')
		echo -e "$OVERWRITE_PROCESSING_LINE"
		echo -e "${DEEPSEEK_BLUE_LABEL}Complete details for model: ${prompt#*model:}\n ${model_data}"
	elif [[ "$prompt" =~ ^command: ]]; then
		# escape quotation marks, new lines, backslashes...
		escaped_prompt=$(escape "$prompt")
		escaped_prompt=${escaped_prompt#command:}
		request_prompt=$COMMAND_GENERATION_PROMPT$escaped_prompt
		build_user_chat_message "$request_prompt"
		response=$(request_to_chat "$chat_message")
		handle_error "$response"
		response_data=$(echo $response | jq -r '.choices[].message.content')

		echo -e "$OVERWRITE_PROCESSING_LINE"
		echo -e "${DEEPSEEK_BLUE_LABEL} ${response_data}" | fold -s -w $COLUMNS
		dangerous_commands=("rm" ">" "mv" "mkfs" ":(){:|:&};" "dd" "chmod" "wget" "curl")

		for dangerous_command in "${dangerous_commands[@]}"; do
			if [[ "$response_data" == *"$dangerous_command"* ]]; then
				echo "Warning! This command can change your file system or download external scripts & data. Please do not execute code that you don't understand completely."
			fi
		done
		echo "Would you like to execute it? (Yes/No)"
		read run_answer
		if [ "$run_answer" == "Yes" ] || [ "$run_answer" == "yes" ] || [ "$run_answer" == "y" ] || [ "$run_answer" == "Y" ]; then
			echo -e "\nExecuting command: $response_data\n"
			eval $response_data
		fi

		add_assistant_response_to_chat_message "$(escape "$response_data")"

		timestamp=$(date +"%Y-%m-%d %H:%M")
		echo -e "$timestamp $prompt \n$response_data \n" >>~/.deepseek_history

	elif [[ "$MODEL" =~ ^deepseek-chat ]]; then
		# escape quotation marks, new lines, backslashes...
		request_prompt=$(escape "$prompt")

		build_user_chat_message "$request_prompt"
		response=$(request_to_chat "$chat_message")
		handle_error "$response"
		response_data=$(echo "$response" | jq -r '.choices[].message.content')

		echo -e "$OVERWRITE_PROCESSING_LINE"
		# if glow installed, print parsed markdown
		if command -v glow &>/dev/null; then
			echo -e "${DEEPSEEK_BLUE_LABEL}"
			echo "${response_data}" | glow -
		else
			echo -e "${DEEPSEEK_BLUE_LABEL}${response_data}" | fold -s -w "$COLUMNS"
		fi
		add_assistant_response_to_chat_message "$(escape "$response_data")"

		timestamp=$(date +"%Y-%m-%d %H:%M")
		echo -e "$timestamp $prompt \n$response_data \n" >>~/.deepseek_history
	else
		# escape quotation marks, new lines, backslashes...
		request_prompt=$(escape "$prompt")

		if [ "$CONTEXT" = true ]; then
			build_chat_context "$request_prompt"
		fi

		response=$(request_to_completions "$request_prompt")
		handle_error "$response"
		response_data=$(echo "$response" | jq -r '.choices[].text')

		echo -e "$OVERWRITE_PROCESSING_LINE"
		# if glow installed, print parsed markdown
		if command -v glow &>/dev/null; then
			echo -e "${DEEPSEEK_BLUE_LABEL}"
			echo "${response_data}" | glow -
		else
			# else remove empty lines and print
			formatted_text=$(echo "${response_data}" | sed '1,2d; s/^A://g')
			echo -e "${DEEPSEEK_BLUE_LABEL}${formatted_text}" | fold -s -w $COLUMNS
		fi

		if [ "$CONTEXT" = true ]; then
			maintain_chat_context "$(escape "$response_data")"
		fi

		timestamp=$(date +"%Y-%m-%d %H:%M")
		echo -e "$timestamp $prompt \n$response_data \n" >>~/.deepseek_history
	fi
done
